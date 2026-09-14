#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering loads and stores that take their
address or value from the integer accumulator, or hand their result to it.

Each folded shape has a reference that keeps the operand in a local, so the
translator cannot fold it; a `check` export runs both and compares the bits.
"""

LOADS = [
    ("i32", "load"), ("i64", "load"), ("f32", "load"), ("f64", "load"),
    ("i32", "load8_s"), ("i32", "load8_u"), ("i32", "load16_s"), ("i32", "load16_u"),
    ("i64", "load8_s"), ("i64", "load8_u"), ("i64", "load16_s"), ("i64", "load16_u"),
    ("i64", "load32_s"), ("i64", "load32_u"),
]
STORES = [("i32", "store"), ("i64", "store"), ("f32", "store"), ("f64", "store"),
          ("i32", "store8"), ("i32", "store16"), ("i64", "store8"), ("i64", "store16"), ("i64", "store32")]
DATA = bytearray((0x81 + 13 * i) & 0xff for i in range(64))

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

def bits(t):
    return "i32" if t in ("i32", "f32") else "i64"

def as_bits(t, expr):
    return expr if t in ("i32", "i64") else f"({bits(t)}.reinterpret_{t} {expr})"

import sys
mem64 = sys.argv[1:] == ["--memory64"]
path = "memory64/accumulator_memory64.wast" if mem64 else "accumulator_memory.wast"
out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       f";;   python3 Tests/WasmKitTests/ExtraSuite/accumulator_memory.gen.py{' --memory64' if mem64 else ''} > Tests/WasmKitTests/ExtraSuite/{path}",
       ""]
pw = 8 if mem64 else 4
DATA[40:40 + pw] = (48).to_bytes(pw, "little")
DATA[48:48 + pw] = (56).to_bytes(pw, "little")

for mem64 in (mem64,):
    at = "i64" if mem64 else "i32"
    out.append(f";; Loads and stores on a {'64' if mem64 else '32'}-bit memory, every kind in every folded position.")
    out.append("(module")
    out.append(f"  (memory {at} 1)")
    out.append(f'  (data ({at}.const 0) "{esc(DATA)}")')
    checks = []
    for t, op in LOADS:
        b = bits(t)
        base = f"{t}.{op} offset=2"
        addr = f"({at}.add (local.get $a) ({at}.const 3))"
        load_a = as_bits(t, f"({base} (local.get $a))")
        forms = {
            # The address comes from the instruction right before the load.
            "addr": (as_bits(t, f"({base} {addr})"),
                     f"(local.set $t {addr}) " + as_bits(t, f"({base} (local.get $t))")),
            # The load's result goes to the instruction right after it.
            "result": (f"({b}.xor {load_a} (local.get $v))",
                       f"(local.set $r {load_a}) ({b}.xor (local.get $r) (local.get $v))"),
            # Address in and result out.
            "chain": (f"({b}.add " + as_bits(t, f"({base} {addr})") + " (local.get $v))",
                      f"(local.set $t {addr}) (local.set $r " + as_bits(t, f"({base} (local.get $t))") + f") ({b}.add (local.get $r) (local.get $v))"),
        }
        for form, (body, ref) in forms.items():
            name = f"{t}.{op}.{form}"
            prm = f"(param $a {at}) (param $v {b})"
            loc = f"(local $t {at}) (local $r {b})"
            out.append(f"  (func ${name} {prm} (result {b}) {loc} {body})")
            out.append(f"  (func ${name}.ref {prm} (result {b}) {loc} {ref})")
            out.append(f'  (func (export "{name}") {prm} (result i32) ({b}.eq (call ${name} (local.get $a) (local.get $v)) (call ${name}.ref (local.get $a) (local.get $v))))')
            checks.append((name, b, "load"))
    for t, op in STORES:
        b = bits(t)
        base = f"{t}.{op} offset=2"
        val = f"({b}.xor (local.get $x) (local.get $y))"
        valT = val if t == b else f"({t}.reinterpret_{b} {val})"
        for form in ("value", "addr"):
            name = f"{t}.{op}.{form}"
            prm = f"(param $a {at}) (param $x {b}) (param $y {b})"
            if form == "value":
                # The stored value comes from the instruction right before.
                loc = f"(local $w {t})"
                body = f"({base} (local.get $a) {valT})"
                ref = f"(local.set $w {valT}) ({base} (local.get $a) (local.get $w))"
            else:
                # The address comes from the instruction right before.
                loc = f"(local $w {t}) (local $s {at})"
                pre = f"(local.set $w {valT})"
                body = f"{pre} ({base} ({at}.add (local.get $a) ({at}.const 1)) (local.get $w))"
                ref = f"{pre} (local.set $s ({at}.add (local.get $a) ({at}.const 1))) ({base} (local.get $s) (local.get $w))"
            rd = f"({bits(t)}.load (local.get $a))"
            out.append(f"  (func ${name} {prm} (result i64) {loc} {body} (i64.or (i64.shl (i64.load ({at}.add (local.get $a) ({at}.const 1))) (i64.const 8)) (i64.load8_u (local.get $a))))")
            out.append(f"  (func ${name}.ref {prm} (result i64) {loc} {ref} (i64.or (i64.shl (i64.load ({at}.add (local.get $a) ({at}.const 1))) (i64.const 8)) (i64.load8_u (local.get $a))))")
            out.append(f'  (func (export "{name}") {prm} (result i32) (local $l i64)')
            out.append(f"    (i64.store (local.get $a) (i64.const 0)) (i64.store ({at}.add (local.get $a) ({at}.const 8)) (i64.const 0))")
            out.append(f"    (local.set $l (call ${name} (local.get $a) (local.get $x) (local.get $y)))")
            out.append(f"    (i64.store (local.get $a) (i64.const 0)) (i64.store ({at}.add (local.get $a) ({at}.const 8)) (i64.const 0))")
            out.append(f"    (i64.eq (local.get $l) (call ${name}.ref (local.get $a) (local.get $x) (local.get $y))))")
            checks.append((name, b, "store"))
    out += [
        "  ;; A pointer read from memory and loaded through, and a chain of three.",
        f'  (func (export "chase") (param $a {at}) (result i32) (i32.load ({at}.load (local.get $a))))',
        f'  (func (export "chase3") (param $a {at}) (result i32) (i32.add (i32.load8_u ({at}.load ({at}.load (local.get $a)))) (i32.const 1)))',
        "  ;; Out-of-bounds accesses through every form.",
        f'  (func (export "oob.addr") (param $a {at}) (result i32) (i32.load ({at}.add (local.get $a) ({at}.const 2))))',
        f'  (func (export "oob.result") (param $a {at}) (result i32) (i32.add (i32.load (local.get $a)) (i32.const 1)))',
        f'  (func (export "oob.chain") (param $a {at}) (result i32) (i32.load8_u ({at}.load (local.get $a))))',
        f'  (func (export "oob.value") (param $a {at}) (param $x i32) (i32.store (local.get $a) (i32.add (local.get $x) (i32.const 1))))',
        f'  (func (export "oob.store.addr") (param $a {at}) (param $x i32) (i32.store ({at}.add (local.get $a) ({at}.const 2)) (local.get $x)))',
        ")",
    ]
    c = lambda x: f"({at}.const {x})"
    for name, b, kind in checks:
        for a in (0, 5, 17):
            if kind == "load":
                for v in ("0", "-1", "0x12345"):
                    out.append(f'(assert_return (invoke "{name}" {c(a)} ({b}.const {v})) (i32.const 1))')
            else:
                for x, y in (("0", "-1"), ("0x1234567", "0x7654321")):
                    out.append(f'(assert_return (invoke "{name}" {c(a)} ({b}.const {x}) ({b}.const {y})) (i32.const 1))')
    last = 65536
    out += [
        f'(assert_return (invoke "chase" {c(40)}) (i32.const 56))',
        f'(assert_return (invoke "chase3" {c(40)}) (i32.const {DATA[56] + 1}))',
        f'(assert_trap (invoke "oob.addr" {c(last - 5)}) "out of bounds memory access")',
        f'(assert_trap (invoke "oob.result" {c(last - 3)}) "out of bounds memory access")',
        f'(assert_trap (invoke "oob.chain" {c(last - 1)}) "out of bounds memory access")',
        f'(assert_trap (invoke "oob.value" {c(last - 3)} (i32.const 1)) "out of bounds memory access")',
        f'(assert_trap (invoke "oob.store.addr" {c(last - 5)} (i32.const 1)) "out of bounds memory access")',
        f'(assert_return (invoke "oob.addr" {c(last - 6)}) (i32.const 0))',
        "",
    ]

print("\n".join(l for l in out if l is not None))
