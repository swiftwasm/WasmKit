struct RecordTestWorldExportsImpl: RecordTestWorldExports {
    static func returnEmpty() -> RecordEmpty {
        return RecordEmpty()
    }
    static func roundtripEmpty(v: RecordEmpty) -> RecordEmpty {
        return v
    }
    static func returnPadded() -> RecordPadded {
        return RecordPadded(f1: 28, f2: 496)
    }
    static func roundtripPadded(v: RecordPadded) -> RecordPadded {
        return v
    }

    static func checkIdentFlat(v: RecordIdentFlat) -> RecordIdentFlat { v }

    static func checkIdentLoadstore(v: RecordIdentLoadstore) -> RecordIdentLoadstore { v }
}
