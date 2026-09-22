;; Expected results may omit the reference's type or value. Each of these is
;; followed by another assertion: a result form that is not fully consumed
;; used to stop the runner from reading the rest of the file.

(module
  (func $f)
  (elem declare func $f)
  (func (export "null-func") (result funcref) (ref.null func))
  (func (export "func") (result funcref) (ref.func $f))
  (func (export "one") (result i32) (i32.const 1))
)

(assert_return (invoke "null-func") (ref.null))
(assert_return (invoke "one") (i32.const 1))
(assert_return (invoke "func") (ref.func))
(assert_return (invoke "one") (i32.const 1))
