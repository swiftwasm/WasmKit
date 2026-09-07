;; local.tee / local.set result relinking (the producer writes the local's slot
;; directly), the inverse-copy peephole, and i64.eqz fused into br_if / if.

;; The producer of a tee'd value writes the local directly.
(module
  (func (export "tee_relink") (param $a i32) (param $b i32) (result i32)
    (local $t i32)
    (local.tee $t (i32.add (local.get $a) (local.get $b)))
    (local.get $t)
    (i32.add)
  )
)
(assert_return (invoke "tee_relink" (i32.const 3) (i32.const 4)) (i32.const 14))
(assert_return (invoke "tee_relink" (i32.const 0) (i32.const 0)) (i32.const 0))
(assert_return (invoke "tee_relink" (i32.const -1) (i32.const 1)) (i32.const 0))

;; The tee'd value stays on the stack as an alias of the local. Overwriting the
;; local before that value is consumed must preserve the old value, so this
;; returns x - y.
(module
  (func (export "tee_then_overwrite") (param $x i32) (param $y i32) (result i32)
    (local $t i32)
    (local.tee $t (i32.mul (local.get $x) (i32.const 1)))
    (local.set $t (i32.mul (local.get $y) (i32.const 1)))
    (local.get $t)
    (i32.sub)
  )
)
(assert_return (invoke "tee_then_overwrite" (i32.const 10) (i32.const 3)) (i32.const 7))
(assert_return (invoke "tee_then_overwrite" (i32.const 0) (i32.const 5)) (i32.const -5))
(assert_return (invoke "tee_then_overwrite" (i32.const -7) (i32.const -2)) (i32.const -5))

;; A relinked tee inside a loop body. Relinking across the loop header would
;; hoist the write out of the body. Returns sum(1...n).
(module
  (func (export "tee_in_loop") (param $n i32) (result i32)
    (local $acc i32)
    (loop $continue
      (local.set $acc (i32.add (local.get $acc) (local.get $n)))
      (local.tee $n (i32.sub (local.get $n) (i32.const 1)))
      (br_if $continue)
    )
    (local.get $acc)
  )
)
(assert_return (invoke "tee_in_loop" (i32.const 1)) (i32.const 1))
(assert_return (invoke "tee_in_loop" (i32.const 4)) (i32.const 10))
(assert_return (invoke "tee_in_loop" (i32.const 10)) (i32.const 55))

;; A v128 result occupies two slots; both must land in the local.
(module
  (func (export "tee_v128") (param $x i64) (result i64)
    (local $v v128)
    (local.tee $v (i64x2.splat (local.get $x)))
    (i64x2.extract_lane 1)
    (i64.add (i64x2.extract_lane 0 (local.get $v)))
  )
  (func (export "set_v128") (param $lo i64) (param $hi i64) (result i64)
    (local $v v128)
    (local.set $v (i64x2.replace_lane 1 (i64x2.splat (local.get $lo)) (local.get $hi)))
    (i64.sub
      (i64x2.extract_lane 1 (local.get $v))
      (i64x2.extract_lane 0 (local.get $v)))
  )
  ;; The producer's inputs are the local it is relinked into (v = v + v).
  (func (export "v128_alias") (param $x i64) (result i64)
    (local $v v128)
    (local.set $v (i64x2.splat (local.get $x)))
    (local.set $v (i64x2.add (local.get $v) (local.get $v)))
    (i64x2.extract_lane 0 (local.get $v))
  )
)
(assert_return (invoke "tee_v128" (i64.const 21)) (i64.const 42))
(assert_return (invoke "tee_v128" (i64.const 0)) (i64.const 0))
(assert_return (invoke "tee_v128" (i64.const -3)) (i64.const -6))
(assert_return (invoke "set_v128" (i64.const 10) (i64.const 31)) (i64.const 21))
(assert_return (invoke "set_v128" (i64.const -5) (i64.const -5)) (i64.const 0))
(assert_return (invoke "v128_alias" (i64.const 3)) (i64.const 6))
(assert_return (invoke "v128_alias" (i64.const -4)) (i64.const -8))

;; The value was not produced by the last instruction, so a real copy is needed.
(module
  (func (export "set_from_local") (param $a i32) (result i32)
    (local $t i32)
    (local.set $t (local.get $a))
    (local.get $t)
  )
)
(assert_return (invoke "set_from_local" (i32.const 9)) (i32.const 9))

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

;; i64.eqz fused into br_if (brIfI64Eqz) and into if (brIfI64Nez). Values with
;; a zero low half but a non-zero high half are not zero.
(module
  (func (export "eqz_br_if") (param $a i64) (result i32)
    (block
      (br_if 0 (i64.eqz (local.get $a)))
      (return (i32.const 0))
    )
    (i32.const 1)
  )
  (func (export "eqz_if") (param $a i64) (result i32)
    (if (i64.eqz (local.get $a))
      (then (return (i32.const 1)))
    )
    (i32.const 0)
  )
  ;; Not consumed by a branch: stays a standalone i64.eqz.
  (func (export "eqz_local") (param $a i64) (result i32)
    (local $t i32)
    (local.set $t (i64.eqz (local.get $a)))
    (local.get $t)
  )
)
(assert_return (invoke "eqz_br_if" (i64.const 0)) (i32.const 1))
(assert_return (invoke "eqz_br_if" (i64.const 1)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const -1)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const 42)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const 4294967296)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const -4294967296)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const 9223372032559808512)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const -9223372036854775808)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const 9223372036854775807)) (i32.const 0))
(assert_return (invoke "eqz_br_if" (i64.const 1311768464867721216)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const 0)) (i32.const 1))
(assert_return (invoke "eqz_if" (i64.const 1)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const -1)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const 42)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const 4294967296)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const -4294967296)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const 9223372032559808512)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const -9223372036854775808)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const 9223372036854775807)) (i32.const 0))
(assert_return (invoke "eqz_if" (i64.const 1311768464867721216)) (i32.const 0))
(assert_return (invoke "eqz_local" (i64.const 0)) (i32.const 1))
(assert_return (invoke "eqz_local" (i64.const 4294967296)) (i32.const 0))
(assert_return (invoke "eqz_local" (i64.const 1)) (i32.const 0))

;; A fused i64.eqz back-edge whose loop variable steps through values with a
;; zero low half; only the last one is zero. Returns n >> 32.
(module
  (func (export "eqz_back_edge") (param $n i64) (result i64)
    (local $i i64)
    (local $count i64)
    (local.set $i (local.get $n))
    (block $break
      (loop $continue
        (local.set $count (i64.add (local.get $count) (i64.const 1)))
        (local.set $i (i64.sub (local.get $i) (i64.const 0x100000000)))
        (br_if $break (i64.eqz (local.get $i)))
        (br $continue)
      )
    )
    (local.get $count)
  )
)
(assert_return (invoke "eqz_back_edge" (i64.const 4294967296)) (i64.const 1))
(assert_return (invoke "eqz_back_edge" (i64.const 12884901888)) (i64.const 3))
(assert_return (invoke "eqz_back_edge" (i64.const 42949672960)) (i64.const 10))
