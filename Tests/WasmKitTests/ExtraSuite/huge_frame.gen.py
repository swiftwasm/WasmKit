#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering frames at the edge of the VReg range.

A register is a pre-shifted byte offset in an Int16, so a frame can address
slots -4096...4095 only. A function whose frame does not fit must be rejected
rather than miscompiled by a wrapped register, and one just inside must run.
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


def local_decls(count, indent):
    return wrap(["(local"] + ["i64"] * count, indent) + ")"


out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/huge_frame.gen.py > Tests/WasmKitTests/ExtraSuite/huge_frame.wast",
       "",
       ";; Locals alone overflow the addressable slot range.",
       "(assert_invalid",
       "  (module",
       '    (func (export "f") (result i64)',
       local_decls(OUTSIDE, "      "),
       "      local.get 0))",
       '  "frame too large")',
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
       ""]
print("\n".join(out), end="")
