import WasmKit

/// A case that is not part of wasmi-benchmarks, reported as `extra/<name>` so
/// it stays out of comparisons with wasmi's own `execute/*` numbers.
///
/// The module exports `run(input) -> result`, and `expected` is checked once
/// after the measurement.
struct ExtraCase {
    let name: String
    let wat: String
    let input: Value
    let expected: Value
}

extension ExtraCase {
    /// SplitMix64's output mixing step (Steele, Lea and Flood, 2014; the
    /// finalizer of Java's `SplittableRandom`), folded `n` times. It is the
    /// shape of a small integer hash or random-number generator in a hot loop,
    /// which the wasmi-benchmarks modules do not contain. Compiled from:
    ///
    ///     __attribute__((noinline)) uint64_t mix(uint64_t x, uint64_t salt) {
    ///       x += salt;
    ///       x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
    ///       x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
    ///       return x ^ (x >> 31);
    ///     }
    ///
    ///     __attribute__((export_name("run"))) uint64_t run(uint64_t n) {
    ///       uint64_t v = n;
    ///       for (uint64_t i = 0; i < n; i++) v = mix(v, n);
    ///       return v;
    ///     }
    ///
    /// with `clang --target=wasm32 -O2 -nostdlib -Wl,--no-entry` (clang 21) and
    /// printed with `wasm-tools print`, keeping only the two functions.
    static let splitmix64 = ExtraCase(
        name: "splitmix64",
        wat: """
            (module
              (func $mix (param i64 i64) (result i64)
                local.get 1
                local.get 0
                i64.add
                local.tee 0
                i64.const 30
                i64.shr_u
                local.get 0
                i64.xor
                i64.const -4658895280553007687
                i64.mul
                local.tee 0
                i64.const 27
                i64.shr_u
                local.get 0
                i64.xor
                i64.const -7723592293110705685
                i64.mul
                local.tee 0
                i64.const 31
                i64.shr_u
                local.get 0
                i64.xor)
              (func (export "run") (param i64) (result i64)
                (local i64 i64)
                block
                  block
                    local.get 0
                    i64.eqz
                    i32.eqz
                    br_if 0
                    i64.const 0
                    local.set 1
                    br 1
                  end
                  local.get 0
                  local.set 2
                  local.get 0
                  local.set 1
                  loop
                    local.get 1
                    local.get 0
                    call $mix
                    local.set 1
                    local.get 2
                    i64.const -1
                    i64.add
                    local.tee 2
                    i64.eqz
                    i32.eqz
                    br_if 0
                  end
                end
                local.get 1))
            """,
        input: Value.i64(1_000_000),
        expected: Value.i64(0x8998_10C3_8D01_1B76)
    )
}
