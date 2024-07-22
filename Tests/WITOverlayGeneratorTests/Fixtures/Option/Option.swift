struct OptionTestWorldExportsImpl: OptionTestWorldExports {
    static func returnNone() -> UInt8? {
        return nil
    }
    static func returnOptionF32() -> Float? {
        return 1 / 2.0
    }
    static func returnOptionTypedef() -> OptionTypedef {
        return .some(42)
    }
    static func returnSomeNone() -> UInt32?? {
        return .some(nil)
    }
    static func returnSomeSome() -> UInt32?? {
        return .some(.some(33_550_336))
    }
    static func roundtrip(v: UInt32?) -> UInt32? {
        return v
    }
}
