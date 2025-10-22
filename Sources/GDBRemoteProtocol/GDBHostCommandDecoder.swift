//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Logging
import NIOCore

extension ByteBuffer {
    /// Returns `true` if byte to be read immediately is a GDB RP checksum
    /// delimiter. Returns `false` otherwise.
    var isChecksumDelimiterAtReader: Bool {
        self.peekInteger(as: UInt8.self) == UInt8(ascii: "#")
    }

    /// Returns `true` if byte to be read immediately is a GDB RP command arguments
    /// delimiter. Returns `false` otherwise.
    var isArgumentsDelimiterAtReader: Bool {
        self.peekInteger(as: UInt8.self) == UInt8(ascii: ":")
    }
}

/// Decoder of GDB RP host commands, that takes raw `ByteBuffer` as an input encoded
/// per https://sourceware.org/gdb/current/onlinedocs/gdb.html/Overview.html#Overview
/// and produces a `GDBPacket<GDBHostCommand>` value as output. This decoder is
/// compatible with NIO channel pipelines, making it easy to integrate with different
/// I/O configurations.
package struct GDBHostCommandDecoder: ByteToMessageDecoder {
    /// Errors that can be thrown during host command decoding.
    package enum Error: Swift.Error {
        /// Expected `+` acknowledgement character to be included in the packet, when
        /// ``GDBHostCommandDecoder/isNoAckModeActive`` is set to `false`.
        case expectedAck

        /// Expected command to start with `$` character`.
        case expectedCommandStart

        /// Expected checksum to be included with the packet was not found.
        case expectedChecksum

        /// Expected checksum included with the packet did not match the expected value.
        case checksumIncorrect(expectedChecksum: Int, receivedChecksum: UInt8)

        /// Unexpected arguments value supplied for a given command.
        case unexpectedArgumentsValue

        /// Host command kind could not be parsed. See `GDBHostCommand.Kind` for the
        /// list of supported commands.
        case unknownCommand(kind: String, arguments: String)
    }

    /// Type of the output value produced by this decoder.
    package typealias InboundOut = GDBPacket<GDBHostCommand>

    private var accumulatedDelimiter: UInt8?

    private var accummulatedKind = [UInt8]()
    private var accummulatedArguments = [UInt8]()
    
    /// Logger instance used by this decoder.
    private let logger: Logger
    
    /// Initializes a new decoder.
    /// - Parameter logger: logger instance that consumes messages from the newly
    /// initialized decoder.
    package init(logger: Logger) { self.logger = logger }
    
    /// Sum of the raw character values consumed in the current command so far,
    /// used in checksum computation.
    private var accummulatedSum = 0

    /// Computed checksum for the values consumed in the current command so far.
    package var accummulatedChecksum: UInt8 {
        UInt8(self.accummulatedSum % 256)
    }
    
    /// Whether `QStartNoAckMode` command was sent. Note that this is separate
    /// from ``isNoAckModeActive``. This mode is "activated" for the subsequent
    /// host command, which is when `isNoAckModeActive` is set by the decoder to
    /// `false`, but not for the immediate response.
    /// See https://sourceware.org/gdb/current/onlinedocs/gdb.html/Packet-Acknowledgment.html#Packet-Acknowledgment
    private var isNoAckModeRequested = false

    /// Whether `QStartNoAckMode` command was sent and this mode has been
    /// subsequently activated.
    /// See https://sourceware.org/gdb/current/onlinedocs/gdb.html/Packet-Acknowledgment.html#Packet-Acknowledgment
    private var isNoAckModeActive = false

    package mutating func decode(
        buffer: inout ByteBuffer
    ) throws(Error) -> GDBPacket<GDBHostCommand>? {
        guard var startDelimiter = self.accumulatedDelimiter ?? buffer.readInteger(as: UInt8.self) else {
            // Not enough data to parse.
            return nil
        }

        if !self.isNoAckModeActive {
            let firstStartDelimiter = startDelimiter

            guard firstStartDelimiter == UInt8(ascii: "+") else {
                logger.error("unexpected ack character: \(Character(UnicodeScalar(startDelimiter)))")
                throw Error.expectedAck
            }

            if self.isNoAckModeRequested {
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
            self.logger.error("unexpected delimiter: \(Character(UnicodeScalar(startDelimiter)))")
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

        buffer.moveReaderIndex(forwardBy: 1)

        guard let checksumString = buffer.readString(length: 2),
            let first = checksumString.first?.hexDigitValue,
            let last = checksumString.last?.hexDigitValue
        else {
            throw Error.expectedChecksum
        }

        let expectedChecksum = (first * 16) + last

        guard expectedChecksum == self.accummulatedChecksum else {
            throw Error.checksumIncorrect(
                expectedChecksum: expectedChecksum,
                receivedChecksum: self.accummulatedChecksum
            )
        }

        let payload = try GDBHostCommand(
            kindString: String(decoding: self.accummulatedKind, as: UTF8.self),
            arguments: String(decoding: self.accummulatedArguments, as: UTF8.self)
        )

        if payload.kind == .startNoAckMode {
            self.isNoAckModeRequested = true
        }

        return .init(payload: payload, checksum: accummulatedChecksum)
    }

    mutating package func decode(
        context: ChannelHandlerContext,
        buffer: inout ByteBuffer
    ) throws(Error) -> DecodingState {
        logger.trace(.init(stringLiteral: buffer.peekString(length: buffer.readableBytes)!))

        guard let command = try self.decode(buffer: &buffer) else {
            return .needMoreData
        }

        // Shift by checksum bytes
        context.fireChannelRead(wrapInboundOut(command))
        return .continue
    }
}
