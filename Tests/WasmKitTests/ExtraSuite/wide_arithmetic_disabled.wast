;; Without the wide-arithmetic feature, each instruction of the proposal makes
;; its module invalid, also where it cannot be reached. Every module is valid
;; with the feature enabled.

(assert_invalid
  (module (func (param i64 i64 i64 i64) (result i64 i64)
    (i64.add128 (local.get 0) (local.get 1) (local.get 2) (local.get 3))))
  "requires the wide-arithmetic feature")
(assert_invalid
  (module (func (param i64 i64 i64 i64) (result i64 i64)
    (i64.sub128 (local.get 0) (local.get 1) (local.get 2) (local.get 3))))
  "requires the wide-arithmetic feature")
(assert_invalid
  (module (func (param i64 i64) (result i64 i64)
    (i64.mul_wide_s (local.get 0) (local.get 1))))
  "requires the wide-arithmetic feature")
(assert_invalid
  (module (func (param i64 i64) (result i64 i64)
    (i64.mul_wide_u (local.get 0) (local.get 1))))
  "requires the wide-arithmetic feature")
(assert_invalid
  (module (func (result i64 i64)
    (unreachable)
    (i64.mul_wide_u)))
  "requires the wide-arithmetic feature")
