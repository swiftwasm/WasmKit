# Runtime Stack Layout

This document describes how the register-based interpreter lays out a function's
frame on the VM stack, and how frames are pushed and popped by calls, returns
and tail calls. See [RegisterMachine.md](RegisterMachine.md) for the
interpreter design as a whole.

The layout is computed by `StackLayout` and `ParameterAreaLayout` in
[`Translator.swift`](../Sources/WasmKit/Translator.swift), and used at runtime
by [`Execution.swift`](../Sources/WasmKit/Execution/Execution.swift) and
[`Control.swift`](../Sources/WasmKit/Execution/Instructions/Control.swift).

## Slots and registers

The VM stack is an array of 64-bit **slots** (`StackSlot == UInt64`). A value of
type `i32`, `i64`, `f32`, `f64` or a reference takes one slot; a `v128` takes two
consecutive slots (`lo`, then `hi`).

Every operand of a VM instruction names a slot by its offset from the stack
pointer `sp` of the current frame. Operands come in three widths, all of which
store a *byte* offset (slot index × 8) rather than a slot index:

| Type     | Storage | Reachable slots from `sp`  |
|----------|---------|----------------------------|
| `VReg`   | `Int16` | `-4096 … 4095`             |
| `LVReg`  | `Int32` | about ±2<sup>28</sup>      |
| `LLVReg` | `Int64` | effectively unlimited      |

An instruction's operands are packed into the 64-bit code slots (`CodeSlot`) of
the instruction stream that follow its opcode, so which width a field gets
depends on how many fields share a code slot. Some examples, with bit 63 on the
left:

```
Binary operator (i32.add, ...)
 63                             32 31             16 15              0
┌─────────────────────────────────┬─────────────────┬─────────────────┐
│          result: LVReg          │   rhs: VReg     │   lhs: VReg     │
└─────────────────────────────────┴─────────────────┴─────────────────┘

Unary operator (i32.clz, ...)
 63                             32 31                                0
┌─────────────────────────────────┬───────────────────────────────────┐
│          input: LVReg           │           result: LVReg           │
└─────────────────────────────────┴───────────────────────────────────┘

copyStack
 63                             32 31                                0
┌─────────────────────────────────┬───────────────────────────────────┐
│           dest: LVReg           │           source: LVReg           │
└─────────────────────────────────┴───────────────────────────────────┘

Load (i32.load, ...): two code slots
 63                                                                  0
┌─────────────────────────────────────────────────────────────────────┐
│                          offset: UInt64                             │
├─────────────────────────────────┬─────────────────┬─────────────────┤
│             unused              │  result: VReg   │  pointer: VReg  │
└─────────────────────────────────┴─────────────────┴─────────────────┘

const32
 63                             32 31                                0
┌─────────────────────────────────┬───────────────────────────────────┐
│          result: LVReg          │           value: UInt32           │
└─────────────────────────────────┴───────────────────────────────────┘

const64: two code slots
 63                                                                  0
┌─────────────────────────────────────────────────────────────────────┐
│                               value                                 │
├─────────────────────────────────────────────────────────────────────┤
│                          result: LLVReg                             │
└─────────────────────────────────────────────────────────────────────┘

call, compilingCall, internalCall: two code slots
 63                                                                  0
┌─────────────────────────────────────────────────────────────────────┐
│                          callee: UInt64                             │
├─────────────────────────────────┬─────────────────┬─────────────────┤
│         spAddend: LVReg         │     unused      │ arguments: VReg │
└─────────────────────────────────┴─────────────────┴─────────────────┘
```

The `VReg` range bounds the frame layout below: anything an ordinary
instruction reads or writes has to be within 4096 slots of `sp`.

## The frame of a function

Everything but the value stack is below `sp`, so that the value stack starts at
`sp` and has the whole positive range of a `VReg`:

| Offset from `sp`          | Contents                                        |
|---------------------------|-------------------------------------------------|
| `-E … -E+P-1`             | Parameter area: parameters, overlapped by results |
| `-(L+3+C) … -(L+4)`       | Constant pool, constant 0 at the top            |
| `-(L+3) … -4`             | Non-parameter locals                            |
| `-3`                      | Saved current function (and with it, instance)  |
| `-2`                      | Saved return PC                                 |
| `-1`                      | Saved caller `sp`                               |
| `0 …`                     | Value stack                                     |

- `P` is the size of the parameter area: the larger of the parameter and result
  slot counts. Parameters and results share the same slots.
