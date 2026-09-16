#!/usr/bin/env python3
"""Translate Taelja proof output to Lean 4 for verification.

Usage
  python taelja2lean.py proof.txt > proof.lean
  taelja ... | python taelja2lean.py > proof.lean
"""

import sys
import re
import os
from dataclasses import dataclass, field
from typing import List, Optional, Tuple, Dict, Set


# ─── Formula AST ─────────────────────────────────────────────────────────────

@dataclass
class Var:
    name: str  # uppercase

@dataclass
class Const:
    name: str  # lowercase, arity 0

@dataclass
class App:
    head: str
    args: list  # list of Term

Term = object  # Var | Const | App

@dataclass
class PredLit:   # predicate application or 0-ary pred
    head: str
    args: list   # list of Term

@dataclass
class EqLit:
    lhs: object  # Term
    rhs: object  # Term

@dataclass
class Not:
    items: list  # the conjuncts of the negated formula

@dataclass
class Implies:
    body: list   # list of PredLit | EqLit
    head: object # PredLit | EqLit

Lit = object  # PredLit | EqLit | Implies


# ─── Proof step AST ──────────────────────────────────────────────────────────

@dataclass
class Ref:
    kind: str   # 'axiom' or 'lemma'
    num: int
    rw: bool = False
    direction: str = 'LR'  # 'LR' or 'RL'

@dataclass
class HaveStep:
    lit: object
    ref: Ref

@dataclass
class AndStep:
    lit: object
    ref: Ref

@dataclass
class HenceStep:
    lit: object
    ref: Ref

@dataclass
class EqChainStep:
    term: object  # Term
    ref: Ref

@dataclass
class HaveHenceProof:
    steps: list  # HaveStep | AndStep | HenceStep

@dataclass
class EqChainProof:
    start: object  # Term
    steps: list    # list of EqChainStep

@dataclass
class AxiomDecl:
    num: int
    formula: object  # Lit

@dataclass
class LemmaDecl:
    num: int
    formula: object
    proof: object

@dataclass
class GoalDecl:
    num: int
    formula: object
    proof: object

@dataclass
class Document:
    axioms: list
    lemmas: list
    goals: list


# ─── Tokenizer ───────────────────────────────────────────────────────────────

_SYM_CHARS = '+*/^<>-%&|~'


def _symbolic_ident_end(s: str, i: int):
    """End index of a run of operator characters at s[i] if it is applied as a
    function symbol, immediately followed by '(', and None otherwise."""
    j = i
    while j < len(s) and s[j] in _SYM_CHARS:
        j += 1
    return j if j > i and j < len(s) and s[j] == '(' else None


def tokenize(s: str) -> list:
    tokens = []
    i = 0
    while i < len(s):
        if s[i].isspace():
            i += 1
        elif s[i:i+2] == '=>':
            tokens.append(('ARROW', '=>'))
            i += 2
        elif s[i:i+2] == '/\\':
            tokens.append(('AND', '/\\'))
            i += 2
        elif s[i:i+2] == 'R-':
            # might be an R->L direction marker, handled at a higher level
            tokens.append(('IDENT', 'R'))
            i += 1
        elif s[i] == '~':
            # negation, which TPTP names never contain
            tokens.append(('NOT', '~'))
            i += 1
        elif s[i] in _SYM_CHARS and _symbolic_ident_end(s, i) is not None:
            # symbolic function/predicate name such as +(X,Y) or >(X,Y)
            j = _symbolic_ident_end(s, i)
            tokens.append(('IDENT', s[i:j]))
            i = j
        elif s[i] == '(':
            tokens.append(('LPAREN', '('))
            i += 1
        elif s[i] == ')':
            tokens.append(('RPAREN', ')'))
            i += 1
        elif s[i] == ',':
            tokens.append(('COMMA', ','))
            i += 1
        elif s[i] == '=':
            tokens.append(('EQ', '='))
            i += 1
        elif s[i] == '-':
            tokens.append(('MINUS', '-'))
            i += 1
        elif s[i] == '>':
            tokens.append(('GT', '>'))
            i += 1
        elif s[i:i+2] == '!=':
            tokens.append(('NEQ', '!='))
            i += 2
        elif s[i].isalnum() or s[i] == '_':
            j = i
            while j < len(s) and (s[j].isalnum() or s[j] == '_'):
                j += 1
            tokens.append(('IDENT', s[i:j]))
            i = j
        else:
            i += 1
    return tokens


# ─── Formula parser ──────────────────────────────────────────────────────────

class Parser:
    def __init__(self, tokens):
        self.toks = tokens
        self.pos = 0

    def peek(self):
        return self.toks[self.pos] if self.pos < len(self.toks) else ('EOF', '')

    def consume(self, kind=None):
        tok = self.toks[self.pos]
        if kind and tok[0] != kind:
            raise ValueError(f'Expected {kind}, got {tok}')
        self.pos += 1
        return tok

    def at_end(self):
        return self.pos >= len(self.toks)

    def parse_formula(self):
        """A formula is body_list '=>' atom, or an atom.  A body item may be a
        parenthesized formula, as a goal's Horn hypothesis is."""
        atoms = [self.parse_unit()]
        while not self.at_end() and self.peek()[0] == 'AND':
            self.consume('AND')
            atoms.append(self.parse_unit())
        if not self.at_end() and self.peek()[0] == 'ARROW':
            self.consume('ARROW')
            head = self.parse_unit()
            return Implies(atoms, head)
        if len(atoms) == 1:
            return atoms[0]
        # bare conjunction (shouldn't happen at top level, but handle)
        return atoms[0]

    def parse_unit(self):
        """An atom, a formula in parentheses, or a negated conjunction."""
        if self.peek()[0] == 'NOT':
            self.consume('NOT')
            self.consume('LPAREN')
            items = [self.parse_unit()]
            while self.peek()[0] == 'AND':
                self.consume('AND')
                items.append(self.parse_unit())
            self.consume('RPAREN')
            return Not(items)
        if self.peek()[0] == 'LPAREN':
            self.consume('LPAREN')
            f = self.parse_formula()
            self.consume('RPAREN')
            return f
        return self.parse_atom()

    def parse_atom(self):
        """An atom is term '=' term, or a predicate application."""
        t = self.parse_term()
        if not self.at_end() and self.peek()[0] == 'EQ':
            self.consume('EQ')
            rhs = self.parse_term()
            # t is a Var, Const or App, so treat the LHS as a term
            return EqLit(t, rhs)
        # t should be an App or bare name, so treat it as a predicate
        if isinstance(t, App):
            return PredLit(t.head, t.args)
        elif isinstance(t, Const):
            return PredLit(t.name, [])
        elif isinstance(t, Var):
            return PredLit(t.name, [])
        return t

    def parse_term(self):
        """A term is name '(' term_list ')', or a name."""
        if self.peek()[0] != 'IDENT':
            raise ValueError(f'Expected IDENT, got {self.peek()}')
        name = self.consume('IDENT')[1]
        if not self.at_end() and self.peek()[0] == 'LPAREN':
            self.consume('LPAREN')
            args = []
            if self.peek()[0] != 'RPAREN':
                args.append(self.parse_term())
                while self.peek()[0] == 'COMMA':
                    self.consume('COMMA')
                    args.append(self.parse_term())
            self.consume('RPAREN')
            return App(name, args)
        # bare name
        if name[0].isupper():
            return Var(name)
        return Const(name)


def parse_formula_str(s: str) -> object:
    s = s.strip()
    if not s:
        return None
    toks = tokenize(s)
    p = Parser(toks)
    return p.parse_formula()

def parse_term_str(s: str) -> object:
    s = s.strip()
    toks = tokenize(s)
    p = Parser(toks)
    return p.parse_term()


# ─── Taelja text parser ───────────────────────────────────────────────────────

def parse_ref(s: str) -> Ref:
    """Parse 'axiom N', 'lemma N', 'axioms', 'rw axiom N', 'rw axiom N R->L' etc."""
    s = s.strip()
    rw = False
    direction = 'LR'
    if s.startswith('rw '):
        rw = True
        s = s[3:].strip()
    if 'R->L' in s:
        direction = 'RL'
        s = s.replace('R->L', '').strip()
    # 'axioms' (plural, no number) is a fallback justification when no specific
    # axiom name is tracked (e.g. derived inner nucleus or Twee-derived block).
    if s == 'axioms':
        return Ref('axioms', 0, rw, direction)
    # the conclusion follows from a derived $false (contradictory axioms)
    if s == 'contradiction':
        return Ref('contradiction', 0, rw, direction)
    # a hypothesis of the goal, assumed at the start of its proof, numbered
    # as the goal states them
    m = re.match(r'assumption(?:\s+(\d+))?$', s)
    if m:
        return Ref('assumption', int(m.group(1) or 0), rw, direction)
    # the goal's hypotheses discharged, which the intro at the start already did
    if s == 'discharge':
        return Ref('discharge', 0, rw, direction)
    m = re.match(r'(axiom|lemma)\s+(\d+)', s)
    if not m:
        raise ValueError(f'Cannot parse ref: {s!r}')
    kind = m.group(1)
    num = int(m.group(2))
    return Ref(kind, num, rw, direction)


def parse_proof_block(lines: list) -> object:
    """Parse a proof block, the non-empty stripped lines after the Proof line."""
    if not lines:
        return HaveHenceProof([])

    # Detect an EqChain, whose first line is a bare term rather than have, and or hence
    first = lines[0].strip()
    if not (first.startswith('have ') or first.startswith('hence ') or
            first.startswith('and ') or first.startswith('by ') or
            first.startswith('assume ')):
        return parse_eqchain(lines)
    return parse_havehence(lines)


def parse_eqchain(lines: list) -> EqChainProof:
    """Parse equational chain proof."""
    # lines look like
    #   term1
    #   = { by axiom N [R->L] }
    #     term2
    # The first line is the start term, then come (= { by ... }, term) pairs.
    i = 0
    start_str = lines[i].strip()
    start = parse_term_str(start_str)
    i += 1
    steps = []
    while i < len(lines):
        eq_line = lines[i].strip()
        i += 1
        if i >= len(lines):
            break
        term_line = lines[i].strip()
        i += 1
        # eq_line is "= { by axiom N [R->L] }"
        m = re.match(r'=\s*\{\s*by\s+(.+?)\s*\}', eq_line)
        if not m:
            break
        ref = parse_ref(m.group(1))
        term = parse_term_str(term_line)
        steps.append(EqChainStep(term, ref))
    return EqChainProof(start, steps)


