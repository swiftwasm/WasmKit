;; A tail call moves the arguments to the start of the caller's parameter area
;; and places the callee's `sp` past its own parameter area and locals. These
;; cover the moves that overlap: a callee whose parameter area reaches past the
;; caller's parameters and locals, over the saved slots and the constant pool.

(module
  (type $sum5 (func (param i64 i64 i64 i64 i64) (result i64)))
  (table funcref (elem $add5))
  (elem declare func $add5)

  (func $add5 (type $sum5)
    (i64.add (local.get 0)
      (i64.add (local.get 1)
        (i64.add (local.get 2) (i64.add (local.get 3) (local.get 4))))))

  ;; No parameters and no locals: the callee's parameters land on this frame's
  ;; saved slots and constants.
  (func (export "grow") (result i64)
    (return_call $add5
      (i64.const 1) (i64.const 20) (i64.const 300) (i64.const 4000) (i64.const 50000)))
  (func (export "grow-indirect") (result i64)
    (return_call_indirect (type $sum5)
      (i64.const 1) (i64.const 20) (i64.const 300) (i64.const 4000) (i64.const 50000)
      (i32.const 0)))

  ;; The arguments come from this frame's own parameters, which the move
  ;; overwrites.
  (func (export "permute") (param i64 i64) (result i64)
    (return_call $add5
      (local.get 1) (local.get 0) (local.get 1) (local.get 0)
      (i64.mul (local.get 0) (i64.const 1000))))

  ;; Alternate between a small and a large frame. The frame is reused, so a
  ;; million iterations do not exhaust the stack.
  (func $small (param $n i64) (result i64)
    (if (result i64) (i64.eqz (local.get $n))
      (then (i64.const 7))
      (else
        (return_call $large
          (i64.sub (local.get $n) (i64.const 1))
          (i64.const 0) (i64.const 0) (i64.const 0) (i64.const 0)))))
  (func $large (param $n i64) (param i64 i64 i64 i64) (result i64)
    (local i64 i64 i64 i64 i64 i64 i64 i64)
    (local.set 5 (local.get $n))
    (return_call $small (local.get 5)))
  (func (export "alternate") (param i64) (result i64)
    (return_call $small (local.get 0)))
)

(assert_return (invoke "grow") (i64.const 54321))
(assert_return (invoke "grow-indirect") (i64.const 54321))
(assert_return (invoke "permute" (i64.const 3) (i64.const 5)) (i64.const 3016))
(assert_return (invoke "alternate" (i64.const 1000000)) (i64.const 7))

;; A tail call into another instance switches the current memory, and the
;; return from it switches back to the original caller's.
(module $callee
  (memory 1)
  (data (i32.const 0) "\2a")
  (func (export "load5") (param i32 i32 i32 i32 i32) (result i32)
    (i32.add (i32.load8_u (local.get 0)) (local.get 4)))
)
(register "callee" $callee)

(module
  (import "callee" "load5" (func $load5 (param i32 i32 i32 i32 i32) (result i32)))
  (memory 1)
  (data (i32.const 0) "\64")
  (func $tail (result i32)
    (return_call $load5 (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 1)))
  ;; 42 + 1 from the callee's memory, then 100 from this instance's.
  (func (export "cross") (result i32)
    (i32.add (call $tail) (i32.load8_u (i32.const 0))))
)

(assert_return (invoke "cross") (i32.const 143))
