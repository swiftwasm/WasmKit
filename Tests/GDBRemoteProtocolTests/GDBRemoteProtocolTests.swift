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
import Logging
import NIOCore
import Testing

@Suite
struct GDBRemoteProtocolTests {
    @Test
    func decoding() throws {
        var logger = Logger(label: "com.swiftwasm.WasmKit.tests")
        logger.logLevel = .critical
        var decoder = GDBHostCommandDecoder(logger: logger)

        var buffer = ByteBuffer(string: "+$g#67")
        var packet = try decoder.decode(buffer: &buffer)
        #expect(packet == GDBPacket(payload: GDBHostCommand(kind: .generalRegisters, arguments: ""), checksum: 103))
        #expect(decoder.accummulatedChecksum == 0)

        buffer = ByteBuffer(
            string: """
                +$qSupported:xmlRegisters=i386,arm,mips,arc;multiprocess+;fork-events+;vfork-events+#2e
                """
        )

        packet = try decoder.decode(buffer: &buffer)
        let expectedPacket = GDBPacket(
            payload: GDBHostCommand(
                kind: .supportedFeatures,
                arguments: "xmlRegisters=i386,arm,mips,arc;multiprocess+;fork-events+;vfork-events+"
            ),
            checksum: 0x2e,
        )
        #expect(packet == expectedPacket)
        #expect(decoder.accummulatedChecksum == 0)
    }
}
