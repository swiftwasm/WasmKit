(module
  (func (export "check") (param i32) (result i32)
    ;; Enough to reach the limit of constant slots
    (drop (i32.const 1))
    (drop (i32.const 2))
    (drop (i32.const 3))
    (drop (i32.const 4))
    (drop (i32.const 5))
    (drop (i32.const 6))
    (i32.add (local.get 0) (i32.add (i32.const 1) (i32.const 1)))
  )
)

(assert_return (invoke "check" (i32.const 3)) (i32.const 5))

