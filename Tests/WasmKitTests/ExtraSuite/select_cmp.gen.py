#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering `select` whose condition is an integer
comparison emitted right before it.

Every folded function has the comparison and the `select` adjacent; its
reference puts a `global.get` between them. A driver loops over operand pairs
stored in linear memory and counts mismatches.
"""
import struct

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

VALUES = [0, 1, -1, 5, 0x7fffffff, -0x80000000, 0x100000000, -0x100000001, 0x7fffffffffffffff]
PREDS = ["eq", "ne", "lt_s", "lt_u", "gt_s", "gt_u", "le_s", "le_u", "ge_s", "ge_u"]
IMMS = {"i32": [0, 5, -1, -0x80000000], "i64": [0, 5, -1, 0x7fffffff]}

def operand(t, name):
    return f"(local.get ${name})" if t == "i64" else f"(i64.extend_i32_s (local.get ${name}32))"

conds = []
for t in ("i32", "i64"):
    x = f"(local.get $x)" if t == "i64" else "(local.get $x32)"
    y = f"(local.get $y)" if t == "i64" else "(local.get $y32)"
    for p in PREDS:
        conds.append((f"{t}.{p}", f"({t}.{p} {x} {y})"))
        for imm in IMMS[t]:
            conds.append((f"{t}.{p}.imm{imm}", f"({t}.{p} {x} ({t}.const {imm}))"))
            conds.append((f"{t}.{p}.imm{imm}.lhs", f"({t}.{p} ({t}.const {imm}) {x})"))
    conds.append((f"{t}.eqz", f"({t}.eqz {x})"))
    conds.append((f"{t}.lt_s.eqz", f"(i32.eqz ({t}.lt_s {x} {y}))"))
    conds.append((f"{t}.gt_u.imm.eqz", f"(i32.eqz ({t}.gt_u {x} ({t}.const 5)))"))
    conds.append((f"{t}.add.lt_u", f"({t}.lt_u ({t}.add {x} {y}) {y})"))

# (name, on-true, on-false) built from the operands.
CANDS = {
    "slots": ("(local.get $x)", "(local.get $y)"),
    "const": ("(i64.const 77)", "(i64.const -3)"),
    "i32": ("(i64.extend_i32_u (select (local.get $x32) (local.get $y32) COND))", None),
    "f64": ("(i64.reinterpret_f64 (select (f64.convert_i64_s (local.get $x)) (f64.const 2.5) COND))", None),
}

def locals_():
    return "(local $x32 i32) (local $y32 i32) (local $c i32) (local.set $x32 (i32.wrap_i64 (local.get $x))) (local.set $y32 (i32.wrap_i64 (local.get $y)))"

def delayed(cond):
    return f"(block (result i32) {cond} (drop (global.get $g)))"

forms = []
for cname, cond in conds:
    for kname, (a, b) in CANDS.items():
        if b is None:
            forms.append((f"{cname}.{kname}", a.replace("COND", cond), a.replace("COND", delayed(cond))))
        else:
            forms.append((f"{cname}.{kname}", f"(select {a} {b} {cond})", f"(select {a} {b} {delayed(cond)})"))
    forms.append((f"{cname}.as_value",
                  f"(i64.extend_i32_u (select {cond} (local.get $y32) (local.get $x32)))",
                  f"(i64.extend_i32_u (select {delayed(cond)} (local.get $y32) (local.get $x32)))"))
    forms.append((f"{cname}.tee",
                  f"(i64.add (select (local.get $x) (local.get $y) (local.tee $c {cond})) (i64.extend_i32_u (local.get $c)))",
                  f"(i64.add (select (local.get $x) (local.get $y) (local.tee $c {delayed(cond)})) (i64.extend_i32_u (local.get $c)))"))
    forms.append((f"{cname}.set_local",
                  f"(local.set $x (select (local.get $x) (local.get $y) {cond})) (local.get $x)",
                  f"(local.set $x (select (local.get $x) (local.get $y) {delayed(cond)})) (drop (global.get $g)) (local.get $x)"))

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/select_cmp.gen.py > Tests/WasmKitTests/ExtraSuite/select_cmp.wast",
       "",
       "(module",
       "  (memory 1)",
       f'  (data (i32.const 0) "{esc(struct.pack("<%dq" % len(VALUES), *VALUES))}")',
       "  (global $g (mut i32) (i32.const 0))"]
p = "(param $x i64) (param $y i64)"
for name, body, ref in forms:
    out.append(f"  (func ${name} {p} (result i64) {locals_()} {body})")
    out.append(f"  (func ${name}.ref {p} (result i64) {locals_()} {ref})")
out.append(f"  (type $f (func {p} (result i64)))")
out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _ in forms) + "))")
n = len(VALUES)
out += ['  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $j i32) (local $n i32) (local $f i32) (local $x i64) (local $y i64)',
        "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
        "    (loop $li",
        "      (local.set $x (i64.load (i32.mul (local.get $i) (i32.const 8))))",
        "      (local.set $j (i32.const 0))",
        "      (loop $lj",
        "        (local.set $y (i64.load (i32.mul (local.get $j) (i32.const 8))))",
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
