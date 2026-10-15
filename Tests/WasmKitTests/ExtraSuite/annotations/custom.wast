;; `@custom` annotations become custom sections. The encoder tests compare every
;; module here with the bytes wasm-tools writes for it.

;; Content is the concatenation of the strings, which may be none.
(module (@custom "test-section" "hello"))
(module (@custom "empty"))
(module (@custom "" "data"))
(module (@custom "cat" "ab" "cd" "ef"))

;; Sections with one placement keep their source order, even with the same name.
(module
  (@custom "first" "1")
  (@custom "second" "2")
  (@custom "third" "3")
)
(module
  (@custom "dup" "a")
  (@custom "dup" "b")
  (@custom "dup" "c")
)

;; Placements around every section kind.
(module
  (@custom "after-last" (after last) "")
  (@custom "unplaced" "")
  (@custom "before-first" (before first) "")
  (@custom "before-type" (before type) "")
  (@custom "after-type" (after type) "")
  (@custom "before-import" (before import) "")
  (@custom "after-import" (after import) "")
  (@custom "before-func" (before func) "")
  (@custom "after-func" (after func) "")
  (@custom "before-table" (before table) "")
  (@custom "after-table" (after table) "")
  (@custom "before-memory" (before memory) "")
  (@custom "after-memory" (after memory) "")
  (@custom "before-global" (before global) "")
  (@custom "after-global" (after global) "")
  (@custom "before-export" (before export) "")
  (@custom "after-export" (after export) "")
  (@custom "before-start" (before start) "")
  (@custom "after-start" (after start) "")
  (@custom "before-elem" (before elem) "")
  (@custom "after-elem" (after elem) "")
  (@custom "before-code" (before code) "")
  (@custom "after-code" (after code) "")
  (@custom "before-data" (before data) "")
  (@custom "after-data" (after data) "")
  (type (func))
  (import "spectest" "print" (func))
  (table 1 funcref)
  (memory 1)
  (global i32 (i32.const 0))
  (export "f" (func $f))
  (start $f)
  (elem (i32.const 0) $f)
  (func $f (memory.init 0 (i32.const 0) (i32.const 0) (i32.const 0)))
  (data "")
)

;; A placement next to a section the module does not have still orders the
;; custom section among the others.
(module
  (@custom "after-func" (after func) "")
  (@custom "before-type" (before type) "")
)

(assert_malformed (module quote "(@custom)") "@custom annotation: missing section name")
(assert_malformed (module quote "(@custom 4)") "@custom annotation: missing section name")
(assert_malformed (module quote "(@custom bla)") "@custom annotation: missing section name")
(assert_malformed (module quote "(@custom \"x\" here)") "@custom annotation: unexpected token")
(assert_malformed (module quote "(@custom \"x\" (type))") "@custom annotation: malformed placement")
(assert_malformed (module quote "(@custom \"x\" (aft type))") "@custom annotation: malformed placement")
(assert_malformed (module quote "(@custom \"x\" (before types))") "@custom annotation: malformed section kind")
(assert_malformed (module quote "(@custom \"x\" (after first))") "@custom annotation: malformed placement")
(assert_malformed (module quote "(@custom \"x\" (before last))") "@custom annotation: malformed placement")
(assert_malformed (module quote "(func (@custom \"x\"))") "unexpected token")
