;; Calls and returns that cross a module instance boundary must switch the
;; current linear memory (base and bound) to the callee's instance on the way
;; in and back to the caller's on the way out. A stale base sends the caller's
;; stores into the callee's memory; a stale bound traps a store that is in
;; bounds for the caller.

;; The callee: its own one-page memory plus functions a caller in another
;; instance invokes.
(module $callee
  (memory (export "mem") 1)
  ;; Writes a marker into this instance's memory.
  (func (export "poke")
    (i32.store (i32.const 0) (i32.const 0xBBBB)))
  ;; Grows this instance's memory, so its bound changes too.
  (func (export "grow") (result i32)
    (memory.grow (i32.const 1)))
  ;; Reads this instance's memory from a fresh invocation.
  (func (export "peek") (param $addr i32) (result i32)
    (i32.load (local.get $addr)))
)
(register "callee" $callee)

;; The caller: a two-page memory, so a store past the callee's one-page memory
;; is in bounds here and out of bounds there.
(module $caller
  (import "callee" "poke" (func $poke))
  (import "callee" "grow" (func $grow (result i32)))
  (memory (export "mem") 2)
  ;; After the cross-instance call returns, this store must land in this
  ;; instance's memory.
  (func (export "storeAfterCall") (result i32)
    (call $poke)
    (i32.store (i32.const 0) (i32.const 0xAAAA))
    (i32.load (i32.const 0)))
  ;; Offset 0x18000 (96 KiB) is in bounds for a two-page memory and out of
  ;; bounds for the callee's one-page memory, so a stale bound traps.
  (func (export "storeHighAfterCall") (result i32)
    (call $poke)
    (i32.store (i32.const 0x18000) (i32.const 0x1234))
    (i32.load (i32.const 0x18000)))
  ;; Same, but the callee grew its own memory during the call, so both its
  ;; base and its bound changed inside the callee.
  (func (export "storeHighAfterGrowingCall") (result i32)
    (drop (call $grow))
    (i32.store (i32.const 0x18000) (i32.const 0x5678))
    (i32.load (i32.const 0x18000)))
  (func (export "peek") (param $addr i32) (result i32)
    (i32.load (local.get $addr)))
)

;; The caller's store lands in the caller's memory and leaves the callee's
;; marker alone.
(assert_return (invoke $caller "storeAfterCall") (i32.const 0xAAAA))
(assert_return (invoke $caller "peek" (i32.const 0)) (i32.const 0xAAAA))
(assert_return (invoke $callee "peek" (i32.const 0)) (i32.const 0xBBBB))

;; The bound comes back to the caller's too.
(assert_return (invoke $caller "storeHighAfterCall") (i32.const 0x1234))
(assert_return (invoke $caller "peek" (i32.const 0x18000)) (i32.const 0x1234))

;; Same when the callee grew its own memory during the call.
(assert_return (invoke $caller "storeHighAfterGrowingCall") (i32.const 0x5678))
(assert_return (invoke $caller "peek" (i32.const 0x18000)) (i32.const 0x5678))
