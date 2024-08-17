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

(module
  (func (export "check") (result i32)
    (local i32 i32)
    i32.const 42
    local.set 0
    block (result i32)
      i32.const 0
      br 0
      local.get 0
    end
    local.set 1
    local.get 1
  )
)

(assert_return (invoke "check") (i32.const 0))
