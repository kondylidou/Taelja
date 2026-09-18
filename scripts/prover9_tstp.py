#!/usr/bin/env python3
"""Turn the TSTP that Prover9's prooftrans writes into TPTP that Taelja reads.

prooftrans keeps Prover9's syntax: infix operators such as *, / and \\ and
function symbols that start with a capital letter, both of which TPTP does
not allow, and it marks every axiom as introduced(assumption).  Here an
infix application becomes a prefix one with the operator as a quoted
functor, a capitalized functor is quoted, and an axiom is sourced from the
input file.  Infix operators of equal precedence are not associated, since
prooftrans parenthesizes them.

Usage
  python3 scripts/prover9_tstp.py proof.tstp > proof.p
"""
import re
import sys

INFIX = {'*', '/', '\\', '+', '^', 'v'}
TOKEN = re.compile(r"""\s*(?:([A-Za-z_][A-Za-z0-9_]*)|(\d+)|('(?:[^'\\]|\\.)*')|("[^"]*")|(\$[a-z]+)|(!=|=|\||~|\(|\)|,|\*|/|\\|\+|\^))""")


def tokenize(s):
    pos, out = 0, []
    while pos < len(s):
        m = TOKEN.match(s, pos)
        if not m or m.end() == pos:
            raise ValueError(f'cannot tokenize at: {s[pos:pos + 30]!r}')
        pos = m.end()
        if m.group(1):
            out.append(('id', m.group(1)))
        elif m.group(2):
            out.append(('num', m.group(2)))
        elif m.group(3) or m.group(4) or m.group(5):
            out.append(('atom', m.group(3) or m.group(4) or m.group(5)))
        else:
            out.append(('op', m.group(6)))
    return out


def quote(f):
    return "'" + f.replace('\\', '\\\\').replace("'", "\\'") + "'"


class Parser:
    """Terms with infix operators of one precedence, given parenthesized."""
    def __init__(self, toks):
        self.toks, self.i = toks, 0

    def peek(self):
        return self.toks[self.i] if self.i < len(self.toks) else (None, None)

    def take(self):
        t = self.toks[self.i]; self.i += 1; return t

    def expect(self, v):
        t = self.take()
        if t[1] != v:
            raise ValueError(f'expected {v}, got {t}')

    def primary(self):
        k, v = self.take()
        if v == '(':
            t = self.term()
            self.expect(')')
            return t
        if k == 'id':
            if self.peek()[1] == '(':
                self.take()
                args = [self.term()]
                while self.peek()[1] == ',':
                    self.take(); args.append(self.term())
                self.expect(')')
                head = quote(v) if v[0].isupper() else v
                return f'{head}({",".join(args)})'
            # a capitalized name without arguments is a variable
            return v
        if k == 'num':
            return quote(v)
        if k == 'atom':
            return v
        raise ValueError(f'unexpected {(k, v)}')

    def term(self):
        t = self.primary()
        seen = None
        while self.peek()[1] in INFIX:
            op = self.take()[1]
            if seen is not None:
                raise ValueError(f'unparenthesized chain of {seen} and {op}')
            seen = op
            t = f'{quote(op)}({t},{self.primary()})'
        return t

    def literal(self):
        neg = ''
        if self.peek()[1] == '~':
            self.take(); neg = '~'
        t = self.term()
        if self.peek()[1] in ('=', '!='):
            op = self.take()[1]
            return f'{neg}{t} {op} {self.term()}'
        return neg + t

    def clause(self):
        lits = [self.literal()]
        while self.peek()[1] == '|':
            self.take(); lits.append(self.literal())
        if self.peek()[0] is not None:
            raise ValueError(f'trailing input at {self.peek()}')
        return ' | '.join(lits)


def convert_formula(s):
    return Parser(tokenize(s)).clause()


UNIT = re.compile(r'^cnf\(([^,]+),\s*([a-z_]+),\s*(.*?),\s*(introduced\(assumption,\[\],\[\]\)|inference\(.*)\)\.\s*$', re.S)


def convert(text, source):
    out, buf = [], ''
    for line in text.splitlines():
        if not buf and not line.startswith('cnf('):
            out.append(line); continue
        buf += line + '\n'
        if line.rstrip().endswith(').'):
            m = UNIT.match(buf.strip())
            if not m:
                raise ValueError(f'unit not understood: {buf[:80]!r}')
            name, role, formula, src = m.groups()
            formula = convert_formula(formula.strip())
            if src.startswith('introduced(assumption'):
                src = f"file('{source}', {name})"
            out.append(f'cnf({name}, {role}, {formula}, {src}).')
            buf = ''
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    path = sys.argv[1]
    sys.stdout.write(convert(open(path).read(), path.rsplit('/', 1)[-1]))
