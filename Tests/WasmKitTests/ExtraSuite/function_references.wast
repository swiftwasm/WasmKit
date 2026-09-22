;; The typed function references proposal is not implemented yet. Its
;; instructions must be rejected rather than translated as no-ops. Each module
;; below stays valid if the instruction is dropped, so only the explicit
;; rejection makes it invalid.

(assert_invalid
  (module
    (type $t (func (result i32)))
    (func (param (ref null $t))
      (drop (call_ref $t (local.get 0)))))
  "call_ref is not implemented yet")

(assert_invalid
  (module
    (type $t (func (result i32)))
    (func (param (ref null $t)) (result i32)
      (return_call_ref $t (local.get 0))
      (unreachable)))
  "return_call_ref is not implemented yet")

(assert_invalid
  (module
    (type $t (func (result i32)))
    (func (param (ref null $t))
      (drop (ref.as_non_null (local.get 0)))))
  "ref.as_non_null is not implemented yet")

(assert_invalid
  (module
    (type $t (func (result i32)))
    (func (param (ref null $t))
      (block (drop (br_on_null 0 (local.get 0))))))
  "br_on_null is not implemented yet")

(assert_invalid
  (module
    (type $t (func (result i32)))
    (func (param (ref null $t))
      (drop
        (block (result (ref $t))
          (br_on_non_null 0 (local.get 0))
          (return)))))
  "br_on_non_null is not implemented yet")
