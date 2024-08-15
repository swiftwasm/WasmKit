(module
  (func (export "brif_not_taken") (param i32) (result i32)
    (block (result i32)
      local.get 0
      i32.const 0
      br_if 0
      local.get 0
      i32.add
    )
  )
)

(assert_return (invoke "brif_not_taken" (i32.const 3)) (i32.const 6))

