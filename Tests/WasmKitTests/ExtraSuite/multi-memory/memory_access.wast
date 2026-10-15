;; Loads, stores, atomics and SIMD accesses reach the memory they name. Memory
;; instructions work on the current memory, memory 0, and the translator
;; switches it around an instruction for another memory.

(module
  (memory $m0 2)
  (memory $m1 1)
  (data (memory $m0) (i32.const 0) "\01\02\03\04\05\06\07\08")
  (data (memory $m1) (i32.const 0) "\f1\f2\f3\f4\f5\f6\f7\f8")

  (func (export "load-m0") (param i32) (result i32) (i32.load8_u $m0 (local.get 0)))
  (func (export "load-m1") (param i32) (result i32) (i32.load8_u $m1 (local.get 0)))
  (func (export "i64-load-m1") (result i64) (i64.load $m1 (i32.const 0)))
  (func (export "f32-load-m1") (result f32) (f32.load $m1 offset=4 (i32.const 0)))
  (func (export "i32-load16-s-m1") (result i32) (i32.load16_s $m1 (i32.const 2)))
  (func (export "store-m1") (param i32 i32) (i32.store8 $m1 (local.get 0) (local.get 1)))
  ;; Memory 0 and memory 1 in one function, alternating.
  (func (export "swap-first-bytes")
    (local $a i32)
    (local.set $a (i32.load8_u $m0 (i32.const 0)))
    (i32.store8 $m0 (i32.const 0) (i32.load8_u $m1 (i32.const 0)))
    (i32.store8 $m1 (i32.const 0) (local.get $a)))

  ;; Growing memory 1 must leave later accesses to memory 0 on memory 0.
  (func (export "grow-m1-then-load-m0") (result i32)
    (drop (memory.grow $m1 (i32.const 1)))
    (i32.load8_u $m0 (i32.const 1)))
  (func (export "size-m1") (result i32) (memory.size $m1))

  ;; Memory 0 has two pages, memory 1 one (until grown): bounds are per memory.
  (func (export "load-m0-page-1") (result i32) (i32.load8_u $m0 (i32.const 70000)))
  (func (export "load-m1-page-1") (result i32) (i32.load8_u $m1 (i32.const 70000)))

  (func (export "atomics-m1") (result i32)
    (drop (i32.atomic.rmw.add $m1 (i32.const 8) (i32.const 5)))
    (drop (i32.atomic.rmw.cmpxchg $m1 (i32.const 8) (i32.const 5) (i32.const 9)))
    (i32.atomic.store8 $m1 (i32.const 12) (i32.const 3))
    (i32.add (i32.atomic.load $m1 (i32.const 8)) (i32.atomic.load8_u $m1 (i32.const 12))))
  (func (export "atomics-m0-untouched") (result i32) (i32.atomic.load $m0 (i32.const 8)))
  ;; A non-shared memory has no waiters to wake.
  (func (export "notify-m1") (result i32) (memory.atomic.notify $m1 (i32.const 8) (i32.const 1)))

  (func (export "simd-m1") (result i32)
    (v128.store $m1 (i32.const 16) (v128.load $m1 (i32.const 0)))
    (v128.store8_lane $m1 15 (i32.const 32) (v128.const i32x4 0 0 0 0xaa000000))
    (i32.add
      (i32.load8_u $m1 (i32.const 23))
      (i32.add
        (i8x16.extract_lane_u 5 (v128.load8_lane $m1 5 (i32.const 0) (v128.const i32x4 0 0 0 0)))
        (i32.load8_u $m1 (i32.const 32)))))
)

(assert_return (invoke "load-m0" (i32.const 0)) (i32.const 0x01))
(assert_return (invoke "load-m1" (i32.const 0)) (i32.const 0xf1))
(assert_return (invoke "i64-load-m1") (i64.const 0xf8f7f6f5f4f3f2f1))
(assert_return (invoke "f32-load-m1") (f32.const -0x1.efedeap+114))
(assert_return (invoke "i32-load16-s-m1") (i32.const -2829))

(invoke "store-m1" (i32.const 3) (i32.const 0x44))
(assert_return (invoke "load-m1" (i32.const 3)) (i32.const 0x44))
(assert_return (invoke "load-m0" (i32.const 3)) (i32.const 0x04))

(invoke "swap-first-bytes")
(assert_return (invoke "load-m0" (i32.const 0)) (i32.const 0xf1))
(assert_return (invoke "load-m1" (i32.const 0)) (i32.const 0x01))

(assert_return (invoke "load-m0-page-1") (i32.const 0))
(assert_trap (invoke "load-m1-page-1") "out of bounds memory access")
(assert_return (invoke "grow-m1-then-load-m0") (i32.const 0x02))
(assert_return (invoke "size-m1") (i32.const 2))
(assert_return (invoke "load-m1-page-1") (i32.const 0))

(assert_return (invoke "atomics-m1") (i32.const 12))
(assert_return (invoke "atomics-m0-untouched") (i32.const 0))
(assert_return (invoke "notify-m1") (i32.const 0))

(assert_return (invoke "simd-m1") (i32.const 0x1a3))

;; The same memory imported as memory 0 and memory 1: growing it through one
;; index is seen through the other.
(module $exporter (memory (export "mem") 1))
(register "exporter")
(module
  (import "exporter" "mem" (memory $a 1))
  (import "exporter" "mem" (memory $b 1))
  (func (export "grow-b-then-use-a") (result i32)
    (drop (memory.grow $b (i32.const 3)))
    (i32.store $a (i32.const 200000) (i32.const 0x12345678))
    (i32.add (memory.size $a) (i32.load $b (i32.const 200000))))
)
(assert_return (invoke "grow-b-then-use-a") (i32.const 0x1234567c))
