#!/usr/bin/python3 -I
"""guard_exec_text.py — does a Bash command string EXECUTE a recursive force-delete, or only mention it?

Called by guard-bash.sh only after the raw command already matched the rm -rf pattern.
stdin: the command string.  stdout: exactly "ALLOW" or "BLOCK".
Fail closed: any parse doubt or error prints nothing / exits non-zero, and the caller blocks
(the raw command matched, so that is the pre-v0.2.4 behavior).

Method: a small lexer splits the command into
  exec text — what the shell itself will run (command substitutions $(..) and `..` included,
              even inside double quotes or unquoted heredoc bodies), and
  dropped text — single-quoted strings, double-quoted literals, heredoc bodies, comments.
Then:
  1. rm -rf in exec text                                                   -> BLOCK
  2. rm -rf only in dropped text, and something in the command could run that text
     (a shell/eval/ssh/xargs/tmux... word, a $VAR or ./script as the command, a script the
     command just wrote, an assignment, or an exec call in the text such as os.system)  -> BLOCK
  3. otherwise (grep patterns, echo, commit messages, python/cat heredoc bodies)          -> ALLOW
"""
import re
import sys

RM_RF = re.compile(r'\brm\s+-[a-zA-Z]*(rf|fr)\b')  # same pattern as guard-bash.sh, \s also spans lines

# Words that run a string or stdin as shell code. Matched as whole words anywhere in the exec text.
SHELLY = re.compile(
    r'(?:^|[\s;&|(!{`])(?:\S*/)?'
    r'(?:bash|sh|zsh|dash|ksh|mksh|fish|csh|tcsh|eval|source|exec|ssh|osascript|su|doas|xargs|'
    r'pwsh|parallel|watch|tmux|screen|herdr|at|batch|crontab|alias|chmod|script)'
    r'(?=$|[\s;&|)])')
# A call that hands a string to a shell from another language.
EXEC_CALL = re.compile(
    r'os\.system|\bsystem\s*\(|subprocess|\bpopen\s*\(|\bPopen\b|\bspawn\w*\s*\(|\bexec[lv]p?e?\s*\(|'
    r'\bexec\s*\(|execSync|execFile|child_process|shell\s*=\s*True|do shell script|Runtime\.getRuntime',
    re.I)
PERL_RUBY = re.compile(r'(?:^|[\s;&|(!{])(?:\S*/)?(?:perl|ruby)(?=$|[\s;&|)])')
CASE = re.compile(r'\bcase\b.*\besac\b', re.S)  # `case x in a)` breaks paren matching: test raw text
SEP = re.compile(r'[;&|\n(){}!`]')
ASSIGN = re.compile(r'^[A-Za-z_]\w*(\[[^\]]*\])?\+?=')
PREFIX = {'sudo', 'doas', 'env', 'nohup', 'nice', 'timeout', 'gtimeout', 'command', 'builtin', 'exec',
          'caffeinate', 'stdbuf', 'time', 'then', 'do', 'else', 'elif', 'if', 'while', 'until', 'xargs'}
# Options whose argument is a shell command (git rebase --exec/-x, find -exec, ...).
CMD_OPTS = {'--exec', '-x', '-exec', '-execdir', '-ok', '-okdir', '--command', '--run'}
REDIRECT = re.compile(r'(?:>>?|>\|)\s*([^\s;&|<>()]+)')
TEE = re.compile(r'\btee\s+(?:-\S+\s+)*([^\s;&|<>()]+)')


class ParseError(Exception):
    pass


class Chunk:
    def __init__(self, text, assigned=False, prev=''):
        self.text, self.assigned, self.prev = text, assigned, prev


