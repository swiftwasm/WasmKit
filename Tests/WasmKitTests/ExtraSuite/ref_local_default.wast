;; Reference-typed locals that are not parameters start out null. The
;; interpreter encodes null as the top bit of a slot, so a zero-filled slot
;; would read as a non-null reference.

(module
  (func (export "funcref-is-null") (result i32)
    (local funcref)
    (ref.is_null (local.get 0)))
  (func (export "externref-is-null") (result i32)
    (local externref)
    (ref.is_null (local.get 0)))
  (func (export "externref") (result externref)
    (local externref)
    (local.get 0))
  (func (export "funcref") (result funcref)
    (local funcref)
    (local.get 0))
  ;; A v128 local takes two slots, shifting the slots of the locals after it.
  (func (export "after-v128-is-null") (param i32) (result i32)
    (local i64 v128 externref f32 funcref)
    (i32.and
      (ref.is_null (local.get 3))
      (ref.is_null (local.get 5))))
)

(assert_return (invoke "funcref-is-null") (i32.const 1))
(assert_return (invoke "externref-is-null") (i32.const 1))
(assert_return (invoke "externref") (ref.null extern))
(assert_return (invoke "funcref") (ref.null func))
(assert_return (invoke "after-v128-is-null" (i32.const 0)) (i32.const 1))
