#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering a value produced into the accumulator,
a copy between two locals, and the value written to a local right after.

Every folded function has the three operations adjacent; its reference puts a
`global.get` before the last write, which folds nothing. A driver loops over
operand pairs stored in linear memory and counts mismatches.
"""
import struct

def esc(data):
    return "".join(f"\\{b:02x}" for b in data)

TYPES = {"i32": ("i", 4), "i64": ("q", 8)}
VALUES = {
    "i32": [0, 1, -1, 5, 0x7fffffff, -0x80000000, 0x12345678],
    "i64": [0, 1, -1, 5, 0x7fffffffffffffff, -0x8000000000000000, 0x123456789abcdef0],
}

def producers(t):
    a, b = "(local.get $a)", "(local.get $b)"
    p = {
        "add": f"({t}.add {a} {b})",
        "sub": f"({t}.sub {a} {b})",
        "rotl": f"({t}.rotl {a} {b})",
        "addimm": f"({t}.add {a} ({t}.const 7))",
        "load": f"({t}.load (i32.const 0))",
    }
    return p

# (name, middle copy, final write): locals a, b, c; the produced value goes to
# the final local.
SHAPES = [
    ("swap", "(local.set $a (local.get $b))", "b"),
    ("unrelated", "(local.set $c (local.get $a))", "b"),
    ("same_dest", "(local.set $a (local.get $b))", "a"),
    ("from_dest", "(local.set $c (local.get $b))", "b"),
]

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/accumulator_copy.gen.py > Tests/WasmKitTests/ExtraSuite/accumulator_copy.wast",
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
        for sname, middle, dest in SHAPES:
            for tee in (False, True):
                write = f"(local.tee ${dest})" if tee else f"(local.set ${dest})"
                keep = "" if tee else f"({t}.const 0)"
                # The result mixes all three locals and, for a tee, the value it left.
                tail = f"({t}.add ({t}.add ({t}.mul (local.get $a) ({t}.const 3)) ({t}.mul (local.get $b) ({t}.const 5))) (local.get $c))"
                folded = f"{prod} {middle} {write} {keep} ({t}.xor {tail})"
                ref = f"{prod} {middle} (drop (global.get $g)) {write} {keep} ({t}.xor {tail})"
                forms.append((f"{pname}.{sname}.{'tee' if tee else 'set'}", folded, ref))
    # A loop swapping two locals through a sum, as in an iterative Fibonacci.
    loop_body = lambda extra: (f"(local.set $c ({t}.const 10)) (loop $l ({t}.add (local.get $a) (local.get $b)) (local.set $a (local.get $b)) {extra} (local.set $b) "
                               f"(br_if $l ({t}.ne (local.tee $c ({t}.sub (local.get $c) ({t}.const 1))) ({t}.const 0)))) "
                               f"({t}.add (local.get $a) ({t}.mul (local.get $b) ({t}.const 3)))")
    forms.append(("fib", loop_body(""), loop_body("(drop (global.get $g))")))
    p = f"(param $a {t}) (param $b {t})"
    for name, body, ref in forms:
        out.append(f"  (func ${name} {p} (result {t}) (local $c {t}) {body})")
        out.append(f"  (func ${name}.ref {p} (result {t}) (local $c {t}) {ref})")
    out.append(f"  (type $f (func {p} (result {t})))")
    out.append("  (table funcref (elem " + " ".join(f"${n} ${n}.ref" for n, _, _ in forms) + "))")
    out += [f'  (func (export "check") (param $k i32) (result i32) (local $i i32) (local $j i32) (local $n i32) (local $f i32) (local $x {t}) (local $y {t})',
            "    (local.set $f (i32.shl (local.get $k) (i32.const 1)))",
            "    (loop $li",
            f"      (local.set $x ({t}.load (i32.mul (local.get $i) (i32.const {w}))))",
            "      (local.set $j (i32.const 0))",
            "      (loop $lj",
            f"        (local.set $y ({t}.load (i32.mul (local.get $j) (i32.const {w}))))",
            f"        (if ({t}.ne (call_indirect (type $f) (local.get $x) (local.get $y) (local.get $f))",
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
