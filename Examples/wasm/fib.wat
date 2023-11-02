(module
  (type (;0;) (func))
  (type (;1;) (func (param i32) (result i32)))
  (func (;0;) (type 0))
  (func (;1;) (type 1) (param i32) (result i32)
    (local i32)
    i32.const 1
    local.set 1
    block  ;; label = @1
      local.get 0
      i32.const 2
      i32.lt_s
      br_if 0 (;@1;)
      local.get 0
      i32.const 2
      i32.add
      local.set 0
      i32.const 1
      local.set 1
      loop  ;; label = @2
        local.get 0
        i32.const -3
        i32.add
        call 1
        local.get 1
        i32.add
        local.set 1
        local.get 0
        i32.const -2
        i32.add
        local.tee 0
        i32.const 3
        i32.gt_s
        br_if 0 (;@2;)
      end
    end
    local.get 1)
  (table (;0;) 1 1 funcref)
  (memory (;0;) 2)
  (global (;0;) (mut i32) (i32.const 66560))
  (global (;1;) i32 (i32.const 66560))
  (global (;2;) i32 (i32.const 1024))
  (export "memory" (memory 0))
  (export "__heap_base" (global 1))
  (export "__data_end" (global 2))
  (export "fib" (func 1)))