def parse_havehence(lines: list) -> HaveHenceProof:
    """Parse have/and/hence proof."""
    steps = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        i += 1
        if not line or line.startswith('by '):
            continue

        if line.startswith('assume '):
            steps.append(HaveStep(parse_formula_str(line[7:].strip()), Ref('assumption', 0)))

        elif line.startswith('have '):
            lit_str = line[5:].strip()
            # next non-empty line should be 'by ...'
            while i < len(lines) and not lines[i].strip():
                i += 1
            by_line = lines[i].strip() if i < len(lines) else ''
            i += 1
            ref = parse_ref(by_line[3:]) if by_line.startswith('by ') else Ref('axiom', 0)
            steps.append(HaveStep(parse_formula_str(lit_str), ref))

        elif line.startswith('and '):
            lit_str = line[4:].strip()
            while i < len(lines) and not lines[i].strip():
                i += 1
            by_line = lines[i].strip() if i < len(lines) else ''
            i += 1
            ref = parse_ref(by_line[3:]) if by_line.startswith('by ') else Ref('axiom', 0)
            steps.append(AndStep(parse_formula_str(lit_str), ref))

        elif line.startswith('hence '):
            lit_str = line[6:].strip()
            while i < len(lines) and not lines[i].strip():
                i += 1
            by_line = lines[i].strip() if i < len(lines) else ''
            i += 1
            ref = parse_ref(by_line[3:]) if by_line.startswith('by ') else Ref('axiom', 0)
            steps.append(HenceStep(parse_formula_str(lit_str), ref))

    return HaveHenceProof(steps)


def parse_document(text: str) -> Document:
    """Parse a complete Taelja proof document."""
    axioms = []
    lemmas = []
    goals = []

    lines = text.splitlines()
    i = 0

    def collect_proof_lines(start):
        """Collect non-empty lines that form the proof body."""
        j = start
        proof_lines = []
        while j < len(lines):
            line = lines[j]
            stripped = line.strip()
            # Stop at a new top-level declaration
            if re.match(r'^(Axiom|Lemma|Goal)\s+\d+:', stripped):
                break
            proof_lines.append(line)
            j += 1
        return proof_lines, j

    while i < len(lines):
        line = lines[i].strip()
        i += 1

        m_ax = re.match(r'^Axiom\s+(\d+):\s*(.+)$', line)
        if m_ax:
            num = int(m_ax.group(1))
            formula = parse_formula_str(m_ax.group(2))
            axioms.append(AxiomDecl(num, formula))
            continue

        m_lem = re.match(r'^Lemma\s+(\d+):\s*(.+)$', line)
        if m_lem:
            num = int(m_lem.group(1))
            formula = parse_formula_str(m_lem.group(2))
            # skip the Proof line
            while i < len(lines) and lines[i].strip() != 'Proof:':
                i += 1
            i += 1  # skip the Proof line
            proof_lines, i = collect_proof_lines(i)
            proof = parse_proof_block([l for l in proof_lines if l.strip()])
            lemmas.append(LemmaDecl(num, formula, proof))
            continue

        m_goal = re.match(r'^Goal\s+(\d+):\s*(.+)$', line)
        if m_goal:
            num = int(m_goal.group(1))
            formula = parse_formula_str(m_goal.group(2))
            while i < len(lines) and lines[i].strip() != 'Proof:':
                i += 1
            i += 1
            proof_lines, i = collect_proof_lines(i)
            proof = parse_proof_block([l for l in proof_lines if l.strip()])
            goals.append(GoalDecl(num, formula, proof))
            continue

    return Document(axioms, lemmas, goals)


# ─── Symbol analysis ──────────────────────────────────────────────────────────

def vars_in_term(t) -> Set[str]:
    if isinstance(t, Var):
        return {t.name}
    if isinstance(t, Const):
        return set()
    if isinstance(t, App):
        s = set()
        for a in t.args:
            s |= vars_in_term(a)
        return s
    return set()

def vars_in_lit(f) -> Set[str]:
    if isinstance(f, PredLit):
        s = set()
        for a in f.args:
            s |= vars_in_term(a)
        return s
    if isinstance(f, EqLit):
        return vars_in_term(f.lhs) | vars_in_term(f.rhs)
    if isinstance(f, Implies):
        s = set()
        for b in f.body:
            s |= vars_in_lit(b)
        s |= vars_in_lit(f.head)
        return s
    if isinstance(f, Not):
        s = set()
        for b in f.items:
            s |= vars_in_lit(b)
        return s
    return set()

def collect_symbols(doc: Document) -> Tuple[Dict, Dict, Set]:
    """Returns function arities, predicate arities and the set of constants."""
    functions = {}   # name -> arity (functions and constants arity=0)
    predicates = {}  # name -> arity
    constants = set()

    def visit_term(t, in_eq_pos=True):
        """Visit a term (in_eq_pos=True means it could be a function/const)."""
        if isinstance(t, Var):
            return
        if isinstance(t, Const):
            constants.add(t.name)
            if t.name not in functions:
                functions[t.name] = 0
            return
        if isinstance(t, App):
            # It's in function position
            if t.head not in functions or functions[t.head] < len(t.args):
                functions[t.head] = len(t.args)
            for a in t.args:
                visit_term(a)

    def visit_atom(f, top_level=True):
        """Visit a formula atom."""
        if isinstance(f, PredLit):
            if is_falsum(f):
                return
            if top_level:
                if f.head not in predicates or predicates[f.head] < len(f.args):
                    predicates[f.head] = len(f.args)
            for a in f.args:
                visit_term(a)
        elif isinstance(f, EqLit):
            visit_term(f.lhs)
            visit_term(f.rhs)
        elif isinstance(f, Implies):
            for b in f.body:
                visit_atom(b, top_level=True)
            visit_atom(f.head, top_level=True)

    def visit_formula(f):
        visit_atom(f, top_level=True)

    def visit_proof(proof):
        if isinstance(proof, HaveHenceProof):
            for step in proof.steps:
                visit_formula(step.lit)
        elif isinstance(proof, EqChainProof):
            visit_term(proof.start)
            for step in proof.steps:
                visit_term(step.term)

    for ax in doc.axioms:
        visit_formula(ax.formula)
    for lem in doc.lemmas:
        visit_formula(lem.formula)
        visit_proof(lem.proof)
    for g in doc.goals:
        visit_formula(g.formula)
        visit_proof(g.proof)

    # Remove predicates from functions and vice versa (prefer predicate)
    for name in list(predicates.keys()):
        if name in functions:
            del functions[name]

    # Detect the "= true" encoding.  Predicates that start an eq-chain and whose
    # head changes in an intermediate step are really α-valued functions, so their
    # Lean type becomes α → ... → α rather than Prop.
    func_preds: set = set()

    def check_reclassify(proof):
        if not isinstance(proof, EqChainProof) or not proof.steps:
            return
        if not isinstance(proof.start, App):
            return
        sh = proof.start.head
        if sh not in predicates:
            return
        steps = proof.steps
        # Exclude the terminal = true step from the head-change check
        if isinstance(steps[-1].term, Const) and steps[-1].term.name == 'true':
            steps = steps[:-1]
        for step in steps:
            t = step.term
            if not (isinstance(t, App) and t.head == sh):
                func_preds.add(sh)
                return

    for lem in doc.lemmas:
        check_reclassify(lem.proof)
    for g in doc.goals:
        check_reclassify(g.proof)

    for name in func_preds:
        arity = predicates.pop(name)
        functions[name] = max(functions.get(name, 0), arity)

    return functions, predicates, constants, func_preds


# ─── Formula → Lean type string ───────────────────────────────────────────────

def lean_term(t, var_map: dict) -> str:
    """Convert a term to Lean string, mapping uppercase vars via var_map."""
    if isinstance(t, Var):
        return var_map.get(t.name, t.name.lower())
    if isinstance(t, Const):
        return lean_name(t.name)
    if isinstance(t, App):
        args = ' '.join(f'({lean_term(a, var_map)})' if isinstance(a, App) and a.args
                        else lean_term(a, var_map)
                        for a in t.args)
        head = lean_name(t.head)
        if args:
            return f'{head} {args}'
        return head
    return str(t)

def lean_name(name: str) -> str:
    """Escape Lean 4 keywords that would be invalid as identifiers."""
    keywords = {
        # declaration keywords
        'axiom', 'def', 'theorem', 'lemma', 'class', 'structure', 'instance',
        'abbrev', 'variable', 'universe', 'example', 'noncomputable', 'attribute',
        'namespace', 'end', 'section', 'open', 'import', 'export',
        # expression / tactic keywords
        'fun', 'let', 'in', 'do', 'return', 'if', 'then', 'else', 'match', 'with',
        'have', 'show', 'from', 'where', 'by', 'exact', 'apply', 'intro', 'calc',
        'rw', 'simp', 'type', 'sort', 'prop', 'extends',
        # Lean 4 built-in values/functions that conflict when declared as axioms
        'true', 'false', 'not', 'and', 'or', 'id',
        # further reserved words / tactic keywords seen as TPTP symbols
        'at', 'only', 'using', 'to', 'as', 'deriving', 'inductive', 'mutual',
        'private', 'protected', 'partial', 'unsafe', 'opaque', 'omit', 'include',
        'notation', 'macro', 'syntax', 'elab', 'set_option', 'termination_by',
        'decreasing_by', 'generalizing', 'suffices', 'obtain', 'rcases', 'cases',
        'induction', 'constructor', 'left', 'right', 'exists', 'forall', 'nat',
        'int', 'string', 'list', 'option', 'unit', 'prod', 'sum', 'eq', 'ne',
        'iff', 'implies', 'xor', 'bool', 'decide', 'trivial', 'rfl', 'symm',
        'trans', 'congr', 'funext', 'ext', 'simp_all', 'omega', 'norm_num',
        'sorry', 'admit', 'done', 'skip', 'first', 'try', 'repeat', 'all_goals',
        'any_goals', 'case', 'next', 'rename_i', 'intros', 'revert', 'clear',
        'subst', 'exfalso', 'contradiction', 'absurd', 'assumption', 'refine',
        'calc', 'show', 'change', 'unfold', 'delta', 'dsimp', 'field', 'ring',
    }
    if name.lower() in keywords:
        return name + '_'
    if name and name[0].isdigit():
        # numerals are not identifiers (SYO632-1 has a constant named 0)
        return 'n_' + name
    if name and not (name[0].isalnum() or name[0] == '_'):
        # symbolic function symbols (e.g. "+", ">") are not Lean identifiers
        words = {'+': 'plus', '-': 'minus', '*': 'times', '/': 'div', '^': 'pow',
                 '<': 'lt', '>': 'gt', '%': 'mod', '&': 'and', '|': 'or', '~': 'tilde'}
        return 'op_' + '_'.join(words.get(c, f'c{ord(c)}') for c in name)
    return name

# Set by emit_lean before emitting, the predicates reclassified as α-valued
# functions.  lean_lit appends "= true_" for these symbols.
_func_predicates: set = frozenset()

def is_falsum(f) -> bool:
    """The reserved TPTP atom $false (the tokenizer may drop the '$')."""
    return isinstance(f, PredLit) and not f.args and f.head.lstrip('$') == 'false'


