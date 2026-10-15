;; A value of a subtype can be used where its supertype is expected, and it then
;; has the expected type: after `br_if`, and as a block parameter, the value on
;; the stack has the label's type even if it came from a local, so it no longer
;; matches the more precise type it had.

(module
  (type $t (func (result i32)))
  (func $f (type $t) (i32.const 7))
  (elem declare func $f)

  ;; (ref $t) where funcref is expected.
  (func (export "to-funcref") (result funcref)
    (block (result funcref) (ref.func $f)))
  (func (export "typed-select") (param i32) (result funcref)
    (select (result funcref) (ref.func $f) (ref.null func) (local.get 0)))
  (func (export "block-param") (result i32)
    ref.func $f
    block (param funcref) (result funcref)
    end
    ref.is_null)
  ;; The programs rejected below, with matching types.
  (func (export "br_if-result") (param i32) (result i32)
    (local $l (ref null $t))
    (block (result (ref null $t))
      (local.set $l (br_if 0 (ref.func $f) (local.get 0)))
      (ref.null $t))
    (drop)
    (ref.is_null (local.get $l)))
  (func (export "block-param-local") (result i32)
    (local $p (ref null $t)) (local $l (ref null $t))
    (local.set $p (ref.func $f))
    (local.get $p)
    (block (param (ref null $t)) (local.set $l))
    (ref.is_null (local.get $l)))
)

(assert_return (invoke "to-funcref") (ref.func))
(assert_return (invoke "typed-select" (i32.const 1)) (ref.func))
(assert_return (invoke "typed-select" (i32.const 0)) (ref.null func))
(assert_return (invoke "block-param") (i32.const 0))
(assert_return (invoke "br_if-result" (i32.const 0)) (i32.const 0))
(assert_return (invoke "br_if-result" (i32.const 1)) (i32.const 1))
(assert_return (invoke "block-param-local") (i32.const 0))

;; After br_if, the value has the label type funcref, not (ref $t).
(assert_invalid
  (module
    (type $t (func (result i32)))
    (func $f (type $t) (i32.const 7))
    (elem declare func $f)
    (func (param i32) (local $l (ref null $t))
      (block (result funcref)
        (local.set $l (br_if 0 (ref.func $f) (local.get 0)))
        (ref.null func))
      (drop)))
  "type mismatch")
;; Likewise for a value that came from a local.
(assert_invalid
  (module
    (type $t (func (result i32)))
    (func (param $p (ref $t)) (param i32) (local $l (ref null $t))
      (block (result funcref)
        (local.set $l (br_if 0 (local.get $p) (local.get 1)))
        (ref.null func))
      (drop)))
  "type mismatch")
;; A block parameter has the parameter type.
(assert_invalid
  (module
    (type $t (func (result i32)))
    (func (param $p (ref $t)) (local $l (ref null $t))
      (local.get $p)
      (block (param funcref) (local.set $l))))
  "type mismatch")