- `C` is the size of the constant pool. It is picked from the code size before
  translation starts (at least 4 and at most 128 slots) so that constant slot
  indices are known while the body is being translated. It is also capped so
  that the whole pool is within `VReg` reach, which leaves no pool at all in a
  function with more than about 4090 slots of locals.
- `L` is the number of slots taken by the non-parameter locals.
- `E = P + C + L + 3` is the **entry offset**: the distance from the start of
  the parameter area to `sp`.
- The value stack holds the intermediate values of the function body. Its
  maximum height is known once the body is translated.

`InstructionSequence.maxStackHeight` is the maximum height of the value stack,
and is used to check for stack exhaustion when the frame is pushed.

The constants are numbered down from the locals, so that the constants in use
and the locals are contiguous and end right below the saved slots. That is the
**frame-initialization image** a call copies in: the constants, then the
default value of each local (zero, or null for a reference).

### Example

```wat
(func $f (param i32 i64) (result i64)
  (local f64 v128)
  (local.set 2 (f64.const 1.5))
  ;; (param 1 + zext(param 0)) * 100 - (param 1 + 7)
  (local.get 1)
  (i64.extend_i32_u (local.get 0))
  (i64.add)
  (i64.const 100)
  (i64.mul)
  (i64.add (local.get 1) (i64.const 7))
  (i64.sub))
```

Two parameter slots and one result slot give `P = 2`. The body is small, so
`C = 4`. The `v128` local takes two slots, so `L = 3`. The entry offset is
`E = 2 + 4 + 3 + 3 = 12`.

| Offset from `sp` | Contents                          |
|------------------|-----------------------------------|
| `-12`            | param 0 (`i32`), result 0 (`i64`) |
| `-11`            | param 1 (`i64`)                   |
| `-10 … -9`       | unused constant slots             |
| `-8`             | constant `7`                      |
| `-7`             | constant `100`                    |
| `-6`             | local 2 (`f64`)                   |
| `-5 … -4`        | local 3 (`v128`, lo and hi)       |
| `-3`             | saved current function            |
| `-2`             | saved return PC                   |
| `-1`             | saved caller `sp`                 |
| `0 … 2`          | value stack, heights 0–2          |

#### Pushing and popping

The translator tracks the Wasm operand stack while it translates. Each entry
has a height, and the entry at height `h` owns slot `h`, whatever kind of value
it holds. An entry is one of:

- a **local**, which refers to the local's slot. `local.get` pushes one and
  emits nothing.
- a **constant**, which refers to a constant pool slot. `i64.const` and the
  other constants push one and emit nothing.
- a **computed value**, stored in the entry's own slot. An instruction that
  produces a value writes its result there.

An instruction pops its operands, uses each one's slot as an operand, and
pushes its result:

| Wasm                   | Stack after (height: entry)                     | Emitted                            |
|------------------------|-------------------------------------------------|------------------------------------|
| `f64.const 1.5`        | 0: const `1.5`                                  |                                    |
| `local.set 2`          | (empty)                                         | `sp[-6] = const64 1.5`             |
| `local.get 1`          | 0: local 1                                      |                                    |
| `local.get 0`          | 0: local 1, 1: local 0                          |                                    |
| `i64.extend_i32_u`     | 0: local 1, 1: `sp[1]`                          | `sp[1] = i64.extend_i32_u sp[-12]` |
| `i64.add`              | 0: `sp[0]`                                      | `sp[0] = i64.add sp[-11], sp[1]`   |
| `i64.const 100`        | 0: `sp[0]`, 1: const `100`                      |                                    |
| `i64.mul`              | 0: `sp[0]`                                      | `sp[0] = i64.mul sp[0], sp[-7]`    |
| `local.get 1`          | 0: `sp[0]`, 1: local 1                          |                                    |
| `i64.const 7`          | 0: `sp[0]`, 1: local 1, 2: const `7`            |                                    |
| `i64.add`              | 0: `sp[0]`, 1: `sp[1]`                          | `sp[1] = i64.add sp[-11], sp[-8]`  |
| `i64.sub`              | 0: `sp[0]`                                      | `sp[0] = i64.sub sp[0], sp[1]`     |
| `end`                  | (empty)                                         | `sp[-12] = copy sp[0]`, `return`   |

The stack reaches height 3 after `i64.const 7`, so `maxStackHeight` is 3 even
though slot `2` is never written.

#### The constant pool