def lean_lit(f, var_map: dict) -> str:
    """Convert a literal/formula to Lean Prop string."""
    if isinstance(f, PredLit):
        if is_falsum(f):
            return 'False'
        head = lean_name(f.head)
        if not f.args:
            if f.head in _func_predicates:
                return f'{head} = true_'
            return head
        parts = []
        for a in f.args:
            s = lean_term(a, var_map)
            # Parenthesise compound terms
            if isinstance(a, App) and a.args:
                s = f'({s})'
            parts.append(s)
        body = f'{head} {" ".join(parts)}'
        if f.head in _func_predicates:
            return f'{body} = true_'
        return body
    if isinstance(f, EqLit):
        lhs = lean_term(f.lhs, var_map)
        rhs = lean_term(f.rhs, var_map)
        if isinstance(f.lhs, App) and f.lhs.args:
            lhs = f'({lhs})'
        if isinstance(f.rhs, App) and f.rhs.args:
            rhs = f'({rhs})'
        return f'{lhs} = {rhs}'
    if isinstance(f, Implies):
        parts = [nested_lit(b, var_map) for b in f.body]
        head = lean_lit(f.head, var_map)
        return ' → '.join(parts + [head])
    if isinstance(f, Not):
        return '¬(' + ' ∧ '.join(nested_lit(b, var_map) for b in f.items) + ')'
    return str(f)


def nested_lit(b, var_map):
    """A body item.  A Horn hypothesis of a goal, or a conjunct of its negated
    conclusion, is a formula of its own, bound over the variables that are its
    alone, and so is an atom while a goal or lemma statement is rendered.  In
    an axiom a plain atom shares the clause's variables."""
    if not isinstance(b, (Implies, Not)) and not _closed_hyps:
        return lean_lit(b, var_map)
    own = [v for v in ordered_vars(b) if v not in var_map]
    vm = dict(var_map)
    for i, v in enumerate(own):
        vm[v] = lean_var_name(v, len(var_map) + i)
    inner = lean_lit(b, vm)
    if own:
        return '(∀ ' + ' '.join(f'({vm[v]} : α)' for v in own) + f', {inner})'
    return f'({inner})'


def nested_only_vars(formula):
    """Variables that occur only inside a goal's hypotheses or negated
    conjuncts, which those formulas bind themselves.  A variable the
    conclusion shares is the goal's own."""
    if isinstance(formula, Not):
        return set(vars_in_lit(formula))
    if not isinstance(formula, Implies):
        return set()
    outer = set() if isinstance(formula.head, Not) else set(vars_in_lit(formula.head))
    inner = set(vars_in_lit(formula.head)) if isinstance(formula.head, Not) else set()
    for b in formula.body:
        (inner if isinstance(b, (Implies, Not)) or _closed_hyps else outer).update(vars_in_lit(b))
    return inner - outer

def lean_type(formula, all_vars: list, extra_vars=None) -> Tuple[str, dict]:
    """
    Return (lean_type_string, var_map), where var_map maps uppercase variable
    names to Lean lowercase names.  Wraps in ∀ if there are free variables.
    extra_vars are more Taelja variables to quantify, used when an EqChainProof
    has chain-internal variables not in the formula.
    """
    fvars = sorted((vars_in_lit(formula) - nested_only_vars(formula))
                   | (set(extra_vars) if extra_vars else set()))
    var_map = {v: lean_var_name(v, i) for i, v in enumerate(fvars)}
    body = lean_lit(formula, var_map)

    if isinstance(formula, Implies):
        type_str = body
    else:
        type_str = body

    if fvars:
        forall_vars = ' '.join(f'({var_map[v]} : α)' for v in fvars)
        type_str = f'∀ {forall_vars}, {type_str}'

    return type_str, var_map

# Set by emit_lean to the Lean names of all declared symbols, so a variable's
# lowercase name never shadows a constant or function, as function y and
# variable Y made `f x (y x) y` ill-typed on SYN339-1.
_symbol_names: set = frozenset()
# Lean name of a declared constant, used as the value of a variable that a
# proof step leaves unconstrained (a premise's ∀-variable the conclusion never
# mentions, a chain-only lemma binder in a ground chain).  None if the problem
# has no constants.
_filler_const = None

def lean_var_name(uppercase_name: str, idx: int) -> str:
    """Map Taelja variable name (e.g. X, Y, X0) to Lean lowercase name."""
    mapping = {'X': 'x', 'Y': 'y', 'Z': 'z', 'X0': 'x0', 'X1': 'x1',
               'Y0': 'y0', 'Y1': 'y1', 'Z0': 'z0'}
    name = mapping.get(uppercase_name, uppercase_name.lower())
    while name in _symbol_names:
        name += '_'
    return name


# ─── Occurrence-based rewrite helpers ────────────────────────────────────────

def term_equal(t1, t2) -> bool:
    """Structural equality of two term objects."""
    if type(t1) != type(t2):
        return False
    if isinstance(t1, Var):
        return t1.name == t2.name
    if isinstance(t1, Const):
        return t1.name == t2.name
    if isinstance(t1, App):
        return (t1.head == t2.head and
                len(t1.args) == len(t2.args) and
                all(term_equal(a, b) for a, b in zip(t1.args, t2.args)))
    return False


def match_term_pat(pat, term, subst=None):
    """Match pat, where a Var is a wildcard, against term.  Returns a substitution dict or None."""
    if subst is None:
        subst = {}
    if isinstance(pat, Var):
        existing = subst.get(pat.name)
        if existing is None:
            return dict(subst, **{pat.name: term})
        return subst if term_equal(existing, term) else None
    if isinstance(pat, Const) and isinstance(term, Const):
        return subst if pat.name == term.name else None
    if isinstance(pat, App) and isinstance(term, App):
        if pat.head != term.head or len(pat.args) != len(term.args):
            return None
        s = dict(subst)
        for p, t in zip(pat.args, term.args):
            s = match_term_pat(p, t, s)
            if s is None:
                return None
        return s
    return None


def apply_subst_obj(subst, term):
    """Apply substitution (str -> Term) to a term object."""
    if isinstance(term, Var) and term.name in subst:
        return subst[term.name]
    if isinstance(term, App):
        return App(term.head, [apply_subst_obj(subst, a) for a in term.args])
    return term


def count_pat_occurrences(pat, term) -> int:
    """Count DFS (leftmost-outermost) occurrences of pattern pat in term."""
    count = 1 if match_term_pat(pat, term) is not None else 0
    if isinstance(term, App):
        for arg in term.args:
            count += count_pat_occurrences(pat, arg)
    return count


def rewrite_occurrence(term, pat, rep, target_n):
    """Rewrite only the target_n-th DFS occurrence of pat -> rep in term."""
    count = [0]
    done = [False]

    def go(t):
        if done[0]:
            return t
        s = match_term_pat(pat, t)
        if s is not None:
            count[0] += 1
            if count[0] == target_n:
                done[0] = True
                return apply_subst_obj(s, rep)
        if isinstance(t, App):
            return App(t.head, [go(a) for a in t.args])
        return t

    return go(term)


def find_rw_subst(prev_term, new_term, ax_formula, direction):
    """
    Find the concrete substitution σ of the calc rewrite step prev_term → new_term.

    For LR rw [axN] finds ax_lhs in prev_term, the LHS of the calc goal, and
    rewrites it to ax_rhs.  For RL it finds ax_lhs in new_term, the RHS, since
    a reverse step has the expanded form there.

    Returns the substitution dict, or None if not found or not an EqLit.
    """
    if not isinstance(ax_formula, EqLit):
        return None

    # The rule's variables and the chain's share names but are different
    # variables, and matching them in one substitution conflated them on GRP445-1.
    # Rename the rule's variables apart.
    def _mark(t):
        if isinstance(t, Var):
            return Var('$' + t.name)
        if isinstance(t, App):
            return App(t.head, [_mark(a) for a in t.args])
        return t
    ax_lhs, ax_rhs = _mark(ax_formula.lhs), _mark(ax_formula.rhs)
    pat, rep = ax_lhs, ax_rhs  # rw [axN] always uses lhs->rhs direction

    search_in = prev_term if direction == 'LR' else new_term
    target    = new_term  if direction == 'LR' else prev_term

    count  = [0]
    result = [None]

    def search(t):
        if result[0] is not None:
            return
        s = match_term_pat(pat, t)
        if s is not None:
            count[0] += 1
            candidate = rewrite_occurrence(search_in, pat, rep, count[0])
            if term_equal(candidate, target):
                result[0] = s
                return
            # LHS variables are resolved in s, but the RHS may still have free ones, as in
            # X = f(Y).  Match the candidate against the target to resolve them.  Only the
            # rule's $-marked variables are wildcards.  The chain's own variables must match
            # themselves, or a wrong occurrence matches by binding one to a bigger term,
            # as on ALG006-1.
            fixed = {v: Var(v) for v in vars_in_term(candidate) if not v.startswith('$')}
            full_s = match_term_pat(candidate, target, dict(s, **fixed))
            if full_s is not None:
                result[0] = full_s
                return
        if isinstance(t, App):
            for arg in t.args:
                search(arg)

    search(search_in)
    if result[0] is None:
        return None
    return {k[1:]: v for k, v in result[0].items() if k.startswith('$')}



def rewritten_occurrence(goal_term, pat_inst, rep_inst, target_term):
    """
    Lean's `rw` rewrites every instance of the instantiated pattern in the goal.
    Return (k, total), where total instances of pat_inst occur in goal_term in
    the pre-order kabstract numbers them by, and rewriting only the 1-based
    k-th turns goal_term into target_term.  k is None if no single occurrence
    does.  Callers pass `(config := { occs := .pos [k] })` when total > 1.
    """
    count = [0]
    found = [None]

    def replace_nth(t, n):
        # returns (new_term, seen) replacing the n-th pre-order instance
        if term_equal(t, pat_inst):
            count[0] += 1
            if count[0] == n:
                return rep_inst
            # an instance may contain further instances only if pat has subterms
        if isinstance(t, App):
            return App(t.head, [replace_nth(a, n) for a in t.args])
        return t

    def total_count(t):
        c = 1 if term_equal(t, pat_inst) else 0
        if isinstance(t, App):
            c += sum(total_count(a) for a in t.args)
        return c

    total = total_count(goal_term)
    for n in range(1, total + 1):
        count[0] = 0
        cand = replace_nth(goal_term, n)
        if term_equal(cand, target_term):
            found[0] = n
            break
    return found[0], total


def rw_tactic(arrow, hyp, k, total):
    if k is not None and total > 1:
        return f'rw (config := {{ occs := .pos [{k}] }}) [{arrow}{hyp}]'
    return f'rw [{arrow}{hyp}]'


