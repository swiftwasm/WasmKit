;; br_if leaving a try_table. The landing pad must stay so that the catch
;; handler is popped on the taken path only; see br_if_landing_pad.wast for the
;; cases without exception handlers. Kept apart from that file because the WAT
;; encoder test does not enable the exception-handling proposal.

;; A br_if that leaves a try_table: the catch handler must be popped on the
;; taken path only.
(module
  (tag $e)
  (func (export "leave_try_table") (param $c i32) (result i32)
    (block $out (result i32)
      (block $h
        (try_table (catch_all $h)
          (local.get $c)
          (br_if $out (local.get $c))
          (i32.const 7)
          (br $out)
        )
        (i32.const 8)
        (br $out)
      )
      (i32.const 9)
    )
  )
)
(assert_return (invoke "leave_try_table" (i32.const 0)) (i32.const 7))
(assert_return (invoke "leave_try_table" (i32.const 5)) (i32.const 5))

;; A throw inside the try_table after the br_if was not taken: the handler
;; stack must still be balanced.
(module
  (tag $e)
  (func $thrower (throw $e))
  (func (export "throw_after_br_if") (param $c i32) (result i32)
    (block $out (result i32)
      (block $h
        (try_table (catch_all $h)
          (local.get $c)
          (br_if $out (local.get $c))
          (call $thrower)
          (i32.const 7)
          (br $out)
        )
        (i32.const 8)
        (br $out)
      )
      (i32.const 9)
    )
  )
)
;; Not taken: falls into the throw, caught by catch_all.
(assert_return (invoke "throw_after_br_if" (i32.const 0)) (i32.const 9))
;; Taken: leaves the try_table with the handler popped.
(assert_return (invoke "throw_after_br_if" (i32.const 3)) (i32.const 3))
