;; The proposal allows placing a custom section around the data count section,
;; but wasm-tools rejects `datacount` as a section name, so the encoder tests
;; have nothing to compare this file with.

(module
  (@custom "before-datacount" (before datacount) "")
  (@custom "after-datacount" (after datacount) "")
  (memory 1)
  (func (memory.init 0 (i32.const 0) (i32.const 0) (i32.const 0)))
  (data "")
)
