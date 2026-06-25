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
    """Parse 'axiom N', 'lemma N', 'rw axiom N', 'rw axiom N R->L' etc."""
    s = s.strip()
    rw = False
    direction = 'LR'
    if s.startswith('rw '):
        rw = True
        s = s[3:].strip()
    if 'R->L' in s:
        direction = 'RL'
        s = s.replace('R->L', '').strip()
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

    return functions, predicates, constants


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
    """Escape Lean keywords."""
    keywords = {'fun', 'let', 'in', 'do', 'if', 'then', 'else', 'match', 'with',
                'have', 'show', 'from', 'theorem', 'def', 'where', 'by', 'exact',
                'apply', 'intro', 'calc', 'rw', 'simp', 'type', 'sort', 'prop'}
    if name.lower() in keywords:
        return name + '_'
    return name

def lean_lit(f, var_map: dict) -> str:
    """Convert a literal/formula to Lean Prop string."""
    if isinstance(f, PredLit):
        head = lean_name(f.head)
        if not f.args:
            return head
        parts = []
        for a in f.args:
            s = lean_term(a, var_map)
            # Parenthesise compound terms
            if isinstance(a, App) and a.args:
                s = f'({s})'
            parts.append(s)
        return f'{head} {" ".join(parts)}'
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

def lean_type(formula, all_vars: list) -> Tuple[str, dict]:
    """
    Return (lean_type_string, var_map) where var_map maps uppercase var names
    to their Lean lowercase variable names. Wraps in ∀ if there are free vars.
    """
    fvars = sorted(vars_in_lit(formula))
    var_map = {v: lean_var_name(v, i) for i, v in enumerate(fvars)}
    body = lean_lit(formula, var_map)

    if isinstance(formula, Implies):
        # Body is already rendered as P → Q → R
        type_str = body
    else:
        type_str = body

    if fvars:
        forall_vars = ' '.join(f'({var_map[v]} : α)' for v in fvars)
        type_str = f'∀ {forall_vars}, {type_str}'

    return type_str, var_map

def lean_var_name(uppercase_name: str, idx: int) -> str:
    """Map Taelja variable name (e.g. X, Y, X0) to Lean lowercase name."""
    mapping = {'X': 'x', 'Y': 'y', 'Z': 'z', 'X0': 'x0', 'X1': 'x1',
               'Y0': 'y0', 'Y1': 'y1', 'Z0': 'z0'}
    if uppercase_name in mapping:
        return mapping[uppercase_name]
    return uppercase_name.lower()


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

    functions, predicates, constants = collect_symbols(doc)

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

    lemma_types = {}   # num -> (type_str, var_map, formula)
    for lem in doc.lemmas:
        type_str, var_map = lean_type(lem.formula, [])
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
        type_str, var_map = lean_type(g.formula, [])
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
    return ['sorry']


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

    def step_tactic(step):
        # rw [axN] works for both LR and RL calc steps:
        # - LR: rewrites l→r in the LHS of the goal, making both sides equal
        # - RL: rewrites l→r in the RHS of the goal, making both sides equal
        ref_name = ref_lean_name(step.ref)
        return f'by rw [{ref_name}]'

    # First calc line: "calc start = term1 := tactic1"
    first = proof.steps[0]
    first_term = lean_term(first.term, var_map)
    lines.append(f'calc {start_str} = {first_term} := {step_tactic(first)}')
    for step in proof.steps[1:]:
        term_str = lean_term(step.term, var_map)
        lines.append(f'    _ = {term_str} := {step_tactic(step)}')

    return lines


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
        lines.append('sorry')
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
            if lit_has_new_vars:
                forall_vars = ' '.join(f'({lean_var_name(v, i)} : α)'
                                        for i, v in enumerate(new_vars))
                lit_str = f'∀ {forall_vars}, {lit_str}'
                body = f'fun {" ".join(lean_var_name(v, i) for i, v in enumerate(new_vars))} => by apply {ref_name}'
                lines.append(f'have {hname} : {lit_str} := {body}')
            else:
                lines.append(f'have {hname} : {lit_str} := by apply {ref_name}')
            hyp_names[idx] = hname
            hyp_lits[idx] = step.lit
            current_idx = idx
            extras = []

        elif isinstance(step, AndStep):
            # Prove independently, collect for next hence
            lit_str = lean_lit(step.lit, svm)
            if lit_has_new_vars:
                forall_vars = ' '.join(f'({lean_var_name(v, i)} : α)'
                                        for i, v in enumerate(new_vars))
                lit_str = f'∀ {forall_vars}, {lit_str}'
                body = f'fun {" ".join(lean_var_name(v, i) for i, v in enumerate(new_vars))} => by apply {ref_name}'
                lines.append(f'have {hname} : {lit_str} := {body}')
            else:
                lines.append(f'have {hname} : {lit_str} := by apply {ref_name}')
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
                    # RL: rewrite the GOAL using axiom LR (brings goal back to prev's form)
                    if prev_new_vars:
                        inst = ' _' * len(prev_new_vars)
                        prev_inst = f'{prev_name}{inst}'
                    else:
                        prev_inst = prev_name
                    lines.append(f'have {hname} : {full_lit_str} := by rw [{ref_name}]; exact {prev_inst}')
                else:
                    # LR: rewrite the HYPOTHESIS forward with axiom LR.
                    # NEVER use rw [← ax] here — its pattern can be a metavar when
                    # the axiom RHS is a plain variable (e.g. f(X)=X), which Lean rejects.
                    if prev_new_vars and isinstance(prev_lit, EqLit):
                        # Non-ground equational prev: simp the axiom into the hypothesis copy,
                        # then apply at any concrete constant (the ∀ becomes spurious after simp).
                        witness = lean_name(consts[0]) if consts else 'a'
                        lines.append(f'have {hname} : {full_lit_str} := by have h_rw := {prev_name}; simp only [{ref_name}] at h_rw; exact h_rw {witness}')
                    else:
                        # Ground (or relational) prev: copy then rw at hypothesis.
                        if prev_new_vars:
                            inst = ' _' * len(prev_new_vars)
                            prev_copy = f'({prev_name}{inst})'
                        else:
                            prev_copy = prev_name
                        lines.append(f'have {hname} : {full_lit_str} := by have h_rw := {prev_copy}; rw [{ref_name}] at h_rw; exact h_rw')
            else:
                # Regular apply step
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
                    inner = '; '.join(inst_lines + [f'apply {ref_name} <;> assumption'])
                    lines.append(f'have {hname} : {full_lit_str} := fun {fvars_str} => by {inner}')
                else:
                    # Use assumption first; fall back to simp_all for symmetric-equation subgoals
                    lines.append(f'have {hname} : {full_lit_str} := by apply {ref_name} <;> first | assumption | simp_all')

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
        if (isinstance(conclusion, EqLit) and isinstance(final_lit, EqLit)):
            concl_str = lean_lit(conclusion, var_map)
            final_str = lean_lit(final_lit, var_map)
            flipped = lean_lit(EqLit(conclusion.rhs, conclusion.lhs), var_map)
            if final_str == flipped and final_str != concl_str:
                lines.append(f'exact {final_name}.symm')
            else:
                lines.append(f'exact {final_name}')
        else:
            lines.append(f'exact {final_name}')
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
