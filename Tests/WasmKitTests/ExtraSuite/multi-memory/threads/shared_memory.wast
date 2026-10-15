;; A shared memory at a non-zero index. A shared memory's bounds check relies on
;; faults in its guard pages, so switching to it must also move the trap guard:
;; an out-of-bounds access has to trap rather than crash the process.

(module
  (memory $m0 1)
  (memory $m1 1 1 shared)
  (func (export "store-load-m1") (result i32)
    (i32.atomic.store $m1 (i32.const 8) (i32.const 42))
    (i32.atomic.load $m1 (i32.const 8)))
  (func (export "load-m1-out-of-bounds") (result i32) (i32.load $m1 (i32.const 65536)))
  (func (export "load-m1-out-of-bounds-after-m0") (result i32)
    (drop (i32.load $m0 (i32.const 0)))
    (i32.load $m1 (i32.const 70000)))
  (func (export "load-m0-after-m1") (result i32)
    (drop (i32.load $m1 (i32.const 0)))
    (i32.load $m0 (i32.const 65532)))
  ;; Waits and notifies use memory 1's parking lot.
  (func (export "wait-m1-not-equal") (result i32)
    (memory.atomic.wait32 $m1 (i32.const 8) (i32.const 0) (i64.const 0)))
  (func (export "notify-m1") (result i32)
    (memory.atomic.notify $m1 (i32.const 8) (i32.const 1)))
)

(assert_return (invoke "store-load-m1") (i32.const 42))
(assert_trap (invoke "load-m1-out-of-bounds") "out of bounds memory access")
(assert_trap (invoke "load-m1-out-of-bounds-after-m0") "out of bounds memory access")
(assert_return (invoke "load-m0-after-m1") (i32.const 0))
(assert_return (invoke "wait-m1-not-equal") (i32.const 1))
(assert_return (invoke "notify-m1") (i32.const 0))
