;; Without the GC feature, its type definitions and abstract heap types are
;; malformed. The modules are binary because they could not be written in text
;; without the feature. Every one of them decodes with the feature enabled.

;; A struct type, `(type (struct))`.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\03\01\5f\00") "malformed function type")

;; A recursion group, `(rec (type (func)))`.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\06\01\4e\01\60\00\00") "malformed function type")

;; A non-final subtype, `(type (sub (func)))`.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\06\01\50\00\60\00\00") "malformed function type")

;; A function type with an anyref parameter.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\05\01\60\01\6e\00") "malformed value type")

;; A function type with a `(ref null none)` parameter, in its long form.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\06\01\60\01\63\71\00") "malformed value type")

;; A function doing `ref.null any`.
(assert_malformed
  (module binary
    "\00\61\73\6d\01\00\00\00"
    "\01\04\01\60\00\00"                ;; (type (func))
    "\03\02\01\00"                      ;; (func (type 0))
    "\0a\07\01\05\00\d0\6e\1a\0b"       ;; ref.null any, drop
  )
  "malformed heap type"
)

;; A function with a block of type anyref.
(assert_malformed
  (module binary
    "\00\61\73\6d\01\00\00\00"
    "\01\04\01\60\00\00"                ;; (type (func))
    "\03\02\01\00"                      ;; (func (type 0))
    "\0a\09\01\07\00\02\6e\00\0b\1a\0b"  ;; (block (result anyref) unreachable), drop
  )
  "malformed block type"
)
