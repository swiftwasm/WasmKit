;; Results of the wide arithmetic instructions stored into locals. The
;; translator writes a result that a local.set or local.tee stores right away
;; straight into the local's register, the upper result first and then the
;; lower one. These cases check that the values stay the same wherever it
;; does so and wherever it has to keep the copies.

(module
  ;; Both results set, the upper one first, as compilers emit them.
  (func (export "set_set") (param $a i64) (param $b i64) (result i64 i64) (local $low i64) (local $high i64)
    (i64.mul_wide_s (local.get $a) (local.get $b))
    (local.set $high)
    (local.set $low)
    (local.get $low)
    (local.get $high))

  ;; The lower result teed, so it also stays on the stack.
  (func (export "set_tee") (param $a i64) (param $b i64) (result i64 i64 i64) (local $low i64) (local $high i64)
    (i64.mul_wide_u (local.get $a) (local.get $b))
    (local.set $high)
    (local.tee $low)
    (local.get $low)
    (local.get $high))

  ;; The upper result teed. The next local.set stores the teed local, which
  ;; sits above the lower result, so it must not take the lower result.
  (func (export "tee_set") (param $a i64) (param $b i64) (result i64 i64 i64) (local $high i64) (local $copy i64)
    (i64.mul_wide_u (local.get $a) (local.get $b))
    (local.tee $high)
    (local.set $copy)
    (local.get $copy)
    (local.get $high))

  ;; Both results set to the same local, which keeps the lower one.
  (func (export "same_local") (param $a i64) (param $b i64) (result i64) (local $x i64)
    (i64.mul_wide_s (local.get $a) (local.get $b))
    (local.set $x)
    (local.set $x)
    (local.get $x))

  ;; The results overwrite the locals of the operands.
  (func (export "into_operands") (param $a i64) (param $b i64) (result i64 i64)
    (i64.mul_wide_s (local.get $a) (local.get $b))
    (local.set $a)
    (local.set $b)
    (local.get $b)
    (local.get $a))

  ;; A value read from a local before the instruction stays on the stack while
  ;; a result overwrites that local.
  (func (export "earlier_read") (param $a i64) (param $b i64) (result i64 i64 i64)
    (local.get $a)
    (i64.mul_wide_u (local.get $a) (local.get $b))
    (local.set $a)
    (local.set $b)
    (local.get $b)
    (local.get $a))

  ;; The lower result consumed by another instruction after the upper one was
  ;; set.
  (func (export "set_add") (param $a i64) (param $b i64) (result i64 i64) (local $high i64)
    (i64.mul_wide_s (local.get $a) (local.get $b))
    (local.set $high)
    (i64.add (i64.const 1))
    (local.get $high))

  ;; The upper result dropped before the lower one is set.
  (func (export "drop_set") (param $a i64) (param $b i64) (result i64) (local $low i64)
    (i64.mul_wide_u (local.get $a) (local.get $b))
    (drop)
    (local.set $low)
    (local.get $low))

  ;; A constant stored between the stores of the two results.
  (func (export "set_const_set") (param $a i64) (param $b i64) (result i64 i64 i64)
    (local $low i64) (local $high i64) (local $c i64)
    (i64.mul_wide_s (local.get $a) (local.get $b))
    (local.set $high)
    (i64.const 9)
    (local.set $c)
    (local.set $low)
    (local.get $low)
    (local.get $high)
    (local.get $c))

  ;; The overflow check of a signed 64-bit multiplication, in the shape LLVM
  ;; emits when it keeps both results in locals.
  (func (export "checked_mul") (param $a i64) (param $b i64) (result i64) (local $low i64) (local $high i64)
    (block
      (i64.mul_wide_s (local.get $a) (local.get $b))
      (local.set $high)
      (local.set $low)
      (br_if 0 (i64.ne (local.get $high) (i64.shr_s (local.get $low) (i64.const 63))))
      (return (local.get $low)))
    (unreachable))

  ;; A 128-bit sum of products that keeps the products and the sum in pairs of
  ;; locals and stores both results of each instruction back into them.
  (func (export "dot") (param $n i64) (result i64 i64)
    (local $i i64) (local $low i64) (local $high i64) (local $productLow i64) (local $productHigh i64)
    (block $done
      (loop $next
        (br_if $done (i64.ge_u (local.get $i) (local.get $n)))
        (i64.mul_wide_u
          (i64.mul (local.get $i) (i64.const 0x9E3779B97F4A7C15))
          (i64.sub (i64.const -1) (local.get $i)))
        (local.set $productHigh)
        (local.set $productLow)
        (i64.add128 (local.get $low) (local.get $high) (local.get $productLow) (local.get $productHigh))
        (local.set $high)
        (local.set $low)
        (local.set $i (i64.add (local.get $i) (i64.const 1)))
        (br $next)))
    (local.get $low)
    (local.get $high))

  ;; A subtraction whose results go back into the locals of its operands.
  (func (export "sub_into_operands") (param $al i64) (param $ah i64) (param $bl i64) (param $bh i64) (result i64 i64)
    (i64.sub128 (local.get $al) (local.get $ah) (local.get $bl) (local.get $bh))
    (local.set $bl)
    (local.set $ah)
    (local.get $ah)
    (local.get $bl))

  ;; One local as every operand and as the destination of the upper result.
  (func (export "add_self") (param $x i64) (result i64 i64) (local $low i64)
    (i64.add128 (local.get $x) (local.get $x) (local.get $x) (local.get $x))
    (local.set $x)
    (local.set $low)
    (local.get $low)
    (local.get $x))

  ;; Results that leave a block, which ends the stores the translator can
  ;; rewrite.
  (func (export "block_results") (param $a i64) (param $b i64) (result i64 i64) (local $low i64) (local $high i64)
    (block (result i64 i64) (i64.mul_wide_s (local.get $a) (local.get $b)))
    (local.set $high)
    (local.set $low)
    (local.get $low)
    (local.get $high))

  ;; Results carried by a branch to a block that also receives other values.
  (func (export "branch_results") (param $a i64) (param $b i64) (param $take i32) (result i64 i64)
    (local $low i64) (local $high i64)
    (block (result i64 i64)
      (i64.mul_wide_s (local.get $a) (local.get $b))
      (br_if 0 (local.get $take))
      (drop)
      (drop)
      (i64.const 1)
      (i64.const 2))
    (local.set $high)
    (local.set $low)
    (local.get $low)
    (local.get $high))

  ;; Constant operands, which the instructions read from constant slots.
  (func (export "constants") (result i64 i64 i64 i64)
    (i64.mul_wide_u (i64.const -1) (i64.const -1))
    (i64.sub128 (i64.const 0) (i64.const 0) (i64.const 1) (i64.const 0)))

  ;; In unreachable code the instructions take operands of any type from the
  ;; polymorphic stack.
  (func (export "unreachable_operands") (result i64)
    (unreachable)
    (i64.add128)
    (i64.mul_wide_u)
    (drop))
)

