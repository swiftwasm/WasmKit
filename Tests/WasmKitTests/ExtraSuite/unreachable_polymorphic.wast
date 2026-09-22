;; After `unreachable`, missing operands are polymorphic, but the results of
;; the instructions that consume them still take part in validation.

;; The call's arguments come from the polymorphic stack; its i64 result must
;; still be checked against the function's i32 result.
(assert_invalid
  (module
    (func $f (param i32) (result i64) (i64.const 0))
    (func (result i32) (unreachable) (call $f)))
  "type mismatch")
(assert_invalid
  (module
    (type $t (func (param i32) (result i64)))
    (table 1 funcref)
    (func (result i32) (unreachable) (call_indirect (type $t))))
  "type mismatch")

(module
  (func $f (param i32) (result i64) (i64.const 0))
  (type $t (func (param i32) (result i64)))
  (table 1 funcref)
  (func (export "call") (result i64) (unreachable) (call $f))
  (func (export "call_indirect") (result i64) (unreachable) (call_indirect (type $t)))
  ;; ref.is_null takes its operand from the polymorphic stack.
  (func (export "is-null") (result i32) (unreachable) (ref.is_null))
  (func (export "is-null-in-block") (result i32)
    (block (result i32) (unreachable) (ref.is_null)))
)

(assert_trap (invoke "call") "unreachable")
(assert_trap (invoke "call_indirect") "unreachable")
(assert_trap (invoke "is-null") "unreachable")
(assert_trap (invoke "is-null-in-block") "unreachable")