class Lexer:
    def __init__(self):
        self.dropped = []   # Chunk: text the shell treats as data
        self.subexec = []   # exec text of every command substitution, in order

    def quoted(self, out, lit, subs):
        self.subexec.extend(subs)
        if lit and not re.search(r'\s', lit):
            out.append(lit)  # one shell word: 'rm' or "$DIR" — keep it, it can be a command or flag
        else:
            assigned = bool(out) and out[-1].endswith('=')
            before = ''.join(out).split()
            self.dropped.append(Chunk(lit, assigned, before[-1] if before else ''))
            out.append('Q')

    def dq(self, s, i, end):
        """Double-quote rules (also unquoted heredoc bodies when end is None)."""
        lit, subs = [], []
        while i < len(s):
            c = s[i]
            if end is not None and c == end:
                return i + 1, ''.join(lit), subs
            if c == '\\' and i + 1 < len(s):
                n = s[i + 1]
                if n in '$`"\\\n':
                    lit.append('' if n == '\n' else n)
                    i += 2
                    continue
                lit.append(c)
                i += 1
                continue
            if s.startswith('$(', i):
                i, sub = self.parse(s, i + 2, ')')
                subs.append(sub)
                lit.append('$_')
                continue
            if c == '`':
                i, sub = self.parse(s, i + 1, '`')
                subs.append(sub)
                lit.append('$_')
                continue
            lit.append(c)
            i += 1
        if end is not None:
            raise ParseError('unterminated double quote')
        return i, ''.join(lit), subs

    def heredoc_op(self, s, i):
        strip = False
        if i < len(s) and s[i] == '-':
            strip, i = True, i + 1
        while i < len(s) and s[i] in ' \t':
            i += 1
        word, quoted = [], False
        while i < len(s) and s[i] not in ' \t\n;&|<>()':
            c = s[i]
            if c in '\'"':
                j = s.find(c, i + 1)
                if j < 0:
                    raise ParseError('unterminated heredoc delimiter quote')
                word.append(s[i + 1:j])
                quoted, i = True, j + 1
            elif c == '\\' and i + 1 < len(s):
                word.append(s[i + 1])
                quoted, i = True, i + 2
            else:
                word.append(c)
                i += 1
        if not word:
            raise ParseError('empty heredoc delimiter')
        return i, (''.join(word), quoted, strip)

    def read_heredoc(self, s, i, hd):
        delim, quoted, strip = hd
        lines = []
        while True:
            if i >= len(s):
                raise ParseError('unterminated heredoc')
            j = s.find('\n', i)
            end = len(s) if j < 0 else j
            line = s[i:end]
            nxt = len(s) if j < 0 else j + 1
            if (line.lstrip('\t') if strip else line) == delim:
                body = '\n'.join(lines)
                if quoted:
                    self.dropped.append(Chunk(body))
                else:  # unquoted: $(..) and `..` in the body run
                    _, lit, subs = self.dq(body, 0, None)
                    self.subexec.extend(subs)
                    self.dropped.append(Chunk(lit))
                return nxt
            lines.append(line)
            i = nxt

    def parse(self, s, i, term):
        out, pending, depth = [], [], 0
        while i < len(s):
            c = s[i]
            if term == ')' and c == ')' and depth == 0:
                if pending:
                    raise ParseError('heredoc pending at )')
                return i + 1, ''.join(out)
            if term == '`' and c == '`':
                if pending:
                    raise ParseError('heredoc pending at `')
                return i + 1, ''.join(out)
            if c == '\\':
                if i + 1 < len(s):
                    if s[i + 1] != '\n':
                        out.append(s[i + 1])  # \rm -> rm, as the shell sees it
                    i += 2
                    continue
                out.append(c)
                i += 1
                continue
            if c == "'":
                j = s.find("'", i + 1)
                if j < 0:
                    raise ParseError('unterminated single quote')
                self.quoted(out, s[i + 1:j], [])
                i = j + 1
                continue
            if s.startswith("$'", i):
                j, buf = i + 2, []
                while j < len(s) and s[j] != "'":
                    step = 2 if s[j] == '\\' and j + 1 < len(s) else 1
                    buf.append(s[j:j + step])
                    j += step
                if j >= len(s):
                    raise ParseError("unterminated $'")
                raw = ''.join(buf)
                try:
                    lit = raw.encode('latin-1', 'backslashreplace').decode('unicode_escape')
                except Exception:
                    lit = raw
                self.quoted(out, lit, [])
                i = j + 1
                continue
            if c == '"' or s.startswith('$"', i):
                i, lit, subs = self.dq(s, i + (1 if c == '"' else 2), '"')
                self.quoted(out, lit, subs)
                continue
            if s.startswith('$(', i):
                i, sub = self.parse(s, i + 2, ')')
                self.subexec.append(sub)
                out.append('$_')
                continue
            if c == '`':
                i, sub = self.parse(s, i + 1, '`')
                self.subexec.append(sub)
                out.append('$_')
                continue
            if c == '#' and (i == 0 or s[i - 1] in ' \t\n;&|('):
                j = s.find('\n', i)
                j = len(s) if j < 0 else j
                self.dropped.append(Chunk(s[i:j]))
                i = j
                continue
            if c == '\n':
                out.append('\n')
                i += 1
                for hd in pending:
                    i = self.read_heredoc(s, i, hd)
                pending = []
                continue
            if s.startswith('<<<', i):
                out.append('<<<')
                i += 3
                continue
            if s.startswith('<<', i):
                i, hd = self.heredoc_op(s, i + 2)
                pending.append(hd)
                out.append('<<H ')
                continue
            if term == ')':
                if c == '(':
                    depth += 1
                elif c == ')':
                    depth -= 1
            out.append(c)
            i += 1
        if term is not None:
            raise ParseError('unterminated substitution')
        if pending:
            raise ParseError('unterminated heredoc')
        return i, ''.join(out)


def command_words(exec_text):
    """The word in command position of each simple command (after sudo/env/timeout/... prefixes)."""
    for seg in SEP.split(exec_text):
        words = seg.split()
        k = 0
        while k < len(words) and (words[k] in PREFIX or words[k].startswith('-') or ASSIGN.match(words[k])
                                  or re.fullmatch(r'\d+[smhd]?', words[k])):
            k += 1
        if k < len(words):
            yield words[k]


def verdict(cmd):
    if CASE.search(cmd):
        return 'BLOCK' if RM_RF.search(cmd) else 'ALLOW'
    lx = Lexer()
    _, main = lx.parse(cmd, 0, None)
    exec_text = '\n'.join([main] + lx.subexec)
    if RM_RF.search(exec_text):
        return 'BLOCK'
    hits = [c for c in lx.dropped if RM_RF.search(c.text)]
    if not hits:
        return 'ALLOW'
    # Could anything in this command run the dropped text as shell code?
    if SHELLY.search(exec_text):
        return 'BLOCK'
    written = set(REDIRECT.findall(exec_text)) | set(TEE.findall(exec_text))
    for w in command_words(exec_text):
        if w in ('.', 'source') or w.startswith(('$', './', '../', '~/')) or w in written:
            return 'BLOCK'
    perl_ruby = bool(PERL_RUBY.search(exec_text))
    for c in hits:
        if c.assigned or c.prev in CMD_OPTS or EXEC_CALL.search(c.text):
            return 'BLOCK'
        if perl_ruby and ('`' in c.text or re.search(r'\bqx\b|%x', c.text)):
            return 'BLOCK'
    return 'ALLOW'


if __name__ == '__main__':
    print(verdict(sys.stdin.read()))
