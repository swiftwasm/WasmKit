#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering `f64` values handed over in the float
accumulator.

Each module stores an operand matrix in linear memory. A driver loops over it
and counts the rows where a site the translator folds disagrees with a
reference that keeps the intermediate in a local, comparing bit patterns and
treating any two NaNs as equal.
"""
import itertools
import struct

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

VALUES = [0.0, -0.0, 1.0, -2.5, float("inf"), float("-inf"), float("nan"), 1e308, 5e-324, 3.0]
triples = list(itertools.product(VALUES, repeat=3))
data = struct.pack("<%dd" % (3 * len(triples)), *[v for t in triples for v in t])

forms = []  # (name, result type, body, reference)
# `f64.div` pairs with no superinstruction, so it produces into the accumulator.
inner = "(f64.div (local.get $a) (local.get $b))"
for op in ("add", "sub", "mul", "div"):
    forms.append((f"{op}.left", "f64", f"(f64.{op} {inner} (local.get $c))",
                  f"(local.set $t {inner}) (f64.{op} (local.get $t) (local.get $c))"))
    forms.append((f"{op}.right", "f64", f"(f64.{op} (local.get $c) {inner})",
                  f"(local.set $t {inner}) (f64.{op} (local.get $c) (local.get $t))"))
    forms.append((f"{op}.chain", "f64", f"(f64.{op} (local.get $a) (f64.div {inner} (local.get $c)))",
                  f"(local.set $t {inner}) (f64.{op} (local.get $a) (f64.div (local.get $t) (local.get $c)))"))
# A superinstruction and `sqrt` as producers.
superinst = "(f64.add (f64.mul (local.get $a) (local.get $b)) (local.get $c))"
forms.append(("super.div", "f64", f"(f64.div (local.get $a) {superinst})",
              f"(local.set $t {superinst}) (f64.div (local.get $a) (local.get $t))"))
forms.append(("sqrt.mul", "f64", "(f64.mul (local.get $b) (f64.sqrt (local.get $a)))",
              "(local.set $t (f64.sqrt (local.get $a))) (f64.mul (local.get $b) (local.get $t))"))
# An accumulator hand-off undone by a following superinstruction.
forms.append(("undo.super", "f64", f"(f64.add (f64.mul {inner} (local.get $c)) (local.get $a))",
              f"(local.set $t {inner}) (f64.add (f64.mul (local.get $t) (local.get $c)) (local.get $a))"))
for cmp in ("eq", "ne", "lt", "gt", "le", "ge"):
    for pos in ("left", "right"):
        c = f"(f64.{cmp} {inner} (local.get $c))" if pos == "left" else f"(f64.{cmp} (local.get $c) {inner})"
        r = f"(f64.{cmp} (local.get $t) (local.get $c))" if pos == "left" else f"(f64.{cmp} (local.get $c) (local.get $t))"
        forms.append((f"{cmp}.{pos}.br_if", "i32", f"(block (br_if 0 {c}) (return (i32.const 0))) (i32.const 1)",
                      f"(local.set $t {inner}) {r}"))
        forms.append((f"{cmp}.{pos}.if", "i32", f"(if (result i32) {c} (then (i32.const 1)) (else (i32.const 0)))",
                      f"(local.set $t {inner}) {r}"))
        forms.append((f"{cmp}.{pos}.eqz", "i32", f"(if (result i32) (i32.eqz {c}) (then (i32.const 0)) (else (i32.const 1)))",
                      f"(local.set $t {inner}) {r}"))
# Loads and stores that meet float arithmetic.
forms.append(("load.add", "f64", "(f64.add (f64.load (i32.const 8)) (local.get $a))",
              "(local.set $t (f64.load (i32.const 8))) (f64.add (local.get $t) (local.get $a))"))
forms.append(("load.addr.sub", "f64", "(f64.sub (local.get $a) (f64.load (i32.add (global.get $p) (i32.const 8))))",
              "(local.set $t (f64.load (i32.add (global.get $p) (i32.const 8)))) (f64.sub (local.get $a) (local.get $t))"))
forms.append(("store", "f64", f"(f64.store (i32.const 16) {inner}) (f64.load (i32.const 16))",
              f"(local.set $t {inner}) (f64.store (i32.const 16) (local.get $t)) (f64.load (i32.const 16))"))
forms.append(("store.load", "f64", "(f64.store (i32.const 16) (f64.load (i32.const 24))) (f64.load (i32.const 16))",
              "(local.set $t (f64.load (i32.const 24))) (f64.store (i32.const 16) (local.get $t)) (f64.load (i32.const 16))"))

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/accumulator_float.gen.py > Tests/WasmKitTests/ExtraSuite/accumulator_float.wast",
       "",
       "(module",
       "  (memory 2)",
       "  (global $p (mut i32) (i32.const 0))",
       f'  (data (i32.const 65536) "{esc(data)}")']
p = "(param $a f64) (param $b f64) (param $c f64)"
for name, rt, body, ref in forms:
    out += [f"  (func ${name} {p} (result {rt}) (local $t f64) {body})",
            f"  (func ${name}.ref {p} (result {rt}) (local $t f64) {ref})"]
out.append(f"  (type $ff64 (func {p} (result f64)))")
out.append(f"  (type $fi32 (func {p} (result i32)))")
out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _, _ in forms) + "))")
load = lambda off: f"(f64.load (i32.add (local.get $o) (i32.const {off})))"
args = f"{load(0)} {load(8)} {load(16)}"
out += ['  (func (export "check.f64") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32) (local $x f64) (local $y f64)',
        "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
        "    (loop $l",
        "      (local.set $o (i32.add (i32.const 65536) (i32.mul (local.get $i) (i32.const 24))))",
        "      (f64.store (i32.const 8) (f64.load (local.get $o))) (f64.store (i32.const 24) (f64.load (i32.add (local.get $o) (i32.const 8))))",
        f"      (local.set $x (call_indirect (type $ff64) {args} (local.get $f)))",
        f"      (local.set $y (call_indirect (type $ff64) {args} (i32.add (local.get $f) (i32.const 1))))",
        "      (if (i32.eqz (i32.or (i32.and (f64.ne (local.get $x) (local.get $x)) (f64.ne (local.get $y) (local.get $y)))",
        "                           (i64.eq (i64.reinterpret_f64 (local.get $x)) (i64.reinterpret_f64 (local.get $y)))))",
        "        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
        f"      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {len(triples)}))))",
        "    (local.get $n))",
        '  (func (export "check.i32") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)',
        "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
        "    (loop $l",
        "      (local.set $o (i32.add (i32.const 65536) (i32.mul (local.get $i) (i32.const 24))))",
        f"      (if (i32.ne (call_indirect (type $fi32) {args} (local.get $f))",
        f"                  (call_indirect (type $fi32) {args} (i32.add (local.get $f) (i32.const 1))))",
        "        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
        f"      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {len(triples)}))))",
        "    (local.get $n))",
        ")"]
for k, (name, rt, _, _) in enumerate(forms):
    out.append(f";; {name}")
    out.append(f'(assert_return (invoke "check.{rt}" (i32.const {k})) (i32.const 0))')
print("\n".join(out))
