;; `(@name "...")` on a module, function or tag names it in the name section,
;; over its `$id`. The encoder tests compare every module here with the bytes
;; wasm-tools writes for it.

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

;; Functions and tags, defined and imported. A name without an annotation
;; still comes from the `$id`.
(module
  (type $t (func))
  (import "spectest" "print" (func (@name "imported λ") (type $t)))
  (import "spectest" "print" (func $imported (@name "imported λ2") (type $t)))
  (func (@name "λ") (type $t))
  (func $lambda (@name "λ2") (type $t))
  (func $plain (type $t))
  (func (@name "exported λ") (export "f") (type $t))
  (tag (@name "θ") (type $t))
  (tag $theta (@name "θ2") (type $t))
  (tag $plain (type $t))
  (tag (@name "exported θ") (export "t") (type $t))
)

(register "names")

;; Quoted because wasm-tools reads no `@name` on a tag import, which the spec allows.
(module quote
  "(import \"names\" \"t\" (tag (@name \"imported θ\")))"
  "(import \"names\" \"t\" (tag $imported (@name \"imported θ2\")))"
)

(assert_malformed
  (module quote "(module (func $f (@name \"a\") (@name \"b\")))")
  "unexpected token"
)
(assert_malformed
  (module quote "(module (func (export \"f\") (@name \"a\")))")
  "unexpected token"
)
(assert_malformed
  (module quote "(module (tag (@name \"a\") $t))")
  "unexpected token"
)