def lit_as_term(lit):
    """View a literal as a term so the rewrite helpers can walk it."""
    if isinstance(lit, EqLit):
        return App('=', [lit.lhs, lit.rhs])
    if isinstance(lit, PredLit):
        return App(lit.head, list(lit.args)) if lit.args else Const(lit.head)
    return None


def precise_hyp_rw(prev_lit, target_lit, rw_formula, direction, ref_name, var_map, prev_ref,
                    binders=None, out_of_scope=(), witnesses=None):
    """Tactic proving `target_lit` from hypothesis `prev_ref` of `prev_lit` by one
    rewrite with the equation `rw_formula`, instantiated explicitly and applied
    to exactly the occurrence that turns the target into the hypothesis.  This
    avoids the metavariable pattern failure of a bare variable side and
    rewriting every occurrence.  Returns None when the step cannot be
    reconstructed, and callers fall back to the plain `rw`.

    `out_of_scope` holds prev_lit's variables not in var_map, schematic to the
    hypothesis chain like a ∀-lemma consumed as `(prev _)`.  If the rewrite
    needs one as an explicit witness this refuses, since the name exists only
    inside the hypothesis's closed binder.  The caller's plain `rw ... at h_rw`
    lets Lean unify the witness on `prev_ref`'s own metavariable instead, as
    on LAT005-6/e.

    `witnesses` are the terms the caller already substituted for those
    variables when instantiating `prev_ref`.  The rewrite is then instantiated
    at the same term, so hypothesis and rewrite agree without a metavariable,
    as on RNG039-1/vampire."""
    if not isinstance(rw_formula, EqLit):
        return None
    prev_t, tgt_t = lit_as_term(prev_lit), lit_as_term(target_lit)
    if prev_t is None or tgt_t is None:
        return None
    subst = find_rw_subst(prev_t, tgt_t, rw_formula, direction)
    if subst is None:
        return None
    if any(v not in subst for v in vars_in_lit(rw_formula)):
        return None
    witnesses = witnesses or {}
    if witnesses:
        subst = {k: (witnesses[t.name]
                     if isinstance(t, Var) and t.name in witnesses else t)
                 for k, t in subst.items()}
        # prev_ref was instantiated at those witnesses, so the term the rewrite
        # has to land on is prev_lit with the same substitution applied.
        prev_t = apply_subst_obj(witnesses, prev_t)
    if any(isinstance(t, Var) and t.name in out_of_scope for t in subst.values()):
        return None
    args = inst_args(rw_formula, subst, var_map, binders)
    inst = f'{ref_name} {" ".join(args)}' if args else ref_name
    lhs_i = apply_subst_obj(subst, rw_formula.lhs)
    rhs_i = apply_subst_obj(subst, rw_formula.rhs)
    if direction == 'LR':
        # the target has rhs_i where the hypothesis has lhs_i, so rewrite the goal backwards
        k, total = rewritten_occurrence(tgt_t, rhs_i, lhs_i, prev_t)
        arrow = '←'
    else:
        k, total = rewritten_occurrence(tgt_t, lhs_i, rhs_i, prev_t)
        arrow = ''
    if k is None:
        return None
    return f'by have h_rw := {inst}; {rw_tactic(arrow, "h_rw", k, total)}; exact {prev_ref}'


# ─── Lean 4 code emitter ─────────────────────────────────────────────────────

def ref_lean_name(ref: Ref) -> str:
    if ref.kind == 'axiom':
        return f'ax{ref.num}'
    if ref.kind == 'hyp':
        return f'hyp{ref.num}'
    if ref.num in _lemma_hyps:
        # a lemma under hypotheses, applied to the goal's
        return '(taelja_lemma' + str(ref.num) + ''.join(f' hyp{i}' for i in _lemma_hyps[ref.num]) + ')'
    return f'taelja_lemma{ref.num}'

def emit_lean(doc: Document, namespace: str = '') -> str:
    lines = []
    lines.append('-- Generated by taelja2lean.py')
    lines.append('-- Lean 4 verification of Taelja proof output')
    lines.append('')
    if namespace:
        lines.append(f'namespace {namespace}')
        lines.append('')

    global _func_predicates, _symbol_names
    functions, predicates, constants, func_preds = collect_symbols(doc)
    _func_predicates = func_preds
    _symbol_names = set(lean_name(n) for n in list(functions) + list(predicates) + list(constants))

    # Sort for determinism
    consts_sorted = sorted(constants)
    # Separate functions by arity
    func_by_arity: Dict[int, List[str]] = {}
    for name, arity in sorted(functions.items()):
        if arity == 0:
            continue  # already in constants
        func_by_arity.setdefault(arity, []).append(name)
    pred_by_arity: Dict[int, List[str]] = {}
    for name, arity in sorted(predicates.items()):
        pred_by_arity.setdefault(arity, []).append(name)

    # Declare sort
    lines.append('-- Uninterpreted sort')
    lines.append('axiom α : Type')
    lines.append('')

    # Declare constants one per line, since Lean 4 does not allow multi-binder axioms
    global _filler_const
    _filler_const = lean_name(consts_sorted[0]) if consts_sorted else None
    if consts_sorted:
        lines.append('-- Constants')
        for c in consts_sorted:
            lines.append(f'axiom {lean_name(c)} : α')
        lines.append('')

    # Declare functions
    for arity, names in sorted(func_by_arity.items()):
        arrow = ' → '.join(['α'] * (arity + 1))
        for name in names:
            lines.append(f'axiom {lean_name(name)} : {arrow}')
    if func_by_arity:
        lines.append('')

    # Declare predicates
    for arity, names in sorted(pred_by_arity.items()):
        if arity == 0:
            ret = 'Prop'
        else:
            ret = ' → '.join(['α'] * arity) + ' → Prop'
        for name in names:
            lines.append(f'axiom {lean_name(name)} : {ret}')
    if pred_by_arity:
        lines.append('')

    # Build map of axiom/lemma names and types
    axiom_types = {}   # num -> (type_str, var_map, formula)
    for ax in doc.axioms:
        type_str, var_map = lean_type(ax.formula, [])
        axiom_types[ax.num] = (type_str, var_map, ax.formula)
        lines.append(f'-- Axiom {ax.num}')
        lines.append(f'axiom ax{ax.num} : {type_str}')
    if doc.axioms:
        lines.append('')

    def chain_only_vars(formula, proof):
        """Return Taelja var names that appear only in EqChain intermediate steps, not in formula."""
        if not isinstance(proof, EqChainProof):
            return set()
        cvars = vars_in_term(proof.start)
        for step in proof.steps:
            cvars |= vars_in_term(step.term)
        return cvars - vars_in_lit(formula)

    global _hyps_before_vars
    _goal_hyps.clear()
    _lemma_hyps.clear()
    if doc.goals:
        _goal_hyps.extend(hyp_key(b) for b in goal_hypotheses(doc.goals[0].formula)[0])

    global _closed_hyps
    lemma_types = {}   # num -> (type_str, var_map, formula)
    for lem in doc.lemmas:
        extra = chain_only_vars(lem.formula, lem.proof)
        hyps, head = goal_hypotheses(lem.formula)
        if hyps and all(hyp_key(b) in _goal_hyps for b in hyps):
            # a lemma under hypotheses of the goal takes them first, then its
            # own variables, so a citation applies it to the goal's hypotheses
            _lemma_hyps[lem.num] = [_goal_hyps.index(hyp_key(b)) + 1 for b in hyps]
            head_str, var_map = lean_type(head, [], extra_vars=extra)
            _closed_hyps = True
            type_str = ' → '.join(nested_lit(b, {}) for b in hyps) + ' → ' + \
                       (f'({head_str})' if head_str.startswith('∀') else head_str)
            _closed_hyps = False
            lemma_types[lem.num] = (type_str, var_map, head)
        else:
            type_str, var_map = lean_type(lem.formula, [], extra_vars=extra)
            lemma_types[lem.num] = (type_str, var_map, lem.formula)

    # Emit lemmas
    for lem in doc.lemmas:
        type_str, var_map, formula = lemma_types[lem.num]
        lines.append(f'-- Lemma {lem.num}')
        lines.append(f'theorem taelja_lemma{lem.num} : {type_str} := by')
        _hyps_before_vars = lem.num in _lemma_hyps
        _closed_hyps = _hyps_before_vars
        proof_lines = emit_proof(lem.proof, axiom_types, lemma_types,
                                 lem.formula if _hyps_before_vars else formula, consts_sorted)
        _hyps_before_vars = False
        _closed_hyps = False
        for pl in proof_lines:
            lines.append(f'  {pl}')
        lines.append('')

    # Emit goals, whose hypotheses are each closed over their own variables
    _closed_hyps = True
    for g in doc.goals:
        extra = chain_only_vars(g.formula, g.proof)
        type_str, var_map = lean_type(g.formula, [], extra_vars=extra)
        lines.append(f'-- Goal {g.num}')
        lines.append(f'theorem taelja_goal{g.num} : {type_str} := by')
        proof_lines = emit_proof(g.proof, axiom_types, lemma_types, g.formula, consts_sorted)
        for pl in proof_lines:
            lines.append(f'  {pl}')
        lines.append('')
    _closed_hyps = False

    if namespace:
        lines.append(f'end {namespace}')
        lines.append('')

    return '\n'.join(lines)


def emit_proof(proof, axiom_types, lemma_types, conclusion_formula, consts=None) -> list:
    """Return list of tactic lines (without leading indentation)."""
    if consts is None:
        consts = []
    if isinstance(proof, EqChainProof):
        return emit_eqchain(proof, axiom_types, lemma_types, conclusion_formula, consts)
    elif isinstance(proof, HaveHenceProof):
        return emit_havehence(proof, axiom_types, lemma_types, conclusion_formula, consts)
    return ['exact taelja_hole_unproved']  # undefined on purpose so a hole fails rather than warns


def inst_args(formula, subst, var_map, binders=None):
    """Arguments for `refN a1 a2 ...` in the order of the reference's ∀-binders.
    A lemma proved by a chain may be quantified over variables that occur only in
    intermediate chain terms.  Such binders are absent from `subst` and any term
    of the sort will do, so the first real argument is reused for them."""
    stmt_vars = vars_in_lit(formula)
    # a hypothesis over the goal's own variables has no binders of its own
    order = list(binders) if binders is not None else sorted(stmt_vars)
    args = []
    for v in order:
        if v in subst:
            t = subst[v]
            a = lean_term(t, var_map)
            args.append(f'({a})' if isinstance(t, App) and t.args else a)
        else:
            args.append(None if v not in stmt_vars else '_')
    filler = next((a for a in args if a not in (None, '_')),
                  next(iter(var_map.values()), None) or _filler_const or '_')
    return [filler if a is None else a for a in args]


