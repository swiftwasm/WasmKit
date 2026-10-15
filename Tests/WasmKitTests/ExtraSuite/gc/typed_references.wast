;; The GC proposal builds on typed function references, but a non-nullable
;; func or extern reference, and a table initializer, still need that feature
;; of its own, as in wasm-tools. The modules are binary because they could not
;; be written in text without the feature.

;; A function type with a `(ref func)` parameter.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\06\01\60\01\64\70\00") "malformed value type")

;; A function type with a `(ref extern)` parameter.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\06\01\60\01\64\6f\00") "malformed value type")

;; A funcref table with an initializer, `(table 1 funcref (ref.null func))`.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\04\09\01\40\00\70\00\01\d0\70\0b") "malformed table")

;; A non-nullable reference to a concrete type needs only GC:
;; `(type (func)) (type (func (param (ref 0))))`.
(module binary "\00\61\73\6d\01\00\00\00\01\09\02\60\00\00\60\01\64\00\00")
