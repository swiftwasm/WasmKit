;; An empty `else` means the same as none, so the encoder leaves it out in the
;; flat form as in the folded one. EncoderTests compares the bytes with wast2json,
;; which does the same.

(module
  (func (export "flat") (param i32) (result i32)
    (local.get 0)
    (if (param i32) (result i32) (local.get 0)
      (then (i32.const 1) (i32.add)))
    (local.get 0)
    if (param i32) (result i32)
      i32.const 10
      i32.add
    else
    end)

  (func (export "flat-label") (param i32) (result i32)
    (local.get 0)
    (local.get 0)
    if $l (param i32) (result i32)
      br $l
    else $l
    end $l)

  (func (export "folded") (param i32) (result i32)
    (local.get 0)
    (if (param i32) (result i32) (local.get 0)
      (then (i32.const 100) (i32.add))
      (else)))
)

(assert_return (invoke "flat" (i32.const 0)) (i32.const 0))
(assert_return (invoke "flat" (i32.const 1)) (i32.const 12))
(assert_return (invoke "flat-label" (i32.const 5)) (i32.const 5))
(assert_return (invoke "flat-label" (i32.const 0)) (i32.const 0))
(assert_return (invoke "folded" (i32.const 0)) (i32.const 0))
(assert_return (invoke "folded" (i32.const 2)) (i32.const 102))
