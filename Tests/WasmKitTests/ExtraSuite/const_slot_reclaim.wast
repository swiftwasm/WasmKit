;; GENERATED FILE, DO NOT EDIT. Regenerate with:
;;   python3 Tests/WasmKitTests/ExtraSuite/const_slot_reclaim.gen.py > Tests/WasmKitTests/ExtraSuite/const_slot_reclaim.wast

(module
  (func $identity (param i64) (result i64) local.get 0)
  ;; Every constant is an immediate, so none is ever allocated.
  (func (export "add") (param i64) (result i64)
    local.get 0 i64.const 1 i64.add local.set 0
    local.get 0 i64.const 2 i64.add local.set 0
    local.get 0 i64.const 3 i64.add local.set 0
    local.get 0 i64.const 4 i64.add local.set 0
    local.get 0 i64.const 5 i64.add local.set 0
    local.get 0 i64.const 6 i64.add local.set 0
    local.get 0 i64.const 7 i64.add local.set 0
    local.get 0 i64.const 8 i64.add local.set 0
    local.get 0 i64.const 9 i64.add local.set 0
    local.get 0 i64.const 10 i64.add local.set 0
    local.get 0 i64.const 11 i64.add local.set 0
    local.get 0 i64.const 12 i64.add local.set 0
    local.get 0 i64.const 13 i64.add local.set 0
    local.get 0 i64.const 14 i64.add local.set 0
    local.get 0 i64.const 15 i64.add local.set 0
    local.get 0 i64.const 16 i64.add local.set 0
    local.get 0 i64.const 17 i64.add local.set 0
    local.get 0 i64.const 18 i64.add local.set 0
    local.get 0 i64.const 19 i64.add local.set 0
    local.get 0 i64.const 20 i64.add local.set 0
    local.get 0 i64.const 21 i64.add local.set 0
    local.get 0 i64.const 22 i64.add local.set 0
    local.get 0 i64.const 23 i64.add local.set 0
    local.get 0 i64.const 24 i64.add local.set 0
    local.get 0 i64.const 25 i64.add local.set 0
    local.get 0 i64.const 26 i64.add local.set 0
    local.get 0 i64.const 27 i64.add local.set 0
    local.get 0 i64.const 28 i64.add local.set 0
    local.get 0 i64.const 29 i64.add local.set 0
    local.get 0 i64.const 30 i64.add local.set 0
    local.get 0 i64.const 31 i64.add local.set 0
    local.get 0 i64.const 32 i64.add local.set 0
    local.get 0 i64.const 33 i64.add local.set 0
    local.get 0 i64.const 34 i64.add local.set 0
    local.get 0 i64.const 35 i64.add local.set 0
    local.get 0 i64.const 36 i64.add local.set 0
    local.get 0 i64.const 37 i64.add local.set 0
    local.get 0 i64.const 38 i64.add local.set 0
    local.get 0 i64.const 39 i64.add local.set 0
    local.get 0 i64.const 40 i64.add local.set 0
    local.get 0)
  ;; Constants left on the stack across the reclaims.
  (func (export "live") (param i64) (result i64 i64 i64)
    i64.const 1234567890123
    i64.const 9876543210123 call $identity
    local.get 0 i64.const 1 i64.add local.set 0
    local.get 0 i64.const 2 i64.add local.set 0
    local.get 0 i64.const 3 i64.add local.set 0
    local.get 0 i64.const 4 i64.add local.set 0
    local.get 0 i64.const 5 i64.add local.set 0
    local.get 0 i64.const 6 i64.add local.set 0
    local.get 0 i64.const 7 i64.add local.set 0
    local.get 0 i64.const 8 i64.add local.set 0
    local.get 0 i64.const 9 i64.add local.set 0
    local.get 0 i64.const 10 i64.add local.set 0
    local.get 0 i64.const 11 i64.add local.set 0
    local.get 0 i64.const 12 i64.add local.set 0
    local.get 0 i64.const 13 i64.add local.set 0
    local.get 0 i64.const 14 i64.add local.set 0
    local.get 0 i64.const 15 i64.add local.set 0
    local.get 0 i64.const 16 i64.add local.set 0
    local.get 0 i64.const 17 i64.add local.set 0
    local.get 0 i64.const 18 i64.add local.set 0
    local.get 0 i64.const 19 i64.add local.set 0
    local.get 0 i64.const 20 i64.add local.set 0
    local.get 0 i64.const 21 i64.add local.set 0
    local.get 0 i64.const 22 i64.add local.set 0
    local.get 0 i64.const 23 i64.add local.set 0
    local.get 0 i64.const 24 i64.add local.set 0
    local.get 0 i64.const 25 i64.add local.set 0
    local.get 0 i64.const 26 i64.add local.set 0
    local.get 0 i64.const 27 i64.add local.set 0
    local.get 0 i64.const 28 i64.add local.set 0
    local.get 0 i64.const 29 i64.add local.set 0
    local.get 0 i64.const 30 i64.add local.set 0
    local.get 0 i64.const 31 i64.add local.set 0
    local.get 0 i64.const 32 i64.add local.set 0
    local.get 0 i64.const 33 i64.add local.set 0
    local.get 0 i64.const 34 i64.add local.set 0
    local.get 0 i64.const 35 i64.add local.set 0
    local.get 0 i64.const 36 i64.add local.set 0
    local.get 0 i64.const 37 i64.add local.set 0
    local.get 0 i64.const 38 i64.add local.set 0
    local.get 0 i64.const 39 i64.add local.set 0
    local.get 0 i64.const 40 i64.add local.set 0
    local.get 0)
  ;; A stack too deep to scan: the constants spill instead.
  (func (export "deep") (param i64) (result i64)
    i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 
    local.get 0 i64.const 1 i64.add local.set 0
    local.get 0 i64.const 2 i64.add local.set 0
    local.get 0 i64.const 3 i64.add local.set 0
    local.get 0 i64.const 4 i64.add local.set 0
    local.get 0 i64.const 5 i64.add local.set 0
    local.get 0 i64.const 6 i64.add local.set 0
    local.get 0 i64.const 7 i64.add local.set 0
    local.get 0 i64.const 8 i64.add local.set 0
    local.get 0 i64.const 9 i64.add local.set 0
    local.get 0 i64.const 10 i64.add local.set 0
    local.get 0 i64.const 11 i64.add local.set 0
    local.get 0 i64.const 12 i64.add local.set 0
    local.get 0 i64.const 13 i64.add local.set 0
    local.get 0 i64.const 14 i64.add local.set 0
    local.get 0 i64.const 15 i64.add local.set 0
    local.get 0 i64.const 16 i64.add local.set 0
    local.get 0 i64.const 17 i64.add local.set 0
    local.get 0 i64.const 18 i64.add local.set 0
    local.get 0 i64.const 19 i64.add local.set 0
    local.get 0 i64.const 20 i64.add local.set 0
    local.get 0 i64.const 21 i64.add local.set 0
    local.get 0 i64.const 22 i64.add local.set 0
    local.get 0 i64.const 23 i64.add local.set 0
    local.get 0 i64.const 24 i64.add local.set 0
    local.get 0 i64.const 25 i64.add local.set 0
    local.get 0 i64.const 26 i64.add local.set 0
    local.get 0 i64.const 27 i64.add local.set 0
    local.get 0 i64.const 28 i64.add local.set 0
    local.get 0 i64.const 29 i64.add local.set 0
    local.get 0 i64.const 30 i64.add local.set 0
    local.get 0 i64.const 31 i64.add local.set 0
    local.get 0 i64.const 32 i64.add local.set 0
    local.get 0 i64.const 33 i64.add local.set 0
    local.get 0 i64.const 34 i64.add local.set 0
    local.get 0 i64.const 35 i64.add local.set 0
    local.get 0 i64.const 36 i64.add local.set 0
    local.get 0 i64.const 37 i64.add local.set 0
    local.get 0 i64.const 38 i64.add local.set 0
    local.get 0 i64.const 39 i64.add local.set 0
    local.get 0 i64.const 40 i64.add local.set 0
    drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop drop 
    local.get 0)
  ;; A stack too deep to scan, but below the current frame, which reclaims.
  (func (export "deep-below-block") (param i64) (result i64)
    i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 i64.const 0 
    block (result i64)
      local.get 0 i64.const 1 i64.add local.set 0
      local.get 0 i64.const 2 i64.add local.set 0
      local.get 0 i64.const 3 i64.add local.set 0
      local.get 0 i64.const 4 i64.add local.set 0
      local.get 0 i64.const 5 i64.add local.set 0
      local.get 0 i64.const 6 i64.add local.set 0
      local.get 0 i64.const 7 i64.add local.set 0
      local.get 0 i64.const 8 i64.add local.set 0
      local.get 0 i64.const 9 i64.add local.set 0
      local.get 0 i64.const 10 i64.add local.set 0
      local.get 0 i64.const 11 i64.add local.set 0
      local.get 0 i64.const 12 i64.add local.set 0
      local.get 0 i64.const 13 i64.add local.set 0
      local.get 0 i64.const 14 i64.add local.set 0
      local.get 0 i64.const 15 i64.add local.set 0
      local.get 0 i64.const 16 i64.add local.set 0
      local.get 0 i64.const 17 i64.add local.set 0
      local.get 0 i64.const 18 i64.add local.set 0
      local.get 0 i64.const 19 i64.add local.set 0
      local.get 0 i64.const 20 i64.add local.set 0
      local.get 0 i64.const 21 i64.add local.set 0
      local.get 0 i64.const 22 i64.add local.set 0
      local.get 0 i64.const 23 i64.add local.set 0
      local.get 0 i64.const 24 i64.add local.set 0
      local.get 0 i64.const 25 i64.add local.set 0
      local.get 0 i64.const 26 i64.add local.set 0
      local.get 0 i64.const 27 i64.add local.set 0
      local.get 0 i64.const 28 i64.add local.set 0
      local.get 0 i64.const 29 i64.add local.set 0
      local.get 0 i64.const 30 i64.add local.set 0
      local.get 0 i64.const 31 i64.add local.set 0
      local.get 0 i64.const 32 i64.add local.set 0
      local.get 0 i64.const 33 i64.add local.set 0
      local.get 0 i64.const 34 i64.add local.set 0
      local.get 0 i64.const 35 i64.add local.set 0
      local.get 0 i64.const 36 i64.add local.set 0
      local.get 0 i64.const 37 i64.add local.set 0
      local.get 0 i64.const 38 i64.add local.set 0
      local.get 0 i64.const 39 i64.add local.set 0
      local.get 0 i64.const 40 i64.add local.set 0
      local.get 0
    end
    i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add i64.add )
  ;; A constant materialized on block entry, then reclaims inside the block.
  (func (export "branch") (param i64 i32) (result i64 i64)
    i64.const 1234567890123
    local.get 1 if
      local.get 0 i64.const 1 i64.add local.set 0
      local.get 0 i64.const 2 i64.add local.set 0
      local.get 0 i64.const 3 i64.add local.set 0
      local.get 0 i64.const 4 i64.add local.set 0
      local.get 0 i64.const 5 i64.add local.set 0
      local.get 0 i64.const 6 i64.add local.set 0
      local.get 0 i64.const 7 i64.add local.set 0
      local.get 0 i64.const 8 i64.add local.set 0
      local.get 0 i64.const 9 i64.add local.set 0
      local.get 0 i64.const 10 i64.add local.set 0
      local.get 0 i64.const 11 i64.add local.set 0
      local.get 0 i64.const 12 i64.add local.set 0
      local.get 0 i64.const 13 i64.add local.set 0
      local.get 0 i64.const 14 i64.add local.set 0
      local.get 0 i64.const 15 i64.add local.set 0
      local.get 0 i64.const 16 i64.add local.set 0
      local.get 0 i64.const 17 i64.add local.set 0
      local.get 0 i64.const 18 i64.add local.set 0
      local.get 0 i64.const 19 i64.add local.set 0
      local.get 0 i64.const 20 i64.add local.set 0
      local.get 0 i64.const 21 i64.add local.set 0
      local.get 0 i64.const 22 i64.add local.set 0
      local.get 0 i64.const 23 i64.add local.set 0
      local.get 0 i64.const 24 i64.add local.set 0
      local.get 0 i64.const 25 i64.add local.set 0
      local.get 0 i64.const 26 i64.add local.set 0
      local.get 0 i64.const 27 i64.add local.set 0
      local.get 0 i64.const 28 i64.add local.set 0
      local.get 0 i64.const 29 i64.add local.set 0
      local.get 0 i64.const 30 i64.add local.set 0
      local.get 0 i64.const 31 i64.add local.set 0
      local.get 0 i64.const 32 i64.add local.set 0
      local.get 0 i64.const 33 i64.add local.set 0
      local.get 0 i64.const 34 i64.add local.set 0
      local.get 0 i64.const 35 i64.add local.set 0
      local.get 0 i64.const 36 i64.add local.set 0
      local.get 0 i64.const 37 i64.add local.set 0
      local.get 0 i64.const 38 i64.add local.set 0
      local.get 0 i64.const 39 i64.add local.set 0
      local.get 0 i64.const 40 i64.add local.set 0
    else
      i64.const 3 local.set 0
    end
    local.get 0))

