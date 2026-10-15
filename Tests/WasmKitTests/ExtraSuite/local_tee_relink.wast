;; local.tee / local.set result relinking: the producer writes the local's slot
;; directly instead of going through a copy.

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

