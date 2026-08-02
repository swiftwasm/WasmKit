(module
  (func (export "check-limit") (param i32) (result i32)
    ;; Enough to reach the limit of constant slots
    (drop (i32.const 1))
    (drop (i32.const 2))
    (drop (i32.const 3))
    (drop (i32.const 4))
    (drop (i32.const 5))
    (drop (i32.const 6))
    (i32.add (local.get 0) (i32.add (i32.const 1) (i32.const 1)))
  )
  (func (export "invalidate-relink") (result i32)
      (local i32)
      (i32.add (i32.const 1) (i32.const 1))
      ;; This constant should invalidate the relinking
      ;; connection of i32.add even though it doesn't
      ;; emit its own instruction.
      (i32.const 0)
      (local.set 0)
      (drop) ;; drop i32.add
      (local.get 0)
  )
)

(assert_return (invoke "check-limit" (i32.const 3)) (i32.const 5))
(assert_return (invoke "invalidate-relink") (i32.const 0))


;; A constant left on the value stack across a block-like construct is
;; materialized into a stack slot on demand. The copy has to dominate every
;; later read of that slot: a branch nested in the block would otherwise
;; materialize it on its own path only, leaving the slot undefined on the paths
;; that skip the branch. Each function below dirties the target slot first so a
;; missing copy is observable.

(module
  (func (export "const-across-block") (param i32) (result i32)
    (drop (i32.add (local.get 0) (i32.const 200)))
    i32.const 42
    block
      ;; Leaves the block before the branch below when the parameter is non-zero.
      local.get 0
      br_if 0
      ;; Branching out of the function spans the constant sitting below this
      ;; frame. Never taken.
      i32.const 7
      i32.const 0
      br_if 1
      drop
    end
  )
)

(assert_return (invoke "const-across-block" (i32.const 0)) (i32.const 42))
(assert_return (invoke "const-across-block" (i32.const 1)) (i32.const 42))

(module
  (func (export "const-across-if") (param i32) (result i32)
    (drop (i32.add (local.get 0) (i32.const 200)))
    i32.const 42
    local.get 0
    if (result i32)
      i32.const 7
      i32.const 0
      br_if 1
    else
      i32.const 2
    end
    drop
  )
)

(assert_return (invoke "const-across-if" (i32.const 0)) (i32.const 42))
(assert_return (invoke "const-across-if" (i32.const 1)) (i32.const 42))

(module
  (func (export "const-across-loop") (param i32) (result i32)
    (drop (i32.add (local.get 0) (i32.const 200)))
    i32.const 42
    loop
      local.get 0
      if
        i32.const 7
        i32.const 0
        br_if 2
        drop
      end
    end
  )
)

(assert_return (invoke "const-across-loop" (i32.const 0)) (i32.const 42))
(assert_return (invoke "const-across-loop" (i32.const 1)) (i32.const 42))
