struct NamingTestWorldExportsImpl: NamingTestWorldExports {
    static func roundtripRecord(v: KeywordingRecord) -> KeywordingRecord { v }
    static func roundtripEnum(v: KeywordingEnum) -> KeywordingEnum { v }
    static func roundtripVariant(v: KeywordingVariant) -> KeywordingVariant { v }
    static func roundtripFlags(v: KeywordingFlags) -> KeywordingFlags { v }
}
