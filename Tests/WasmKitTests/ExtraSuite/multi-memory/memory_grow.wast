;; Growing a memory other than memory 0 leaves memory 0's accesses on memory 0.
;; The instructions access memory through registers caching memory 0's base and
;; size, which `memory.grow` of another memory used to overwrite.

(module
  (memory $m0 1)
  (memory $m1 1)
  (data (memory $m0) (i32.const 0) "\01\02")
  (data (memory $m1) (i32.const 0) "\f1\f2")
  (func (export "grow-m1-then-load-m0") (result i32)
    (drop (memory.grow $m1 (i32.const 1)))
    (i32.load8_u (i32.const 1)))
  (func (export "size-m0") (result i32) (memory.size $m0))
  (func (export "size-m1") (result i32) (memory.size $m1))
)

(assert_return (invoke "grow-m1-then-load-m0") (i32.const 0x02))
(assert_return (invoke "size-m0") (i32.const 1))
(assert_return (invoke "size-m1") (i32.const 2))
