enum LEBError: Swift.Error, Equatable {
    case overflow
    case integerRepresentationTooLong
    case insufficientBytes
}

extension FixedWidthInteger where Self: UnsignedInteger {
    init<Stream: ByteStream>(LEB stream: Stream) throws {
        var result: Self = 0
        var shift: UInt = 0

        var byte: UInt8
        repeat {
            byte = try stream.consumeAny()

            guard shift < Self.bitWidth else {
                throw LEBError.integerRepresentationTooLong
            }

            let slice = Self(byte & 0b0111_1111)
            guard (slice << shift) >> shift == slice else {
                throw LEBError.overflow
            }
            result |= slice << shift
            shift += 7
        } while byte & 0b1000_0000 != 0

        self = result
    }
}

extension FixedWidthInteger where Self: SignedInteger {
    init<Stream: ByteStream>(LEB stream: Stream) throws {
        var result: Self = 0
        var shift: Self = 0

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
