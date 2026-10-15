;; Which globals a constant expression may read. A global initializer sees the
;; globals defined before it and a segment offset sees every global, but only
;; immutable ones. The spec tests that read a mutable global import it from a
;; module that is never registered, so they fail to link before this is checked.

(module
  (global $a i32 (i32.const 3))
  (global $b i32 (i32.add (global.get $a) (i32.const 4)))
  (memory 1)
  (data (global.get $b) "\2a")
  (func (export "load") (param i32) (result i32)
    (i32.load8_u (local.get 0)))
  (func (export "b") (result i32) (global.get $b))
)
(assert_return (invoke "b") (i32.const 7))
(assert_return (invoke "load" (i32.const 7)) (i32.const 42))

(assert_invalid
  (module
    (global $m (mut i32) (i32.const 0))
    (global i32 (global.get $m)))
  "constant expression required"
)

(assert_invalid
  (module
    (global $m (mut i32) (i32.const 0))
    (memory 1)
    (data (global.get $m) ""))
  "constant expression required"
)

(assert_invalid
  (module
    (global $m (mut i32) (i32.const 0))
    (table 1 funcref)
    (elem (global.get $m) func))
  "constant expression required"
)