def get_formula_vars(num, kind, axiom_types, lemma_types):
    """Return (var_map, formula) for an axiom, lemma or hypothesis."""
    if kind == 'axiom':
        if num in axiom_types:
            return axiom_types[num][1], axiom_types[num][2]
    elif kind == 'hyp':
        if num in _hyp_types:
            return _hyp_types[num][1], _hyp_types[num][2]
    else:
        if num in lemma_types:
            return lemma_types[num][1], lemma_types[num][2]
    return {}, None


def emit_eqchain(proof: EqChainProof, axiom_types, lemma_types, conclusion, consts=None) -> list:
    lines = []
    conclusion_vars = vars_in_lit(conclusion)
    chain_vars = set()
    chain_vars |= vars_in_term(proof.start)
    for step in proof.steps:
        chain_vars |= vars_in_term(step.term)

    if _hyps_before_vars:
        conclusion = intro_hypotheses(conclusion, lines, {})
        conclusion_vars = vars_in_lit(conclusion)
    fvars = sorted((chain_vars | conclusion_vars) - nested_only_vars(conclusion))
    var_map = {v: lean_var_name(v, i) for i, v in enumerate(fvars)}
    if fvars:
        lines.append(f'intro {" ".join(var_map[v] for v in fvars)}')
    if not _hyps_before_vars:
        conclusion = intro_hypotheses(conclusion, lines, var_map)
    for step in proof.steps:
        step.ref = resolve_assumption(step.ref, None, want_eq=True)

    if not proof.steps:
        lines.append('rfl')
        return lines

    start_str = lean_term(proof.start, var_map)

    def step_tactic(step, prev_term):
        # Pre-instantiate the axiom with ground terms so rw [h_rw] finds exactly the
        # right occurrence in the calc goal.  For LR ax_lhs is in prev_term and rw
        # rewrites the goal's LHS.  For RL it is in new_term and rw rewrites the RHS.
        ref_name  = ref_lean_name(step.ref)
        direction = step.ref.direction

        ax_formula = None
        if step.ref.kind == 'axiom' and step.ref.num in axiom_types:
            ax_formula = axiom_types[step.ref.num][2]
        elif step.ref.kind == 'lemma' and step.ref.num in lemma_types:
            ax_formula = lemma_types[step.ref.num][2]
        elif step.ref.kind == 'hyp' and step.ref.num in _hyp_types:
            ax_formula = _hyp_types[step.ref.num][2]

        if ax_formula is None or not isinstance(ax_formula, EqLit):
            return f'by rw [{ref_name}]'

        subst = find_rw_subst(prev_term, step.term, ax_formula, direction)
        if subst is None:
            return f'by rw [{ref_name}]'  # fallback

        # Build the instantiated application axN arg1 arg2 ...
        args = inst_args(ax_formula, subst, var_map,
                         get_formula_vars(step.ref.num, step.ref.kind, axiom_types, lemma_types)[0])
        if args:
            inst = f'{ref_name} {" ".join(args)}'
        else:
            inst = ref_name  # ground lemma (no vars)

        # The calc goal is `prev_term = step.term`, and rw [h_rw] rewrites instances
        # of h_rw's LHS anywhere in it in pre-order and must leave a reflexive
        # equation.  Select that single occurrence.
        lhs_i = apply_subst_obj(subst, ax_formula.lhs)
        rhs_i = apply_subst_obj(subst, ax_formula.rhs)
        goal_t = App('=', [prev_term, step.term])
        target = App('=', [step.term, step.term]) if direction == 'LR' else App('=', [prev_term, prev_term])
        k, total = rewritten_occurrence(goal_t, lhs_i, rhs_i, target)
        return f'by have h_rw := {inst}; {rw_tactic("", "h_rw", k, total)}'

    # TPTP predicates are sometimes encoded as "f(args) = true" in the proof.
    # When the last calc step lands on Const('true'), the chain ends with a
    # predicate-holds step, not an equality.  Emit as rw + apply instead of a
    # calc chain to avoid the Prop/α type mismatch.
    if isinstance(proof.steps[-1].term, Const) and proof.steps[-1].term.name == 'true':
        prev_t = proof.start
        for step in proof.steps[:-1]:
            rn = ref_lean_name(step.ref)
            direction = step.ref.direction
            ax_f = None
            if step.ref.kind == 'axiom' and step.ref.num in axiom_types:
                ax_f = axiom_types[step.ref.num][2]
            elif step.ref.kind == 'lemma' and step.ref.num in lemma_types:
                ax_f = lemma_types[step.ref.num][2]
            if ax_f is not None and isinstance(ax_f, EqLit):
                subst = find_rw_subst(prev_t, step.term, ax_f, direction)
                if subst is not None:
                    step_args = inst_args(ax_f, subst, var_map,
                                          get_formula_vars(step.ref.num, step.ref.kind, axiom_types, lemma_types)[0])
                    inst_s = f'{rn} {" ".join(step_args)}' if step_args else rn
                    arrow = '← ' if direction == 'RL' else ''
                    # rw [h] abstracts instances of h's LHS in the goal, or the RHS for ←, so
                    # pick the single occurrence whose rewrite yields the next term
                    lhs_i = apply_subst_obj(subst, ax_f.lhs)
                    rhs_i = apply_subst_obj(subst, ax_f.rhs)
                    pat_g, rep_g = (rhs_i, lhs_i) if direction == 'RL' else (lhs_i, rhs_i)
                    k, total = rewritten_occurrence(prev_t, pat_g, rep_g, step.term)
                    lines.append(f'have h_rw := {inst_s}')
                    lines.append(rw_tactic(arrow, 'h_rw', k, total))
                else:
                    arrow = '← ' if direction == 'RL' else ''
                    lines.append(f'rw [{arrow}{rn}]')
            else:
                arrow = '← ' if direction == 'RL' else ''
                lines.append(f'rw [{arrow}{rn}]')
            prev_t = step.term
        final = proof.steps[-1]
        final_rn = ref_lean_name(final.ref)
        if final.ref.direction == 'RL':
            # RL, where the reversed ref proves <prev_term> = true_.
            # Instantiate with true_ and wrap in Eq.symm.
            final_ax_f = None
            if final.ref.kind == 'axiom' and final.ref.num in axiom_types:
                final_ax_f = axiom_types[final.ref.num][2]
            elif final.ref.kind == 'lemma' and final.ref.num in lemma_types:
                final_ax_f = lemma_types[final.ref.num][2]
            if final_ax_f is not None and isinstance(final_ax_f, EqLit):
                subst = find_rw_subst(prev_t, Const('true'), final_ax_f, 'RL')
                if subst is not None:
                    fa = inst_args(final_ax_f, subst, var_map,
                                   get_formula_vars(final.ref.num, final.ref.kind, axiom_types, lemma_types)[0])
                    inst_f = f'{final_rn} {" ".join(fa)}' if fa else final_rn
                    lines.append(f'exact Eq.symm ({inst_f})')
                else:
                    lines.append(f'exact Eq.symm ({final_rn} true_)')
            else:
                lines.append(f'exact Eq.symm ({final_rn} true_)')
        else:
            close_tac = 'first | assumption | rfl | exact Eq.symm (by assumption)'
            lines.append(f'apply {final_rn} <;> ({close_tac})')
        return lines

    # First calc line
    first = proof.steps[0]
    first_term = lean_term(first.term, var_map)
    lines.append(f'calc {start_str} = {first_term} := {step_tactic(first, proof.start)}')
    prev_term = first.term
    for step in proof.steps[1:]:
        term_str = lean_term(step.term, var_map)
        lines.append(f'    _ = {term_str} := {step_tactic(step, prev_term)}')
        prev_term = step.term

    return lines


# ─── Explicit instantiation of Horn steps ────────────────────────────────────
# A "hence C by ref" line applies the rule ref to the premises written before
# it.  Lean can often infer the rule's binders from `exact ref _ _ h1 h2`, but
# not when a binder occurs only in a premise that is itself a ∀-hypothesis
# instantiated with `_` (LCL126-1/Twee).  Matching the rule against the
# printed conclusion and premises yields every argument explicitly.

def _subst_lit(subst, lit):
    if isinstance(lit, EqLit):
        return EqLit(apply_subst_obj(subst, lit.lhs), apply_subst_obj(subst, lit.rhs))
    if isinstance(lit, PredLit):
        return PredLit(lit.head, [apply_subst_obj(subst, a) for a in lit.args])
    return lit


def _walk(t, s):
    while isinstance(t, Var) and t.name in s:
        t = s[t.name]
    return t


def _occurs(name, t, s):
    t = _walk(t, s)
    if isinstance(t, Var):
        return t.name == name
    if isinstance(t, App):
        return any(_occurs(name, a, s) for a in t.args)
    return False


def _unify_wild(t1, t2, s, wild):
    """Unify two terms whose only bindable variables are the rule's $-variables
    and the premise-local variables in `wild`.  Every other variable is a fixed
    Lean-bound name.  Bindings accumulate in the triangular substitution s."""
    t1, t2 = _walk(t1, s), _walk(t2, s)
    def is_wild(t):
        return isinstance(t, Var) and (t.name.startswith('$') or t.name in wild)
    if isinstance(t1, Var) and isinstance(t2, Var) and t1.name == t2.name:
        return s
    if is_wild(t1):
        if _occurs(t1.name, t2, s):
            return None
        return dict(s, **{t1.name: t2})
    if is_wild(t2):
        if _occurs(t2.name, t1, s):
            return None
        return dict(s, **{t2.name: t1})
    if isinstance(t1, Var) or isinstance(t2, Var):
        return None
    if isinstance(t1, Const) and isinstance(t2, Const):
        return s if t1.name == t2.name else None
    if isinstance(t1, App) and isinstance(t2, App):
        if t1.head != t2.head or len(t1.args) != len(t2.args):
            return None
        for a, b in zip(t1.args, t2.args):
            s = _unify_wild(a, b, s, wild)
            if s is None:
                return None
        return s
    return None


def _unify_lits(l1, l2, s, wild):
    """Unify the rule literal l1 against the printed target l2, trying l1's own
    orientation first and l1 flipped second.  Returns (subst, flipped) or None,
    where flipped says whether the term proving l1 needs `.symm` for l2."""
    a, b = lit_as_term(l1), lit_as_term(l2)
    if a is None or b is None:
        return None
    r = _unify_wild(a, b, s, wild)
    if r is not None:
        return (r, False)
    if isinstance(l1, EqLit) and isinstance(l2, EqLit):
        r = _unify_wild(App('=', [l1.rhs, l1.lhs]), b, s, wild)
        if r is not None:
            return (r, True)
    return None


def _resolve(t, s):
    t = _walk(t, s)
    if isinstance(t, App):
        return App(t.head, [_resolve(a, s) for a in t.args])
    return t


def _lean_arg(t, s, in_scope, var_map):
    """Lean text for a resolved argument, or None if it still holds a variable
    that is not bound at this point of the proof."""
    t = _resolve(t, s)
    if any(v.startswith('$') or v not in in_scope for v in vars_in_term(t)):
        return None
    a = lean_term(t, var_map)
    return f'({a})' if isinstance(t, App) and t.args else a


