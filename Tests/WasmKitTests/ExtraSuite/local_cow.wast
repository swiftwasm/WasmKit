;; This test file checks Copy-on-Write behavior of the local-source values

(module
  (func (export "local_source_block_param") (param i32) (result i32)
    (local.get 0)
    (block (param i32) (result i32))
  )
)

(assert_return (invoke "local_source_block_param" (i32.const 3)) (i32.const 3))

(module
  (func (export "local_source_loop_param") (param i32) (result i32)
    (local.get 0)
    (loop (param i32) (result i32))
  )
)

(assert_return (invoke "local_source_loop_param" (i32.const 3)) (i32.const 3))
