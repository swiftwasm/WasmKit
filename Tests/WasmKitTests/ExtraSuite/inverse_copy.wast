;; Inverse-copy peephole: `copy B <- A` followed by `copy A <- B` keeps only
;; the first copy, unless control can reach the second without running the first.

;; A tee whose relink is refused, followed by a branch that copies the tee'd
;; value back into its stack slot: an inverse copy pair.
(module
  (func (export "inverse_copy") (param $n i32) (param $m i32) (result i32)
    (local.get $n)
    (loop $continue (param i32) (result i32)
      (drop)
      (local.tee $n (i32.sub (local.get $n) (i32.const 1)))
      (local.get $n)
      (br_if $continue)
    )
  )
)
(assert_return (invoke "inverse_copy" (i32.const 1) (i32.const 0)) (i32.const 0))
(assert_return (invoke "inverse_copy" (i32.const 50) (i32.const 0)) (i32.const 0))

;; A label between two copies: the second is reachable from the br_if without
;; the first having run, so the pair must not be collapsed.
(module
  (func (export "label_between_copies") (param $c i32) (param $x i32) (result i32)
    (local $t i32)
    (local.set $t
      (block (result i32)
        (local.get $x)
        (i32.const 7)
        (local.get $c)
        (br_if 0)
        (drop)
        (drop)
        (i32.const 99)
      )
    )
    (local.get $t)
  )
)
(assert_return (invoke "label_between_copies" (i32.const 1) (i32.const 5)) (i32.const 7))
(assert_return (invoke "label_between_copies" (i32.const 0) (i32.const 5)) (i32.const 99))

;; The loop header is pinned between an inverse copy pair. Collapsing it would
;; leave $n at its entry value and the loop would not terminate.
(module
  (func (export "loop_header_copies") (param $n i32) (result i32)
    (local $acc i32)
    (local.get $n)
    (loop $continue (param i32) (result i32)
      (local.set $n)
      (local.set $acc (i32.add (local.get $acc) (local.get $n)))
      (local.tee $n (i32.sub (local.get $n) (i32.const 1)))
      (local.get $n)
      (br_if $continue)
    )
    (drop)
    (local.get $acc)
  )
)
(assert_return (invoke "loop_header_copies" (i32.const 1)) (i32.const 1))
(assert_return (invoke "loop_header_copies" (i32.const 4)) (i32.const 10))
(assert_return (invoke "loop_header_copies" (i32.const 10)) (i32.const 55))

