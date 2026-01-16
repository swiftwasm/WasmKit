(module
  (import "printer" "print_str" (func $print_str (param i32 i32)))

  (memory (export "memory") 1)

  (data (i32.const 0) "Hello from Wasm!\n")
  (func (export "print_hello")
    (call $print_str (i32.const 0) (i32.const 17))
  )

  (global $heap (mut i32) (i32.const 1024))
  (func (export "alloc") (param $size i32) (result i32)
    (local $old i32)
    (local.set $old (global.get $heap))
    (global.set $heap (i32.add (global.get $heap) (local.get $size)))
    (local.get $old)
  )

  (func (export "checksum") (param $ptr i32) (param $len i32) (result i32)
    (local $i i32)
    (local $sum i32)
    (local.set $i (i32.const 0))
    (local.set $sum (i32.const 0))
    (block $exit
      (loop $loop
        (br_if $exit (i32.ge_u (local.get $i) (local.get $len)))
        (local.set $sum
          (i32.add
            (local.get $sum)
            (i32.load8_u (i32.add (local.get $ptr) (local.get $i)))
          )
        )
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)
      )
    )
    (local.get $sum)
  )
)
