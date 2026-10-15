;; Every way a guest can run forever must stop against a budget rather than hang.
;;
;; `(assert_out_of_fuel N (invoke "f"))` gives the store N units, runs the action, and requires it
;; to trap with the out-of-fuel reason -- not merely to trap, so a case that dies of something else
;; (an out-of-bounds access, a stack overflow) is a failure rather than a false pass. The module
;; form does the same for instantiation, which is where a runaway start function shows up.
;;
;; This is the property an embedder relies on, so the catalogue is deliberately exhaustive about
;; the shapes: each kind of back-edge, each kind of call, and the one shape that reuses its frame.
;; Wasmtime keeps the same catalogue in tests/all/fuel.rs (`iloop`).

(module
  ;; Back-edges of every kind.
  (func (export "br") (loop $l (br $l)))
  (func (export "br_if") (loop $l (br_if $l (i32.const 1))))
  (func (export "br_table") (loop $l (br_table $l (i32.const 0))))

  ;; A loop whose body is made only of operators priced at zero. The back-edge itself is what
  ;; stops it: if a branch were ever priced at zero, this case would hang instead of failing.
  (func (export "free_operators") (loop $l (nop) (nop) (br $l)))

  ;; Recursion: bounded by the callee's own entry charge rather than by a back-edge.
  (func $recurse (call $recurse))
  (func (export "recursion") (call $recurse))

  ;; The same through a table, where the callee is not known at translation time.
  (type $v (func))
  (table 1 funcref)
  (elem (i32.const 0) $indirect)
  (func $indirect (call_indirect (type $v) (i32.const 0)))
  (func (export "call_indirect") (call $indirect))

  ;; A tail call reuses the caller's frame, so this never exhausts the stack and would spin
  ;; forever on its own. Only the callee's entry charge stops it.
  (func $tail (return_call $tail))
  (func (export "tail_call") (call $tail))

  ;; Nested loops: the inner one never returns to the outer.
  (func (export "nested_loops")
    (loop $outer
      (loop $inner (br $inner))
      (br $outer)))

  ;; Not a loop at all: a finite program whose cost is exponential in its size, 2^16 calls from
  ;; 17 functions. A budget has to stop it even though nothing repeats.
  (func $f0 (call $f1) (call $f1))
  (func $f1 (call $f2) (call $f2))
  (func $f2 (call $f3) (call $f3))
  (func $f3 (call $f4) (call $f4))
  (func $f4 (call $f5) (call $f5))
  (func $f5 (call $f6) (call $f6))
  (func $f6 (call $f7) (call $f7))
  (func $f7 (call $f8) (call $f8))
  (func $f8 (call $f9) (call $f9))
  (func $f9 (call $f10) (call $f10))
  (func $f10 (call $f11) (call $f11))
  (func $f11 (call $f12) (call $f12))
  (func $f12 (call $f13) (call $f13))
  (func $f13 (call $f14) (call $f14))
  (func $f14 (call $f15) (call $f15))
  (func $f15 (call $f16) (call $f16))
  (func $f16)
  (func (export "call_tree") (call $f0))

  ;; A guest that does something expensive rather than something endless: copying a megabyte at a
  ;; time, charged per byte, so a budget bounds the work and not just the operator count.
  (memory 32)
  (func (export "bulk_copy")
    (loop $l
      (memory.copy (i32.const 0) (i32.const 1048576) (i32.const 1048576))
      (br $l)))
)

(assert_out_of_fuel 10000 (invoke "br"))
(assert_out_of_fuel 10000 (invoke "br_if"))
(assert_out_of_fuel 10000 (invoke "br_table"))
(assert_out_of_fuel 10000 (invoke "free_operators"))
;; These two grow the call stack, so their budgets are kept well under what the stack allows:
;; with a large budget they die of "call stack exhausted" first, which would pass an `assert_trap`
;; while proving nothing about fuel.
(assert_out_of_fuel 100 (invoke "recursion"))
(assert_out_of_fuel 100 (invoke "call_indirect"))
(assert_out_of_fuel 10000 (invoke "tail_call"))
(assert_out_of_fuel 10000 (invoke "nested_loops"))
(assert_out_of_fuel 10000 (invoke "call_tree"))
(assert_out_of_fuel 10000 (invoke "bulk_copy"))

;; A budget of zero stops a guest before it runs a single region.
(assert_out_of_fuel 0 (invoke "br"))

;; A start function that never returns would otherwise hang the embedder at instantiation, before
;; it holds a function to call at all.
(assert_out_of_fuel 1000 (module (func $s (loop $l (br $l))) (start $s)))

;; The budget also covers a start function that is merely expensive.
(assert_out_of_fuel 100 (module
  (memory 4)
  (func $s (memory.fill (i32.const 0) (i32.const 1) (i32.const 262144)))
  (start $s)))
