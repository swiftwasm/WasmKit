#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering integer operations whose constant
operand is carried in the instruction.

Every folded function takes a literal constant; its reference reads the same
value from a global, which is never folded. A driver loops over operand values
stored in linear memory and counts mismatches.
"""
import struct

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

TYPES = {"i32": ("i", 4), "i64": ("q", 8)}
CONSTS = {
    "i32": [0, -1, -0x80000000, 33],
    # 0x80000000 and 0x100000005 do not survive sign extension from 32 bits.
    "i64": [-1, -0x80000000, 0x80000000, 0x100000005],
}
VALUES = {
    "i32": [0, 1, -1, 0x7fffffff, -0x80000000, 31, 0x12345678],
    "i64": [0, 1, -1, 0x7fffffffffffffff, -0x8000000000000000, 63, 0x123456789abcdef0],
}
ARITH = ["add", "sub", "mul", "and", "or", "xor", "shl", "shr_s", "shr_u", "rotl", "rotr"]
CMPS = ["eq", "ne", "lt_s", "lt_u", "gt_s", "gt_u", "le_s", "le_u", "ge_s", "ge_u"]

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/immediate_operands.gen.py > Tests/WasmKitTests/ExtraSuite/immediate_operands.wast",
       ""]
for t, (fmt, w) in TYPES.items():
    data = struct.pack("<%d%s" % (len(VALUES[t]), fmt), *VALUES[t])
    out.append("(module")
    out.append("  (memory 1)")
    out.append(f'  (data (i32.const 0) "{esc(data)}")')
    forms = []  # (name, result type, folded body, reference body, const)
    for k, c in enumerate(CONSTS[t]):
        C = f"({t}.const {c})"
        G = f"(global.get $c{k})"
        for op in ARITH:
            forms.append((f"{op}.{k}.right", t, f"({t}.{op} (local.get $x) {C})", f"({t}.{op} (local.get $x) {G})"))
            forms.append((f"{op}.{k}.left", t, f"({t}.{op} {C} (local.get $x))", f"({t}.{op} {G} (local.get $x))"))
        for op in CMPS:
            for pos in (("right", "left") if k == 0 else ("right",)):
                fc = f"({t}.{op} (local.get $x) {C})" if pos == "right" else f"({t}.{op} {C} (local.get $x))"
                rc = f"({t}.{op} (local.get $x) {G})" if pos == "right" else f"({t}.{op} {G} (local.get $x))"
                forms.append((f"{op}.{k}.{pos}", "i32", fc, rc))
                forms.append((f"{op}.{k}.{pos}.br_if", "i32", f"(block (br_if 0 {fc}) (return (i32.const 7))) (i32.const 9)",
                              f"(if (result i32) {rc} (then (i32.const 9)) (else (i32.const 7)))"))
                forms.append((f"{op}.{k}.{pos}.if", "i32", f"(if (result i32) {fc} (then (i32.const 9)) (else (i32.const 7)))",
                              f"(if (result i32) {rc} (then (i32.const 9)) (else (i32.const 7)))"))
                if k == 0: forms.append((f"{op}.{k}.{pos}.eqz", "i32", f"(if (result i32) (i32.eqz {fc}) (then (i32.const 7)) (else (i32.const 9)))",
                              f"(if (result i32) {rc} (then (i32.const 9)) (else (i32.const 7)))"))
        band = f"({t}.and (local.get $x) {C})"
        bref = f"({t}.ne ({t}.and (local.get $x) {G}) ({t}.const 0))"
        btest = band if t == "i32" else f"(i32.eqz ({t}.eqz {band}))"
        forms.append((f"and.{k}.br_if", "i32", f"(block (br_if 0 {btest}) (return (i32.const 7))) (i32.const 9)",
                      f"(if (result i32) {bref} (then (i32.const 9)) (else (i32.const 7)))"))
        forms.append((f"and.{k}.br_if_not", "i32", f"(if (result i32) {btest} (then (i32.const 9)) (else (i32.const 7)))",
                      f"(if (result i32) {bref} (then (i32.const 9)) (else (i32.const 7)))"))
        # An immediate producer handing its result on, and folded into a
        # superinstruction with the next operation.
        forms.append((f"acc.{k}", t, f"({t}.rotr ({t}.sub (local.get $x) {C}) (local.get $x))",
                      f"({t}.rotr ({t}.sub (local.get $x) {G}) (local.get $x))"))
        forms.append((f"super.{k}", t, f"({t}.add ({t}.shl (local.get $x) {C}) (local.get $x))",
                      f"({t}.add ({t}.shl (local.get $x) {G}) (local.get $x))"))
        # A subtraction of a constant folded into the next operation.
        forms.append((f"super.sub.{k}", t, f"({t}.and ({t}.sub (local.get $x) {C}) (local.get $x))",
                      f"({t}.and ({t}.sub (local.get $x) {G}) (local.get $x))"))
    for k, c in enumerate(CONSTS[t]):
        out.append(f"  (global $c{k} {t} ({t}.const {c}))")
    p = f"(param $x {t})"
    for name, rt, body, ref in forms:
        out.append(f"  (func ${name} {p} (result {rt}) {body})")
        out.append(f"  (func ${name}.ref {p} (result {rt}) {ref})")
    for rt in dict.fromkeys([t, "i32"]):
        out.append(f"  (type $f{rt} (func {p} (result {rt})))")
    out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _, _ in forms) + "))")
    for rt in dict.fromkeys([t, "i32"]):
        out += [f'  (func (export "check.{rt}") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $f i32) (local $x {t})',
                "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
                "    (loop $l",
                f"      (local.set $x ({t}.load (i32.mul (local.get $i) (i32.const {w}))))",
                f"      (if ({rt}.ne (call_indirect (type $f{rt}) (local.get $x) (local.get $f))",
                f"                  (call_indirect (type $f{rt}) (local.get $x) (i32.add (local.get $f) (i32.const 1))))",
                "        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
                f"      (br_if $l (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {len(VALUES[t])}))))",
                "    (local.get $n))"]
    out.append(")")
    for k, (name, rt, _, _) in enumerate(forms):
        out.append(f'(assert_return (invoke "check.{rt}" (i32.const {k})) (i32.const 0)) ;; {t} {name}')
    out.append("")

consts = " ".join(f"(i32.add (local.get $x) (i32.const {100 + i}))" for i in range(12))
out += [
    ";; More distinct constants than the constant pool holds, read as registers,",
    ";; and constants that stay on the stack across a branch.",
    "(module",
    '  (func (export "many") (param $x i32) (result i32)',
    "    " + "".join(f"(i32.div_u (i32.const {1000 + i}) (i32.add (local.get $x) (i32.const 1)))" for i in range(12)),
    "    " + "(i32.add) " * 11 + ")",
    '  (func (export "branch") (param $x i32) (result i32)',
    "    (block (result i32) (i32.const 5) (i32.const 6) (local.get $x) (br_if 0) (drop)))",
    '  (func (export "set") (result i32) (local $y i32) (local.set $y (i32.const 42)) (local.get $y))',
    ")",
    '(assert_return (invoke "many" (i32.const 0)) (i32.const ' + str(sum(1000 + i for i in range(12))) + "))",
    '(assert_return (invoke "branch" (i32.const 1)) (i32.const 6))',
    '(assert_return (invoke "branch" (i32.const 0)) (i32.const 5))',
    '(assert_return (invoke "set") (i32.const 42))',
    "",
]
print("\n".join(out))
