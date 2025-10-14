import Foundation
import NIOCore

extension String {
    fileprivate var appendedChecksum: String.UTF8View {
        "\(self)#\(String(format:"%02X", self.utf8.reduce(0, { $0 + Int($1) }) % 256))".utf8
    }
}

package class GDBTargetResponseEncoder: MessageToByteEncoder {
    private var isNoAckModeActive = false

    package init() {}
    package func encode(data: GDBTargetResponse, out: inout ByteBuffer) throws {
        if !isNoAckModeActive {
            out.writeInteger(UInt8(ascii: "+"))
        }
        if data.isNoAckModeActivated {
            self.isNoAckModeActive = true
        }
        out.writeInteger(UInt8(ascii: "$"))

        switch data.kind {
        case .ok:
            out.writeBytes("OK#9a".utf8)

        case .keyValuePairs(let info):
            out.writeBytes(info.map { (key, value) in "\(key):\(value);" }.joined().appendedChecksum)

        case .vContSupportedActions(let actions):
            out.writeBytes("vCont;\(actions.map { "\($0.rawValue);" }.joined())".appendedChecksum)

        case .raw(let str):
            out.writeBytes(str.appendedChecksum)

        case .empty:
            out.writeBytes("".appendedChecksum)
        }
    }
}
