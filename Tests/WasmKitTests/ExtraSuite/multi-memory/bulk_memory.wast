;; memory.fill, memory.copy and memory.init act on the memory they name. A byte
;; of memory 1 is read by copying it into memory 0, which also exercises
;; memory.copy between two memories in both directions.

(module
  (memory $m0 1)
  (memory $m1 1)
  (data (memory $m0) (i32.const 0) "\aa\bb\cc\dd")
  (data "\11\22\33\44")

  (func (export "fill-m1") (memory.fill $m1 (i32.const 0) (i32.const 0x07) (i32.const 3)))
  (func (export "copy-m0-to-m1") (memory.copy $m1 $m0 (i32.const 8) (i32.const 0) (i32.const 4)))
  (func (export "init-m1") (memory.init $m1 1 (i32.const 16) (i32.const 0) (i32.const 4)))
  (func (export "fill-m1-oob") (memory.fill $m1 (i32.const 0) (i32.const 0) (i32.const 0x1_0001)))
  (func (export "copy-m0-to-m1-oob") (memory.copy $m1 $m0 (i32.const 0xffff) (i32.const 0) (i32.const 2)))

  (func (export "m0-byte") (param i32) (result i32) (i32.load8_u (local.get 0)))
  (func (export "m1-byte") (param i32) (result i32)
    (memory.copy $m0 $m1 (i32.const 100) (local.get 0) (i32.const 1))
    (i32.load8_u (i32.const 100)))
)

(invoke "fill-m1")
(assert_return (invoke "m1-byte" (i32.const 0)) (i32.const 0x07))
(assert_return (invoke "m1-byte" (i32.const 2)) (i32.const 0x07))
(assert_return (invoke "m1-byte" (i32.const 3)) (i32.const 0))
;; Memory 0 is untouched.
(assert_return (invoke "m0-byte" (i32.const 0)) (i32.const 0xaa))

(invoke "copy-m0-to-m1")
(assert_return (invoke "m1-byte" (i32.const 8)) (i32.const 0xaa))
(assert_return (invoke "m1-byte" (i32.const 11)) (i32.const 0xdd))

(invoke "init-m1")
(assert_return (invoke "m1-byte" (i32.const 16)) (i32.const 0x11))
(assert_return (invoke "m1-byte" (i32.const 19)) (i32.const 0x44))

(assert_trap (invoke "fill-m1-oob") "out of bounds memory access")
(assert_trap (invoke "copy-m0-to-m1-oob") "out of bounds memory access")
