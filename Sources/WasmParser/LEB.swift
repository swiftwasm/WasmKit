@usableFromInline
enum LEBError: Swift.Error, Equatable {
    case overflow
    case integerRepresentationTooLong
    case insufficientBytes
}

@inlinable
func decodeLEB128<IntType, Stream>(
    stream: Stream
) throws -> IntType where IntType: FixedWidthInteger, IntType: UnsignedInteger, Stream: ByteStream {
    let firstByte = try stream.consumeAny()
    var result: IntType = IntType(firstByte & 0b0111_1111)
    if _fastPath(firstByte & 0b1000_0000 == 0) {
        return result
    }

    var shift: UInt = 7

    while true {
        let byte = try stream.consumeAny()
        let slice = IntType(byte & 0b0111_1111)
        let nextShift = shift + 7
        if nextShift >= IntType.bitWidth, (byte >> (UInt(IntType.bitWidth) - shift)) != 0 {
            throw LEBError.integerRepresentationTooLong
        }
        result |= slice << shift
        shift = nextShift

        guard byte & 0b1000_0000 != 0 else { break }
    }

    return result
}

@inlinable
func decodeLEB128<IntType, Stream>(
    stream: Stream, bitWidth: Int = IntType.bitWidth
) throws -> IntType where IntType: FixedWidthInteger, IntType: RawSignedInteger, Stream: ByteStream {
    let firstByte = try stream.consumeAny()
    var result = IntType.Unsigned(firstByte & 0b0111_1111)
    if _fastPath(firstByte & 0b1000_0000 == 0) {
        // Interpret Int${Self.bitWidth-1} as Int${Self.bitWidth}
        return (IntType(bitPattern: result) << (IntType.bitWidth - 7)) >> (IntType.bitWidth - 7)
    }

    var shift: IntType = 7

    var byte: UInt8
    repeat {
        byte = try stream.consumeAny()

        let slice = IntType.Unsigned(byte & 0b0111_1111)
        result |= slice << shift

        // When we don't have enough bit width
        if shift > (bitWidth - 7) {
            let remainingBitWidth = bitWidth - Int(shift)
            let continuationBit = (byte & 0b1000_0000) != 0
            // When a next byte is expected
            if continuationBit {
                throw LEBError.integerRepresentationTooLong
            }

            let signAndDiscardingBits = Int8(bitPattern: byte << 1) >> remainingBitWidth
            // When meaningful bits are discarded
            if signAndDiscardingBits != 0 && signAndDiscardingBits != -1 {
                throw LEBError.overflow
            }
            return IntType(bitPattern: result)
        }

        shift += 7
    } while byte & 0b1000_0000 != 0

    // Sign flag is second high-order bit
    if byte & 0b0100_0000 != 0 {
        // Sign extend
        result |= IntType.Unsigned(bitPattern: ~0) << shift
    }

    return IntType(bitPattern: result)
}
