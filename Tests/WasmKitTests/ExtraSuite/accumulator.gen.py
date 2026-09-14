#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering values handed over in the integer
accumulator.

Each module stores an operand matrix in linear memory. A driver loops over it
and counts the rows where a site the translator folds disagrees with a reference
that keeps the intermediate in a local, so one assertion covers a whole matrix.
"""
import itertools
import struct

def esc(data):
    return "".join(chr(b) if 0x20 <= b < 0x7f and chr(b) not in '"\\' else f"\\{b:02x}" for b in data)

TYPES = {"i32": ("i", 4), "i64": ("q", 8)}
OPS = ["add", "sub", "mul", "and", "or", "xor", "shl", "shr_s", "shr_u", "rotl", "rotr"]
CMPS = ["eq", "ne", "lt_s", "lt_u", "gt_s", "gt_u", "le_s", "le_u", "ge_s", "ge_u"]
VALUES = {
    "i32": [0, 1, -1, 0x7fffffff, -0x80000000, 31, 33, 0x12345678],
    "i64": [0, 1, -1, 0x7fffffffffffffff, -0x8000000000000000, 63, 65, 0x123456789abcdef0],
}

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/accumulator.gen.py > Tests/WasmKitTests/ExtraSuite/accumulator.wast",
       ""]

for t, (fmt, w) in TYPES.items():
    triples = list(itertools.product(VALUES[t], repeat=3))
    data = struct.pack("<%d%s" % (3 * len(triples), fmt), *[v for tr in triples for v in tr])
    p = f"(param $a {t}) (param $b {t}) (param $c {t})"
    # `rotr` has no two-operation superinstruction, so it produces into the
    # accumulator and the consumer reads it.
    inner = f"({t}.rotr (local.get $a) (local.get $b))"
    forms = []  # (name, result type, folded body, reference body)
    # A taken branch that has to copy a value into the block's result slot goes
    # through a landing pad.
    def pad(c):
        return (f"(block (result i32) (i32.add (i32.const 10) (i32.const 1)) (i32.add (i32.const 3) (i32.const 2))"
                f" {c} (br_if 0) (i32.sub))")
    def pad_ref(r):
        return (f"(local.set $t {inner}) (if (result i32) {r} (then (i32.const 5))"
                f" (else (i32.sub (i32.add (i32.const 10) (i32.const 1)) (i32.const 5))))")
    for op in OPS:
        forms.append((f"{op}.left", t, f"({t}.{op} {inner} (local.get $c))",
                      f"(local.set $t {inner}) ({t}.{op} (local.get $t) (local.get $c))"))
        forms.append((f"{op}.right", t, f"({t}.{op} (local.get $c) {inner})",
                      f"(local.set $t {inner}) ({t}.{op} (local.get $c) (local.get $t))"))
        forms.append((f"{op}.chain", t, f"({t}.{op} ({t}.sub {inner} (local.get $c)) (local.get $a))",
                      f"(local.set $t {inner}) ({t}.{op} ({t}.sub (local.get $t) (local.get $c)) (local.get $a))"))
    for cmp in CMPS:
        for pos in ("left", "right"):
            c = f"({t}.{cmp} {inner} (local.get $c))" if pos == "left" else f"({t}.{cmp} (local.get $c) {inner})"
            r = f"({t}.{cmp} (local.get $t) (local.get $c))" if pos == "left" else f"({t}.{cmp} (local.get $c) (local.get $t))"
            forms.append((f"{cmp}.{pos}.br_if", "i32",
                          f"(block (br_if 0 {c}) (return (i32.const 0))) (i32.const 1)",
                          f"(local.set $t {inner}) {r}"))
            forms.append((f"{cmp}.{pos}.if", "i32",
                          f"(if (result i32) {c} (then (i32.const 1)) (else (i32.const 0)))",
                          f"(local.set $t {inner}) {r}"))
            forms.append((f"{cmp}.{pos}.br_if_copy", "i32",
                          f"(block (result i32) (i32.const 1) {c} (br_if 0) (drop) (i32.const 0))",
                          f"(local.set $t {inner}) {r}"))
            forms.append((f"{cmp}.{pos}.br_if_pad", "i32", pad(c), pad_ref(r)))
    cond = f"({t}.rotr (local.get $a) (local.get $b))" if t == "i32" else f"(i64.ne {inner} (i64.const 0))"
    forms.append(("cond.br_if", "i32", f"(block (br_if 0 {cond}) (return (i32.const 0))) (i32.const 1)",
                  f"(local.set $t {inner}) ({t}.ne (local.get $t) ({t}.const 0))"))
    forms.append(("cond.if", "i32", f"(if (result i32) {cond} (then (i32.const 1)) (else (i32.const 0)))",
                  f"(local.set $t {inner}) ({t}.ne (local.get $t) ({t}.const 0))"))
    forms.append(("cond.br_if_pad", "i32", pad(cond), pad_ref(f"({t}.ne (local.get $t) ({t}.const 0))")))
    forms.append(("cond.br_if_copy", "i32", f"(block (result i32) (i32.const 1) {cond} (br_if 0) (drop) (i32.const 0))",
                  f"(local.set $t {inner}) ({t}.ne (local.get $t) ({t}.const 0))"))
    # A bit test on a value from the accumulator, branched on directly and
    # through `eqz`.
    band = f"({t}.and {inner} (local.get $c))"
    bref = f"({t}.ne ({t}.and (local.get $t) (local.get $c)) ({t}.const 0))"
    btest = band if t == "i32" else f"(i32.eqz (i64.eqz {band}))"
    forms.append(("and.br_if", "i32", f"(block (br_if 0 {btest}) (return (i32.const 0))) (i32.const 1)",
                  f"(local.set $t {inner}) {bref}"))
    forms.append(("and.eqz.if", "i32", f"(if (result i32) ({t}.eqz {band}) (then (i32.const 0)) (else (i32.const 1)))",
                  f"(local.set $t {inner}) {bref}"))
    # A superinstruction pair after an accumulator hand-off undoes the hand-off.
    forms.append(("super.after", t, f"({t}.add ({t}.shl ({t}.and {inner} (local.get $c)) (local.get $b)) (local.get $a))",
                  f"(local.set $t {inner}) ({t}.add ({t}.shl ({t}.and (local.get $t) (local.get $c)) (local.get $b)) (local.get $a))"))

    out.append("(module")
    out.append("  (memory 1)")
    out.append(f'  (data (i32.const 0) "{esc(data)}")')
    for name, rt, body, ref in forms:
        out += [f"  (func ${name} {p} (result {rt}) {body})",
                f"  (func ${name}.ref {p} (result {rt}) (local $t {t}) {ref})"]
    for rt in dict.fromkeys([t, "i32"]):
        out.append(f"  (type $f{rt} (func {p} (result {rt})))")
    out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _, _ in forms) + "))")
    load = lambda off: f"({t}.load (i32.add (local.get $o) (i32.const {off})))"
    args = f"{load(0)} {load(w)} {load(2 * w)}"
    for rt in dict.fromkeys(rt for _, rt, _, _ in forms):
        out += [f'  (func (export "check.{rt}") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)',
                f"    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
                f"    (loop $l",
                f"      (local.set $o (i32.mul (local.get $i) (i32.const {3 * w})))",
                f"      (if ({rt}.ne (call_indirect (type $f{rt}) {args} (local.get $f))",
                f"                  (call_indirect (type $f{rt}) {args} (i32.add (local.get $f) (i32.const 1))))",
                f"        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
                f"      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {len(triples)}))))",
                f"    (local.get $n))"]
    out.append(")")
    for k, (name, rt, _, _) in enumerate(forms):
        out.append(f";; {t} {name}")
        out.append(f'(assert_return (invoke "check.{rt}" (i32.const {k})) (i32.const 0))')
    out.append("")

out += [
    ";; Edges around a hand-off: a label, a call, a trapping instruction, a",
    ";; relinked local.set and a pushed local between producer and consumer.",
    "(module",
    '  (global $g (mut i32) (i32.const 0))',
    '  (global $h (mut i64) (i64.const 0))',
    '  (func $id (param i32) (result i32) (local.get 0))',
    '  (func (export "label") (param $a i32) (param $b i32) (result i32)',
    "    (i32.sub (block (result i32) (i32.rotr (local.get $a) (local.get $b))) (local.get $b)))",
    '  (func (export "call") (param $a i32) (param $b i32) (result i32)',
    "    (i32.sub (i32.rotr (local.get $a) (local.get $b)) (call $id (local.get $b))))",
    '  (func (export "div") (param $a i32) (param $b i32) (result i32)',
    "    (i32.sub (i32.rotr (local.get $a) (local.get $b)) (i32.div_s (local.get $a) (local.get $b))))",
    '  (func (export "live") (param $a i32) (param $b i32) (result i32) (local $t i32)',
    "    (i32.sub (local.tee $t (i32.rotr (local.get $a) (local.get $b))) (local.get $t)))",
    '  (func (export "set-local") (param $a i32) (param $b i32) (result i32) (local $x i32)',
    "    (i32.rotr (local.get $a) (local.get $b)) (local.get $b) (local.set $x) (drop) (local.get $x))",
    '  (func (export "pushed-local") (param $a i32) (param $b i32) (result i32)',
    "    (i32.rotr (local.get $a) (local.get $b)) (local.get $b) (i32.sub))",
    ";; A counter loop through a global, and globals as compare operands and conditions.",
    '  (func (export "counter") (param $n i32) (result i32)',
    "    (global.set $g (local.get $n))",
    "    (loop $l (br_if $l (global.set $g (i32.sub (global.get $g) (i32.const 1))) (global.get $g)))",
    "    (global.get $g))",
    '  (func (export "global-cmp") (param $a i32) (result i32)',
    "    (global.set $g (local.get $a))",
    "    (block (br_if 0 (i32.lt_u (global.get $g) (i32.const 10))) (return (i32.const 0))) (i32.const 1))",
    '  (func (export "global-cond") (param $a i32) (result i32)',
    "    (global.set $g (local.get $a))",
    "    (if (result i32) (global.get $g) (then (i32.const 1)) (else (i32.const 0))))",
    '  (func (export "global64") (param $a i64) (result i64)',
    "    (global.set $h (local.get $a))",
    "    (i64.add (global.get $h) (i64.const 0x100000000)))",
    ")",
    '(assert_return (invoke "label" (i32.const 8) (i32.const 1)) (i32.const 3))',
    '(assert_return (invoke "call" (i32.const 8) (i32.const 1)) (i32.const 3))',
    '(assert_return (invoke "div" (i32.const 8) (i32.const 1)) (i32.const -4))',
    '(assert_trap (invoke "div" (i32.const 8) (i32.const 0)) "integer divide by zero")',
    '(assert_return (invoke "live" (i32.const 8) (i32.const 1)) (i32.const 0))',
    '(assert_return (invoke "set-local" (i32.const 8) (i32.const 1)) (i32.const 1))',
    '(assert_return (invoke "pushed-local" (i32.const 8) (i32.const 1)) (i32.const 3))',
    '(assert_return (invoke "counter" (i32.const 100)) (i32.const 0))',
    '(assert_return (invoke "global-cmp" (i32.const 3)) (i32.const 1))',
    '(assert_return (invoke "global-cmp" (i32.const 30)) (i32.const 0))',
    '(assert_return (invoke "global-cond" (i32.const 0)) (i32.const 0))',
    '(assert_return (invoke "global-cond" (i32.const 256)) (i32.const 1))',
    '(assert_return (invoke "global64" (i64.const -1)) (i64.const 0xffffffff))',
    "",
]
print("\n".join(out), end="")
