struct NumberTestWorldExportsImpl: NumberTestWorldExports {
    static func roundtripBool(v: Bool) -> Bool { v }
    static func roundtripU8(v: UInt8) -> UInt8 { v }
    static func roundtripU16(v: UInt16) -> UInt16 { v }
    static func roundtripU32(v: UInt32) -> UInt32 { v }
    static func roundtripU64(v: UInt64) -> UInt64 { v }
    static func roundtripS8(v: Int8) -> Int8 { v }
    static func roundtripS16(v: Int16) -> Int16 { v }
    static func roundtripS32(v: Int32) -> Int32 { v }
    static func roundtripS64(v: Int64) -> Int64 { v }
    static func roundtripFloat32(v: Float) -> Float { v }
    static func roundtripFloat64(v: Double) -> Double { v }

    static func retptrU8() -> (UInt8, UInt8) { (1, 2) }
    static func retptrU16() -> (UInt16, UInt16) { (1, 2) }
    static func retptrU32() -> (UInt32, UInt32) { (1, 2) }
    static func retptrU64() -> (UInt64, UInt64) { (1, 2) }
    static func retptrS8() -> (Int8, Int8) { (1, -2) }
    static func retptrS16() -> (Int16, Int16) { (1, -2) }
    static func retptrS32() -> (Int32, Int32) { (1, -2) }
    static func retptrS64() -> (Int64, Int64) { (1, -2) }
}
