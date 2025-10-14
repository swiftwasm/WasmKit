import Logging
import NIOCore

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
        case expectedAck
        case expectedCommandStart
        case unknownCommandKind(String)
        case expectedChecksum
        case checksumIncorrect
    }

    package typealias InboundOut = GDBPacket<GDBHostCommand>

    private var accumulatedDelimiter: UInt8?

    private var accummulatedKind = [UInt8]()
    private var accummulatedArguments = [UInt8]()

    private let logger: Logger

    package init(logger: Logger) { self.logger = logger }

    private var accummulatedSum = 0
    package var accummulatedChecksum: UInt8 {
        UInt8(self.accummulatedSum % 256)
    }

    private var isNoAckModeRequested = false
    private var isNoAckModeActive = false

    mutating package func decode(buffer: inout ByteBuffer) throws -> GDBPacket<GDBHostCommand>? {
        guard var startDelimiter = self.accumulatedDelimiter ?? buffer.readInteger(as: UInt8.self) else {
            // Not enough data to parse.
            return nil
        }

        if !isNoAckModeActive {
            let firstStartDelimiter = startDelimiter

            guard firstStartDelimiter == UInt8(ascii: "+") else {
                logger.error("unexpected ack character: \(Character(UnicodeScalar(startDelimiter)))")
                throw Error.expectedAck
            }

            if isNoAckModeRequested {
                self.isNoAckModeActive = true
            }

            guard let secondStartDelimiter = buffer.readInteger(as: UInt8.self) else {
                // Preserve what we already read.
                self.accumulatedDelimiter = firstStartDelimiter

                // Not enough data to parse.
                return nil
            }

            startDelimiter = secondStartDelimiter
        }

        // Command start delimiters.
        guard startDelimiter == UInt8(ascii: "$") else {
            logger.error("unexpected delimiter: \(Character(UnicodeScalar(startDelimiter)))")
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
            self.accumulatedDelimiter = nil
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

            if commandKind == .startNoAckMode {
                self.isNoAckModeRequested = true
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
        logger.trace(.init(stringLiteral: buffer.peekString(length: buffer.readableBytes)!))

        guard let command = try self.decode(buffer: &buffer) else {
            return .needMoreData
        }

        // Shift by checksum bytes
        context.fireChannelRead(wrapInboundOut(command))
        return .continue
    }
}
