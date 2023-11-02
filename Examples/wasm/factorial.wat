  (func $fac (export "fac") (param i64) (result i64)
    (if (result i64) (i64.eqz (local.get 0))
      (then (i64.const 1))
      (else
        (i64.mul
          (local.get 0)
          (call $fac (i64.sub (local.get 0) (i64.const 1)))
        )
      )
    )
  )
