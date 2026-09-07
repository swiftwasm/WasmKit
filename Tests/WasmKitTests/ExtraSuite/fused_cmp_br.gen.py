#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering the fused integer compare+branch forms.

For every width and comparison one exported function runs the three fusion
sites (br_if on a result-less block, `if`, and br_if out of a block with a
result) and returns a 3-bit mask, so one assert_return per operand pair
checks all three. Boundary operands pin down signedness and the complement.
"""
OPS = ["eq", "ne", "lt_s", "lt_u", "gt_s", "gt_u", "le_s", "le_u", "ge_s", "ge_u"]
I32 = [0, 1, 0x7fff_ffff, 0x8000_0000, 0xffff_ffff, 42]
I64 = [0, 1, 0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff, 0x0000_0001_0000_0000, 42]

def signed(v, bits): return v - (1 << bits) if v >> (bits - 1) else v
def holds(op, a, b, bits):
    sa, sb = signed(a, bits), signed(b, bits)
    return {"eq": a == b, "ne": a != b, "lt_s": sa < sb, "lt_u": a < b, "gt_s": sa > sb, "gt_u": a > b,
            "le_s": sa <= sb, "le_u": a <= b, "ge_s": sa >= sb, "ge_u": a >= b}[op]
def lit(v, bits): return f"i{bits}.const {v}" if v < (1 << (bits - 1)) else f"i{bits}.const {signed(v, bits)}"

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/fused_cmp_br.gen.py > Tests/WasmKitTests/ExtraSuite/fused_cmp_br.wast",
       ";;",
       ";; Fused integer compare + branch: every comparison, at each of the three",
       ";; fusion sites, on the boundary operands that separate signed from unsigned",
       ";; and a comparison from its complement. Each function returns a mask:",
       ";; bit0 = br_if (result-less block), bit1 = if (br_if_not), bit2 = br_if out",
       ";; of a block with a result (landing pad, br_if_not)."]
for bits, values in ((32, I32), (64, I64)):
    t = f"i{bits}"
    out.append("(module")
    for op in OPS:
        out.append(f"""  (func (export "{t}.{op}") (param $a {t}) (param $b {t}) (result i32) (local $m i32)
    (block (br_if 0 ({t}.{op} (local.get $a) (local.get $b))) (return (local.get $m)))
    (local.set $m (i32.const 1))
    (if ({t}.{op} (local.get $a) (local.get $b)) (then (local.set $m (i32.or (local.get $m) (i32.const 2)))))
    (local.set $m (i32.or (local.get $m)
      (block (result i32)
        (i32.add (i32.const 4) (i32.const 0))
        (br_if 0 ({t}.{op} (local.get $a) (local.get $b)))
        (drop)
        (i32.const 0))))
    (local.get $m))""")
    out.append(")")
    out.append("")
    for op in OPS:
        for a in values:
            for b in values:
                exp = 7 if holds(op, a, b, bits) else 0
                out.append(f'(assert_return (invoke "{t}.{op}" ({lit(a, bits)}) ({lit(b, bits)})) (i32.const {exp}))')
        out.append("")

out += [";; i32.eqz feeding br_if / if (fused into br_if_not / br_if on the input).",
        "(module",
        '  (func (export "eqz") (param $a i32) (result i32) (local $m i32)',
        "    (block (br_if 0 (i32.eqz (local.get $a))) (return (local.get $m)))",
        "    (local.set $m (i32.const 1))",
        "    (if (i32.eqz (local.get $a)) (then (local.set $m (i32.or (local.get $m) (i32.const 2)))))",
        "    (local.get $m))",
        ")"]
for a in I32:
    out.append(f'(assert_return (invoke "eqz" ({lit(a, 32)})) (i32.const {3 if a == 0 else 0}))')
out += ["",
        ";; A comparison whose result is also stored in a local must keep its value.",
        "(module",
        '  (func (export "stored") (param $a i32) (param $b i32) (result i32) (local $c i32)',
        "    (local.set $c (i32.lt_u (local.get $a) (local.get $b)))",
        "    (block (br_if 0 (local.get $c)) (return (i32.mul (local.get $c) (i32.const 10))))",
        "    (i32.add (local.get $c) (i32.const 1)))",
        ")",
        '(assert_return (invoke "stored" (i32.const 1) (i32.const 2)) (i32.const 2))',
        '(assert_return (invoke "stored" (i32.const 2) (i32.const 1)) (i32.const 0))',
        "",
        ";; Float comparisons: NaN makes a comparison and its complement both false,",
        ";; so neither branch polarity may be expressed as a flipped compare.",
        "(module",
        '  (func (export "f32.lt.brif") (param $a f32) (param $b f32) (result i32)',
        "    (block (br_if 0 (f32.lt (local.get $a) (local.get $b))) (return (i32.const 0))) (i32.const 1))",
        '  (func (export "f32.lt.if") (param $a f32) (param $b f32) (result i32)',
        "    (if (f32.lt (local.get $a) (local.get $b)) (then (return (i32.const 1)))) (i32.const 0))",
        '  (func (export "f64.ge.brif") (param $a f64) (param $b f64) (result i32)',
        "    (block (br_if 0 (f64.ge (local.get $a) (local.get $b))) (return (i32.const 0))) (i32.const 1))",
        '  (func (export "f64.ge.if") (param $a f64) (param $b f64) (result i32)',
        "    (if (f64.ge (local.get $a) (local.get $b)) (then (return (i32.const 1)))) (i32.const 0))",
        ")"]
for fn in ("f32.lt.brif", "f32.lt.if"):
    for a, b in (("nan", "1"), ("1", "nan"), ("nan", "nan")):
        out.append(f'(assert_return (invoke "{fn}" (f32.const {a}) (f32.const {b})) (i32.const 0))')
    out.append(f'(assert_return (invoke "{fn}" (f32.const 1) (f32.const 2)) (i32.const 1))')
    out.append(f'(assert_return (invoke "{fn}" (f32.const 2) (f32.const 1)) (i32.const 0))')
for fn in ("f64.ge.brif", "f64.ge.if"):
    for a, b in (("nan", "1"), ("1", "nan"), ("nan", "nan")):
        out.append(f'(assert_return (invoke "{fn}" (f64.const {a}) (f64.const {b})) (i32.const 0))')
    out.append(f'(assert_return (invoke "{fn}" (f64.const 2) (f64.const 1)) (i32.const 1))')
    out.append(f'(assert_return (invoke "{fn}" (f64.const 1) (f64.const 2)) (i32.const 0))')
print("\n".join(out))
