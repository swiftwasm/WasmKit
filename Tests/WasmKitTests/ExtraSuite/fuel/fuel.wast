;; Golden costs for fuel metering, in the style of Wasmtime's tests/all/fuel.wast.
;;
;; `(assert_fuel N (invoke "f"))` pins the fuel a call consumes; `(assert_fuel N (module ...))`
;; pins what instantiating a module costs, including its start function. Scripts in this directory
;; run on an engine with fuel metering enabled -- the runner derives that from the directory, the
;; way it derives the feature set -- and the spectest suite runs each of them under both threading
;; models, so these numbers also pin that the two dispatch paths agree.
;;
;; The model: one unit per executed Wasm operator, except operators that generate no code
;; (`nop`, `drop`, `block`, `loop`, `unreachable`, `return`, `else`, `end`), summed per region and
;; charged when the region is entered. A region is a function body, a loop body, or one arm of an
;; `if`. Bulk memory operations additionally cost one unit per 64 bytes they move, charged after
;; their bounds checks pass. Every number below is derived from that model by hand; if one of them
;; changes, the cost of running a guest changed, and that is the thing this file exists to catch.

(module
  (memory 2)
  (global $g (mut i32) (i32.const 0))

  ;; Nothing to charge: `end` is free, so an empty body costs nothing at all.
  (func (export "empty"))

  ;; `nop` and `drop` generate no code; only the constant is priced.
  (func (export "free_operators") (nop) (nop) (drop (i32.const 1)))

  ;; const + const + add.
  (func (export "add") (result i32) (i32.add (i32.const 1) (i32.const 2)))

  ;; A block is not a region: entering it is a fall-through the function body already paid for.
  (func (export "block") (block (drop (i32.const 1)) (drop (i32.const 2))))

  ;; Operators after `return` are unreachable, are never translated, and are not charged.
  (func (export "dead_code") (result i32) (i32.const 7) (return) (i32.const 8))

  ;; `unreachable` is free, so this traps having spent nothing.
  (func (export "trap_immediately") (unreachable))

  ;; The body's region is charged before it runs, so a trap part-way through still pays for the
  ;; whole region: const + const + div + (drop is free) = 3, even though the division traps.
  (func (export "trap_midway") (drop (i32.div_s (i32.const 1) (i32.const 0))))

  ;; The loop body is its own region, charged once per iteration:
  ;; local.get + const + sub + tee + br_if = 5.
  (func (export "loop") (param $n i32)
    (loop $l (br_if $l (local.tee $n (i32.sub (local.get $n) (i32.const 1))))))

  ;; Entry region: local.get + if = 2. Each arm is a region of its own, entered only when taken:
  ;; the `then` costs const + const + add = 3, the `else` costs const = 1.
  (func (export "if_else") (param i32) (result i32)
    (if (result i32) (local.get 0)
      (then (i32.add (i32.const 10) (i32.const 11)))
      (else (i32.const 20))))

  ;; An `if` with no `else`: the implicit else path runs no operators.
  (func (export "if_only") (param i32)
    (if (local.get 0) (then (drop (i32.const 1)))))

  (func $callee (result i32) (i32.const 1))
  ;; The caller pays for `call`, and the callee's own body region is charged on entry.
  (func (export "call") (result i32) (call $callee))

  (type $v (func (result i32)))
  (table 1 funcref)
  (elem (i32.const 0) $callee)
  (func (export "call_indirect") (result i32)
    (call_indirect (type $v) (i32.const 0)))

  (func (export "global") (global.set $g (i32.const 1)))

  (func (export "select") (param i32) (result i32)
    (select (i32.const 1) (i32.const 2) (local.get 0)))

  (func (export "br_table") (block $a (br_table $a $a (i32.const 0))))

  ;; 128 bytes at 64 bytes per unit adds 2 to the four operators.
  (func (export "fill_128") (memory.fill (i32.const 0) (i32.const 7) (i32.const 128)))

  ;; 63 bytes is less than one unit's worth, and the charge rounds down.
  (func (export "fill_63") (memory.fill (i32.const 0) (i32.const 7) (i32.const 63)))

  ;; 256 bytes adds 4.
  (func (export "copy_256") (memory.copy (i32.const 1024) (i32.const 0) (i32.const 256)))

  ;; An out-of-bounds copy fails its bounds check, so only the operators are charged.
  (func (export "copy_out_of_bounds")
    (memory.copy (i32.const 0) (i32.const 0) (i32.const 0x7fffffff)))

  ;; One 64 KiB page is 1024 units on top of the constant and the grow itself.
  (func (export "grow_1") (drop (memory.grow (i32.const 1))))
)

(assert_fuel 0 (invoke "empty"))
(assert_fuel 1 (invoke "free_operators"))
(assert_fuel 3 (invoke "add"))
(assert_fuel 2 (invoke "block"))
(assert_fuel 1 (invoke "dead_code"))
(assert_fuel 0 (invoke "trap_immediately"))
(assert_fuel 3 (invoke "trap_midway"))

(assert_fuel 5 (invoke "loop" (i32.const 1)))
(assert_fuel 10 (invoke "loop" (i32.const 2)))
(assert_fuel 50 (invoke "loop" (i32.const 10)))

(assert_fuel 5 (invoke "if_else" (i32.const 1)))
(assert_fuel 3 (invoke "if_else" (i32.const 0)))
(assert_fuel 3 (invoke "if_only" (i32.const 1)))
(assert_fuel 2 (invoke "if_only" (i32.const 0)))

(assert_fuel 2 (invoke "call"))
(assert_fuel 3 (invoke "call_indirect"))
(assert_fuel 2 (invoke "global"))
(assert_fuel 4 (invoke "select" (i32.const 1)))
(assert_fuel 2 (invoke "br_table"))

(assert_fuel 6 (invoke "fill_128"))
(assert_fuel 4 (invoke "fill_63"))
(assert_fuel 8 (invoke "copy_256"))
(assert_fuel 4 (invoke "copy_out_of_bounds"))
(assert_fuel 1026 (invoke "grow_1"))

;; A grow that the memory's maximum forbids fails its checks, so only the operators are charged:
;; the pages it never allocated are not billed.
(assert_fuel 2 (module (memory 1 1) (func $f (drop (memory.grow (i32.const 1)))) (start $f)))

;; Instantiation is not metered, but the start function it runs is.
(assert_fuel 0 (module (func $f) (start $f)))
(assert_fuel 1 (module (func $f (drop (i32.const 1))) (start $f)))
(assert_fuel 3 (module (func $f (drop (i32.add (i32.const 1) (i32.const 2)))) (start $f)))

;; Data and element segment initialization happens at instantiation and is deliberately not
;; charged: a guest cannot use it to do unmetered work, because its sizes are fixed by the module.
(assert_fuel 0 (module (memory 1) (data (i32.const 0) "hello world")))
