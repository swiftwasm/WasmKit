package struct GDBPacket<Payload: Sendable>: Sendable {
    package let payload: Payload
    package let checksum: UInt8

    package init(payload: Payload, checksum: UInt8) {
        self.payload = payload
        self.checksum = checksum
    }
}

extension GDBPacket: Equatable where Payload: Equatable {}
