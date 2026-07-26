;; Extended constant expressions: i32/i64 add/sub/mul in const exprs, including a folded data-segment offset.
(module
  ;; 20*2 - 2 + 4 = 42
  (global $computed i32 (i32.add (i32.sub (i32.mul (i32.const 20) (i32.const 2)) (i32.const 2)) (i32.const 4)))
  (global $w i64 (i64.mul (i64.const 6) (i64.const 7)))   ;; 42
  (memory 1)
  (data (i32.add (i32.const 6) (i32.const 4)) "ok")        ;; offset 10
  (func (export "computed") (result i32) (global.get $computed))
  (func (export "w") (result i64) (global.get $w))
  (func (export "load") (result i32) (i32.load8_u (i32.const 10))))   ;; 'o' = 0x6f
(assert_return (invoke "computed") (i32.const 42))
(assert_return (invoke "w") (i64.const 42))
(assert_return (invoke "load") (i32.const 0x6f))

;; `global.get` of a module-defined global in a const expr is a GC-proposal relaxation, not part of extended
;; const; without GC it is invalid, so only imported globals are referenceable. Both positions are rejected:
;; a global initializer and a data-segment offset.
(assert_invalid
  (module (global $a i32 (i32.const 1)) (global $b i32 (global.get $a)))
  "constant expression required")
(assert_invalid
  (module (global $a i32 (i32.const 0)) (memory 1) (data (global.get $a) "x"))
  "constant expression required")
