struct TupleTestWorldExportsImpl: TupleTestWorldExports {
    static func roundtrip(v: (Bool, UInt32)) -> (Bool, UInt32) { v }
}
