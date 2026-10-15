#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering a load whose address was copied into a
local by the instruction right before it.

Every folded function has the copy and the load adjacent; its reference puts a
`global.get` between them. A driver compares both over a range of addresses
and counts mismatches.
"""
import random

random.seed(49)
DATA = bytes(random.randrange(256) for _ in range(64))

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

LOADS = {
    "i32.load": "(i64.extend_i32_u X)", "i64.load": "X",
    "f32.load": "(i64.extend_i32_u (i32.reinterpret_f32 X))", "f64.load": "(i64.reinterpret_f64 X)",
    "i32.load8_s": "(i64.extend_i32_u X)", "i32.load8_u": "(i64.extend_i32_u X)",
    "i32.load16_s": "(i64.extend_i32_u X)", "i32.load16_u": "(i64.extend_i32_u X)",
    "i64.load8_s": "X", "i64.load8_u": "X", "i64.load16_s": "X", "i64.load16_u": "X",
    "i64.load32_s": "X", "i64.load32_u": "X",
}
GAP = "(global.set $g (local.get $q))"

def mix(e):
    return f"(i64.add (i64.add (i64.mul {e} (i64.const 1000003)) (i64.extend_i32_u (local.get $a))) (i64.shl (i64.extend_i32_u (global.get $g)) (i64.const 32)))"

forms = []
for load, widen in LOADS.items():
    w = lambda e: widen.replace("X", e)
    ty = load.split(".")[0]
    for off in (0, 3):
        l = f"({load} offset={off} (local.get $a))"
        # The copied local is read afterwards, so the copy must still happen.
        forms.append((f"{load}.off{off}",
                      f"(local.set $a (local.get $p)) {mix(w(l))}",
                      f"(local.set $a (local.get $p)) {GAP} {mix(w(l))}"))
    lt = f"(local.tee $a (local.get $p))"
    forms.append((f"{load}.tee", f"{w(f'({load} {lt})')} (drop) {mix('(i64.const 0)')}",
                  f"{w(f'({load} (block (result i32) {lt} {GAP}))')} (drop) {mix('(i64.const 0)')}"))
    if ty == "i32":
        # The result written back to the copy's destination or source.
        forms.append((f"{load}.to_dest",
                      f"(local.set $a (local.get $p)) (local.set $a ({load} (local.get $a))) {mix('(i64.extend_i32_u (local.get $p))')}",
                      f"(local.set $a (local.get $p)) {GAP} (local.set $a ({load} (local.get $a))) {mix('(i64.extend_i32_u (local.get $p))')}"))
        forms.append((f"{load}.to_source",
                      f"(local.set $a (local.get $p)) (local.set $p ({load} (local.get $a))) {mix('(i64.extend_i32_u (local.get $p))')}",
                      f"(local.set $a (local.get $p)) {GAP} (local.set $p ({load} (local.get $a))) {mix('(i64.extend_i32_u (local.get $p))')}"))
    # A load that does not read the copied local.
    forms.append((f"{load}.other",
                  f"(local.set $a (local.get $q)) {mix(w(f'({load} (local.get $p))'))}",
                  f"(local.set $a (local.get $q)) {GAP} {mix(w(f'({load} (local.get $p))'))}"))
    # A loop header between the copy and the load: later iterations reach the
    # load without running the copy.
    loop_body = lambda gap: (f"(local.set $a (local.get $p)) (loop $l (local.set $s (i64.add (local.get $s) {w(f'({load} (local.get $a))')})) {gap}"
                             f" (local.set $a (i32.add (local.get $a) (i32.const 1))) (br_if $l (i32.lt_u (local.get $a) (i32.add (local.get $p) (i32.const 3))))) {mix('(local.get $s)')}")
    forms.append((f"{load}.loop", loop_body(""), GAP + " " + loop_body("(drop (global.get $g))")))

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/copy_into_load.gen.py > Tests/WasmKitTests/ExtraSuite/copy_into_load.wast",
       "",
       "(module",
       "  (memory 1)",
       f'  (data (i32.const 0) "{esc(DATA)}")',
       "  (global $g (mut i32) (i32.const 0))"]
p = "(param $p i32) (param $q i32)"
loc = "(local $a i32) (local $s i64)"
for name, body, ref in forms:
    out.append(f"  (func ${name} {p} (result i64) {loc} (global.set $g (i32.const 0)) {GAP} {body})")
    out.append(f"  (func ${name}.ref {p} (result i64) {loc} (global.set $g (i32.const 0)) {ref})")
out.append(f"  (type $f (func {p} (result i64)))")
out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _ in forms) + "))")
out += ['  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $n i32) (local $f i32)',
        "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
        "    (loop $li",
        "      (if (i64.ne (call_indirect (type $f) (local.get $i) (i32.sub (i32.const 40) (local.get $i)) (local.get $f))",
        "                  (call_indirect (type $f) (local.get $i) (i32.sub (i32.const 40) (local.get $i)) (i32.add (local.get $f) (i32.const 1))))",
        "        (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
        "      (br_if $li (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const 40))))",
        "    (local.get $n))",
        '  (func (export "oob") (param $p i32) (result i32) (local $a i32) (local.set $a (local.get $p)) (i32.load (local.get $a)))',
        ")"]
for k, (name, _, _) in enumerate(forms):
    out.append(f'(assert_return (invoke "check" (i32.const {k})) (i32.const 0)) ;; {name}')
out.append('(assert_return (invoke "oob" (i32.const 65532)) (i32.const 0))')
out.append('(assert_trap (invoke "oob" (i32.const 65533)) "out of bounds memory access")')
print("\n".join(out))
