enum LEBError: Swift.Error, Equatable {
    case overflow
    case integerRepresentationTooLong
    case insufficientBytes
}

extension FixedWidthInteger where Self: UnsignedInteger {
    @inline(__always)
    init<Stream: ByteStream>(LEB stream: Stream) throws {
        let firstByte = try stream.consumeAny()
        var result: Self = Self(firstByte & 0b0111_1111)
        if _fastPath(firstByte & 0b1000_0000 == 0) {
            self = result
            return
        }

        var shift: UInt = 7

        while true {
            let byte = try stream.consumeAny()
            let slice = Self(byte & 0b0111_1111)
            let nextShift = shift + 7
            if nextShift >= Self.bitWidth, (byte >> (UInt(Self.bitWidth) - shift)) != 0 {
                throw LEBError.integerRepresentationTooLong
            }
            result |= slice << shift
            shift = nextShift

            guard byte & 0b1000_0000 != 0 else { break }
        }

        self = result
    }
}

extension FixedWidthInteger where Self: SignedInteger {
    @inline(__always)
    init<Stream: ByteStream>(LEB stream: Stream) throws {
        let firstByte = try stream.consumeAny()
        var result: Self = Self(firstByte & 0b0111_1111)
        if _fastPath(firstByte & 0b1000_0000 == 0) {
            // Interpret Int${Self.bitWidth-1} as Int${Self.bitWidth}
            self = (result << (Self.bitWidth - 7)) >> (Self.bitWidth - 7)
            return
        }

        var shift: Self = 7

        var byte: UInt8
        repeat {
            byte = try stream.consumeAny()

            let slice = Self(byte & 0b0111_1111)
            result |= slice << shift

            // When we don't have enough bit width
            if shift > (Self.bitWidth - 7) {
                let remainingBitWidth = Self.bitWidth - Int(shift)
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
                self = result
                return
            }

            shift += 7
        } while byte & 0b1000_0000 != 0

        // Sign flag is second high-order bit
        if byte & 0b0100_0000 != 0 {
            // Sign extend
            result |= Self(~0) << shift
        }

        self = result
    }
}
