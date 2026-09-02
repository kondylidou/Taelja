#!/usr/bin/env python3
"""Translate Taelja proof output to Lean 4 for verification.

Usage:
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
    function symbol, i.e. immediately followed by '('; else None."""
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
            # might be R->L direction indicator — handled at higher level
            tokens.append(('IDENT', 'R'))
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
        """formula ::= body_list '=>' atom | atom"""
        atoms = [self.parse_atom()]
        while not self.at_end() and self.peek()[0] == 'AND':
            self.consume('AND')
            atoms.append(self.parse_atom())
        if not self.at_end() and self.peek()[0] == 'ARROW':
            self.consume('ARROW')
            head = self.parse_atom()
            return Implies(atoms, head)
        if len(atoms) == 1:
            return atoms[0]
        # bare conjunction (shouldn't happen at top level, but handle)
        return atoms[0]

    def parse_atom(self):
        """atom ::= term '=' term | pred_app"""
        t = self.parse_term()
        if not self.at_end() and self.peek()[0] == 'EQ':
            self.consume('EQ')
            rhs = self.parse_term()
            # t is either a Var/Const/App; treat LHS as a term
            return EqLit(t, rhs)
        # t should be an App or bare name — treat as predicate
        if isinstance(t, App):
            return PredLit(t.head, t.args)
        elif isinstance(t, Const):
            return PredLit(t.name, [])
        elif isinstance(t, Var):
            return PredLit(t.name, [])
        return t

    def parse_term(self):
        """term ::= name '(' term_list ')' | name"""
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
    m = re.match(r'(axiom|lemma)\s+(\d+)', s)
    if not m:
        raise ValueError(f'Cannot parse ref: {s!r}')
    kind = m.group(1)
    num = int(m.group(2))
    return Ref(kind, num, rw, direction)


def parse_proof_block(lines: list) -> object:
    """Parse a proof block (list of non-empty stripped lines after 'Proof:')."""
    if not lines:
        return HaveHenceProof([])

    # Detect EqChain: first line is a bare term (not 'have/and/hence')
    first = lines[0].strip()
    if not (first.startswith('have ') or first.startswith('hence ') or
            first.startswith('and ') or first.startswith('by ')):
        return parse_eqchain(lines)
    return parse_havehence(lines)


def parse_eqchain(lines: list) -> EqChainProof:
    """Parse equational chain proof."""
    # lines look like:
    #   term1
    #   = { by axiom N [R->L] }
    #     term2
    # Collect (term, ref) pairs.
    # First line is start term, then pairs of (= { by ... }, term)
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
        # eq_line: "= { by axiom N [R->L] }"
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

        if line.startswith('have '):
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
            # skip 'Proof:'
            while i < len(lines) and lines[i].strip() != 'Proof:':
                i += 1
            i += 1  # skip 'Proof:'
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
    return set()

def collect_symbols(doc: Document) -> Tuple[Dict, Dict, Set]:
    """Returns (functions: name->arity, predicates: name->arity, constants: set of name)."""
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

    # Detect "= true" encoding: predicates that appear as eq-chain starts whose
    # head changes in an intermediate step are really α-valued functions.
    # Reclassify them so their Lean type is α → ... → α (not → Prop).
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

# Set by emit_lean before emitting: predicates reclassified as α-valued functions
# (= true encoding). lean_lit appends "= true_" for these symbols.
_func_predicates: set = frozenset()

def lean_lit(f, var_map: dict) -> str:
    """Convert a literal/formula to Lean Prop string."""
    if isinstance(f, PredLit):
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
        parts = [lean_lit(b, var_map) for b in f.body]
        head = lean_lit(f.head, var_map)
        return ' → '.join(parts + [head])
    return str(f)

def lean_type(formula, all_vars: list, extra_vars=None) -> Tuple[str, dict]:
    """
    Return (lean_type_string, var_map) where var_map maps uppercase var names
    to their Lean lowercase variable names. Wraps in ∀ if there are free vars.
    extra_vars: additional Taelja variable names (uppercase) to include in ∀,
                used when an EqChainProof has chain-internal variables not in formula.
    """
    fvars = sorted(vars_in_lit(formula) | (set(extra_vars) if extra_vars else set()))
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

