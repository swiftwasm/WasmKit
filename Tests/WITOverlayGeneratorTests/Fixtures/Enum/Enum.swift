struct EnumTestWorldExportsImpl: EnumTestWorldExports {
    static func roundtripSingle(v: Single) -> Single {
        return v
    }

    static func roundtripLarge(v: Large) -> Large {
        return v
    }

    static func returnByPointer() -> (Binary, Binary) {
        return (.a, .b)
    }
}
