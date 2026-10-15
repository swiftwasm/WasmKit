;; The typed function references instructions, including the paths the
;; translator lowers differently: branches that copy values to their label
;; (a landing pad) and branches that leave `try_table` blocks.

(module
  (type $i2i (func (param i32) (result i32)))
  (type $ii2i (func (param i32 i32) (result i32)))
  ;; An explicit tag type keeps the type section in the order wast2json writes.
  (type $void (func))
  (tag $e (type $void))
  (func $inc (type $i2i) (i32.add (local.get 0) (i32.const 1)))
  (func $add (type $ii2i) (i32.add (local.get 0) (local.get 1)))
  (elem declare func $inc $add $count)

  (func (export "call_ref") (param i32) (result i32)
    (call_ref $i2i (local.get 0) (ref.func $inc)))
  (func (export "call_ref-local") (param i32) (result i32)
    (local $f (ref null $ii2i))
    (local.set $f (ref.func $add))
    (call_ref $ii2i (local.get 0) (local.get 0) (local.get $f)))
  (func (export "call_ref-null") (result i32)
    (call_ref $i2i (i32.const 0) (ref.null $i2i)))

  ;; Counts down to zero by tail calls through a reference; deep enough to
  ;; overflow the stack if the calls were not tail calls.
  (func $count (type $i2i)
    (if (result i32) (i32.eqz (local.get 0))
      (then (i32.const 0))
      (else (return_call_ref $i2i (i32.sub (local.get 0) (i32.const 1)) (ref.func $count)))))
  (func (export "return_call_ref") (param i32) (result i32)
    (return_call_ref $i2i (local.get 0) (ref.func $count)))
  (func (export "return_call_ref-null") (result i32)
    (return_call_ref $i2i (i32.const 0) (ref.null $i2i)))

  (func (export "ref.as_non_null") (result i32)
    (call_ref $i2i (i32.const 41) (ref.as_non_null (ref.func $inc))))
  (func (export "ref.as_non_null-null")
    (drop (ref.as_non_null (ref.null $i2i))))

  ;; br_on_null passes the other values to the label when it branches.
  (func (export "br_on_null") (param $null i32) (result i32 i32)
    (local $f (ref null $i2i))
    (if (i32.eqz (local.get $null)) (then (local.set $f (ref.func $inc))))
    (block $l (result i32 i32)
      (i32.const 10) (i32.const 20)
      (br_on_null $l (local.get $f))
      ;; Not null: call it on the second value.
      (call_ref $i2i)))
  ;; br_on_non_null passes the other values and the reference.
  (func (export "br_on_non_null") (param $null i32) (result i32)
    (local $f (ref null $i2i))
    (if (i32.eqz (local.get $null)) (then (local.set $f (ref.func $inc))))
    (block $l (result i32 (ref $i2i))
      (i32.const 5)
      (br_on_non_null $l (local.get $f))
      ;; Null: the reference is dropped.
      (return (i32.const -1)))
    (call_ref $i2i))
  ;; The same, leaving a try_table on the way to the label. The throw after the
  ;; branch must not be caught by the handler of the try_table left behind.
  (func (export "br_on_null-try_table") (param $null i32) (result i32)
    (local $f (ref null $i2i))
    (if (i32.eqz (local.get $null)) (then (local.set $f (ref.func $inc))))
    (block $caught
      (drop
        (block $l (result i32)
          (try_table (result i32) (catch $e $caught)
            (i32.const 7)
            (br_on_null $l (local.get $f))
            (call_ref $i2i))))
      (throw $e))
    (i32.const -1))
  (func (export "br_on_non_null-try_table") (param $null i32) (result i32)
    (local $f (ref null $i2i))
    (if (i32.eqz (local.get $null)) (then (local.set $f (ref.func $inc))))
    (block $caught
      (drop
        (call_ref $i2i
          (block $l (result i32 (ref $i2i))
            (try_table (catch $e $caught)
              (i32.const 7)
              (br_on_non_null $l (local.get $f))
              (drop)
              (return (i32.const -2)))
            (unreachable))))
      (throw $e))
    (i32.const -1))
)

(assert_return (invoke "call_ref" (i32.const 41)) (i32.const 42))
(assert_return (invoke "call_ref-local" (i32.const 21)) (i32.const 42))
(assert_trap (invoke "call_ref-null") "null function reference")
(assert_return (invoke "return_call_ref" (i32.const 100000)) (i32.const 0))
(assert_trap (invoke "return_call_ref-null") "null function reference")
(assert_return (invoke "ref.as_non_null") (i32.const 42))
(assert_trap (invoke "ref.as_non_null-null") "null reference")
(assert_return (invoke "br_on_null" (i32.const 0)) (i32.const 10) (i32.const 21))
(assert_return (invoke "br_on_null" (i32.const 1)) (i32.const 10) (i32.const 20))
(assert_return (invoke "br_on_non_null" (i32.const 0)) (i32.const 6))
(assert_return (invoke "br_on_non_null" (i32.const 1)) (i32.const -1))
(assert_exception (invoke "br_on_null-try_table" (i32.const 1)))
(assert_exception (invoke "br_on_null-try_table" (i32.const 0)))
(assert_exception (invoke "br_on_non_null-try_table" (i32.const 0)))
(assert_return (invoke "br_on_non_null-try_table" (i32.const 1)) (i32.const -2))
