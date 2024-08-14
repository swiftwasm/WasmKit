(module
    ;; Lots of local operations
    (func (export "_start") (local $x i32) (local $i i32)
        (local.set $x (i32.const 42))
        (loop $loop
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (local.set $x (i32.add (local.get $x) (i32.const 1)))
            (br_if $loop (i32.lt_u (local.get $i) (i32.const 60000000)))
        )
    )
)


