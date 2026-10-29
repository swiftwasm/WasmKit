import Testing
import WasmParser

@testable import WAT

@Suite
struct TextFormattingTests {
    @Test(arguments: [
        (UInt32(0x3F80_0000), "0x1p+0"),
        (UInt32(0x3F88_0000), "0x1.1p+0"),
        (UInt32(0x3F90_0000), "0x1.2p+0"),
        (UInt32(0x3F80_0001), "0x1.000002p+0"),
        (UInt32(0x0000_0001), "0x1p-149"),
        (UInt32(0xBF80_0000), "-0x1p+0"),
    ])
    func f32HexFloatsDropTrailingZeros(bits: UInt32, text: String) {
        #expect(formatF32(IEEE754.Float32(bitPattern: bits)) == text)
    }

    @Test(arguments: [
        (UInt64(0x3FF0_0000_0000_0000), "0x1p+0"),
        (UInt64(0x3FF8_0000_0000_0000), "0x1.8p+0"),
        (UInt64(0x3FF0_0000_0000_0001), "0x1.0000000000001p+0"),
        (UInt64(0x0000_0000_0000_0001), "0x1p-1074"),
    ])
    func f64HexFloatsDropTrailingZeros(bits: UInt64, text: String) {
        #expect(formatF64(IEEE754.Float64(bitPattern: bits)) == text)
    }

    @Test func dataBytesEscapeEverythingOutsidePrintableASCII() {
        let bytes: [UInt8] = [0x00, 0x09, 0x22, 0x5C, 0x41, 0xC3, 0xA9, 0x7F]
        #expect(watStringLiteral(bytes, keepingUTF8: false) == #""\00\t\"\\A\c3\a9\7f""#)
    }

    @Test func namesKeepTheirUTF8() {
        #expect(watStringLiteral("é\n".utf8, keepingUTF8: true) == #""é\n""#)
    }
}
