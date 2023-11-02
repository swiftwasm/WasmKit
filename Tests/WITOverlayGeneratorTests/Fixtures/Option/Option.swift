struct OptionTestWorldExportsImpl: OptionTestWorldExports {
    static func returnNone() -> Optional<UInt8> {
        return nil
    }
    static func returnOptionF32() -> Optional<Float> {
        return 1/2.0
    }
    static func returnOptionTypedef() -> OptionTypedef {
        return .some(42)
    }
    static func returnSomeNone() -> Optional<Optional<UInt32>> {
        return .some(nil)
    }
    static func returnSomeSome() -> Optional<Optional<UInt32>> {
        return .some(.some(33550336))
    }
    static func roundtrip(v: Optional<UInt32>) -> Optional<UInt32> {
        return v
    }
}
