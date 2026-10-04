;; WasmKit decodes GC types but cannot execute them yet, so it refuses every
;; module that uses a GC type definition or an abstract heap type the proposal
;; adds. Each module below is valid under the GC proposal.

;; A recursion group of one final function type is the long form of a plain
;; function type, which WasmKit runs.
(module
  (rec (type $f (func (param i32) (result i32))))
  (func (export "id") (type $f) (local.get 0))
)
(assert_return (invoke "id" (i32.const 42)) (i32.const 42))

;; Type definitions other than a final function type without supertypes.
(assert_invalid (module (type (struct))) "GC type definitions are not implemented yet")
(assert_invalid (module (type (array i8))) "GC type definitions are not implemented yet")
(assert_invalid (module (type (sub (func)))) "GC type definitions are not implemented yet")
(assert_invalid (module (type $f (sub (func))) (type (sub final $f (func)))) "GC type definitions are not implemented yet")
(assert_invalid (module (rec (type (func)) (type (func)))) "GC type definitions are not implemented yet")
(assert_invalid (module (rec)) "GC type definitions are not implemented yet")

;; An abstract heap type the proposal adds, in each place a module declares a type.
(assert_invalid (module (type (func (param anyref)))) "heap type any is not implemented yet")
(assert_invalid (module (type (func (result eqref)))) "heap type eq is not implemented yet")
(assert_invalid (module (table 1 arrayref)) "heap type array is not implemented yet")
(assert_invalid (module (table 1 funcref (ref.null nofunc))) "heap type nofunc is not implemented yet")
(assert_invalid (module (global nullref (ref.null none))) "heap type none is not implemented yet")
(assert_invalid (module (global externref (ref.null noextern))) "heap type noextern is not implemented yet")
(assert_invalid (module (elem (ref null any))) "heap type any is not implemented yet")
(assert_invalid (module (elem externref (ref.null noextern))) "heap type noextern is not implemented yet")
(assert_invalid (module (func (local nullexnref))) "heap type noexn is not implemented yet")

;; An abstract heap type the proposal adds, inside a function body.
(assert_invalid (module (func (block (result eqref) (ref.null eq)) drop)) "heap type eq is not implemented yet")
(assert_invalid (module (func (loop (result eqref) (ref.null eq)) drop)) "heap type eq is not implemented yet")
(assert_invalid
  (module (func (if (result eqref) (i32.const 0) (then (ref.null eq)) (else (ref.null eq))) drop))
  "heap type eq is not implemented yet"
)
(assert_invalid (module (func (try_table (result anyref) (ref.null any)) drop)) "heap type any is not implemented yet")
(assert_invalid
  (module (func (select (result i31ref) (ref.null i31) (ref.null i31) (i32.const 0)) drop))
  "heap type i31 is not implemented yet"
)
(assert_invalid (module (func (ref.null struct) drop)) "heap type struct is not implemented yet")
