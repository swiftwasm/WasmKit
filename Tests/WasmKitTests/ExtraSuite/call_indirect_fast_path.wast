;; `call_indirect` resolves the callee on a fast path that reads the table
;; baked into the immediate and hands every other case (a trap, a callee that
;; is not compiled yet, a host callee, a callee in another instance, a frame
;; image too large to copy inline) to a slow handler that resolves again from
;; scratch.

(module
  (type $unary (func (param i32) (result i32)))
  (type $nullary (func (result i32)))
  (table 4 funcref)
  ;; Slots 0 and 3 stay null. The callees are reachable only through the
  ;; table, so under lazy compilation neither is compiled before its first
  ;; indirect call.
  (elem (i32.const 1) $double $triple)
  (func $double (type $unary) (i32.mul (local.get 0) (i32.const 2)))
  (func $triple (type $unary) (i32.mul (local.get 0) (i32.const 3)))
  (func (export "call") (param i32 i32) (result i32)
    (call_indirect (type $unary) (local.get 1) (local.get 0)))
  (func (export "call_nullary") (param i32) (result i32)
    (call_indirect (type $nullary) (local.get 0)))
  (func (export "set_triple") (param i32)
    (table.set (local.get 0) (ref.func $triple)))
  (func (export "grow_double") (result i32)
    (table.grow (ref.func $double) (i32.const 2)))
  (func (export "size") (result i32) (table.size))
)

;; The first call reaches an uncompiled callee; the second finds it compiled.
(assert_return (invoke "call" (i32.const 1) (i32.const 21)) (i32.const 42))
(assert_return (invoke "call" (i32.const 2) (i32.const 21)) (i32.const 63))
(assert_return (invoke "call" (i32.const 1) (i32.const 21)) (i32.const 42))

(assert_trap (invoke "call" (i32.const 0) (i32.const 1)) "uninitialized element")
(assert_trap (invoke "call" (i32.const 3) (i32.const 1)) "uninitialized element")
(assert_trap (invoke "call" (i32.const 4) (i32.const 1)) "undefined element")
;; Zero-extended to a large offset, not a negative one.
(assert_trap (invoke "call" (i32.const 0xFFFFFFFF) (i32.const 1)) "undefined element")
(assert_trap (invoke "call_nullary" (i32.const 1)) "indirect call type mismatch")

;; Only the table's address is baked in, not its contents: a `table.set` after
;; translation is visible to the same call site.
(assert_return (invoke "set_triple" (i32.const 1)))
(assert_return (invoke "call" (i32.const 1) (i32.const 10)) (i32.const 30))

;; `table.grow` moves the elements to a new buffer. The new slots and the ones
;; that moved are both reachable, and slots past the end still trap.
(assert_return (invoke "size") (i32.const 4))
(assert_return (invoke "grow_double") (i32.const 4))
(assert_return (invoke "size") (i32.const 6))
(assert_return (invoke "call" (i32.const 4) (i32.const 10)) (i32.const 20))
(assert_return (invoke "call" (i32.const 5) (i32.const 10)) (i32.const 20))
(assert_return (invoke "call" (i32.const 1) (i32.const 10)) (i32.const 30))
(assert_return (invoke "call" (i32.const 2) (i32.const 10)) (i32.const 30))
(assert_trap (invoke "call" (i32.const 0) (i32.const 1)) "uninitialized element")
(assert_trap (invoke "call" (i32.const 6) (i32.const 1)) "undefined element")

;; A host function in a table cannot have a guest frame laid out for it.
(module
  (type $print (func (param i32)))
  (type $unary (func (param i32) (result i32)))
  (import "spectest" "print_i32" (func $print_i32 (type $print)))
  (table 1 funcref)
  (elem (i32.const 0) $print_i32)
  (func (export "call_host") (param i32)
    (call_indirect (type $print) (local.get 0) (i32.const 0)))
  (func (export "call_host_wrong_type") (param i32) (result i32)
    (call_indirect (type $unary) (local.get 0) (i32.const 0)))
)

(assert_return (invoke "call_host" (i32.const 7)))
(assert_return (invoke "call_host" (i32.const 8)))
(assert_trap (invoke "call_host_wrong_type" (i32.const 7)) "indirect call type mismatch")

;; A callee with more locals than the fast path copies inline; its locals must
;; still start out zeroed on every call.
(module
  (type $unary (func (param i32) (result i32)))
  (table 1 funcref)
  (elem (i32.const 0) $many_locals)
  (func $many_locals (type $unary)
    (local i32 i32 i32 i32 i32 i32 i32 i32 i32 i32
           i32 i32 i32 i32 i32 i32 i32 i32 i32 i32
           i32 i32 i32 i32)
    (local.set 23 (i32.add (local.get 23) (local.get 0)))
    (local.get 23))
  (func (export "call") (param i32) (result i32)
    (call_indirect (type $unary) (local.get 0) (i32.const 0)))
)

(assert_return (invoke "call" (i32.const 5)) (i32.const 5))
(assert_return (invoke "call" (i32.const 6)) (i32.const 6))

;; Through an imported table, a callee in another instance writes into its own
;; memory; the caller's next store must go to the caller's memory and use the
;; caller's bound.
(module $callee
  (memory (export "mem") 1)
  (table (export "table") 2 funcref)
  (elem (i32.const 0) $poke $grow)
  (func $poke (result i32)
    (i32.store (i32.const 0) (i32.const 0xBBBB))
    (i32.const 1))
  ;; Grows this instance's memory, so its base and bound change inside the call.
  (func $grow (result i32)
    (i32.store (i32.const 0) (i32.const 0xCCCC))
    (drop (memory.grow (i32.const 1)))
    (i32.const 2))
  (func (export "peek") (param i32) (result i32)
    (i32.load (local.get 0)))
)
(register "callee" $callee)

;; Two pages, so 0x18000 is in bounds here and out of bounds in the callee.
(module $caller
  (type $nullary (func (result i32)))
  (import "callee" "table" (table 2 funcref))
  (memory 2)
  (func (export "storeAfterCall") (param i32) (result i32)
    (drop (call_indirect (type $nullary) (local.get 0)))
    (i32.store (i32.const 0) (i32.const 0xAAAA))
    (i32.load (i32.const 0)))
  (func (export "storeHighAfterCall") (param i32) (result i32)
    (drop (call_indirect (type $nullary) (local.get 0)))
    (i32.store (i32.const 0x18000) (i32.const 0x1234))
    (i32.load (i32.const 0x18000)))
)

(assert_return (invoke $caller "storeAfterCall" (i32.const 0)) (i32.const 0xAAAA))
(assert_return (invoke $callee "peek" (i32.const 0)) (i32.const 0xBBBB))
(assert_return (invoke $caller "storeHighAfterCall" (i32.const 0)) (i32.const 0x1234))
(assert_return (invoke $caller "storeHighAfterCall" (i32.const 1)) (i32.const 0x1234))
(assert_return (invoke $callee "peek" (i32.const 0)) (i32.const 0xCCCC))