def horn_exact(ref_name, ref_formula, ref_binders, concl, prems, in_scope, var_map):
    """`exact ref a1 .. ak (h1 b..) (h2 ..)` with every argument computed, or
    None.  prems lists (hyp_name, hyp_lit, hyp_local_vars) in the rule's body
    order, and in_scope the Taelja variables bound here by intro or fun."""
    if isinstance(ref_formula, Implies):
        body, head = ref_formula.body, ref_formula.head
    elif ref_formula is not None:
        body, head = [], ref_formula
    else:
        return None
    if len(body) != len(prems):
        return None
    ren = {v: Var('$' + v) for v in vars_in_lit(ref_formula)}
    head = _subst_lit(ren, head)
    body = [_subst_lit(ren, b) for b in body]
    # A premise's ∀-variable is bindable only if the step does not bind a variable
    # of that name itself.  Equal names in a block denote the same variable, and
    # one bound by this step's intro or fun is fixed.
    wild = set()
    for _, _, loc in prems:
        wild |= set(v for v in loc if v not in in_scope)
    import os
    dbg = os.environ.get('TAELJA_HORN_DEBUG')
    r = _unify_lits(head, concl, {}, wild)
    if r is None:
        if dbg: sys.stderr.write(f'[horn_exact] head {head} !~ {concl}\n')
        return None
    s, head_flipped = r
    prem_flipped = {}
    for b, (pname, plit, _) in zip(body, prems):
        r = _unify_lits(b, plit, s, wild)
        if r is None:
            if dbg: sys.stderr.write(f'[horn_exact] body {b} !~ {pname}: {plit}\n')
            return None
        s, prem_flipped[pname] = r
    # Variables the conclusion leaves unconstrained (a premise's ∀-variable,
    # a rule binder occurring only in such a premise) may take any value.
    scope_var = next((v for v in in_scope if v in var_map), None)
    filler_t = Var(scope_var) if scope_var is not None else (Const(_filler_const) if _filler_const else None)
    if filler_t is not None:
        pending = [Var('$' + v) for v in ref_binders] + [Var(v) for _, _, loc in prems for v in loc]
        for _ in range(4):
            loose = set()
            for t in pending:
                for v in vars_in_term(_resolve(t, s)):
                    if v.startswith('$') or (v in wild and v not in in_scope):
                        loose.add(v)
            if not loose:
                break
            for v in loose:
                s[v] = filler_t
    args = []
    for v in ref_binders:
        a = _lean_arg(Var('$' + v), s, in_scope, var_map)
        args.append(a if a is not None else '_')
    parts = [ref_name] + args
    for pname, _, loc in prems:
        if loc:
            largs = [_lean_arg(Var(v), s, in_scope, var_map) or '_' for v in loc]
            term = f'({pname} {" ".join(largs)})'
        else:
            term = pname
        # A premise that only matched the rule's body atom flipped (equation
        # symmetry) needs the hypothesis term itself flipped to fit the slot.
        parts.append(f'({term}.symm)' if prem_flipped.get(pname) else term)
    term = ' '.join(parts)
    # A conclusion matched only by flipping the rule's equation needs the whole
    # application flipped, since Eq is not definitionally symmetric for `exact`.
    return 'exact ' + (f'Eq.symm ({term})' if head_flipped else term)


def ref_formula_of(ref, axiom_types, lemma_types):
    if ref.kind == 'axiom' and ref.num in axiom_types:
        return axiom_types[ref.num][2], list(axiom_types[ref.num][1].keys())
    if ref.kind == 'lemma' and ref.num in lemma_types:
        return lemma_types[ref.num][2], list(lemma_types[ref.num][1].keys())
    if ref.kind == 'hyp' and ref.num in _hyp_types:
        return _hyp_types[ref.num][2], list(_hyp_types[ref.num][1].keys())
    return None, []


# The hypotheses of the goal being proved, numbered as the goal states them,
# each with its Lean type, the map of its own variables and its formula, so a
# step citing an assumption can use them like an axiom.
_hyp_types: dict = {}
# The goal's hypotheses in statement order, as repr strings, so a lemma
# stated under some of them numbers them the same way.
_goal_hyps: list = []


def ordered_vars(b):
    """The variables of a formula in order of first occurrence, the binder
    order of a hypothesis, the same on every statement that names it."""
    seen = []
    for m in re.finditer(r"Var\(name='([A-Z]\w*)'\)", repr(b)):
        if m.group(1) not in seen:
            seen.append(m.group(1))
    return seen


def hyp_key(b):
    """A hypothesis up to the names of its variables, which each statement
    renames on its own, so a lemma finds the goal hypothesis it uses."""
    names = {}
    def canon(m):
        return f"Var(name='V{names.setdefault(m.group(1), len(names))}')"
    return re.sub(r"Var\(name='([A-Z]\w*)'\)", canon, repr(b))
# The lemmas stated under hypotheses, each with the goal indices of the
# hypotheses it takes, which a citation applies it to.
_lemma_hyps: dict = {}

# while a goal or a lemma under the goal's hypotheses is rendered, every
# hypothesis is a formula of its own, an atom included
_closed_hyps = False
# Whether hypotheses are introduced before the statement's variables, as a
# lemma under hypotheses is typed.
_hyps_before_vars = False


def goal_hypotheses(formula):
    """The hypotheses a goal or lemma statement assumes, in order: the
    antecedent's conjuncts, then the conjuncts of a negated conclusion."""
    hyps, head = [], formula
    if isinstance(formula, Implies):
        hyps, head = list(formula.body), formula.head
    if isinstance(head, Not):
        return hyps + list(head.items), PredLit('$false', [])
    return hyps, head


def intro_hypotheses(conclusion, lines, var_map=None):
    """A goal stated as H1 /\\ H2 => G introduces its hypotheses and is then
    proved as G.  A negated conclusion ~(C /\\ D) is proved by introducing C
    and D as hypotheses too and deriving False.  Returns the conclusion to
    prove."""
    _hyp_types.clear()
    hyps, head = goal_hypotheses(conclusion)
    negated = hyps[len(conclusion.body):] if isinstance(conclusion, Implies) else hyps
    plain = hyps[:len(hyps) - len(negated)]
    def name_of(i, b):
        return f'hyp{_goal_hyps.index(hyp_key(b)) + 1}' if hyp_key(b) in _goal_hyps else f'hyp{i + 1}'
    names = [name_of(i, b) for i, b in enumerate(hyps)]
    if plain:
        lines.append('intro ' + ' '.join(names[:len(plain)]))
    if negated:
        neg_names = names[len(plain):]
        lines.append('intro hneg')
        lines.append('obtain ⟨' + ', '.join(neg_names) + '⟩ := hneg' if len(neg_names) > 1 else f'have {neg_names[0]} := hneg')
    for name, b in zip(names, hyps):
        own = [v for v in ordered_vars(b) if v not in (var_map or {})]
        vm = {v: lean_var_name(v, len(var_map or {}) + j) for j, v in enumerate(own)}
        _hyp_types[int(name[3:])] = (nested_lit(b, var_map or {}), vm, b)
    return head


def resolve_assumption(ref, lit, want_eq=False):
    """The hypothesis a step cited as an assumption stands for, as a reference
    of kind hyp, or the reference unchanged when none fits."""
    if ref.kind != 'assumption':
        return ref
    if ref.num and ref.num in _hyp_types:
        return Ref('hyp', ref.num, ref.rw, ref.direction)
    for k, (_, _, f) in _hyp_types.items():
        if want_eq:
            if isinstance(f, EqLit):
                return Ref('hyp', k, ref.rw, ref.direction)
            continue
        head = f.head if isinstance(f, Implies) else f
        same = (isinstance(head, PredLit) and isinstance(lit, PredLit) and head.head == lit.head) \
            or (isinstance(head, EqLit) and isinstance(lit, EqLit))
        if same and isinstance(f, Implies):
            return Ref('hyp', k, ref.rw, ref.direction)
    return ref


