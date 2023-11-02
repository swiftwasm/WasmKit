struct FlagsTestWorldExportsImpl: FlagsTestWorldExports {
    static func roundtripSingle(v: Single) -> Single {
        return v
    }

    static func roundtripManyU8(v: ManyU8) -> ManyU8 { v }
    static func roundtripManyU16(v: ManyU16) -> ManyU16 { v }
    static func roundtripManyU32(v: ManyU32) -> ManyU32 { v }
    static func roundtripManyU64(v: ManyU64) -> ManyU64 { v }
}
