(module
  (func (export "check-limit") (param i32) (result i32)
    ;; Enough to reach the limit of constant slots
    (drop (i32.const 1))
    (drop (i32.const 2))
    (drop (i32.const 3))
    (drop (i32.const 4))
    (drop (i32.const 5))
    (drop (i32.const 6))
    (i32.add (local.get 0) (i32.add (i32.const 1) (i32.const 1)))
  )
  (func (export "invalidate-relink") (result i32)
      (local i32)
      (i32.add (i32.const 1) (i32.const 1))
      ;; This constant should invalidate the relinking
      ;; connection of i32.add even though it doesn't
      ;; emit its own instruction.
      (i32.const 0)
      (local.set 0)
      (drop) ;; drop i32.add
      (local.get 0)
  )
)

(assert_return (invoke "check-limit" (i32.const 3)) (i32.const 5))
(assert_return (invoke "invalidate-relink") (i32.const 0))

