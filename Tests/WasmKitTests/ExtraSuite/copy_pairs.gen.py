#!/usr/bin/env python3
"""Generate an ExtraSuite .wast covering runs of adjacent copies between locals,
including copies whose source is an earlier copy's destination and copies that
write the same local.

Every folded function runs its `local.set`s back to back; its reference puts a
`global.get` between each pair. Each function returns a mix of all locals.
"""
import itertools

LOCALS = ["a", "b", "c", "d"]
PAIRS = list(itertools.permutations(LOCALS, 2))
SEQS = list(itertools.product(PAIRS, repeat=2))
# Every run of three copies starting from one first copy.
SEQS += [((PAIRS[0]),) + rest for rest in itertools.product(PAIRS, repeat=2)]

out = [";; GENERATED FILE, DO NOT EDIT. Regenerate with:",
       ";;   python3 Tests/WasmKitTests/ExtraSuite/copy_pairs.gen.py > Tests/WasmKitTests/ExtraSuite/copy_pairs.wast",
       ""]
for t in ("i64", "v128"):
    out.append("(module")
    out.append("  (global $g (mut i32) (i32.const 0))")
    init = " ".join(f"(local.set ${l} {c})" for l, c in zip(LOCALS, (
        ["(i64.const 11)", "(i64.const 13)", "(i64.const 17)", "(i64.const 19)"] if t == "i64" else
        ["(v128.const i64x2 11 111)", "(v128.const i64x2 13 113)", "(v128.const i64x2 17 117)", "(v128.const i64x2 19 119)"])))
    def mix():
        if t == "i64":
            return "(i64.add (i64.add (i64.mul (local.get $a) (i64.const 1000)) (i64.mul (local.get $b) (i64.const 100))) (i64.add (i64.mul (local.get $c) (i64.const 10)) (local.get $d)))"
        lanes = lambda l: f"(i64.add (i64x2.extract_lane 0 (local.get ${l})) (i64x2.extract_lane 1 (local.get ${l})))"
        return f"(i64.add (i64.add (i64.mul {lanes('a')} (i64.const 1000)) (i64.mul {lanes('b')} (i64.const 100))) (i64.add (i64.mul {lanes('c')} (i64.const 10)) {lanes('d')}))"
    names = []
    for k, seq in enumerate(SEQS):
        sets = [f"(local.set ${d} (local.get ${s}))" for s, d in seq]
        body = " ".join(sets)
        ref = " (drop (global.get $g)) ".join(sets)
        loc = " ".join(f"(local ${l} {t})" for l in LOCALS)
        out.append(f"  (func (export \"f{k}\") (result i64) {loc} {init} {body} {mix()})")
        out.append(f"  (func (export \"r{k}\") (result i64) {loc} {init} {ref} {mix()})")
        names.append(k)
    out.append("  (func (export \"check\") (result i32) (local $n i32)")
    for k in names:
        out.append(f"    (if (i64.ne (call {2*k}) (call {2*k+1})) (then (local.set $n (i32.add (local.get $n) (i32.const 1)))))")
    out.append("    (local.get $n))")
    out.append(")")
    out.append('(assert_return (invoke "check") (i32.const 0))')
    out.append("")
print("\n".join(out))
