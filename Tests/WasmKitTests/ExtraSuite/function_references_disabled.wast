;; Without the function-references feature, typed reference types are
;; malformed and the proposal's instructions are invalid. The modules are
;; binary because they could not be written in text without the feature.
;; Every one of them is valid with the feature enabled.

;; A function type with a (ref func) parameter.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\06\01\60\01\64\70\00") "malformed value type")

;; A function type with a (ref null $t) parameter.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\01\09\02\60\00\00\60\01\63\00\00") "malformed value type")

;; A funcref table with an initializer, `(table 1 funcref (ref.null func))`.
(assert_malformed (module binary "\00\61\73\6d\01\00\00\00\04\09\01\40\00\70\00\01\d0\70\0b") "malformed table")

;; 0x63 followed by an abstract heap type is only the long form of funcref.
(module binary "\00\61\73\6d\01\00\00\00\01\06\01\60\01\63\70\00")

;; An exported function using call_ref.
(assert_invalid (module binary "\00\61\73\6d\01\00\00\00\01\04\01\60\00\00\03\02\01\00\07\05\01\01\66\00\00\0a\08\01\06\00\d2\00\14\00\0b") "requires the function-references feature")

;; An exported function using return_call_ref.
(assert_invalid (module binary "\00\61\73\6d\01\00\00\00\01\04\01\60\00\00\03\02\01\00\07\05\01\01\66\00\00\0a\08\01\06\00\d2\00\15\00\0b") "requires the function-references feature")

;; An exported function using ref.as_non_null.
(assert_invalid (module binary "\00\61\73\6d\01\00\00\00\01\04\01\60\00\00\03\02\01\00\07\05\01\01\66\00\00\0a\08\01\06\00\d2\00\d4\1a\0b") "requires the function-references feature")

;; An exported function using br_on_null.
(assert_invalid (module binary "\00\61\73\6d\01\00\00\00\01\04\01\60\00\00\03\02\01\00\07\05\01\01\66\00\00\0a\0c\01\0a\00\02\40\d2\00\d5\00\1a\0b\0b") "requires the function-references feature")

;; An exported function using br_on_non_null.
(assert_invalid (module binary "\00\61\73\6d\01\00\00\00\01\04\01\60\00\00\03\02\01\00\07\05\01\01\66\00\00\0a\0e\01\0c\00\02\70\d2\00\d6\00\d0\70\0b\1a\0b") "requires the function-references feature")