(assert_return (invoke "set_set" (i64.const 0x7FFFFFFFFFFFFFFF) (i64.const 3))
  (i64.const 0x7FFFFFFFFFFFFFFD) (i64.const 1))
(assert_return (invoke "set_set" (i64.const -5) (i64.const 7)) (i64.const -35) (i64.const -1))
(assert_return (invoke "set_tee" (i64.const -5) (i64.const 7)) (i64.const -35) (i64.const -35) (i64.const 6))
(assert_return (invoke "tee_set" (i64.const -5) (i64.const 7)) (i64.const -35) (i64.const 6) (i64.const 6))
(assert_return (invoke "same_local" (i64.const -5) (i64.const 7)) (i64.const -35))
(assert_return (invoke "same_local" (i64.const 0x100000000) (i64.const 0x100000000)) (i64.const 0))
(assert_return (invoke "into_operands" (i64.const -0x8000000000000000) (i64.const -1))
  (i64.const -0x8000000000000000) (i64.const 0))
(assert_return (invoke "into_operands" (i64.const 0x7FFFFFFFFFFFFFFF) (i64.const 0x7FFFFFFFFFFFFFFF))
  (i64.const 1) (i64.const 0x3FFFFFFFFFFFFFFF))
(assert_return (invoke "earlier_read" (i64.const -5) (i64.const 7)) (i64.const -5) (i64.const -35) (i64.const 6))
(assert_return (invoke "set_add" (i64.const -5) (i64.const 7)) (i64.const -34) (i64.const -1))
(assert_return (invoke "drop_set" (i64.const -5) (i64.const 7)) (i64.const -35))
(assert_return (invoke "set_const_set" (i64.const -0x8000000000000000) (i64.const 1))
  (i64.const -0x8000000000000000) (i64.const -1) (i64.const 9))
(assert_return (invoke "checked_mul" (i64.const 3) (i64.const 5)) (i64.const 15))
(assert_return (invoke "checked_mul" (i64.const -0x8000000000000000) (i64.const 1)) (i64.const -0x8000000000000000))
(assert_return (invoke "checked_mul" (i64.const -4294967296) (i64.const 2147483648)) (i64.const -0x8000000000000000))
(assert_trap (invoke "checked_mul" (i64.const -0x8000000000000000) (i64.const -1)) "unreachable")
(assert_trap (invoke "checked_mul" (i64.const 4294967296) (i64.const 2147483648)) "unreachable")
(assert_trap (invoke "checked_mul" (i64.const 0x7FFFFFFFFFFFFFFF) (i64.const 3)) "unreachable")
(assert_return (invoke "dot" (i64.const 0)) (i64.const 0) (i64.const 0))
(assert_return (invoke "dot" (i64.const 2)) (i64.const -4354685564936845354) (i64.const -7046029254386353133))
(assert_return (invoke "dot" (i64.const 1000)) (i64.const 7895783857347671384) (i64.const -417254790617265362))
(assert_return (invoke "sub_into_operands" (i64.const 0) (i64.const 1) (i64.const 1) (i64.const 0))
  (i64.const -1) (i64.const 0))
(assert_return (invoke "sub_into_operands" (i64.const 5) (i64.const -1) (i64.const 7) (i64.const 0x7FFFFFFFFFFFFFFF))
  (i64.const -2) (i64.const 0x7FFFFFFFFFFFFFFF))
(assert_return (invoke "add_self" (i64.const -0x8000000000000000)) (i64.const 0) (i64.const 1))
(assert_return (invoke "add_self" (i64.const 0x123456789ABCDEF0))
  (i64.const 2623536934927580640) (i64.const 2623536934927580640))
(assert_return (invoke "block_results" (i64.const -5) (i64.const 7)) (i64.const -35) (i64.const -1))
(assert_return (invoke "branch_results" (i64.const -5) (i64.const 7) (i32.const 1)) (i64.const -35) (i64.const -1))
(assert_return (invoke "branch_results" (i64.const -5) (i64.const 7) (i32.const 0)) (i64.const 1) (i64.const 2))
(assert_return (invoke "constants") (i64.const 1) (i64.const -2) (i64.const -1) (i64.const -1))
(assert_trap (invoke "unreachable_operands") "unreachable")
