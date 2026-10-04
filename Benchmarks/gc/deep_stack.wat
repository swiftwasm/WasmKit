;; Recurses `frames` deep, each frame holding a struct in a local next to
;; numeric locals, then allocates `allocations` garbage structs at the bottom.
;; Measures how collections scale with the number of Wasm frames to walk.
(module
  (type $box (struct (field $value i32)))

  (func $descend (param $frames i32) (param $allocations i32) (result i32)
    (local $kept (ref null $box))
    (local $a i64)
    (local $b f64)
    (local.set $kept (struct.new $box (local.get $frames)))
    (if (i32.eqz (local.get $frames))
      (then
        (block $done
          (loop $loop
            (br_if $done (i32.eqz (local.get $allocations)))
            (drop (struct.new $box (local.get $allocations)))
            (local.set $allocations (i32.sub (local.get $allocations) (i32.const 1)))
            (br $loop)
          )
        )
        (return (struct.get $box $value (local.get $kept)))
      )
    )
    (i32.add
      (call $descend (i32.sub (local.get $frames) (i32.const 1)) (local.get $allocations))
      (struct.get $box $value (local.get $kept))
    )
  )

  (func (export "run") (param $frames i32) (param $allocations i32) (result i32)
    (call $descend (local.get $frames) (local.get $allocations))
  )
)