def emit_havehence(proof: HaveHenceProof, axiom_types, lemma_types, conclusion, consts=None) -> list:
    if consts is None:
        consts = []
    lines = []
    if _hyps_before_vars:
        conclusion = intro_hypotheses(conclusion, lines, {})
    conclusion_vars = vars_in_lit(conclusion) - nested_only_vars(conclusion)
    fvars = sorted(conclusion_vars)
    var_map = {v: lean_var_name(v, i) for i, v in enumerate(fvars)}
    if fvars:
        lines.append(f'intro {" ".join(var_map[v] for v in fvars)}')
    if not _hyps_before_vars:
        conclusion = intro_hypotheses(conclusion, lines, var_map)

    steps = proof.steps
    if not steps:
        lines.append('exact taelja_hole_unproved')  # undefined on purpose so a hole fails rather than warns
        return lines

    # step_name[i] is the Lean hypothesis name for step i, current is the main
    # chain hypothesis from have or hence, and extras are the and-items collected
    # for the next hence
    hyp_names = {}   # index -> lean name 'h{i}'
    hyp_lits = {}    # index -> formula
    current_idx = None  # index of current main chain hyp
    extras = []          # (idx,) of pending and-items for next hence
    hyp_counter = [0]

    def fresh_hyp():
        hyp_counter[0] += 1
        return f'h{hyp_counter[0]}'

    def vars_for_step_lit(lit):
        """Get variable map for a step literal (may have own vars beyond conclusion vars)."""
        sv = sorted(vars_in_lit(lit))
        vm = dict(var_map)
        for i, v in enumerate(sv):
            if v not in vm:
                vm[v] = lean_var_name(v, len(vm))
        return sv, vm

    for idx, step in enumerate(steps):
        sv, svm = vars_for_step_lit(step.lit)
        # New vars not in conclusion
        new_vars = [v for v in sv if v not in var_map]
        lit_has_new_vars = bool(new_vars)

        # a step citing a hypothesis by number uses it like an axiom, while an
        # assume line restates the hypothesis itself
        ref = resolve_assumption(step.ref, step.lit)
        ref_name = ref_lean_name(ref)
        hname = fresh_hyp()

        if ref.kind == 'discharge':
            # the hypotheses were introduced at the start, so the previous
            # step already proves the conclusion
            continue

        if ref.kind == 'assumption':
            # an assumed hypothesis, introduced at the start of the proof
            lit_str = lean_lit(step.lit, svm)
            lines.append(f'have {hname} : {lit_str} := by assumption')
            hyp_names[idx] = hname
            hyp_lits[idx] = step.lit
            if isinstance(step, AndStep):
                extras.append(idx)
            else:
                current_idx = idx
                extras = []
            continue

        if isinstance(step, HaveStep):
            # Prove step.lit from ref (unconditional use)
            lit_str = lean_lit(step.lit, svm)
            unit_tac = 'first | ' + ' | '.join(
                ([f'apply {ref_name} <;> first | rfl | assumption']
                 + ([f'(apply Eq.symm; apply {ref_name} <;> first | rfl | assumption)']
                    if isinstance(step.lit, EqLit) else [])))
            u_formula, u_binders = ref_formula_of(ref, axiom_types, lemma_types)
            if u_formula is not None and not isinstance(u_formula, Implies):
                precise = horn_exact(ref_name, u_formula, u_binders, step.lit, [],
                                     set(var_map) | set(new_vars), svm)
                if precise is not None:
                    unit_tac = f'first | ({precise}) | ({unit_tac})'
            if lit_has_new_vars:
                forall_vars = ' '.join(f'({lean_var_name(v, i)} : α)'
                                        for i, v in enumerate(new_vars))
                lit_str = f'∀ {forall_vars}, {lit_str}'
                body = f'fun {" ".join(lean_var_name(v, i) for i, v in enumerate(new_vars))} => by {unit_tac}'
                lines.append(f'have {hname} : {lit_str} := {body}')
            else:
                lines.append(f'have {hname} : {lit_str} := by {unit_tac}')
            hyp_names[idx] = hname
            hyp_lits[idx] = step.lit
            current_idx = idx
            extras = []

        elif isinstance(step, AndStep):
            # Prove independently, collect for next hence
            lit_str = lean_lit(step.lit, svm)
            unit_tac = 'first | ' + ' | '.join(
                ([f'apply {ref_name} <;> first | rfl | assumption']
                 + ([f'(apply Eq.symm; apply {ref_name} <;> first | rfl | assumption)']
                    if isinstance(step.lit, EqLit) else [])))
            u_formula, u_binders = ref_formula_of(ref, axiom_types, lemma_types)
            if u_formula is not None and not isinstance(u_formula, Implies):
                precise = horn_exact(ref_name, u_formula, u_binders, step.lit, [],
                                     set(var_map) | set(new_vars), svm)
                if precise is not None:
                    unit_tac = f'first | ({precise}) | ({unit_tac})'
            if lit_has_new_vars:
                forall_vars = ' '.join(f'({lean_var_name(v, i)} : α)'
                                        for i, v in enumerate(new_vars))
                lit_str = f'∀ {forall_vars}, {lit_str}'
                body = f'fun {" ".join(lean_var_name(v, i) for i, v in enumerate(new_vars))} => by {unit_tac}'
                lines.append(f'have {hname} : {lit_str} := {body}')
            else:
                lines.append(f'have {hname} : {lit_str} := by {unit_tac}')
            hyp_names[idx] = hname
            hyp_lits[idx] = step.lit
            extras.append(idx)

        elif isinstance(step, HenceStep):
            lit_str = lean_lit(step.lit, svm)
            if lit_has_new_vars:
                forall_vars = ' '.join(f'({lean_var_name(v, i)} : α)'
                                        for i, v in enumerate(new_vars))
                full_lit_str = f'∀ {forall_vars}, {lit_str}'
            else:
                full_lit_str = lit_str

            if ref.kind == 'contradiction':
                # the previous hypothesis is False, so anything follows
                prev_name = hyp_names.get(current_idx, 'sorry_no_prev')
                if lit_has_new_vars:
                    binders = ' '.join(lean_var_name(v, i) for i, v in enumerate(new_vars))
                    lines.append(f'have {hname} : {full_lit_str} := fun {binders} => {prev_name}.elim')
                else:
                    lines.append(f'have {hname} : {full_lit_str} := {prev_name}.elim')
                hyp_names[idx] = hname
                hyp_lits[idx] = step.lit
                current_idx = idx
                continue

            if ref.rw:
                # Rewrite step, turning the current hypothesis into the new literal.
                prev_name = hyp_names.get(current_idx, 'sorry_no_prev')
                prev_lit = hyp_lits.get(current_idx)
                prev_sv = sorted(vars_in_lit(prev_lit)) if prev_lit else []
                prev_new_vars = [v for v in prev_sv if v not in var_map]

                if ref.direction == 'RL':
                    # RL rewrites the goal forward with the axiom LR.  The goal has 'a' where prev
                    # has 'b', and rw [ref_name] replaces a by b, turning the goal into prev's form.
                    rl_witnesses = {}
                    if prev_new_vars:
                        if lit_has_new_vars and len(prev_new_vars) == len(new_vars):
                            # The step's literal is still ∀-quantified since Tälja only renamed the
                            # schematic variable.  Apply prev at the same binder just introduced, not an
                            # arbitrary witness, since the result must hold for that bound variable, as
                            # on HEN011-2/vampire.
                            inst = ''.join(f' {svm[v]}' for v in new_vars)
                        else:
                            # A concrete problem constant, not `_`.  The rewrite eliminates the witness
                            # whatever its value, but an unresolved `_` has nothing to unify with later
                            # and Lean cannot synthesize it, as on LAT005-6/e.
                            witness_c = lean_name(consts[0]) if consts else 'a'
                            inst = f' {witness_c}' * len(prev_new_vars)
                            rl_witnesses = {v: Const(consts[0]) for v in prev_new_vars} \
                                           if consts else {}
                        prev_inst = f'{prev_name}{inst}'
                    else:
                        prev_inst = prev_name
                    # If the lemma's LHS is a bare variable rw [ref] fails with a metavariable
                    # error.  For ∀ X Y, X = f(Y,...) use Eq.trans (ref A _) prev instead and let
                    # Lean unify the middle term from prev's type.
                    rl_rw_formula = None
                    if ref.kind == 'axiom' and ref.num in axiom_types:
                        rl_rw_formula = axiom_types[ref.num][2]
                    elif ref.kind == 'lemma' and ref.num in lemma_types:
                        rl_rw_formula = lemma_types[ref.num][2]
                    elif ref.kind == 'hyp' and ref.num in _hyp_types:
                        rl_rw_formula = _hyp_types[ref.num][2]
                    rl_lhs_is_var = isinstance(rl_rw_formula, EqLit) and isinstance(rl_rw_formula.lhs, Var)
                    precise = precise_hyp_rw(
                        prev_lit, step.lit, rl_rw_formula, 'RL', ref_name, svm, prev_inst,
                        get_formula_vars(ref.num, ref.kind, axiom_types, lemma_types)[0],
                        out_of_scope=prev_new_vars, witnesses=rl_witnesses)
                    if precise is not None:
                        if lit_has_new_vars:
                            # a quantified target opens its binders first, since rw cannot rewrite
                            # under a ∀ (LCL212-3)
                            fvs = ' '.join(svm[v] for v in new_vars)
                            lines.append(f'have {hname} : {full_lit_str} := fun {fvs} => {precise}')
                        else:
                            lines.append(f'have {hname} : {full_lit_str} := {precise}')
                    elif rl_lhs_is_var and isinstance(step.lit, EqLit) and not prev_new_vars:
                        # An equational goal is bridged via Eq.trans so Lean unifies the middle term.
                        goal_lhs = lean_term(step.lit.lhs, svm)
                        lines.append(f'have {hname} : {full_lit_str} := Eq.trans ({ref_name} {goal_lhs} _) {prev_inst}')
                    elif rl_lhs_is_var and isinstance(step.lit, PredLit) and not prev_new_vars:
                        # For a predicate goal, find where step.lit and prev_lit differ, instantiate
                        # the lemma with those two terms, then rw [h_eq] in the goal.
                        step_args = step.lit.args if isinstance(step.lit, PredLit) else []
                        prev_args = prev_lit.args if isinstance(prev_lit, PredLit) else []
                        x_inst_term = None
                        y_inst_term = None
                        for sa, pa in zip(step_args, prev_args):
                            if not term_equal(sa, pa):
                                x_inst_term, y_inst_term = sa, pa
                                break
                        if x_inst_term is not None:
                            x_str = lean_term(x_inst_term, svm)
                            y_str = lean_term(y_inst_term, svm)
                            if isinstance(x_inst_term, App) and x_inst_term.args:
                                x_str = f'({x_str})'
                            if isinstance(y_inst_term, App) and y_inst_term.args:
                                y_str = f'({y_str})'
                            lines.append(f'have {hname} : {full_lit_str} := by have h_eq := {ref_name} {x_str} {y_str}; rw [h_eq]; exact {prev_inst}')
                        else:
                            lines.append(f'have {hname} : {full_lit_str} := ' + (f'fun {" ".join(svm[v] for v in new_vars)} => by rw [{ref_name}]; exact {prev_inst}' if lit_has_new_vars else f'by rw [{ref_name}]; exact {prev_inst}'))
                    else:
                        lines.append(f'have {hname} : {full_lit_str} := ' + (f'fun {" ".join(svm[v] for v in new_vars)} => by rw [{ref_name}]; exact {prev_inst}' if lit_has_new_vars else f'by rw [{ref_name}]; exact {prev_inst}'))
                else:
                    # LR rewrites the goal backward with the axiom RL.  The goal has 'b' where prev
                    # has 'a', and rw [← ref_name] replaces b by a, turning the goal into prev's
                    # form.  This avoids the metavariable LHS problem, since for a lemma x = f(x)
                    # rw [ref_name] at h would use the bare x as pattern and fail, while
                    # rw [← ref_name] uses the compound f(x).
                    if prev_new_vars and isinstance(prev_lit, EqLit):
                        # A non-ground equational prev gets the axiom simped into the hypothesis copy
                        # and is then applied at any constant, since the ∀ is spurious after simp.
                        witness = lean_name(consts[0]) if consts else 'a'
                        lines.append(f'have {hname} : {full_lit_str} := by have h_rw := {prev_name}; simp only [{ref_name}] at h_rw; exact h_rw {witness}')
                    else:
                        # A ground or relational prev picks the rewrite strategy by whether the
                        # lemma's LHS is a plain variable or a compound term.
                        lr_witnesses = {}
                        if prev_new_vars:
                            # As in the RL branch above, a concrete witness and not `_`
                            # (LAT005-6/e).
                            witness_c = lean_name(consts[0]) if consts else 'a'
                            inst = f' {witness_c}' * len(prev_new_vars)
                            prev_copy = f'({prev_name}{inst})'
                            if consts:
                                lr_witnesses = {v: Const(consts[0]) for v in prev_new_vars}
                        else:
                            prev_copy = prev_name
                        # Look up the formula to decide which direction avoids a metavar pattern.
                        rw_formula = None
                        if ref.kind == 'axiom' and ref.num in axiom_types:
                            rw_formula = axiom_types[ref.num][2]
                        elif ref.kind == 'lemma' and ref.num in lemma_types:
                            rw_formula = lemma_types[ref.num][2]
                        elif ref.kind == 'hyp' and ref.num in _hyp_types:
                            rw_formula = _hyp_types[ref.num][2]
                        lhs_is_var = isinstance(rw_formula, EqLit) and isinstance(rw_formula.lhs, Var)
                        precise = precise_hyp_rw(
                            prev_lit, step.lit, rw_formula, 'LR', ref_name, svm, prev_copy,
                            get_formula_vars(ref.num, ref.kind, axiom_types, lemma_types)[0],
                            out_of_scope=prev_new_vars, witnesses=lr_witnesses)
                        if precise is not None:
                            if lit_has_new_vars:
                                fvs = ' '.join(svm[v] for v in new_vars)
                                lines.append(f'have {hname} : {full_lit_str} := fun {fvs} => {precise}')
                            else:
                                lines.append(f'have {hname} : {full_lit_str} := {precise}')
                        elif lhs_is_var or prev_new_vars:
                            # The LHS is a bare variable as in x = f(x), so rw [ref] would use ?x as
                            # pattern and fail, while rw [← ref] uses the compound RHS.  This is also used
                            # when prev_copy applies a ∀-hypothesis at `_` because precise_hyp_rw refused
                            # to name an eliminated witness.  Rewriting the goal lets `exact prev_copy`
                            # unify that `_`, while a standalone `have h_rw := prev_copy` gives Lean
                            # nothing to solve it against, as on LAT005-6/e.
                            lines.append(f'have {hname} : {full_lit_str} := by rw [← {ref_name}]; exact {prev_copy}')
                        else:
                            # The LHS is compound, as in f(f(x)) = x or a = b, so apply the rewrite
                            # forward into the hypothesis copy with the compound LHS as pattern.
                            lines.append(f'have {hname} : {full_lit_str} := by have h_rw := {prev_copy}; rw [{ref_name}] at h_rw; exact h_rw')
            else:
                # Regular apply step.
                # The closing tactic handles three cases strictly.  A direct match closes by
                # assumption, a flipped equation by exact Eq.symm, and a universally
                # quantified hypothesis needing instantiation by apply h_i.
                # Collect the universally quantified earlier hypotheses for the last case.
                univ_hyp_names = [
                    hyp_names[pidx]
                    for pidx in sorted(hyp_names.keys())
                    if hyp_lits.get(pidx) is not None
                    and any(v not in var_map
                            for v in sorted(vars_in_lit(hyp_lits[pidx])))
                ]
                close_parts = ['assumption', 'rfl', 'exact Eq.symm (by assumption)',
                               # a premise that is the composition of two established
                               # equations (possibly flipped), e.g. CAT001-4's ax3
                               'exact Eq.trans (by assumption) (by assumption)',
                               'exact Eq.trans (Eq.symm (by assumption)) (by assumption)',
                               'exact Eq.trans (by assumption) (Eq.symm (by assumption))',
                               'exact Eq.trans (Eq.symm (by assumption)) (Eq.symm (by assumption))']
                close_parts += [f'apply {h}' for h in univ_hyp_names]
                close_tac = 'first | ' + ' | '.join(close_parts)

                # 'axioms' in plural names no specific axiom, so try every axiom and lemma in
                # scope and let Lean find the right one.
                if ref.kind == 'axioms':
                    all_names = (
                        [f'ax{n}' for n in sorted(axiom_types)]
                        + [f'taelja_lemma{n}' for n in sorted(lemma_types)]
                    )
                    # the last arm must be a hard error and never `sorry`, since a warning would
                    # let an unproved step pass the census
                    try_parts = [close_tac] + [f'apply {n} <;> ({close_tac})' for n in all_names] + ['exact taelja_hole_unproved']
                    fallback_tac = 'first | ' + ' | '.join(f'({p})' for p in try_parts)
                    if lit_has_new_vars:
                        fvars_str = ' '.join(svm[v] for v in new_vars)
                        lines.append(f'have {hname} : {full_lit_str} := fun {fvars_str} => by {fallback_tac}')
                    else:
                        lines.append(f'have {hname} : {full_lit_str} := by {fallback_tac}')
                    hyp_names[idx] = hname
                    hyp_lits[idx] = step.lit
                    current_idx = idx
                    extras = []
                    continue

                # Premises in written order, the chain hypothesis then pending and-items,
                # mirror the referenced clause's body order, so try `exact ref h1 … hk` first.
                # The `apply … <;> assumption` fallback binds metavariables greedily against
                # the latest hypothesis and cannot backtrack, which fails when subgoals share
                # variables, as on E HEN008-2.  A premise emitted as a ∀-statement is passed
                # as `(hN _ …)` with one `_` per binder, so elaboration finds the instance
                # from the ref's type.
                def prem_term(pidx):
                    pname = hyp_names[pidx]
                    plit = hyp_lits.get(pidx)
                    if plit is not None:
                        p_new = [v for v in sorted(vars_in_lit(plit))
                                 if v not in var_map]
                        if p_new:
                            return f'({pname}{" _" * len(p_new)})'
                    return pname
                prem_hyps = []
                if current_idx is not None and current_idx in hyp_names:
                    prem_hyps.append(prem_term(current_idx))
                prem_hyps += [prem_term(e) for e in extras if e in hyp_names]
                # The ref's ∀-binders are explicit arguments, so pass an
                # inferred `_` for each before the premise hypotheses.
                ref_var_map = None
                if ref.kind == 'axiom' and ref.num in axiom_types:
                    ref_var_map = axiom_types[ref.num][1]
                elif ref.kind == 'lemma' and ref.num in lemma_types:
                    ref_var_map = lemma_types[ref.num][1]
                elif ref.kind == 'hyp' and ref.num in _hyp_types:
                    ref_var_map = _hyp_types[ref.num][1]
                # `apply` unifies against the rule's own orientation only.  A rule deriving
                # the flipped equation, like an axiom `f x = c` cited for a goal `c = f x`,
                # needs `apply Eq.symm` first before `apply ref` can unify.
                symm_first = f'apply Eq.symm; apply {ref_name} <;> ({close_tac})' \
                    if isinstance(step.lit, EqLit) else None
                if prem_hyps and ref_var_map is not None:
                    apply_alts = [f'(exact {ref_name}{" _" * len(ref_var_map)} {" ".join(prem_hyps)})',
                                  f'(apply {ref_name} <;> ({close_tac}))']
                else:
                    apply_alts = [f'apply {ref_name} <;> ({close_tac})']
                if symm_first is not None:
                    apply_alts.append(f'({symm_first})')
                apply_tac = 'first | ' + ' | '.join(apply_alts)
                # Fully explicit application, tried first.  Binders and ∀-premises are
                # instantiated by matching the rule against the printed conclusion and
                # premises, in written order and then any order for small bodies.
                r_formula, r_binders = ref_formula_of(ref, axiom_types, lemma_types)
                prem_idxs = ([current_idx] if current_idx is not None and current_idx in hyp_names else []) \
                            + [e for e in extras if e in hyp_names]
                in_scope = set(var_map) | set(new_vars)
                def _prem(pidx):
                    plit = hyp_lits.get(pidx)
                    loc = [v for v in sorted(vars_in_lit(plit)) if v not in var_map] if plit is not None else []
                    return (hyp_names[pidx], plit, loc)
                precise = None
                if r_formula is not None and all(hyp_lits.get(i) is not None for i in prem_idxs):
                    import itertools
                    orders = [prem_idxs]
                    if 1 < len(prem_idxs) <= 4:
                        orders += [list(o) for o in itertools.permutations(prem_idxs) if list(o) != prem_idxs]
                    for order in orders:
                        precise = horn_exact(ref_name, r_formula, r_binders, step.lit,
                                             [_prem(i) for i in order], in_scope, svm)
                        if precise is not None:
                            break
                fallback_tac = apply_tac
                if precise is not None:
                    apply_tac = f'first | ({precise}) | ({apply_tac})'

                if lit_has_new_vars:
                    # Wrap in lambda, instantiate any ∀-quantified previous hyps
                    fvars_str = ' '.join(svm[v] for v in new_vars)
                    inst_lines = []
                    for pidx in list(hyp_names.keys()):
                        plit = hyp_lits.get(pidx)
                        if plit is None:
                            continue
                        psv = sorted(vars_in_lit(plit))
                        p_new_vars = [v for v in psv if v not in var_map]
                        if p_new_vars:
                            pname = hyp_names[pidx]
                            pvars_args = ' '.join(svm.get(v, '_') for v in p_new_vars)
                            inst_lines.append(f'have {pname}_i := {pname} {pvars_args}')
                    # The `_`-instantiated copies of ∀-premises can fail to
                    # elaborate on their own, so they only accompany the
                    # fallback tactics, never the explicit term.
                    with_preludes = '; '.join(inst_lines + [fallback_tac])
                    if precise is not None:
                        inner = f'first | ({precise}) | ({with_preludes})'
                    elif any('_' in l for l in inst_lines):
                        inner = f'first | ({with_preludes}) | ({fallback_tac})'
                    else:
                        inner = with_preludes
                    lines.append(f'have {hname} : {full_lit_str} := fun {fvars_str} => by {inner}')
                else:
                    lines.append(f'have {hname} : {full_lit_str} := by {apply_tac}')

            hyp_names[idx] = hname
            hyp_lits[idx] = step.lit
            current_idx = idx
            extras = []

    # Final step closing the goal.  If the last hypothesis is the conclusion's
    # equation flipped, as c=b for the goal b=c, add .symm.
    if current_idx is not None:
        final_name = hyp_names[current_idx]
        final_lit = hyp_lits.get(current_idx)
        # A ∀-quantified last step is instantiated by unification with the goal.
        fin_loc = [v for v in sorted(vars_in_lit(final_lit)) if v not in var_map] if final_lit is not None else []
        final_term = f'({final_name}{" _" * len(fin_loc)})' if fin_loc else final_name
        if (isinstance(conclusion, EqLit) and isinstance(final_lit, EqLit)):
            concl_str = lean_lit(conclusion, var_map)
            final_str = lean_lit(final_lit, var_map)
            flipped = lean_lit(EqLit(conclusion.rhs, conclusion.lhs), var_map)
            if final_str == flipped and final_str != concl_str:
                lines.append(f'exact {final_term}.symm')
            else:
                lines.append(f'exact {final_term}')
        else:
            lines.append(f'exact {final_term}')
    else:
        lines.append('assumption')

    return lines


# ─── Entry point ─────────────────────────────────────────────────────────────

def to_pascal_case(name: str) -> str:
    return ''.join(w.capitalize() for w in name.split('_'))


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('input', nargs='?', help='input file')
    parser.add_argument('--namespace', default='', help='wrap output in this Lean namespace')
    args = parser.parse_args()

    if args.input:
        with open(args.input) as f:
            text = f.read()
        ns = args.namespace or to_pascal_case(os.path.splitext(os.path.basename(args.input))[0])
    else:
        text = sys.stdin.read()
        ns = args.namespace

    doc = parse_document(text)
    lean_code = emit_lean(doc, namespace=ns)
    print(lean_code)


if __name__ == '__main__':
    main()
