#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering `select` whose condition was produced
by the instruction right before it, and `select` results written to a local.

Every folded function has the condition producer and the `select` adjacent;
its reference puts a `global.get` between them. A driver loops over operand
pairs stored in linear memory and counts mismatches.
"""
import struct

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

VALUES = [0, 1, -1, 5, 0x7fffffff, -0x80000000, 256]
CONDS = {
    "lt_s": "(i32.lt_s (local.get $x) (local.get $y))",
    "eq": "(i32.eq (local.get $x) (local.get $y))",
    "and": "(i32.and (local.get $x) (local.get $y))",
    "addimm": "(i32.add (local.get $x) (i32.const 1))",
    "load": "(i32.load8_u (i32.and (local.get $x) (i32.const 15)))",
    "eqz": "(i32.eqz (local.get $x))",
}
# (value type, on-true, on-false) built from the operands.
VALS = {
    "i32": ("(local.get $x)", "(local.get $y)"),
    "i64": ("(i64.extend_i32_s (local.get $x))", "(i64.const 77)"),
    "f64": ("(f64.convert_i32_s (local.get $y))", "(f64.const 2.5)"),
    "f32": ("(f32.const 1.5)", "(f32.convert_i32_u (local.get $x))"),
}

def widen(t, e):
    return {"i32": f"(i64.extend_i32_u {e})", "i64": e, "f64": f"(i64.reinterpret_f64 {e})", "f32": f"(i64.extend_i32_u (i32.reinterpret_f32 {e}))"}[t]

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/select_forms.gen.py > Tests/WasmKitTests/ExtraSuite/select_forms.wast",
       "",
       "(module",
       "  (memory 1)",
       f'  (data (i32.const 0) "{esc(struct.pack("<%di" % len(VALUES), *VALUES))}")',
       "  (global $g (mut i32) (i32.const 0))"]
forms = []
for cname, cond in CONDS.items():
    for t, (a, b) in VALS.items():
        for typed in (False, True):
            sel = f"(select{f' (result {t})' if typed else ''}"
            # Condition produced right before the select, result consumed directly.
            forms.append((f"{cname}.{t}.{'typed' if typed else 'plain'}",
                          widen(t, f"{sel} {a} {b} {cond})"),
                          widen(t, f"{sel} {a} {b} (block (result i32) {cond} (drop (global.get $g))))")))
        # Result written to a local that is also one of the candidates.
        if t == "i32":
            forms.append((f"{cname}.set_local",
                          f"(local.set $x (select (local.get $x) (local.get $y) {cond})) (i64.extend_i32_u (local.get $x))",
                          f"(local.set $x (select (local.get $x) (local.get $y) (block (result i32) {cond} (drop (global.get $g))))) (drop (global.get $g)) (i64.extend_i32_u (local.get $x))"))
p = "(param $x i32) (param $y i32)"
for name, body, ref in forms:
    out.append(f"  (func ${name} {p} (result i64) {body})")
    out.append(f"  (func ${name}.ref {p} (result i64) {ref})")
out.append(f"  (type $f (func {p} (result i64)))")
out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _ in forms) + "))")
n = len(VALUES)
out += ['  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $j i32) (local $n i32) (local $f i32) (local $x i32) (local $y i32)',
        "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
        "    (loop $li",
        "      (local.set $x (i32.load (i32.mul (local.get $i) (i32.const 4))))",
        "      (local.set $j (i32.const 0))",
        "      (loop $lj",
        "        (local.set $y (i32.load (i32.mul (local.get $j) (i32.const 4))))",
        "        (if (i64.ne (call_indirect (type $f) (local.get $x) (local.get $y) (local.get $f))",
        "                    (call_indirect (type $f) (local.get $x) (local.get $y) (i32.add (local.get $f) (i32.const 1))))",
        "          (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
        f"        (br_if $lj (i32.lt_u (local.tee $j (i32.add (local.get $j) (i32.const 1))) (i32.const {n}))))",
        f"      (br_if $li (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {n}))))",
        "    (local.get $n))",
        ")"]
for k, (name, _, _) in enumerate(forms):
    out.append(f'(assert_return (invoke "check" (i32.const {k})) (i32.const 0)) ;; {name}')
print("\n".join(out))