A constant gets a pool slot the first time an instruction reads it as an
operand: `100` gets constant 0 (slot `-7`) at `i64.mul` and `7` gets constant 1
(slot `-8`) at `i64.add`. A constant that is stored straight into a slot, like
`1.5` into local 2, becomes a `const32`/`const64` instruction and takes no pool
slot. Equal bit patterns share a slot. When the pool is full, a constant is
written to its value stack slot with `const32`/`const64` instead.

The frame-initialization image is `7, 100, 0, 0, 0`: the two constants that
were given slots, then zeroes for the three local slots. It covers slots
`-8 … -4`.

## Calls

A call places the callee's parameter area right on top of the caller's value
stack, so that the arguments the caller pushed are already in the callee's
parameter slots and nothing has to be copied. The call instruction's
`arguments` is the slot of the first argument, i.e. where the callee's
parameter area starts.

The callee's `sp` is its entry offset above that. For `call` (and
`compilingCall` and `internalCall`, which it becomes for a callee in the same
module) the callee is known when the caller is translated, and its entry
offset depends only on its type, its locals and its code size. So the
translator works it out without compiling the callee and puts the callee's
`sp` in the instruction as `spAddend = arguments + E(callee)`. For
`call_indirect` and `call_ref` the callee is only known at runtime, so its
`sp` is `arguments + E(callee)` with `E` read from the callee's compiled
`InstructionSequence`.

`pushFrame` in `Execution.swift` then:

1. checks that the callee's `sp + maxStackHeight` fits in the VM stack, and
   traps with "call stack exhausted" otherwise,
2. copies the callee's frame-initialization image to the slots right below its
   saved slots, and
3. writes the three saved slots right below the callee's `sp`.

### Example

`$g` has one value on its value stack and calls `$f` from the example above:

```
Caller $g                           Callee $f
offset from $g's sp                 offset from $f's sp
  0   value stack [0]
  1   arg 0 (i32)       ─────────▶  -12  param 0 / result 0
  2   arg 1 (i64)       ─────────▶  -11  param 1
  3 … 6                             -10 … -7  constants
  7 … 9                              -6 … -4  locals
 10                                  -3  saved function ($f)
 11                                  -2  saved return PC
 12                                  -1  saved $g's sp
 13                                   0  $f's value stack   ◀── $f's sp
```

`arguments` is `1`, and `spAddend` is `1 + 12 = 13`. When `$f` returns, it has
written its result to its slot `-12`, which is slot `1` of `$g`: exactly where
the translator of `$g` put the call's result on its value stack.

### Returns

Before returning, a function copies its results into the result slots at the
bottom of its frame. `return` then reads the saved return PC and caller `sp`
from `sp[-2]` and `sp[-1]` and continues in the caller. Returns, exception
unwinding and backtraces read only the saved slots right below `sp`, not the
rest of the frame.

### Host functions

A call to a host function pushes no frame: the host function reads its
arguments from and writes its results to the parameter area at `arguments`.

## Tail calls

`return_call` and its variants reuse the current frame for the callee: the
callee's parameter area starts where the current one's does. The translator
puts the arguments on the value stack and emits the tail call with two
operands: `arguments`, the slot of the first argument, and `frameBase`, the
start of the current frame's parameter area (`-E`).

The runtime, in `Execution.tailInvoke`:

1. reads the three saved slots,
2. moves the arguments down to `frameBase` (with a `memmove`, since the new
   parameter area may reach into the old saved slots, constants or value stack),
3. places the callee's `sp` at `frameBase + E(callee)`, copies its
   frame-initialization image below it, and writes the saved slots there,
   unless the callee's `sp` is where the current one is, as in a function
   calling itself, in which case the saved slots stay where they are.

For a host function the second and third step are the same with no locals and
no constants, and the next instruction returns from the new frame.

### Example

```wat
(func $h (param i64 i64 i64) (result i64)
  (i64.add (i64.add (local.get 0) (local.get 1)) (local.get 2)))

(func $t (param i32 i64) (result i64)
  (return_call $h (local.get 1) (i64.extend_i32_u (local.get 0)) (i64.const 1)))
```

`$t` has `P = 2`, `C = 4` and no locals, so `E = 9`. `$h` has `P = 3`, so
`E = 10`.

```
sp[1] = i64.extend_i32_u sp[-9]     ;; arg 1
sp[2] = copy sp[-4]                 ;; arg 2: constant 1, onto the stack
sp[0] = copy sp[-8]                 ;; arg 0: local 1, onto the stack
return_call $h, arguments: sp[0], frameBase: sp[-9]
```

