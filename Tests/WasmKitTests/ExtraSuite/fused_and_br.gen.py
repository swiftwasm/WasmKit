#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering and-tests fused into conditional branches.

For each width one exported function runs every fusion site (br_if, if, through
eqz, br_if out of a block with a result) and returns a bitmask, so one
assert_return per operand pair checks them all.
"""
I32 = [0, 1, 2, 3, 0x8000_0000, 0x7fff_ffff, 0xffff_ffff, 0xff00]
I64 = [0, 1, 0x1_0000_0000, 0x8000_0000_0000_0000, 0xffff_ffff_0000_0000, 0x0000_0000_ffff_ffff,
       0x0000_ff00_0000_0000, 0xffff_ffff_ffff_ffff]

def lit(v, bits):
    return f"i{bits}.const {v - (1 << bits) if v >> (bits - 1) else v}"

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/fused_and_br.gen.py > Tests/WasmKitTests/ExtraSuite/fused_and_br.wast",
       "",
       ";; i32.and feeding br_if, if, i32.eqz + br_if, and br_if out of a block with a",
       ";; result. bit0..bit3 are set when the respective site sees a non-zero and.",
       "(module",
       '  (func (export "i32") (param $a i32) (param $b i32) (result i32) (local $m i32)',
       "    (block (br_if 0 (i32.and (local.get $a) (local.get $b))) (return (local.get $m)))",
       "    (local.set $m (i32.const 1))",
       "    (if (i32.and (local.get $a) (local.get $b)) (then (local.set $m (i32.or (local.get $m) (i32.const 2)))))",
       "    (block (br_if 0 (i32.eqz (i32.and (local.get $a) (local.get $b)))) (local.set $m (i32.or (local.get $m) (i32.const 4))))",
       "    (local.set $m (i32.or (local.get $m)",
       "      (block (result i32)",
       "        (i32.add (i32.const 8) (i32.const 0))",
       "        (br_if 0 (i32.and (local.get $a) (local.get $b)))",
       "        (drop)",
       "        (i32.const 0))))",
       "    (local.get $m))",
       ")"]
for a in I32:
    for b in I32:
        exp = 15 if a & b else 0
        out.append(f'(assert_return (invoke "i32" ({lit(a, 32)}) ({lit(b, 32)})) (i32.const {exp}))')

out += ["",
        ";; i64.and reaches a branch through i64.eqz; values whose and is non-zero only",
        ";; in the high half must take the non-zero path. bit0: eqz + br_if, bit1:",
        ";; eqz + i32.eqz + br_if, bit2: eqz + if.",
        "(module",
        '  (func (export "i64") (param $a i64) (param $b i64) (result i32) (local $m i32)',
        "    (block (br_if 0 (i64.eqz (i64.and (local.get $a) (local.get $b)))) (local.set $m (i32.const 1)))",
        "    (block (br_if 0 (i32.eqz (i64.eqz (i64.and (local.get $a) (local.get $b))))) (local.set $m (i32.or (local.get $m) (i32.const 2))))",
        "    (if (i64.eqz (i64.and (local.get $a) (local.get $b))) (then) (else (local.set $m (i32.or (local.get $m) (i32.const 4)))))",
        "    (local.get $m))",
        ")"]
for a in I64:
    for b in I64:
        exp = 5 if a & b else 2
        out.append(f'(assert_return (invoke "i64" ({lit(a, 64)}) ({lit(b, 64)})) (i32.const {exp}))')

out += ["",
        ";; The and's result is still needed after the branch.",
        "(module",
        '  (func (export "stored") (param $a i32) (param $b i32) (result i32) (local $t i32)',
        "    (local.set $t (i32.and (local.get $a) (local.get $b)))",
        "    (block (br_if 0 (local.get $t)) (return (i32.const 0)))",
        "    (local.get $t))",
        '  (func (export "teed") (param $a i32) (param $b i32) (result i32) (local $t i32)',
        "    (block (br_if 0 (local.tee $t (i32.and (local.get $a) (local.get $b)))) (return (i32.const 0)))",
        "    (local.get $t))",
        '  (func (export "label-between") (param $a i32) (param $b i32) (result i32)',
        "    (block $out",
        "      (i32.and (local.get $a) (local.get $b))",
        "      (block)",
        "      (br_if $out)",
        "      (return (i32.const 0)))",
        "    (i32.const 1))",
        ";; A fused bit test inside a loop.",
        '  (func (export "popcount") (param $x i32) (result i32) (local $n i32)',
        "    (block $done",
        "      (loop $loop",
        "        (br_if $done (i32.eqz (local.get $x)))",
        "        (if (i32.and (local.get $x) (i32.const 1)) (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
        "        (local.set $x (i32.shr_u (local.get $x) (i32.const 1)))",
        "        (br $loop)))",
        "    (local.get $n))",
        ")"]
for f in ("stored", "teed"):
    out.append(f'(assert_return (invoke "{f}" (i32.const 0xff00) (i32.const 0x0f0f)) (i32.const 0x0f00))')
    out.append(f'(assert_return (invoke "{f}" (i32.const 0xff00) (i32.const 0x00ff)) (i32.const 0))')
out.append('(assert_return (invoke "label-between" (i32.const 0xff00) (i32.const 0x0f0f)) (i32.const 1))')
out.append('(assert_return (invoke "label-between" (i32.const 0xff00) (i32.const 0x00ff)) (i32.const 0))')
for v in (0, 1, 0xff, 0x8000_0000, 0xffff_ffff, 0x1234_5678):
    out.append(f'(assert_return (invoke "popcount" ({lit(v, 32)})) (i32.const {bin(v).count("1")}))')
print("\n".join(out))
