#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering fused float compare+branch and the
two-operation float superinstructions.

Each module stores its operand matrix in linear memory. A driver loops over it
and counts the rows where a fused site disagrees with a reference that keeps the
intermediate in a local (so the translator cannot fuse it), so one assertion
covers a whole matrix.
"""
import struct

def esc(data):
    return "".join(chr(b) if 0x20 <= b < 0x7f and chr(b) not in '"\\' else f"\\{b:02x}" for b in data)

TYPES = {"f32": ("f", 4, "i32"), "f64": ("d", 8, "i64")}

def specials(t):
    if t == "f32":
        return [0.0, -0.0, 1.0, -1.0, float("inf"), float("-inf"), float("nan"), -float("nan"),
                struct.unpack("<f", struct.pack("<I", 1))[0], struct.unpack("<f", struct.pack("<I", 0x7f7fffff))[0]]
    return [0.0, -0.0, 1.0, -1.0, float("inf"), float("-inf"), float("nan"), -float("nan"),
            struct.unpack("<d", struct.pack("<Q", 1))[0], struct.unpack("<d", struct.pack("<Q", 0x7fefffffffffffff))[0]]

def pack(t, values):
    return struct.pack("<%d%s" % (len(values), TYPES[t][0]), *values)

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/float_fusion.gen.py > Tests/WasmKitTests/ExtraSuite/float_fusion.wast",
       ""]

# --- Fused float compare + branch -------------------------------------------
CMPS = ["eq", "ne", "lt", "gt", "le", "ge"]
out += [";; Fused float compare + branch, every operator at each fusion site",
        ";; (br_if, if, br_if out of a block with a result, and <cmp>; i32.eqz; if),",
        ";; against the unfused comparison over NaN, signed zeroes, infinities and",
        ";; denormals. Each driver returns the number of mismatching operand pairs for the k-th operator."]
for t, (fmt, w, it) in TYPES.items():
    vals = specials(t)
    pairs = [(a, b) for a in vals for b in vals]
    data = pack(t, [x for p in pairs for x in p])
    out.append("(module")
    out.append("  (memory 1)")
    out.append(f'  (data (i32.const 0) "{esc(data)}")')
    for op in CMPS:
        c = f"({t}.{op} (local.get $a) (local.get $b))"
        p = f"(param $a {t}) (param $b {t})"
        out += [f"  (func ${op}.brif {p} (result i32)",
                f"    (block (br_if 0 {c}) (return (i32.const 0))) (i32.const 1))",
                f"  (func ${op}.if {p} (result i32)",
                f"    (if {c} (then (return (i32.const 1)))) (i32.const 0))",
                f"  (func ${op}.brifcopy {p} (result i32)",
                f"    (block (result i32) (i32.add (i32.const 1) (i32.const 0)) (br_if 0 {c}) (drop) (i32.const 0)))",
                f"  (func ${op}.eqzif {p} (result i32)",
                f"    (if (i32.eqz {c}) (then (return (i32.const 1)))) (i32.const 0))",
                f"  (func ${op}.ref {p} (result i32) (local $r i32)",
                f"    (local.set $r {c}) (local.get $r))",
                ]
    sites = ["brif", "if", "brifcopy", "eqzif", "ref"]
    out.append("  (type $cmp (func (param " + t + " " + t + ") (result i32)))")
    out.append("  (table funcref (elem " + " ".join(f"${op}.{site}" for op in CMPS for site in sites) + "))")
    out += [f'  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $a {t}) (local $b {t}) (local $r i32) (local $base i32)',
            f"    (local.set $base (i32.mul (local.get $k) (i32.const {len(sites)})))",
            f"    (loop $l",
            f"      (local.set $a ({t}.load (i32.mul (local.get $i) (i32.const {2 * w}))))",
            f"      (local.set $b ({t}.load (i32.add (i32.mul (local.get $i) (i32.const {2 * w})) (i32.const {w}))))",
            f"      (local.set $r (call_indirect (type $cmp) (local.get $a) (local.get $b) (i32.add (local.get $base) (i32.const 4))))",
            f"      (if (i32.or (i32.or (i32.ne (call_indirect (type $cmp) (local.get $a) (local.get $b) (local.get $base)) (local.get $r))",
            f"                          (i32.ne (call_indirect (type $cmp) (local.get $a) (local.get $b) (i32.add (local.get $base) (i32.const 1))) (local.get $r)))",
            f"                  (i32.or (i32.ne (call_indirect (type $cmp) (local.get $a) (local.get $b) (i32.add (local.get $base) (i32.const 2))) (local.get $r))",
            f"                          (i32.eq (call_indirect (type $cmp) (local.get $a) (local.get $b) (i32.add (local.get $base) (i32.const 3))) (local.get $r))))",
            f"        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
            f"      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {len(pairs)}))))",
            f"    (local.get $n))",
            ")"]
    for k, op in enumerate(CMPS):
        out.append(f';; {t}.{op}')
        out.append(f'(assert_return (invoke "check" (i32.const {k})) (i32.const 0))')
    out.append("")

out += [";; <cmp>; i32.eqz; br_if on integers fuses to the flipped comparison.",
        "(module",
        '  (func (export "f") (param $a i32) (param $b i32) (result i32)',
        "    (block (br_if 0 (i32.eqz (i32.lt_u (local.get $a) (local.get $b)))) (return (i32.const 0)))",
        "    (i32.const 1))",
        ";; An i32.eqz of a comparison with no branch after it still produces the value.",
        '  (func (export "g") (param $a f64) (param $b f64) (result i32)',
        "    (i32.eqz (f64.lt (local.get $a) (local.get $b))))",
        ")",
        '(assert_return (invoke "f" (i32.const 1) (i32.const 2)) (i32.const 0))',
        '(assert_return (invoke "f" (i32.const 2) (i32.const 1)) (i32.const 1))',
        '(assert_return (invoke "f" (i32.const 2) (i32.const 2)) (i32.const 1))',
        '(assert_return (invoke "g" (f64.const 1) (f64.const 2)) (i32.const 0))',
        '(assert_return (invoke "g" (f64.const 2) (f64.const 1)) (i32.const 1))',
        '(assert_return (invoke "g" (f64.const nan) (f64.const 1)) (i32.const 1))',
        ""]

# --- Two-operation float superinstructions ----------------------------------
OPS = ["add", "sub", "mul"]
out += [";; Two-operation float superinstructions: (x op1 y) op2 z with the",
        ";; intermediate as the left and as the right operand (and left with a constant",
        ";; right operand), against a reference",
        ";; that stores the intermediate in a local. Both results must be bit-identical",
        ";; unless both are NaN. Each driver returns the number of mismatching triples for the k-th form."]
for t, (fmt, w, it) in TYPES.items():
    eps = 2.0 ** -52 if t == "f64" else 2.0 ** -23
    big = 1e300 if t == "f64" else 1e38
    triples = [(1 + eps, 1 - eps, -1.0), (1 - eps, 1 + eps, -1.0), (1 + eps, 1 + eps, -1.0),
               (2 + 2 * eps, 1 - eps, -2.0), (big, big, float("-inf"))]
    sp = specials(t)[:8] + [3.0, 0.1]
    for a in sp:
        for b in sp:
            triples.append((a, b, 1.0))
            triples.append((a, 1.0, b))
    data = pack(t, [x for tr in triples for x in tr])
    out.append("(module")
    out.append("  (memory 1)")
    out.append(f'  (data (i32.const 0) "{esc(data)}")')
    p = f"(param $a {t}) (param $b {t}) (param $c {t})"
    names = []
    for op1 in OPS:
        for op2 in OPS:
            inner = f"({t}.{op1} (local.get $a) (local.get $b))"
            for pos in ("left", "right", "const"):
                name = f"{op1}.{op2}.{pos}"
                if pos == "left":
                    fused = f"({t}.{op2} {inner} (local.get $c))"
                    ref = f"({t}.{op2} (local.get $t) (local.get $c))"
                elif pos == "const":
                    fused = f"({t}.{op2} {inner} ({t}.const 0.1))"
                    ref = f"({t}.{op2} (local.get $t) ({t}.const 0.1))"
                else:
                    fused = f"({t}.{op2} (local.get $c) {inner})"
                    ref = f"({t}.{op2} (local.get $c) (local.get $t))"
                names.append(name)
                out += [f'  (func ${name} (export "{name}") {p} (result {t}) {fused})',
                        f"  (func ${name}.ref {p} (result {t}) (local $t {t})",
                        f"    (local.set $t {inner}) {ref})",
                        ]
    out.append(f"  (type $bin (func {p} (result {t})))")
    out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n in names) + "))")
    load = lambda off: f"({t}.load (i32.add (local.get $o) (i32.const {off})))"
    args = f"{load(0)} {load(w)} {load(2 * w)}"
    out += [f'  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $o i32) (local $x {t}) (local $y {t})',
            f"    (loop $l",
            f"      (local.set $o (i32.mul (local.get $i) (i32.const {3 * w})))",
            f"      (local.set $x (call_indirect (type $bin) {args} (i32.shl (local.get $k) (i32.const 1))))",
            f"      (local.set $y (call_indirect (type $bin) {args} (i32.add (i32.shl (local.get $k) (i32.const 1)) (i32.const 1))))",
            f"      (if (i32.eqz (i32.or (i32.and ({t}.ne (local.get $x) (local.get $x)) ({t}.ne (local.get $y) (local.get $y)))",
            f"                           ({it}.eq ({it}.reinterpret_{t} (local.get $x)) ({it}.reinterpret_{t} (local.get $y)))))",
            f"        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
            f"      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {len(triples)}))))",
            f"    (local.get $n))"]
    out += [";; A local.set right after a pushed local must store that local's value,",
            ";; not the float operation emitted before it.",
            f'  (func (export "set-local") {p} (result {t}) (local $x {t})',
            f"    ({t}.add (local.get $a) (local.get $b)) (local.get $c) (local.set $x) (drop) (local.get $x))",
            ";; A label between the two operations blocks the fold.",
            f'  (func (export "label") {p} (result {t}) ({t}.add (block (result {t}) ({t}.mul (local.get $a) (local.get $b))) (local.get $c)))',
            ";; A chain of three folds the first pair and keeps the third operation.",
            f'  (func (export "chain") {p} (param $d {t}) (result {t}) ({t}.mul ({t}.add ({t}.mul (local.get $a) (local.get $b)) (local.get $c)) (local.get $d)))',
            ";; A live intermediate is not folded.",
            f'  (func (export "live") {p} (result {t}) (local $t {t})',
            f"    (local.set $t ({t}.mul (local.get $a) (local.get $b))) ({t}.add ({t}.add (local.get $t) (local.get $c)) (local.get $t)))",
            ";; Division has no superinstruction.",
            f'  (func (export "div") {p} (result {t}) ({t}.add ({t}.div (local.get $a) (local.get $b)) (local.get $c)))',
            ")"]
    for k, n in enumerate(names):
        out.append(f';; {t} {n}')
        out.append(f'(assert_return (invoke "check" (i32.const {k})) (i32.const 0))')
    one_plus = "0x1.0000000000001p+0" if t == "f64" else "0x1.000002p+0"
    one_minus = "0x1.fffffffffffffp-1" if t == "f64" else "0x1.fffffcp-1"
    out += [";; fmul then fadd rounds the product to 1.0, so the sum is exactly zero; a",
            ";; contracted fused multiply-add would keep the extra bits.",
            f'(assert_return (invoke "mul.add.left" ({t}.const {one_plus}) ({t}.const {one_minus}) ({t}.const -1)) ({t}.const 0))',
            f'(assert_return (invoke "mul.add.right" ({t}.const {one_plus}) ({t}.const {one_minus}) ({t}.const -1)) ({t}.const 0))',
            f'(assert_return (invoke "set-local" ({t}.const 3) ({t}.const 4) ({t}.const 5)) ({t}.const 5))',
            f'(assert_return (invoke "label" ({t}.const 3) ({t}.const 4) ({t}.const 5)) ({t}.const 17))',
            f'(assert_return (invoke "chain" ({t}.const 3) ({t}.const 4) ({t}.const 5) ({t}.const 2)) ({t}.const 34))',
            f'(assert_return (invoke "live" ({t}.const 3) ({t}.const 4) ({t}.const 5)) ({t}.const 29))',
            f'(assert_return (invoke "div" ({t}.const 6) ({t}.const 4) ({t}.const 1)) ({t}.const 2.5))',
            ""]
print("\n".join(out), end="")
