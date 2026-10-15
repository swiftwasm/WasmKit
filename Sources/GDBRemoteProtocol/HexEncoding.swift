/// Hex encoding/decoding helpers shared by the GDB remote protocol stack.
/// The wire format uses lowercase hex for binary payloads and either case for
/// checksums.

package enum HexEncoding {
    static let lowercaseDigits: [UInt8] = Array("0123456789abcdef".utf8)
    static let uppercaseDigits: [UInt8] = Array("0123456789ABCDEF".utf8)

    /// Encodes bytes as continuous lowercase hex (e.g. `[0xde, 0xad]` -> `"dead"`).
    package static func encode(_ bytes: some Sequence<UInt8>) -> String {
        var output = [UInt8]()
        for byte in bytes {
            output.append(Self.lowercaseDigits[Int(byte >> 4)])
            output.append(Self.lowercaseDigits[Int(byte & 0xF)])
        }
        return String(decoding: output, as: UTF8.self)
    }

    /// Encodes a single byte as two uppercase hex digits.
    package static func encodeByteUppercase(_ byte: UInt8) -> String {
        String(decoding: [uppercaseDigits[Int(byte >> 4)], uppercaseDigits[Int(byte & 0xF)]], as: UTF8.self)
    }

    /// Decodes a continuous hex string into bytes; returns nil for odd-length
    /// or non-hex input.
    package static func decode(_ string: some StringProtocol) -> [UInt8]? {
        let digits = Array(string.utf8)
        guard digits.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(digits.count / 2)
        var index = 0
        while index < digits.count {
            guard let high = Character(UnicodeScalar(digits[index])).hexDigitValue,
                let low = Character(UnicodeScalar(digits[index + 1])).hexDigitValue
            else { return nil }
            bytes.append(UInt8(high << 4 | low))
            index += 2
        }
        return bytes
    }
}

extension FixedWidthInteger {
    /// The integer's bytes in big-endian order.
    package var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian) { [UInt8]($0) }
    }

    /// The integer's bytes in little-endian order.
    package var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.littleEndian) { [UInt8]($0) }
    }

    /// Reads an integer from bytes in the given order; returns nil unless
    /// exactly `MemoryLayout<Self>.size` bytes are provided.
    package init?(bigEndianBytes bytes: some Collection<UInt8>) {
        guard bytes.count == MemoryLayout<Self>.size else { return nil }
        var value = Self.zero
        for byte in bytes {
            value = value << 8 | Self(byte)
        }
        self = value
    }

    /// Reads an integer from bytes in little-endian order; returns nil unless
    /// exactly `MemoryLayout<Self>.size` bytes are provided.
    package init?(littleEndianBytes bytes: some Collection<UInt8>) {
        self.init(bigEndianBytes: bytes.reversed())
    }
}
