#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering producers whose result goes into a
local that is read again later, handing the value to the next instruction in
the accumulator as well.

Every folded function writes a producer's result into a local, consumes the
local right away and reads it again afterwards; its reference puts a
`global.get` between the producer and the consumer, which folds nothing. A
driver loops over operand pairs stored in linear memory and counts mismatches.
"""
import struct

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

TYPES = {"i32": ("i", 4), "i64": ("q", 8)}
VALUES = {
    "i32": [0, 1, -1, 5, 6, 0x7fffffff, -0x80000000, 0x12345678],
    "i64": [0, 1, -1, 5, 6, 0x7fffffffffffffff, -0x8000000000000000, 0x123456789abcdef0],
}

def producers(t):
    x, y = "(local.get $x)", "(local.get $y)"
    p = {
        "add": f"({t}.add {x} {y})",
        "sub": f"({t}.sub {x} {y})",
        "shl": f"({t}.shl {x} {y})",
        "rotl": f"({t}.rotl {x} {y})",
        "addimm": f"({t}.add {x} ({t}.const 1))",
        "subimm": f"({t}.sub {x} ({t}.const 1))",
        "andimm": f"({t}.and {x} ({t}.const 255))",
    }
    # Loads from a small address, so that any value can index memory.
    if t == "i32":
        p["load"] = f"(i32.load (i32.and {x} (i32.const 31)))"
        p["load8s"] = f"(i32.load8_s (i32.and {x} (i32.const 31)))"
    else:
        p["load"] = f"(i64.load (i32.wrap_i64 (i64.and {x} (i64.const 31))))"
        p["load32u"] = f"(i64.load32_u (i32.wrap_i64 (i64.and {x} (i64.const 31))))"
    return p

def consumers(t):
    V, y = "(local.get $v)", "(local.get $y)"
    def code(cond):
        return f"(if (result i32) {cond} (then (i32.const 9)) (else (i32.const 7)))"
    def br(cond):
        return f"(block $b (result i32) (drop (br_if $b (i32.const 9) {cond})) (i32.const 7))"
    nz = (lambda e: e) if t == "i32" else (lambda e: f"(i32.eqz ({t}.eqz {e}))")
    c = {
        "xor": (t, f"({t}.xor {V} {y})"),
        "addconst": (t, f"({t}.add {V} ({t}.const 3))"),
        "rsub": (t, f"({t}.sub {y} {V})"),
        "shrs": (t, f"({t}.shr_s {V} {y})"),
        "lt_u.br_if": ("i32", br(f"({t}.lt_u {V} {y})")),
        "gt_s.imm.if": ("i32", code(f"({t}.gt_s {V} ({t}.const 5))")),
        "le_s.imm.left.br_if": ("i32", br(f"({t}.le_s ({t}.const 5) {V})")),
        "ne.imm.eqz.if": ("i32", code(f"(i32.eqz ({t}.ne {V} ({t}.const 6)))")),
        "and.imm.br_if": ("i32", br(nz(f"({t}.and {V} ({t}.const 4))"))),
        "and.slot.br_if": ("i32", br(nz(f"({t}.and {y} {V})"))),
        "store": (t, f"(block (result {t}) ({t}.store (i32.const 200) {V}) ({t}.load (i32.const 200)))"),
    }
    if t == "i32":
        c["br_if"] = ("i32", br(V))
        c["eqz.if"] = ("i32", code(f"(i32.eqz {V})"))
        # Pointer consumers, for the small values of an `and` producer only.
        c["load.pointer"] = ("i32", f"(i32.load8_u {V})")
        c["store.pointer"] = ("i32", f"(block (result i32) (i32.store8 offset=1000 {V} (local.get $y)) (i32.load8_u offset=1000 {V}))")
    return c

def widen(t, e):
    return e if t == "i64" else f"(i64.extend_i32_u {e})"

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/accumulator_and_slot.gen.py > Tests/WasmKitTests/ExtraSuite/accumulator_and_slot.wast",
       ""]
for t, (fmt, w) in TYPES.items():
    n = len(VALUES[t])
    data = struct.pack("<%d%s" % (n, fmt), *VALUES[t])
    out.append("(module")
    out.append("  (memory 1)")
    out.append(f'  (data (i32.const 0) "{esc(data)}")')
    out.append("  (global $g (mut i32) (i32.const 0))")
    forms = []
    for pname, prod in producers(t).items():
        for cname, (rt, body) in consumers(t).items():
            if cname.endswith(".pointer") and pname != "andimm":
                continue
            tail = widen(t, "(local.get $v)")
            for style in ("set", "tee"):
                if style == "set":
                    folded = f"(local.set $v {prod}) (i64.xor {widen(rt, body)} {tail})"
                    ref = f"(local.set $v {prod}) (drop (global.get $g)) (i64.xor {widen(rt, body)} {tail})"
                else:
                    tbody = body.replace("(local.get $v)", f"(local.tee $v {prod})", 1)
                    folded = f"(i64.xor {widen(rt, tbody)} {tail})"
                    ref = f"(local.set $v {prod}) (drop (global.get $g)) (i64.xor {widen(rt, body)} {tail})"
                forms.append((f"{pname}.{cname}.{style}", folded, ref))
    # A loop counter: the increment goes into the local and the exit test
    # reads it back.
    forms.append(("counter",
                  f"(local.set $v ({t}.const 0)) (loop $l (local.set $v ({t}.add (local.get $v) ({t}.const 1))) (br_if $l ({t}.lt_u (local.get $v) ({t}.and (local.get $x) ({t}.const 15))))) {widen(t, '(local.get $v)')}",
                  f"(local.set $v ({t}.const 0)) (loop $l (local.set $v ({t}.add (local.get $v) ({t}.const 1))) (drop (global.get $g)) (br_if $l ({t}.lt_u (local.get $v) ({t}.and (local.get $x) ({t}.const 15))))) {widen(t, '(local.get $v)')}"))
    p = f"(param $x {t}) (param $y {t})"
    for name, body, ref in forms:
        out.append(f"  (func ${name} {p} (result i64) (local $v {t}) {body})")
        out.append(f"  (func ${name}.ref {p} (result i64) (local $v {t}) {ref})")
    out.append(f"  (type $f (func {p} (result i64)))")
    out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _ in forms) + "))")
    out += [f'  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $j i32) (local $n i32) (local $f i32) (local $x {t}) (local $y {t})',
            "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
            "    (loop $li",
            f"      (local.set $x ({t}.load (i32.mul (local.get $i) (i32.const {w}))))",
            "      (local.set $j (i32.const 0))",
            "      (loop $lj",
            f"        (local.set $y ({t}.load (i32.mul (local.get $j) (i32.const {w}))))",
            "        (if (i64.ne (call_indirect (type $f) (local.get $x) (local.get $y) (local.get $f))",
            "                    (call_indirect (type $f) (local.get $x) (local.get $y) (i32.add (local.get $f) (i32.const 1))))",
            "          (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))",
            f"        (br_if $lj (i32.lt_u (local.tee $j (i32.add (local.get $j) (i32.const 1))) (i32.const {n}))))",
            f"      (br_if $li (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (i32.const {n}))))",
            "    (local.get $n))"]
    out.append(")")
    for k, (name, _, _) in enumerate(forms):
        out.append(f'(assert_return (invoke "check" (i32.const {k})) (i32.const 0)) ;; {t} {name}')
    out.append("")
print("\n".join(out))
