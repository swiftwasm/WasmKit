#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering internal calls on either side of the
small-frame limit.

`internalCall` enters a callee whose frame image (its constant slots and its
non-parameter locals) is at most 128 bytes with fixed-size copies, and leaves a
larger one to `internalCallSlow`. The constant pool takes some of those bytes,
so the callees sweep the number of locals well past 16 slots instead of
stopping at the limit. Each callee is called twice from the same call site: the
first call goes through `compilingCall`, the second through the instruction it
rewrote itself to.

Unbounded recursion through a callee on each side of the limit must exhaust
the stack rather than overrun it.
"""
LOCAL_COUNTS = list(range(0, 25)) + [32, 100]


def callee(count):
    locals_ = f" (local{' i64' * count})" if count else ""
    last = f"(local.get {count})" if count else "(i64.const 0)"
    return (
        f"  (func $callee{count} (param i64) (result i64){locals_}\n"
        f"    (i64.add (local.get 0) {last}))\n"
        f"  (func (export \"call{count}\") (param i64) (result i64)\n"
        f"    (call $callee{count} (call $callee{count} (local.get 0))))"
    )


def recursion(name, count):
    locals_ = f" (local{' i64' * count})" if count else ""
    return (
        f"  (func ${name} (export \"{name}\") (param i64) (result i64){locals_}\n"
        f"    (call ${name} (local.get 0)))"
    )


def main():
    print(";; GENERATED FILE, DO NOT EDIT. Regenerate with:")
    print(";;   python3 Tests/WasmKitTests/ExtraSuite/internal_call_frames.gen.py"
          " > Tests/WasmKitTests/ExtraSuite/internal_call_frames.wast")
    print()
    print("(module")
    print("\n".join(callee(count) for count in LOCAL_COUNTS))
    print(")")
    print()
    for count in LOCAL_COUNTS:
        for value in (1, 0x7fff_ffff_ffff_ffff):
            print(f'(assert_return (invoke "call{count}" (i64.const {value}))'
                  f' (i64.const {value}))')
    print()
    print(";; Recursion through a small frame and through a large one.")
    print("(module")
    print(recursion("small", 0))
    print(recursion("large", 32))
    print(")")
    print()
    print('(assert_exhaustion (invoke "small" (i64.const 0)) "call stack exhausted")')
    print('(assert_exhaustion (invoke "large" (i64.const 0)) "call stack exhausted")')


if __name__ == "__main__":
    main()
