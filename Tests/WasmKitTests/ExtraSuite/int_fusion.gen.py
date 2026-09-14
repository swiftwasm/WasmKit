#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering the two-operation integer
superinstructions.

Each module stores an operand matrix in linear memory. A driver loops over it
and counts the rows where a fused site disagrees with a reference that keeps the
intermediate in a local (so the translator cannot fold it), so one assertion
covers a whole matrix.
"""
import itertools
import struct

def esc(data):
    return "".join(chr(b) if 0x20 <= b < 0x7f and chr(b) not in '"\\' else f"\\{b:02x}" for b in data)

TYPES = {"i32": ("i", 4), "i64": ("q", 8)}
SNAKE = {"ShrU": "shr_u", "ShrS": "shr_s"}
snake = lambda op: SNAKE.get(op, op.lower())

# Pairs with an opcode, as in the VM spec, plus pairs without one.
PAIRS = {
    "i32": [("Shl", "Add"), ("Mul", "Add"), ("Add", "Add"), ("And", "Add"),
            ("ShrU", "And"), ("Or", "And"), ("ShrU", "Add"), ("Sub", "And"),
            ("Shl", "Or"), ("Add", "And"), ("ShrU", "Or"), ("Xor", "ShrU"),
            ("Add", "Sub"), ("Xor", "Shl"), ("Sub", "Add"), ("And", "Shl"),
            ("Mul", "Sub"), ("ShrS", "Rotr"), ("Rotl", "Mul")],
    "i64": [("Xor", "Rotl"), ("Mul", "Add"), ("Shl", "And"), ("And", "Mul"),
            ("Shl", "Or"), ("Xor", "And"), ("Mul", "Xor"), ("And", "Xor"),
            ("Rotl", "Xor"), ("Sub", "And"), ("Xor", "Xor"), ("Or", "Or"),
            ("ShrU", "And"), ("And", "And"), ("Xor", "Mul"), ("Xor", "ShrU"),
            ("Mul", "Sub"), ("ShrS", "Rotr"), ("Rotr", "Sub")],
}

VALUES = {
    "i32": [0, 1, -1, 0x7fffffff, -0x80000000, 31, 33, 0x12345678],
    "i64": [0, 1, -1, 0x7fffffffffffffff, -0x8000000000000000, 63, 65, 0x123456789abcdef0],
}

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/int_fusion.gen.py > Tests/WasmKitTests/ExtraSuite/int_fusion.wast",
       "",
       ";; Two-operation integer superinstructions: (x op1 y) op2 z with the",
       ";; intermediate as the left and as the right operand, against a reference",
       ";; that stores the intermediate in a local. Operands include shift amounts",
       ";; at and past the width. Each driver returns the number of mismatching",
       ";; triples for the k-th form."]
for t, (fmt, w) in TYPES.items():
    triples = list(itertools.product(VALUES[t], repeat=3))
    data = struct.pack("<%d%s" % (3 * len(triples), fmt), *[v for tr in triples for v in tr])
    out.append("(module")
    out.append("  (memory 1)")
    out.append(f'  (data (i32.const 0) "{esc(data)}")')
    p = f"(param $a {t}) (param $b {t}) (param $c {t})"
    names = []
    for op1, op2 in PAIRS[t]:
        inner = f"({t}.{snake(op1)} (local.get $a) (local.get $b))"
        for pos in ("left", "right"):
            name = f"{snake(op1)}.{snake(op2)}.{pos}"
            if pos == "left":
                fused = f"({t}.{snake(op2)} {inner} (local.get $c))"
                ref = f"({t}.{snake(op2)} (local.get $t) (local.get $c))"
            else:
                fused = f"({t}.{snake(op2)} (local.get $c) {inner})"
                ref = f"({t}.{snake(op2)} (local.get $c) (local.get $t))"
            names.append(name)
            out += [f'  (func ${name} {p} (result {t}) {fused})',
                    f"  (func ${name}.ref {p} (result {t}) (local $t {t})",
                    f"    (local.set $t {inner}) {ref})"]
    out.append(f"  (type $bin (func {p} (result {t})))")
    out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n in names) + "))")
    load = lambda off: f"({t}.load (i32.add (local.get $o) (i32.const {off})))"
    args = f"{load(0)} {load(w)} {load(2 * w)}"
    out += [f'  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $f i32)',
            f"    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
            f"    (loop $l",
            f"      (local.set $o (i32.mul (local.get $i) (i32.const {3 * w})))",
            f"      (if ({t}.ne (call_indirect (type $bin) {args} (local.get $f))",
            f"                  (call_indirect (type $bin) {args} (i32.add (local.get $f) (i32.const 1))))",
            f"        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
            f"      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {len(triples)}))))",
            f"    (local.get $n))",
            ";; A local.set right after a pushed local must store that local's value,",
            ";; not the operation emitted before it.",
            f'  (func (export "set-local") {p} (result {t}) (local $x {t})',
            f"    ({t}.shl (local.get $a) (local.get $b)) (local.get $c) (local.set $x) (drop) (local.get $x))",
            ";; A label between the two operations blocks the fold.",
            f'  (func (export "label") {p} (result {t}) ({t}.add (block (result {t}) ({t}.mul (local.get $a) (local.get $b))) (local.get $c)))',
            ";; A chain of three folds the first pair and keeps the third operation.",
            f'  (func (export "chain") {p} (param $d {t}) (result {t}) ({t}.sub ({t}.add ({t}.mul (local.get $a) (local.get $b)) (local.get $c)) (local.get $d)))',
            ";; A live intermediate is not folded.",
            f'  (func (export "live") {p} (result {t}) (local $t {t})',
            f"    (local.set $t ({t}.mul (local.get $a) (local.get $b))) ({t}.add ({t}.add (local.get $t) (local.get $c)) (local.get $t)))",
            ";; Constant operands on both operations.",
            f'  (func (export "const") (param $a {t}) (result {t}) ({t}.add ({t}.shl (local.get $a) ({t}.const 3)) ({t}.const 5)))',
            ";; A folded and-producer or and-consumer feeding a branch.",
            f'  (func (export "and-branch") {p} (result i32)',
            f"    (block (br_if 0 ({t}.eqz ({t}.and ({t}.shr_u (local.get $a) (local.get $b)) (local.get $c)))) (return (i32.const 1)))",
            f"    (block (br_if 0 ({t}.ne ({t}.and ({t}.xor (local.get $a) (local.get $b)) (local.get $c)) ({t}.const 0))) (return (i32.const 2)))",
            f"    (i32.const 3))",
            ";; Division has no superinstruction.",
            f'  (func (export "div") {p} (result {t}) ({t}.add ({t}.div_s (local.get $a) (local.get $b)) (local.get $c)))',
            ")"]
    for k, n in enumerate(names):
        out.append(f';; {t} {n}')
        out.append(f'(assert_return (invoke "check" (i32.const {k})) (i32.const 0))')
    out += [f'(assert_return (invoke "set-local" ({t}.const 3) ({t}.const 4) ({t}.const 5)) ({t}.const 5))',
            f'(assert_return (invoke "label" ({t}.const 3) ({t}.const 4) ({t}.const 5)) ({t}.const 17))',
            f'(assert_return (invoke "chain" ({t}.const 3) ({t}.const 4) ({t}.const 5) ({t}.const 2)) ({t}.const 15))',
            f'(assert_return (invoke "live" ({t}.const 3) ({t}.const 4) ({t}.const 5)) ({t}.const 29))',
            f'(assert_return (invoke "const" ({t}.const 2)) ({t}.const 21))',
            f'(assert_return (invoke "and-branch" ({t}.const 12) ({t}.const 2) ({t}.const 1)) (i32.const 1))',
            f'(assert_return (invoke "and-branch" ({t}.const 12) ({t}.const 2) ({t}.const 4)) (i32.const 3))',
            f'(assert_return (invoke "and-branch" ({t}.const 12) ({t}.const 2) ({t}.const 16)) (i32.const 2))',
            f'(assert_return (invoke "div" ({t}.const -7) ({t}.const 2) ({t}.const 1)) ({t}.const -2))',
            ""]
print("\n".join(out), end="")
