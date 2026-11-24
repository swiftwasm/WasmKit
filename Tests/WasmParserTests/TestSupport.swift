enum TestSupport {
    static func unsignedLEB128(_ value: Int) -> [UInt8] {
        var value = UInt(value)
        var bytes: [UInt8] = []
        repeat {
            var byte = UInt8(value & 0b0111_1111)
            value >>= 7
            if value != 0 {
                byte |= 0b1000_0000
            }
            bytes.append(byte)
        } while value != 0
        return bytes
    }
}
