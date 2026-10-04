;; `(@name "...")` on a module names it in the name section, over its `$id`.
;; The encoder tests compare every module here with the bytes wasm-tools writes
;; for it.

(module (@name "Modül"))
(module $moduel (@name "Modül"))

(assert_malformed
  (module quote "(module (@name \"M1\") (@name \"M2\"))")
  "@name annotation: multiple module names"
)
(assert_malformed
  (module quote "(module (func) (@name \"M\"))")
  "unexpected token"
)
(assert_malformed
  (module quote "(module (start $f (@name \"M\")) (func $f))")
  "unexpected token"
)
