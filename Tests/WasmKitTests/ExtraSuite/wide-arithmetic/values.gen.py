#!/usr/bin/env python3
"""Generate an ExtraSuite .wast checking the wide arithmetic instructions on
edge values.

Python integers have arbitrary precision, so each expected result is the exact
128-bit value reduced modulo 2^128 and split into its low and high halves.
"""

MASK64 = (1 << 64) - 1
MASK128 = (1 << 128) - 1

# 64-bit operands around the sign bit, the 32-bit boundary and the carries
# between them.
EDGES = [
    0, 1, 2, 3, -1, -2,
    0x7FFFFFFFFFFFFFFF, -0x8000000000000000, -0x7FFFFFFFFFFFFFFF,
    0xFFFFFFFF, 0x100000000, -0x100000000, 0x7FFFFFFF, -0x80000000,
    0xFFFFFFFF00000000, 0x1FFFFFFFF, 0x5555555555555555, -0x5555555555555556,
    0x123456789ABCDEF0, -0x0FEDCBA987654321,
]

# 128-bit operands as (low, high) halves: zero, one, all ones, both signed
# extremes, values that carry or borrow across the halves, and mixed bits.
WIDE = [
    (0, 0), (1, 0), (-1, -1), (-1, 0), (0, 1), (0, -1),
    (-1, 0x7FFFFFFFFFFFFFFF), (0, -0x8000000000000000), (1, -0x8000000000000000),
    (0x8000000000000000, 0), (0x7FFFFFFFFFFFFFFF, -1),
    (0x123456789ABCDEF0, 0x0FEDCBA987654321), (-0x0FEDCBA987654321, -0x123456789ABCDEF0),
]


def u64(value):
    return value & MASK64


def s64(value):
    value &= MASK64
    return value - (1 << 64) if value >> 63 else value


def halves(value):
    value &= MASK128
    return s64(value), s64(value >> 64)


def wide(low, high):
    return u64(low) | (u64(high) << 64)


def const(value):
    return f"(i64.const {s64(value)})"


out = [
    ";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
    ";;   python3 Tests/WasmKitTests/ExtraSuite/wide-arithmetic/values.gen.py > Tests/WasmKitTests/ExtraSuite/wide-arithmetic/values.wast",
    "",
    ";; The wide arithmetic instructions on edge values, checked against exact",
    ";; integer arithmetic. The multiplications take every pair of 64-bit edges",
    ";; and the additions and subtractions every pair of 128-bit edges.",
    "(module",
    '  (func (export "add128") (param i64 i64 i64 i64) (result i64 i64)',
    "    (i64.add128 (local.get 0) (local.get 1) (local.get 2) (local.get 3)))",
    '  (func (export "sub128") (param i64 i64 i64 i64) (result i64 i64)',
    "    (i64.sub128 (local.get 0) (local.get 1) (local.get 2) (local.get 3)))",
    '  (func (export "mul_wide_s") (param i64 i64) (result i64 i64)',
    "    (i64.mul_wide_s (local.get 0) (local.get 1)))",
    '  (func (export "mul_wide_u") (param i64 i64) (result i64 i64)',
    "    (i64.mul_wide_u (local.get 0) (local.get 1)))",
    ")",
]

for lhs in EDGES:
    for rhs in EDGES:
        low, high = halves(s64(lhs) * s64(rhs))
        out.append(f'(assert_return (invoke "mul_wide_s" {const(lhs)} {const(rhs)}) {const(low)} {const(high)})')
        low, high = halves(u64(lhs) * u64(rhs))
        out.append(f'(assert_return (invoke "mul_wide_u" {const(lhs)} {const(rhs)}) {const(low)} {const(high)})')

for lhs in WIDE:
    for rhs in WIDE:
        operands = f"{const(lhs[0])} {const(lhs[1])} {const(rhs[0])} {const(rhs[1])}"
        low, high = halves(wide(*lhs) + wide(*rhs))
        out.append(f'(assert_return (invoke "add128" {operands}) {const(low)} {const(high)})')
        low, high = halves(wide(*lhs) - wide(*rhs))
        out.append(f'(assert_return (invoke "sub128" {operands}) {const(low)} {const(high)})')

print("\n".join(out))
