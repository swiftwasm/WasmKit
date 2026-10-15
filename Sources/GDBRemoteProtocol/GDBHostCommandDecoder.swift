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

/// Decoder of GDB RP host commands, that takes raw bytes as an input encoded
/// per https://sourceware.org/gdb/current/onlinedocs/gdb.html/Overview.html#Overview
/// and produces `GDBPacket<GDBHostCommand>` values as output.
///
/// The decoder is transport-agnostic (sans-IO): feed it bytes from any source
/// with ``feed(_:)`` and drain decoded packets with ``next()``.
package struct GDBHostCommandDecoder {
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
    }

    /// Bytes received but not consumed yet.
    private var buffer = [UInt8]()
    /// Index of the next unconsumed byte in `buffer`.
    private var readerIndex = 0

    /// Logger instance used by this decoder.
    private let logger: GDBLogger

    /// Initializes a new decoder.
    /// - Parameter logger: logger instance that consumes messages from the newly
    /// initialized decoder.
    package init(logger: GDBLogger) { self.logger = logger }

    /// Sum of the raw character values consumed in the last command,
    /// used in checksum computation. Reset to zero once a packet completes.
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

    /// Appends newly received bytes to the decoder's internal buffer.
    package mutating func feed(_ bytes: some Sequence<UInt8>) {
        // Compact consumed bytes before growing the buffer.
        if readerIndex > 0 {
            buffer.removeFirst(readerIndex)
            readerIndex = 0
        }
        buffer.append(contentsOf: bytes)
    }

    /// Decodes the next host command from the accumulated bytes.
    ///
    /// Bytes are consumed only when a complete packet is available, so input
    /// may be split at arbitrary boundaries across ``feed(_:)`` calls.
    ///
    /// - Returns: The next decoded packet, or nil when more bytes are needed;
    ///   feed more input with ``feed(_:)`` and call again.
    package mutating func next() throws(Error) -> GDBPacket<GDBHostCommand>? {
        // Scan without consuming; `index` becomes the new `readerIndex` only
        // once a whole packet has been decoded.
        var index = readerIndex

        func peek() -> UInt8? {
            index < buffer.count ? buffer[index] : nil
        }
        func read() -> UInt8? {
            guard index < buffer.count else { return nil }
            defer { index += 1 }
            return buffer[index]
        }

        guard var startDelimiter = read() else {
            // Not enough data to parse.
            return nil
        }

        // Whether decoding this packet completes activation of no-ack mode:
        // the packet following `QStartNoAckMode` still carries the host's
        // final `+` (acknowledging our response); later ones don't.
        var activatesNoAckMode = false
        if !self.isNoAckModeActive {
            guard startDelimiter == UInt8(ascii: "+") else {
                logger.error("unexpected ack character: \(Character(UnicodeScalar(startDelimiter)))")
                throw Error.expectedAck
            }

            guard let secondStartDelimiter = read() else {
                // Not enough data to parse.
                return nil
            }

            startDelimiter = secondStartDelimiter
            activatesNoAckMode = self.isNoAckModeRequested
        }

        // Command start delimiters.
        guard startDelimiter == UInt8(ascii: "$") else {
            self.logger.error("unexpected delimiter: \(Character(UnicodeScalar(startDelimiter)))")
            throw Error.expectedCommandStart
        }

        var sum = 0
        var kind = [UInt8]()
        var arguments = [UInt8]()

        // Command kind, up to the arguments or checksum delimiter.
        while let char = peek(), char != UInt8(ascii: "#"), char != UInt8(ascii: ":") {
            index += 1
            sum += Int(char)
            kind.append(char)
        }

        if peek() == UInt8(ascii: ":") {
            let argumentsDelimiter = read()!
            sum += Int(argumentsDelimiter)

            while let char = peek(), char != UInt8(ascii: "#") {
                index += 1
                sum += Int(char)
                arguments.append(char)
            }
        }

        // Command checksum delimiter followed by two checksum digits.
        guard peek() == UInt8(ascii: "#") else {
            // Not enough data to parse; the caller needs to top up the buffer.
            return nil
        }
        index += 1

        guard let firstChecksumByte = read(), let secondChecksumByte = read() else {
            // Not enough data to parse.
            return nil
        }
        guard let first = Character(UnicodeScalar(firstChecksumByte)).hexDigitValue,
            let last = Character(UnicodeScalar(secondChecksumByte)).hexDigitValue
        else {
            throw Error.expectedChecksum
        }

        let expectedChecksum = (first * 16) + last
        let receivedChecksum = UInt8(sum % 256)

        guard expectedChecksum == receivedChecksum else {
            throw Error.checksumIncorrect(
                expectedChecksum: expectedChecksum,
                receivedChecksum: receivedChecksum
            )
        }

        let payload = GDBHostCommand(
            kindString: String(decoding: kind, as: UTF8.self),
            arguments: String(decoding: arguments, as: UTF8.self)
        )

        if payload.kind == .startNoAckMode {
            self.isNoAckModeRequested = true
        }
        if activatesNoAckMode {
            self.isNoAckModeActive = true
        }

        // The packet is complete: consume it.
        readerIndex = index
        return .init(payload: payload, checksum: receivedChecksum)
    }
}
