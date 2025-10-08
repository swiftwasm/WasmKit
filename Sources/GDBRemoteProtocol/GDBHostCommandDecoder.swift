import NIOCore

import struct Foundation.Date

extension ByteBuffer {
    var isChecksumDelimiterAtReader: Bool {
        self.peekInteger(as: UInt8.self) == UInt8(ascii: "#")
    }

    var isArgumentsDelimiterAtReader: Bool {
        self.peekInteger(as: UInt8.self) == UInt8(ascii: ":")
    }
}

package struct GDBHostCommandDecoder: ByteToMessageDecoder {
    enum Error: Swift.Error {
        case expectedCommandStart
        case unknownCommandKind(String)
        case expectedChecksum
        case checksumIncorrect
    }

    package typealias InboundOut = GDBPacket<GDBHostCommand>

    private var accummulatedKind = [UInt8]()
    private var accummulatedArguments = [UInt8]()

    package init() {}

    private var accummulatedSum = 0
    package var accummulatedChecksum: UInt8 {
        UInt8(self.accummulatedSum % 256)
    }

    mutating package func decode(buffer: inout ByteBuffer) throws -> GDBPacket<GDBHostCommand>? {
        // Command start delimiters.
        let firstStartDelimiter = buffer.readInteger(as: UInt8.self)
        let secondStartDelimiter = buffer.readInteger(as: UInt8.self)
        guard
            firstStartDelimiter == UInt8(ascii: "+")
                && secondStartDelimiter == UInt8(ascii: "$")
        else {
            if let firstStartDelimiter, let secondStartDelimiter {
                print("unexpected delimiter: \(Character(UnicodeScalar(firstStartDelimiter)))\(Character(UnicodeScalar(secondStartDelimiter)))")
            }
            throw Error.expectedCommandStart
        }

        // Byte offset for command start.
        while !buffer.isChecksumDelimiterAtReader && !buffer.isArgumentsDelimiterAtReader,
            let char = buffer.readInteger(as: UInt8.self)
        {
            self.accummulatedSum += Int(char)
            self.accummulatedKind.append(char)
        }

        if buffer.isArgumentsDelimiterAtReader,
            let argumentsDelimiter = buffer.readInteger(as: UInt8.self)
        {
            self.accummulatedSum += Int(argumentsDelimiter)

            while !buffer.isChecksumDelimiterAtReader, let char = buffer.readInteger(as: UInt8.self) {
                self.accummulatedSum += Int(char)
                self.accummulatedArguments.append(char)
            }
        }

        // Command checksum delimiter.
        if !buffer.isChecksumDelimiterAtReader {
            // If delimiter not available yet, return `nil` to indicate that the caller needs to top up the buffer.
            return nil
        }

        defer {
            self.accummulatedKind = []
            self.accummulatedArguments = []
            self.accummulatedSum = 0
        }

        let kindString = String(decoding: self.accummulatedKind, as: UTF8.self)

        if let commandKind = GDBHostCommand.Kind(rawValue: kindString) {
            buffer.moveReaderIndex(forwardBy: 1)

            guard let checksumString = buffer.readString(length: 2),
                let first = checksumString.first?.hexDigitValue,
                let last = checksumString.last?.hexDigitValue
            else {
                throw Error.expectedChecksum
            }

            guard (first * 16) + last == self.accummulatedChecksum else {
                // FIXME: better diagnostics
                throw Error.checksumIncorrect
            }

            return .init(
                payload: .init(
                    kind: commandKind,
                    arguments: String(decoding: self.accummulatedArguments, as: UTF8.self)
                ),
                checksum: accummulatedChecksum,
            )
        } else {
            throw Error.unknownCommandKind(kindString)
        }
    }

    mutating package func decode(
        context: ChannelHandlerContext,
        buffer: inout ByteBuffer
    ) throws -> DecodingState {
        print(buffer.peekString(length: buffer.readableBytes)!)

        guard let command = try self.decode(buffer: &buffer) else {
            return .needMoreData
        }

        // Shift by checksum bytes
        context.fireChannelRead(wrapInboundOut(command))
        return .continue
        // } else {
        //     throw Error.unknownCommand(accummulated)
        // }
    }
}
