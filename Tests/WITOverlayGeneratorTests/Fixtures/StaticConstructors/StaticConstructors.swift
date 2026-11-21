@_extern(c, "static_constructor_runs")
func staticConstructorRuns() -> UInt32

struct StaticConstructorsTestWorldExportsImpl: StaticConstructorsTestWorldExports {
    static func constructorRuns() -> UInt32 {
        staticConstructorRuns()
    }
}