The runtime moves slots `0 … 2` to `-9 … -7`, which become `$h`'s parameters,
places `$h`'s `sp` at `-9 + 10 = 1`, and writes the saved slots to `-2 … 0`.
`$h` then returns straight to `$t`'s caller.

## Functions with many locals

Unoptimized code routinely declares thousands of locals. They are below `sp`
like any others, so the value stack stays in reach however many there are; it
is the locals, and the parameter area below them, that may not be.

A slot below `sp - 4096` can't be named by a `VReg`, but can be by the `LVReg`
operands of `copyStack`. The translator calls such a local (or parameter, or
result) *wide* and accesses it only with `copyStack`, or `const32`/`const64` to
store a constant:

| Wasm                          | Local within reach                    | Wide local                                 |
|-------------------------------|---------------------------------------|--------------------------------------------|
| `local.get`                   | no instruction; operand is its slot   | `copyStack` into a value stack slot        |
| `local.set` of a computed value | producer writes the slot directly, or `copy` | `copyStack` from the value stack slot |
| `local.set` of a constant     | `const32`/`const64` into the slot     | the same                                   |
| `return` (results)            | `copy` into the result slot           | `copyStack` into the result slot           |

The constant pool is below the locals and has to be in reach, so it shrinks as
the locals grow, down to no pool at all. Constants are then written to value
stack slots with `const32`/`const64`.

### Example

```wat
(func $big (param $a i64) (param $b i32) (result i64)
  (local $l0 i64) (local $l1 i64) ;; ... 5000 i64 locals in all, up to
  (local $l4999 i64)
  (local.set $l10 (i64.const 7))
  (local.set $l4000 (i64.extend_i32_u (local.get $b)))
  (local.set $l10 (i64.add (local.get $l10) (local.get $l4000)))
  (i64.mul (local.get $l10) (local.get $a)))
```

`P = 2` and `L = 5000`, which leaves no room for a constant pool, so `C = 0` and
`E = 2 + 0 + 5000 + 3 = 5005`:

| Offset from `sp` | Contents                        | Access  |
|------------------|---------------------------------|---------|
| `-5005`          | `$a`, result 0                  | wide    |
| `-5004`          | `$b`                            | wide    |
| `-5003 … -4097`  | `$l0` … `$l906`                 | wide    |
| `-4096 … -4`     | `$l907` … `$l4999`              | `VReg`  |
| `-3 … -1`        | saved slots                     |         |
| `0 …`            | value stack                     | `VReg`  |

`$l10` is at `-5003 + 10 = -4993` and is wide. `$l4000` is at `-1003` and is
not.

| Wasm                                     | Emitted                                    |
|------------------------------------------|--------------------------------------------|
| `i64.const 7`                            | `sp[0] = const64 7`                        |
| `local.set $l10`                         | `sp[-4993] = copyStack sp[0]`              |
| `local.get $b`                           | `sp[0] = copyStack sp[-5004]`              |
| `i64.extend_i32_u`, `local.set $l4000`   | `sp[-1003] = i64.extend_i32_u sp[0]`       |
| `local.get $l10`                         | `sp[0] = copyStack sp[-4993]`              |
| `local.get $l4000`, `i64.add`            | `sp[0] = i64.add sp[0], sp[-1003]`         |
| `local.set $l10`                         | `sp[-4993] = copyStack sp[0]`              |
| `local.get $l10`                         | `sp[0] = copyStack sp[-4993]`              |
| `local.get $a`                           | `sp[1] = copyStack sp[-5005]`              |
| `i64.mul`                                | `sp[0] = i64.mul sp[0], sp[1]`             |
| `end`                                    | `sp[-5005] = copyStack sp[0]`, `return`    |

- There is no constant pool, so the constant `7` is written to its value stack
  slot when it is pushed, and `local.set` copies it from there.
- `$b` and `$l10` are wide, so each `local.get` of them is a `copyStack` onto
  the value stack instead of a reference to the local's slot.
- `$l4000` is in reach: `local.get $l4000` emits nothing, and the
  `i64.extend_i32_u` before `local.set $l4000` writes its slot directly.
- The result is copied into the wide result slot, and `return` reads the saved
  slots at `sp[-3 … -1]`.

## Limits

A function is rejected with "The frame of this function is too large for the
interpreter" when:

- the bottom of its frame, `-E`, does not fit an `LVReg`, or
- its value stack, or the parameter area of a callee on top of it, grows past
  slot `4095`.
