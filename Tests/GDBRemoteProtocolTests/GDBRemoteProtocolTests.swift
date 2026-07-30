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

import GDBRemoteProtocol
import Testing

@Suite
struct GDBRemoteProtocolTests {
    var decoder: GDBHostCommandDecoder {
        GDBHostCommandDecoder(logger: .disabled)
    }

    @Test
    func decodingUnknownCommand() throws {
        var decoder = self.decoder
        // "p0" is "read single register 0" — not supported by WasmKit
        decoder.feed(Array("+$p0#a0".utf8))
        let packet = try decoder.next()
        #expect(packet?.payload.kind == .unsupported)
        #expect(packet?.payload.arguments == "p0")
    }

    @Test
    func decoding() throws {
        var decoder = GDBHostCommandDecoder(logger: .disabled)

        decoder.feed(Array("+$g#67".utf8))
        var packet = try decoder.next()
        #expect(packet == GDBPacket(payload: GDBHostCommand(kind: .generalRegisters, arguments: ""), checksum: 103))
        #expect(decoder.accummulatedChecksum == 0)

        decoder.feed(
            Array(
                """
                +$qSupported:xmlRegisters=i386,arm,mips,arc;multiprocess+;fork-events+;vfork-events+#2e
                """.utf8
            )
        )

        packet = try decoder.next()
        let expectedPacket = GDBPacket(
            payload: GDBHostCommand(
                kind: .supportedFeatures,
                arguments: "xmlRegisters=i386,arm,mips,arc;multiprocess+;fork-events+;vfork-events+"
            ),
            checksum: 0x2e
        )
        #expect(packet == expectedPacket)
        #expect(decoder.accummulatedChecksum == 0)
    }

    @Test
    func decodingWasmGlobal() throws {
        var decoder = self.decoder
        decoder.feed(Array("+$qWasmGlobal:0;1#30".utf8))
        let packet = try decoder.next()
        #expect(packet?.payload.kind == .wasmGlobal)
        #expect(packet?.payload.arguments == "0;1")
    }

    @Test
    func wasmGlobalMemberwiseInit() {
        let command = GDBHostCommand(kind: .wasmGlobal, arguments: "0;1")
        #expect(command.kind == .wasmGlobal)
        #expect(command.arguments == "0;1")
    }

    @Test
    func decodingSplitAcrossFeeds() throws {
        var decoder = self.decoder
        decoder.feed(Array("+$g".utf8))
        #expect(try decoder.next() == nil)
        decoder.feed(Array("#67".utf8))
        let packet = try decoder.next()
        #expect(packet == GDBPacket(payload: GDBHostCommand(kind: .generalRegisters, arguments: ""), checksum: 103))
    }

    @Test
    func encodingRoundTrip() {
        let encoder = GDBTargetResponseEncoder(logger: .disabled)
        let ok = encoder.encode(data: .init(kind: .ok, isNoAckModeActive: false))
        #expect(String(decoding: ok, as: UTF8.self) == "+$OK#9a")
        let binary = encoder.encode(data: .init(kind: .hexEncodedBinary([0xDE, 0xAD]), isNoAckModeActive: false))
        #expect(String(decoding: binary, as: UTF8.self) == "+$dead#8E")
    }
}
