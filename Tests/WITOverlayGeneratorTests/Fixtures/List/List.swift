struct ListTestWorldExportsImpl: ListTestWorldExports {
    static func returnEmpty() -> [UInt32] {
        return []
    }

    static func roundtrip(v: [UInt8]) -> [UInt8] {
        return v
    }

    static func roundtripNonPod(v: [String]) -> [String] {
        return v
    }

    static func roundtripListList(v: [[String]]) -> [[String]] {
        return v
    }
}
