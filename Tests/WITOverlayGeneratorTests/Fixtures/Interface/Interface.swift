struct InterfaceTestWorldExportsImpl: InterfaceTestWorldExports {
    static func roundtripT1(v: T1) -> T1 { v }
}

struct TestInterfaceCheckIfaceFuncsExportsImpl: TestInterfaceCheckIfaceFuncsExports {
    static func roundtripU8(v: UInt8) -> UInt8 { v }
}
