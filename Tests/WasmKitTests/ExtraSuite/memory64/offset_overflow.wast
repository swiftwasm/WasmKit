;; A `memarg` offset on a 64-bit memory is a full `u64`, so `index + offset` can
;; run past the end of the address space and even wrap around it. Every such
;; access has to raise the ordinary out-of-bounds trap: the bounds check must not
;; overflow on the way to that decision, and the address must not reach a host
;; conversion that can fault.
;;
;; Each case below picks an offset whose sum with the access width wraps, which
;; is what defeats a check phrased as `index + offset + length <= ms`.

(module $mem64
  (memory i64 1)

  ;; offset + 8 wraps to 0, so a width-based check sees an in-bounds end address
  ;; for a small index while the address itself is near the top of the range.
  (func (export "load_wrapping_width") (param $i i64) (result i64)
    (i64.load offset=0xfffffffffffffff8 (local.get $i)))
  (func (export "store_wrapping_width") (param $i i64)
    (i64.store offset=0xfffffffffffffff8 (local.get $i) (i64.const 0x1234)))

  ;; offset + 1 wraps to 0 and index + offset wraps to 0 as well, so without a
  ;; guard on the wrap this reads byte 0 of the memory instead of trapping.
  (func (export "load_wrapping_address") (param $i i64) (result i32)
    (i32.load8_u offset=0xffffffffffffffff (local.get $i)))

  ;; An index at the top of the range with an ordinary offset.
  (func (export "load_index_at_max") (result i64)
    (i64.load offset=8 (i64.const 0xffffffffffffffff)))

  ;; The last in-bounds 8-byte access of a one-page memory, and the first access
  ;; that runs off its end.
  (func (export "load_last_in_bounds") (result i64)
    (i64.load offset=65528 (i64.const 0)))
  (func (export "load_first_out_of_bounds") (result i64)
    (i64.load offset=65529 (i64.const 0)))

  (func (export "store_then_load") (param $v i64) (result i64)
    (i64.store offset=16 (i64.const 8) (local.get $v))
    (i64.load offset=16 (i64.const 8)))
)

;; Byte 0 is zero, so a wrapped read that reached it would return 0 rather than trap.
(assert_trap (invoke "load_wrapping_width" (i64.const 0)) "out of bounds memory access")
(assert_trap (invoke "load_wrapping_width" (i64.const 8)) "out of bounds memory access")
(assert_trap (invoke "store_wrapping_width" (i64.const 0)) "out of bounds memory access")
(assert_trap (invoke "load_wrapping_address" (i64.const 1)) "out of bounds memory access")
(assert_trap (invoke "load_index_at_max") "out of bounds memory access")
(assert_trap (invoke "load_first_out_of_bounds") "out of bounds memory access")

;; The ordinary accesses around them still work.
(assert_return (invoke "load_last_in_bounds") (i64.const 0))
(assert_return (invoke "store_then_load" (i64.const 0x0123456789abcdef)) (i64.const 0x0123456789abcdef))

;; The same boundary on a 32-bit memory, which takes a different bounds check:
;; its index slot is zero-extended and its offset fits in `u32`, so it cannot
;; wrap, but the end of the memory still has to be respected.
(module $mem32
  (memory 1)
  (func (export "load_last_in_bounds") (result i32)
    (i32.load offset=65532 (i32.const 0)))
  (func (export "load_first_out_of_bounds") (result i32)
    (i32.load offset=65533 (i32.const 0)))
  (func (export "load_max_offset") (result i32)
    (i32.load offset=0xffffffff (i32.const 0)))
  (func (export "load_max_index") (result i32)
    (i32.load offset=0 (i32.const 0xffffffff)))
  (func (export "load8_last_in_bounds") (result i32)
    (i32.load8_u offset=65535 (i32.const 0)))
  (func (export "load8_first_out_of_bounds") (result i32)
    (i32.load8_u offset=65536 (i32.const 0)))
)

(assert_return (invoke "load_last_in_bounds") (i32.const 0))
(assert_trap (invoke "load_first_out_of_bounds") "out of bounds memory access")
(assert_trap (invoke "load_max_offset") "out of bounds memory access")
(assert_trap (invoke "load_max_index") "out of bounds memory access")
(assert_return (invoke "load8_last_in_bounds") (i32.const 0))
(assert_trap (invoke "load8_first_out_of_bounds") "out of bounds memory access")
