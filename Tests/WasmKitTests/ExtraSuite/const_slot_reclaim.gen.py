#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering reclaimed constant-pool reservations.

A constant reserves a pool slot when it is pushed, and gets one only when it is
read as a register. One consumed as an immediate or dropped releases its
reservation only when a later constant finds the pool full. Each function here
has a pool of about 15 slots and adds 40 distinct constants, so its reservations
are reclaimed many times; the cases check that a constant still on the stack, or
below an enclosing block, keeps its value.
"""
ADDS = 40
TOTAL = sum(range(1, ADDS + 1))
# Over the limit of values above the current frame that a reclaim scans.
DEEP = 130
LIVE_A = 1234567890123
LIVE_B = 9876543210123


def additions(indent):
    return "\n".join(f"{indent}local.get 0 i64.const {i} i64.add local.set 0" for i in range(1, ADDS + 1))


def main():
    i = "    "
    print(f""";; GENERATED FILE, DO NOT EDIT. Regenerate with:
;;   python3 Tests/WasmKitTests/ExtraSuite/const_slot_reclaim.gen.py > Tests/WasmKitTests/ExtraSuite/const_slot_reclaim.wast

(module
  (func $identity (param i64) (result i64) local.get 0)
  ;; Every constant is an immediate, so none is ever allocated.
  (func (export "add") (param i64) (result i64)
{additions(i)}
    local.get 0)
  ;; Constants left on the stack across the reclaims.
  (func (export "live") (param i64) (result i64 i64 i64)
    i64.const {LIVE_A}
    i64.const {LIVE_B} call $identity
{additions(i)}
    local.get 0)
  ;; A stack too deep to scan: the constants spill instead.
  (func (export "deep") (param i64) (result i64)
    {"i64.const 0 " * DEEP}
{additions(i)}
    {"drop " * DEEP}
    local.get 0)
  ;; A stack too deep to scan, but below the current frame, which reclaims.
  (func (export "deep-below-block") (param i64) (result i64)
    {"i64.const 0 " * DEEP}
    block (result i64)
{additions(i + "  ")}
      local.get 0
    end
    {"i64.add " * DEEP})
  ;; A constant materialized on block entry, then reclaims inside the block.
  (func (export "branch") (param i64 i32) (result i64 i64)
    i64.const {LIVE_A}
    local.get 1 if
{additions(i + "  ")}
    else
      i64.const 3 local.set 0
    end
    local.get 0))
""")
    for x in ["0", "17", "-1"]:
        print(f'(assert_return (invoke "add" (i64.const {x})) (i64.const {int(x) + TOTAL}))')
        print(f'(assert_return (invoke "live" (i64.const {x})) (i64.const {LIVE_A}) (i64.const {LIVE_B}) (i64.const {int(x) + TOTAL}))')
        print(f'(assert_return (invoke "deep" (i64.const {x})) (i64.const {int(x) + TOTAL}))')
        print(f'(assert_return (invoke "deep-below-block" (i64.const {x})) (i64.const {int(x) + TOTAL}))')
        print(f'(assert_return (invoke "branch" (i64.const {x}) (i32.const 1)) (i64.const {LIVE_A}) (i64.const {int(x) + TOTAL}))')
        print(f'(assert_return (invoke "branch" (i64.const {x}) (i32.const 0)) (i64.const {LIVE_A}) (i64.const 3))')


if __name__ == "__main__":
    main()
