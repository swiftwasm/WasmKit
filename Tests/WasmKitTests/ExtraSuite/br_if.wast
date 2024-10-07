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

(module
  (func (export "check")
    (local i64 i32 f32)
    i64.const 4
    ;; use non-const nor local instruction to force
    ;; leaving local.set at runtime
    i64.clz

    i32.const 0
    i32.eqz
    ;; popping the i32.eqz should invalidate the relinking state
    br_if 0
    local.set 0
    unreachable)
)


(invoke "check")
