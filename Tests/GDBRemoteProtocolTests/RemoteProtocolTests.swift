import GDBRemoteProtocol
import NIOCore
import Testing

@Suite
struct LLDBRemoteProtocolTests {
    @Test
    func decoding() throws {
        var decoder = GDBHostCommandDecoder()

        var buffer = ByteBuffer(string: "+$g#67")
        var packet = try decoder.decode(buffer: &buffer)
        #expect(packet == Packet(payload: GDBHostCommand(kind: .generalRegisters, arguments: ""), checksum: 103))
        #expect(decoder.accummulatedChecksum == 0)

        buffer = ByteBuffer(
            string: """
                +$qSupported:xmlRegisters=i386,arm,mips,arc;multiprocess+;fork-events+;vfork-events+#2e
                """
        )

        packet = try decoder.decode(buffer: &buffer)
        let expectedPacket = Packet(
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
