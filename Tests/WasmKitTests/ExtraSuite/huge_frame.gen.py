#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering frames at the edge of the VReg range.

A register is a pre-shifted byte offset in an Int16, so a frame can address
slots -4096...4095 only. The value stack has to fit in that range: a function
whose value stack does not must be rejected rather than miscompiled by a
wrapped register, and one just inside must run.

Locals do not have to fit: a function with many of them moves `sp` past its
locals on entry and reaches the ones still out of range (and its parameters
and results) with wide copies. The functions with `OUTSIDE` locals exercise
that for every way a local, a parameter or a result is accessed.

The operand stack is grown by calling a function with eight results, which
keeps the file small.
"""
MAX_SLOT_INDEX = 4095
# Leave room for the frame header and the constant pool, both of which count
# against the same range.
INSIDE = MAX_SLOT_INDEX - 200
OUTSIDE = MAX_SLOT_INDEX + 100


def wrap(tokens, indent, per_line=24):
    return "\n".join(indent + " ".join(tokens[i:i + per_line]) for i in range(0, len(tokens), per_line))


def eight(indent):
    consts = " ".join(["i32.const 7"] * 8)
    return f"{indent}(func $eight (result i32 i32 i32 i32 i32 i32 i32 i32)\n{indent}  {consts})"


def local_decls(count, indent, type="i64"):
    return wrap(["(local"] + [type] * count, indent) + ")"


# `OUTSIDE` i64 locals below the moved `sp`, the first ones (and the frame
# header below them) out of a VReg's reach.
FIRST = 0
LAST = OUTSIDE - 1

# A v128 local whose two slots straddle the edge of the range, i.e. its first
# slot is at -4097 from the moved `sp`: `STRADDLE_BEFORE` i64 locals, the v128,
# then `STRADDLE_AFTER` slots of locals up to the three moved saved slots.
STRADDLE_BEFORE = 200
STRADDLE_AFTER = MAX_SLOT_INDEX + 2 - 3 - 2
# ...made of i64 locals and one more v128 that is within reach.
STRADDLE_NEAR_I64 = STRADDLE_AFTER - 2
V128_FAR = STRADDLE_BEFORE
V128_NEAR = STRADDLE_BEFORE + 1 + STRADDLE_NEAR_I64

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/huge_frame.gen.py > Tests/WasmKitTests/ExtraSuite/huge_frame.wast",
       "",
       ";; The operand stack overflows the addressable slot range.",
       "(assert_invalid",
       "  (module",
       eight("    "),
       '    (func (export "f")',
       wrap(["call $eight"] * (OUTSIDE // 8 + 1), "      "),
       "      unreachable))",
       '  "frame too large")',
       "",
       ";; Frames just inside the range still compile and run.",
       "(module",
       eight("  "),
       '  (func (export "locals") (result i64)',
       local_decls(INSIDE, "    "),
       f"    (local.set {INSIDE - 1} (i64.const 42))",
       f"    (local.get {INSIDE - 1}))",
       '  (func (export "stack") (result i32)',
       "    (block (result i32)",
       wrap(["call $eight"] * (INSIDE // 8), "      "),
       "      i32.const 42",
       "      br 0)))",
       '(assert_return (invoke "locals") (i64.const 42))',
       '(assert_return (invoke "stack") (i32.const 42))',
       "",
       ";; Locals alone overflow the addressable slot range.",
       "(module",
       "  (tag $e (param i64))",
       "  (func $add (param i64 i64) (result i64)",
       "    (i64.add (local.get 0) (local.get 1)))",
       "  (func $thrower (param i64)",
       "    (throw $e (local.get 0)))",
       "  (func $pair (param i64 i32 f64) (result i64 i32)",
       "    (local.get 0) (local.get 1))",
       "",
       "  ;; Parameters, results and the first locals are out of reach; the last",
       "  ;; locals are not.",
       '  (func (export "locals") (param $p i64) (param $q i32) (result i64 i32)',
       local_decls(OUTSIDE, "    "),
       f"    (local.set {2 + FIRST} (i64.add (local.get $p) (i64.const 1)))",
       f"    (local.set {2 + LAST} (i64.const 40))",
       f"    (local.set {2 + FIRST + 1} (local.tee {2 + FIRST + 2} (i64.const 5)))",
       f"    (local.set {2 + LAST - 1} (i64.mul (local.tee {2 + FIRST + 3} (i64.add (local.get {2 + FIRST + 1}) (local.get {2 + FIRST + 2}))) (i64.const 2)))",
       f"    (local.set {2 + FIRST} (call $add (local.get {2 + FIRST}) (local.get {2 + LAST})))",
       f"    (i64.add (local.get {2 + FIRST}) (i64.add (local.get {2 + FIRST + 3}) (local.get {2 + LAST - 1})))",
       "    (local.get $q))",
       "",
       "  ;; A branch out of the function writes the results.",
       '  (func (export "branch") (param $p i64) (result i64)',
       local_decls(OUTSIDE, "    "),
       f"    (local.set {1 + FIRST} (local.get $p))",
       f"    (br_if 0 (local.get {1 + FIRST}) (i64.eqz (local.get $p)))",
       f"    (drop)",
       f"    (i64.add (local.get {1 + FIRST}) (i64.const 1)))",
       "",
       "  ;; A tail call moves `sp` back to where the function was entered.",
       '  (func (export "tail_other") (param $p i64) (result i64 i32)',
       local_decls(OUTSIDE, "    "),
       f"    (local.set {1 + FIRST} (i64.add (local.get $p) (i64.const 1)))",
       f"    (local.set {1 + LAST} (i64.const 2))",
       f"    (return_call $pair (i64.add (local.get {1 + FIRST}) (local.get {1 + LAST})) (i32.const 3) (f64.const 0)))",
       "",
       "  ;; Deep enough to exhaust the stack if a tail call left the frame behind.",
       '  (func $sum (export "tail_self") (param $n i64) (param $acc i64) (result i64)',
       local_decls(OUTSIDE, "    "),
       "    (if (i64.eqz (local.get $n)) (then (return (local.get $acc))))",
       f"    (local.set {2 + FIRST} (i64.add (local.get $acc) (local.get $n)))",
       f"    (return_call $sum (i64.sub (local.get $n) (i64.const 1)) (local.get {2 + FIRST})))",
       "",
       "  ;; An exception thrown by a callee is caught in the moved frame.",
       '  (func (export "catch") (result i64)',
       local_decls(OUTSIDE, "    "),
       f"    (local.set {FIRST} (i64.const 100))",
       "    (block $h (result i64)",
       "      (try_table (catch $e $h)",
       "        (call $thrower (i64.const 5)))",
       "      (i64.const 0))",
       f"    (i64.add (local.get {FIRST})))",
       "",
       "  ;; A v128 local is out of reach unless both of its slots are.",
       '  (func (export "v128") (result i64)',
       local_decls(STRADDLE_BEFORE, "    "),
       "    (local v128)",
       local_decls(STRADDLE_NEAR_I64, "    "),
       "    (local v128)",
       f"    (local.set {V128_FAR} (v128.const i64x2 1 2))",
       f"    (local.set {V128_NEAR} (local.get {V128_FAR}))",
       f"    (local.set {V128_FAR} (v128.const i64x2 0 0))",
       f"    (i64.add",
       f"      (i64x2.extract_lane 0 (local.get {V128_NEAR}))",
       f"      (i64x2.extract_lane 1 (local.tee {V128_FAR} (local.get {V128_NEAR}))))))",
       "",
       '(assert_return (invoke "locals" (i64.const 1) (i32.const 7)) (i64.const 72) (i32.const 7))',
       '(assert_return (invoke "branch" (i64.const 0)) (i64.const 0))',
       '(assert_return (invoke "branch" (i64.const 5)) (i64.const 6))',
       '(assert_return (invoke "tail_other" (i64.const 4)) (i64.const 7) (i32.const 3))',
       '(assert_return (invoke "tail_self" (i64.const 1000) (i64.const 0)) (i64.const 500500))',
       '(assert_return (invoke "catch") (i64.const 105))',
       '(assert_return (invoke "v128") (i64.const 3))',
       ""]
print("\n".join(out), end="")
