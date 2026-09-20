;; Fuel metering inserts a `consume_fuel` instruction at the head of every region: the function
;; body, each loop, and each arm of an `if`. What these cases pin is that inserting it does not
;; disturb the peephole fusions that surround those insertion points -- fused compare-and-branch at
;; a loop back-edge, accumulator chains across an `if`, and branch landing pads -- and that the
;; results are unchanged with the meters in place.
;;
;; Scripts in this directory run metered, so the fused shapes above are exercised with meters in
;; place rather than without them, and the assertions at the end pin what they cost. The broader
;; cost table lives in fuel.wast.

(module
  (memory 1)
  (table 4 funcref)

  ;; A loop whose back-edge is a fused compare-and-branch. The meter sits between the loop label
  ;; and the body, which is precisely where a rewind would have eaten it.
  (func (export "count_down") (param $n i32) (result i32)
    (local $acc i32)
    (loop $l
      (local.set $acc (i32.add (local.get $acc) (local.get $n)))
      (local.set $n (i32.sub (local.get $n) (i32.const 1)))
      (br_if $l (i32.gt_s (local.get $n) (i32.const 0))))
    (local.get $acc))

  ;; An `if` whose condition feeds a fused branch, with both arms producing a value. Each arm is
  ;; its own region, so a meter is emitted after the conditional branch and again after the `else`
  ;; label is pinned.
  (func (export "select_branch") (param $x i32) (param $y i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $x) (local.get $y))
      (then (i32.mul (local.get $y) (i32.const 2)))
      (else (i32.sub (local.get $x) (local.get $y)))))

  ;; An `if` without an `else`, where the block type makes the implicit else path real.
  (func (export "clamp") (param $x i32) (result i32)
    (local.get $x)
    (if (param i32) (result i32) (i32.lt_s (local.get $x) (i32.const 0))
      (then (drop) (i32.const 0))))

  ;; Nested regions: a loop inside an `if` inside a loop, so meters nest and each one is restored
  ;; to its parent when the region closes.
  (func (export "nested") (param $n i32) (result i32)
    (local $total i32)
    (loop $outer
      (if (i32.rem_s (local.get $n) (i32.const 2))
        (then
          (local.set $total (i32.add (local.get $total) (i32.const 1)))
          (block $inner
            (loop $spin
              (br_if $inner (i32.eqz (local.get $total)))
              (br $inner)))))
      (local.set $n (i32.sub (local.get $n) (i32.const 1)))
      (br_if $outer (i32.gt_s (local.get $n) (i32.const 0))))
    (local.get $total))

  ;; Unreachable code after a branch: the translator emits nothing for it, and the meter of the
  ;; enclosing region must not be disturbed by the operators it skips.
  (func (export "dead_code") (result i32)
    (block $b (result i32)
      (i32.const 7)
      (br $b)
      (drop)
      (i32.const 8))
    )

  ;; Bulk operations, charged at run time by their handlers rather than by a meter.
  (func (export "bulk") (result i32)
    (memory.fill (i32.const 0) (i32.const 0xAB) (i32.const 200))
    (memory.copy (i32.const 256) (i32.const 0) (i32.const 200))
    (i32.load8_u (i32.const 300)))

  (func $one (result i32) (i32.const 1))
  (elem (i32.const 0) $one)

  ;; A call inside a metered loop: the callee's own body meter is charged on every call.
  (func (export "call_in_loop") (param $n i32) (result i32)
    (local $acc i32)
    (loop $l
      (local.set $acc (i32.add (local.get $acc) (call $one)))
      (local.set $n (i32.sub (local.get $n) (i32.const 1)))
      (br_if $l (local.get $n)))
    (local.get $acc))
)

(assert_return (invoke "count_down" (i32.const 4)) (i32.const 10))
(assert_return (invoke "count_down" (i32.const 1)) (i32.const 1))
(assert_return (invoke "count_down" (i32.const 0)) (i32.const 0))

(assert_return (invoke "select_branch" (i32.const 1) (i32.const 5)) (i32.const 10))
(assert_return (invoke "select_branch" (i32.const 5) (i32.const 1)) (i32.const 4))

(assert_return (invoke "clamp" (i32.const 7)) (i32.const 7))
(assert_return (invoke "clamp" (i32.const -7)) (i32.const 0))

(assert_return (invoke "nested" (i32.const 5)) (i32.const 3))
(assert_return (invoke "nested" (i32.const 1)) (i32.const 1))

(assert_return (invoke "dead_code") (i32.const 7))

(assert_return (invoke "bulk") (i32.const 0xAB))

(assert_return (invoke "call_in_loop" (i32.const 3)) (i32.const 3))

;; count_down's body region prices only the trailing `local.get $acc`; its loop region prices the
;; twelve operators of the body, charged once per iteration.
(assert_fuel 13 (invoke "count_down" (i32.const 1)))
(assert_fuel 49 (invoke "count_down" (i32.const 4)))

;; Entry region: local.get + local.get + lt_s + if = 4. The `then` arm prices local.get + const +
;; mul = 3, the `else` arm local.get + local.get + sub = 3.
(assert_fuel 7 (invoke "select_branch" (i32.const 1) (i32.const 5)))
(assert_fuel 7 (invoke "select_branch" (i32.const 5) (i32.const 1)))
