;; An allocation that needs the GC heap to grow beyond its limit traps
;; instead of taking all of the host's memory. The default limit is 1 GiB.
(module
  (type $bytes (array (mut i8)))
  (func (export "allocate") (param i32) (result i32)
    (array.len (array.new_default $bytes (local.get 0)))
  )
)
(assert_return (invoke "allocate" (i32.const 16)) (i32.const 16))
(assert_trap (invoke "allocate" (i32.const 0x7fffffff)) "out of GC heap memory")
;; The heap stays usable after an allocation failed.
(assert_return (invoke "allocate" (i32.const 32)) (i32.const 32))