(assert_return (invoke "add" (i64.const 0)) (i64.const 820))
(assert_return (invoke "live" (i64.const 0)) (i64.const 1234567890123) (i64.const 9876543210123) (i64.const 820))
(assert_return (invoke "deep" (i64.const 0)) (i64.const 820))
(assert_return (invoke "deep-below-block" (i64.const 0)) (i64.const 820))
(assert_return (invoke "branch" (i64.const 0) (i32.const 1)) (i64.const 1234567890123) (i64.const 820))
(assert_return (invoke "branch" (i64.const 0) (i32.const 0)) (i64.const 1234567890123) (i64.const 3))
(assert_return (invoke "add" (i64.const 17)) (i64.const 837))
(assert_return (invoke "live" (i64.const 17)) (i64.const 1234567890123) (i64.const 9876543210123) (i64.const 837))
(assert_return (invoke "deep" (i64.const 17)) (i64.const 837))
(assert_return (invoke "deep-below-block" (i64.const 17)) (i64.const 837))
(assert_return (invoke "branch" (i64.const 17) (i32.const 1)) (i64.const 1234567890123) (i64.const 837))
(assert_return (invoke "branch" (i64.const 17) (i32.const 0)) (i64.const 1234567890123) (i64.const 3))
(assert_return (invoke "add" (i64.const -1)) (i64.const 819))
(assert_return (invoke "live" (i64.const -1)) (i64.const 1234567890123) (i64.const 9876543210123) (i64.const 819))
(assert_return (invoke "deep" (i64.const -1)) (i64.const 819))
(assert_return (invoke "deep-below-block" (i64.const -1)) (i64.const 819))
(assert_return (invoke "branch" (i64.const -1) (i32.const 1)) (i64.const 1234567890123) (i64.const 819))
(assert_return (invoke "branch" (i64.const -1) (i32.const 0)) (i64.const 1234567890123) (i64.const 3))
