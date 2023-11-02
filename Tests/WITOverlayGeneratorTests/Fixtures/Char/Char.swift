struct CharTestWorldExportsImpl: CharTestWorldExports {
    static func roundtrip(v: Unicode.Scalar) -> Unicode.Scalar { v }
}
