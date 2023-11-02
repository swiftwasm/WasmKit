struct StringTestWorldExportsImpl: StringTestWorldExports {
    static func returnEmpty() -> String {
        return ""
    }

    static func roundtrip(v: String) -> String {
        return v
    }
}
