;; br_if targets whose block parameters or results already sit in the
;; destination slots (the "landing pad copies nothing" shape), next to targets
;; that really need the copy and targets that leave a try_table. The branch
;; must take exactly the copies it needs, and only on the taken path.

;; A loop (param i32) (result i32) whose back-edge needs no copy: the operand
;; is already in the loop's parameter slot. Counts down to zero.
(module
  (func (export "loop_no_copy") (param $n i32) (result i32)
    (local.get $n)
    (loop $continue (param i32) (result i32)
      (i32.const 1)
      (i32.sub)
      (local.tee $n)
      (local.get $n)
      (br_if $continue)
    )
  )
)
(assert_return (invoke "loop_no_copy" (i32.const 1)) (i32.const 0))
(assert_return (invoke "loop_no_copy" (i32.const 10)) (i32.const 0))
(assert_return (invoke "loop_no_copy" (i32.const 1000)) (i32.const 0))

;; The same shape with a comparison as the condition; the loop operand is a
;; temporary so nothing sits between the comparison and the branch. Returns
;; the sum of 0..<max(n, 1).
(module
  (func (export "loop_no_copy_cmp") (param $n i32) (result i32) (local $i i32)
    (i32.const 0)
    (loop $continue (param i32) (result i32)
      (local.get $i)
      (i32.add)
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (i32.lt_s (local.get $i) (local.get $n))
      (br_if $continue)
    )
  )
)
(assert_return (invoke "loop_no_copy_cmp" (i32.const 0)) (i32.const 0))
(assert_return (invoke "loop_no_copy_cmp" (i32.const 1)) (i32.const 0))
(assert_return (invoke "loop_no_copy_cmp" (i32.const 5)) (i32.const 10))
(assert_return (invoke "loop_no_copy_cmp" (i32.const 100)) (i32.const 4950))

;; A br_if whose target needs a copy: the copy writes a slot that stays live
;; on the fall-through path, so it may only run when the branch is taken.
(module
  (func (export "real_copy") (param $c i32) (result i32)
    (block (result i32)
      (i32.const 42)
      (i32.const 24)
      (local.get $c)
      (br_if 0)
      (drop)
    )
  )
)
;; Taken: the block result is the copied 24.
(assert_return (invoke "real_copy" (i32.const 1)) (i32.const 24))
;; Not taken: the copy must not have happened, 42 is still there.
(assert_return (invoke "real_copy" (i32.const 0)) (i32.const 42))

;; Same, with a comparison as the condition and temporaries as the operands.
(module
  (func (export "real_copy_cmp") (param $a i32) (param $b i32) (result i32)
    (block (result i32)
      (i32.add (local.get $a) (local.get $a))
      (i32.add (local.get $b) (local.get $b))
      (i32.lt_s (local.get $a) (local.get $b))
      (br_if 0)
      (drop)
    )
  )
)
;; Taken: the block result is the copied 2*b.
(assert_return (invoke "real_copy_cmp" (i32.const 1) (i32.const 2)) (i32.const 4))
;; Not taken: the copy must not have happened, 2*a is still there.
(assert_return (invoke "real_copy_cmp" (i32.const 3) (i32.const 2)) (i32.const 6))

;; if with block parameters.
(module
  (func (export "if_params") (param $a i32) (param $c i32) (result i32)
    (local.get $a)
    (if (param i32) (result i32) (local.get $c)
      (then (i32.const 1) (i32.add))
      (else (i32.const 2) (i32.add)))
  )
)
(assert_return (invoke "if_params" (i32.const 10) (i32.const 1)) (i32.const 11))
(assert_return (invoke "if_params" (i32.const 10) (i32.const 0)) (i32.const 12))
