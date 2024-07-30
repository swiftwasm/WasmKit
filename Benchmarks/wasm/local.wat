(module
    (import "wasi_snapshot_preview1" "random_get" (func $random_get (param i32 i32) (result i32)))
    (memory (export "memory") 1)

    (func (export "_start") (local $x i32) (local $i i32)
        (; Get random seed ;)
        (call $random_get (i32.const 0) (i32.const 1))
        (drop)
        (local.set $x (i32.load (i32.const 0)))
        (loop $loop
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (local.set $x (i32.add (local.get $x) (i32.const 1)))
            (br_if $loop (i32.lt_u (local.get $i) (i32.const 60000000)))
        )
    )
)


