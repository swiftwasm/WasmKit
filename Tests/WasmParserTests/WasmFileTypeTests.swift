import Testing

@testable import WasmParser

@Suite struct WasmFileTypeTests {
    @Test func detectsCoreModuleHeader() {
        let header: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
            0x00, 0x61, 0x73, 0x6d,
            0x01, 0x00, 0x00, 0x00
        )

        #expect(detectWasmFileType(header) == .coreModule)
    }

    @Test func detectsComponentHeader() {
        let header: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
            0x00, 0x61, 0x73, 0x6d,
            0x0d, 0x00, 0x01, 0x00
        )

        #expect(detectWasmFileType(header) == .component)
    }

    @Test func rejectsUnknownHeaders() {
        let invalidMagic: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
            0x00, 0x61, 0x73, 0x78,
            0x01, 0x00, 0x00, 0x00
        )
        let invalidVersion: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
            0x00, 0x61, 0x73, 0x6d,
            0x02, 0x00, 0x00, 0x00
        )

        #expect(detectWasmFileType(invalidMagic) == .unknown)
        #expect(detectWasmFileType(invalidVersion) == .unknown)
    }
}
