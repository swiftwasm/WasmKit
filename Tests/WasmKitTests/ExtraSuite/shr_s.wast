(module
  (func (export "i64.shr_s") (param i64) (param i64) (result i64)
    (i64.shr_s (local.get 0) (local.get 1))
  )
)

(assert_return (invoke "i64.shr_s" (i64.const -1309934030728401938) (i64.const -1309934030728401938)) (i64.const -18616))