# Set by emit_lean: Lean names of all declared symbols, so that a variable's
# lowercase name never shadows a constant/function (SYN339-1: function `y`
# versus variable Y, which made `f x (y x) y` ill-typed).
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
    """Pattern match: pat (Var = wildcard) against term. Returns substitution dict or None."""
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
    Find the concrete substitution σ used in the calc rewrite step prev_term → new_term.

    For LR: rw [axN] finds ax_lhs in prev_term (LHS of calc goal) and rewrites to ax_rhs.
    For RL: rw [axN] finds ax_lhs in new_term (RHS of calc goal) and rewrites to ax_rhs,
            because for a reverse step the expanded (ax_lhs) form lives in new_term.

    Returns the substitution dict {VarName: Term} or None if not found / not an EqLit.
    """
    if not isinstance(ax_formula, EqLit):
        return None

    # The rule's variables and the chain's variables share names (both X, Y, ...)
    # but are different logical variables; matching them in one substitution
    # conflated them (GRP445-1: rule var X bound to the chain's Y, then the
    # chain's own X failed to match).  Rename the rule's variables apart.
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
            # LHS vars are resolved in s; RHS may still have free vars (e.g. ax: X = f(Y)).
            # Match the candidate (with free RHS vars as patterns) against target to resolve them.
            # Only the rule's ($-marked) variables are wildcards here: the chain's own
            # variables must match themselves, otherwise a wrong occurrence can be
            # "matched" by binding a chain variable to a bigger term (ALG006-1).
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
    Lean's `rw` rewrites EVERY instance of the (instantiated) pattern in the goal.
    Return (k, total): `total` instances of pat_inst occur in goal_term (pre-order,
    left to right, the order Lean's kabstract numbers them), and rewriting only
    the k-th one (1-based) turns goal_term into target_term; k is None if no single
    occurrence does.  Callers pass `(config := { occs := .pos [k] })` when total > 1.
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


def precise_hyp_rw(prev_lit, target_lit, rw_formula, direction, ref_name, var_map, prev_ref, binders=None):
    """Tactic proving `target_lit` from hypothesis `prev_ref : prev_lit` by one
    rewrite with `rw_formula` (an equation), instantiated explicitly and applied
    to exactly the occurrence that turns the target into the hypothesis.  This
    avoids both the metavariable-pattern failure (rules with a bare variable on
    one side) and rewriting every occurrence.  Returns None when the step cannot
    be reconstructed; callers then fall back to the plain `rw`."""
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
    args = inst_args(rw_formula, subst, var_map, binders)
    inst = f'{ref_name} {" ".join(args)}' if args else ref_name
    lhs_i = apply_subst_obj(subst, rw_formula.lhs)
    rhs_i = apply_subst_obj(subst, rw_formula.rhs)
    if direction == 'LR':
        # target has rhs_i where the hypothesis has lhs_i: rewrite the goal backwards
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
    else:
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

    # Declare constants (one per line — Lean 4 does not allow multi-binder axioms)
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

    lemma_types = {}   # num -> (type_str, var_map, formula)
    for lem in doc.lemmas:
        extra = chain_only_vars(lem.formula, lem.proof)
        type_str, var_map = lean_type(lem.formula, [], extra_vars=extra)
        lemma_types[lem.num] = (type_str, var_map, lem.formula)

    # Emit lemmas
    for lem in doc.lemmas:
        type_str, var_map, formula = lemma_types[lem.num]
        lines.append(f'-- Lemma {lem.num}')
        lines.append(f'theorem taelja_lemma{lem.num} : {type_str} := by')
        proof_lines = emit_proof(lem.proof, axiom_types, lemma_types, formula, consts_sorted)
        for pl in proof_lines:
            lines.append(f'  {pl}')
        lines.append('')

    # Emit goals
    for g in doc.goals:
        extra = chain_only_vars(g.formula, g.proof)
        type_str, var_map = lean_type(g.formula, [], extra_vars=extra)
        lines.append(f'-- Goal {g.num}')
        lines.append(f'theorem taelja_goal{g.num} : {type_str} := by')
        proof_lines = emit_proof(g.proof, axiom_types, lemma_types, g.formula, consts_sorted)
        for pl in proof_lines:
            lines.append(f'  {pl}')
        lines.append('')

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
    return ['exact taelja_hole_unproved']  # undefined on purpose: a hole must fail, not warn


def inst_args(formula, subst, var_map, binders=None):
    """Arguments for `refN a1 a2 ...` in the order of the reference's ∀-binders.
    A lemma proved by a chain may be quantified over variables that occur only in
    intermediate chain terms; such binders are absent from `subst` and any term
    of the sort will do, so the first real argument is reused for them."""
    stmt_vars = vars_in_lit(formula)
    order = list(binders) if binders else sorted(stmt_vars)
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
    """Return (var_map, formula) for an axiom or lemma."""
    if kind == 'axiom':
        if num in axiom_types:
            return axiom_types[num][1], axiom_types[num][2]
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

    fvars = sorted(chain_vars | conclusion_vars)
    var_map = {v: lean_var_name(v, i) for i, v in enumerate(fvars)}
    if fvars:
        lines.append(f'intro {" ".join(var_map[v] for v in fvars)}')

    if not proof.steps:
        lines.append('rfl')
        return lines

    start_str = lean_term(proof.start, var_map)

    def step_tactic(step, prev_term):
        # Strategy: pre-instantiate the axiom with concrete ground terms so that
        # rw [h_rw] finds exactly one occurrence (the right one) in the calc goal.
        # For LR: ax_lhs appears in prev_term → rw rewrites LHS of goal.
        # For RL: ax_lhs appears in new_term → rw rewrites RHS of goal (no ← needed).
        ref_name  = ref_lean_name(step.ref)
        direction = step.ref.direction

        ax_formula = None
        if step.ref.kind == 'axiom' and step.ref.num in axiom_types:
            ax_formula = axiom_types[step.ref.num][2]
        elif step.ref.kind == 'lemma' and step.ref.num in lemma_types:
            ax_formula = lemma_types[step.ref.num][2]

        if ax_formula is None or not isinstance(ax_formula, EqLit):
            return f'by rw [{ref_name}]'

        subst = find_rw_subst(prev_term, step.term, ax_formula, direction)
        if subst is None:
            return f'by rw [{ref_name}]'  # fallback

        # Build instantiated application: axN arg1 arg2 ...
        args = inst_args(ax_formula, subst, var_map,
                         get_formula_vars(step.ref.num, step.ref.kind, axiom_types, lemma_types)[0])
        if args:
            inst = f'{ref_name} {" ".join(args)}'
        else:
            inst = ref_name  # ground lemma (no vars)

        # the calc goal is `prev_term = step.term`; rw [h_rw] rewrites instances of
        # h_rw's LHS anywhere in it (pre-order: prev_term first, then step.term) and
        # must leave a reflexive equation.  Select that single occurrence.
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
                    # rw [h] abstracts instances of h's LHS in the goal (RHS for ←);
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
            # RL: the ref (reversed) proves <prev_term> = true_.
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
    and the premise-local variables in `wild`; every other variable is a fixed
    Lean-bound name.  Bindings accumulate in s (a triangular substitution)."""
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
    a, b = lit_as_term(l1), lit_as_term(l2)
    if a is None or b is None:
        return None
    r = _unify_wild(a, b, s, wild)
    if r is None and isinstance(l1, EqLit) and isinstance(l2, EqLit):
        r = _unify_wild(App('=', [l1.rhs, l1.lhs]), b, s, wild)
    return r


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
    None.  prems: [(hyp_name, hyp_lit, hyp_local_vars)] in the rule's body
    order; in_scope: Taelja variables bound at this point (intro/fun)."""
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
    # A premise's ∀-variable is bindable only if the step does not bind a
    # variable of that name itself: in the block, equal names denote the
    # same variable, and one bound by this step's intro/fun is fixed.
    wild = set()
    for _, _, loc in prems:
        wild |= set(v for v in loc if v not in in_scope)
    import os
    dbg = os.environ.get('TAELJA_HORN_DEBUG')
    s = _unify_lits(head, concl, {}, wild)
    if s is None:
        if dbg: sys.stderr.write(f'[horn_exact] head {head} !~ {concl}\n')
        return None
    for b, (pname, plit, _) in zip(body, prems):
        s = _unify_lits(b, plit, s, wild)
        if s is None:
            if dbg: sys.stderr.write(f'[horn_exact] body {b} !~ {pname}: {plit}\n')
            return None
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
            parts.append(f'({pname} {" ".join(largs)})')
        else:
            parts.append(pname)
    return 'exact ' + ' '.join(parts)


def ref_formula_of(ref, axiom_types, lemma_types):
    if ref.kind == 'axiom' and ref.num in axiom_types:
        return axiom_types[ref.num][2], list(axiom_types[ref.num][1].keys())
    if ref.kind == 'lemma' and ref.num in lemma_types:
        return lemma_types[ref.num][2], list(lemma_types[ref.num][1].keys())
    return None, []


def emit_havehence(proof: HaveHenceProof, axiom_types, lemma_types, conclusion, consts=None) -> list:
    if consts is None:
        consts = []
    lines = []
    conclusion_vars = vars_in_lit(conclusion)
    fvars = sorted(conclusion_vars)
    var_map = {v: lean_var_name(v, i) for i, v in enumerate(fvars)}
    if fvars:
        lines.append(f'intro {" ".join(var_map[v] for v in fvars)}')

    steps = proof.steps
    if not steps:
        lines.append('exact taelja_hole_unproved')  # undefined on purpose: a hole must fail, not warn
        return lines

    # Track: step_name[i] = lean hypothesis name for step i
    # "current" = the primary chain hypothesis (from have/hence)
    # "extras" = collected and-items for the upcoming hence
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

        ref = step.ref
        ref_name = ref_lean_name(ref)
        hname = fresh_hyp()

        if isinstance(step, HaveStep):
            # Prove step.lit from ref (unconditional use)
            lit_str = lean_lit(step.lit, svm)
            unit_tac = f'apply {ref_name} <;> first | rfl | assumption'
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
            unit_tac = f'apply {ref_name} <;> first | rfl | assumption'
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

            if ref.rw:
                # Rewrite step: transform current hypothesis into new literal.
                prev_name = hyp_names.get(current_idx, 'sorry_no_prev')
                prev_lit = hyp_lits.get(current_idx)
                prev_sv = sorted(vars_in_lit(prev_lit)) if prev_lit else []
                prev_new_vars = [v for v in prev_sv if v not in var_map]

                if ref.direction == 'RL':
                    # RL: rewrite the GOAL forward with axiom LR (brings goal back to prev's form).
                    # The goal has 'a' where prev has 'b'; rw [ref_name] in goal uses LHS (a) as
                    # pattern and replaces with RHS (b), turning the goal into prev's form.
                    if prev_new_vars:
                        inst = ' _' * len(prev_new_vars)
                        prev_inst = f'{prev_name}{inst}'
                    else:
                        prev_inst = prev_name
                    # Check if the lemma's LHS is a bare Var — rw [ref] would fail with metavar error.
                    # For ∀ X Y, X = f(Y,...): use Eq.trans (ref A _) prev instead, letting Lean
                    # unify the middle term from prev's type.
                    rl_rw_formula = None
                    if ref.kind == 'axiom' and ref.num in axiom_types:
                        rl_rw_formula = axiom_types[ref.num][2]
                    elif ref.kind == 'lemma' and ref.num in lemma_types:
                        rl_rw_formula = lemma_types[ref.num][2]
                    rl_lhs_is_var = isinstance(rl_rw_formula, EqLit) and isinstance(rl_rw_formula.lhs, Var)
                    precise = None if prev_new_vars or lit_has_new_vars else precise_hyp_rw(
                        prev_lit, step.lit, rl_rw_formula, 'RL', ref_name, svm, prev_inst,
                        get_formula_vars(ref.num, ref.kind, axiom_types, lemma_types)[0])
                    if precise is not None:
                        lines.append(f'have {hname} : {full_lit_str} := {precise}')
                    elif rl_lhs_is_var and isinstance(step.lit, EqLit) and not prev_new_vars:
                        # Goal is an equation: bridge via Eq.trans so Lean unifies the middle term.
                        goal_lhs = lean_term(step.lit.lhs, svm)
                        lines.append(f'have {hname} : {full_lit_str} := Eq.trans ({ref_name} {goal_lhs} _) {prev_inst}')
                    elif rl_lhs_is_var and isinstance(step.lit, PredLit) and not prev_new_vars:
                        # Goal is a predicate: find where step.lit and prev_lit differ, instantiate
                        # the lemma with those two terms, then rw [h_eq] in goal.
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
                            lines.append(f'have {hname} : {full_lit_str} := by rw [{ref_name}]; exact {prev_inst}')
                    else:
                        lines.append(f'have {hname} : {full_lit_str} := by rw [{ref_name}]; exact {prev_inst}')
                else:
                    # LR: rewrite the GOAL backward with axiom RL (brings goal back to prev's form).
                    # The goal has 'b' where prev has 'a'; rw [← ref_name] in goal uses RHS (b) as
                    # pattern and replaces with LHS (a), turning the goal into prev's form.
                    # This avoids the metavar-LHS problem: when the lemma has the form x = f(x),
                    # rw [ref_name] at h would use 'x' (a pure metavar) as pattern and fail in Lean,
                    # whereas rw [← ref_name] uses 'f(x)' (a compound term) as pattern and succeeds.
                    if prev_new_vars and isinstance(prev_lit, EqLit):
                        # Non-ground equational prev: simp the axiom into the hypothesis copy,
                        # then apply at any concrete constant (the ∀ becomes spurious after simp).
                        witness = lean_name(consts[0]) if consts else 'a'
                        lines.append(f'have {hname} : {full_lit_str} := by have h_rw := {prev_name}; simp only [{ref_name}] at h_rw; exact h_rw {witness}')
                    else:
                        # Ground (or relational) prev: choose rewrite strategy based on whether
                        # the referenced lemma's LHS is a plain Var or a compound term.
                        if prev_new_vars:
                            inst = ' _' * len(prev_new_vars)
                            prev_copy = f'({prev_name}{inst})'
                        else:
                            prev_copy = prev_name
                        # Look up the formula to decide which direction avoids a metavar pattern.
                        rw_formula = None
                        if ref.kind == 'axiom' and ref.num in axiom_types:
                            rw_formula = axiom_types[ref.num][2]
                        elif ref.kind == 'lemma' and ref.num in lemma_types:
                            rw_formula = lemma_types[ref.num][2]
                        lhs_is_var = isinstance(rw_formula, EqLit) and isinstance(rw_formula.lhs, Var)
                        precise = None if prev_new_vars or lit_has_new_vars else precise_hyp_rw(
                            prev_lit, step.lit, rw_formula, 'LR', ref_name, svm, prev_copy,
                            get_formula_vars(ref.num, ref.kind, axiom_types, lemma_types)[0])
                        if precise is not None:
                            lines.append(f'have {hname} : {full_lit_str} := {precise}')
                        elif lhs_is_var:
                            # LHS is a pure variable (e.g. x = f(x)): rw [ref] would use ?x as
                            # pattern and fail in Lean. rw [← ref] uses the compound RHS instead.
                            lines.append(f'have {hname} : {full_lit_str} := by rw [← {ref_name}]; exact {prev_copy}')
                        else:
                            # LHS is compound (e.g. f(f(x)) = x, a = b): apply the rewrite forward
                            # into the hypothesis copy so the compound LHS is the pattern.
                            lines.append(f'have {hname} : {full_lit_str} := by have h_rw := {prev_copy}; rw [{ref_name}] at h_rw; exact h_rw')
            else:
                # Regular apply step.
                # Build a closing tactic that handles three cases strictly:
                #   1. direct match               — assumption
                #   2. equation in wrong orientation — exact Eq.symm (by assumption)
                #   3. universally-quantified hyp needs instantiation — apply h_i
                # Collecting universally-quantified prior hyps for case 3:
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

                # 'axioms' (plural): no specific axiom named; try every axiom and
                # lemma in scope so Lean can find the right one automatically.
                if ref.kind == 'axioms':
                    all_names = (
                        [f'ax{n}' for n in sorted(axiom_types)]
                        + [f'taelja_lemma{n}' for n in sorted(lemma_types)]
                    )
                    # the last arm must be a hard error, never `sorry`: a warning would
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

                # Premises in written order (chain hyp, then pending and-items)
                # mirror the referenced clause's body order, so try the direct
                # term `exact ref h1 … hk` first. The `apply … <;> assumption`
                # fallback binds each subgoal's metavariables greedily against
                # the most recent hypothesis and cannot backtrack, which fails
                # when several subgoals share variables (e.g. E HEN008-2 ax6).
                # A premise emitted as a ∀-statement (its literal has vars
                # beyond the conclusion's) must be instantiated when passed to
                # the exact term: pass `(hN _ …)` with one `_` per binder so
                # elaboration unifies the instance from the ref's type.
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
                if prem_hyps and ref_var_map is not None:
                    binder_us = ' _' * len(ref_var_map)
                    apply_tac = (f'first | (exact {ref_name}{binder_us} {" ".join(prem_hyps)})'
                                 f' | (apply {ref_name} <;> ({close_tac}))')
                else:
                    apply_tac = f'apply {ref_name} <;> ({close_tac})'
                # Fully explicit application, tried first: binders and the
                # ∀-premises instantiated by matching the rule against the
                # printed conclusion and premises (written order, then any
                # order for small bodies).
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

    # Final step: close the goal.
    # If the last hypothesis is an equation in the FLIPPED orientation of the
    # conclusion (e.g. proof produces c=b but goal is b=c), add .symm.
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
