import Foundation
import NIOCore

extension String {
    fileprivate var appendedChecksum: String {
        "\(self)#\(String(format:"%02X", self.utf8.reduce(0, { $0 + Int($1) }) % 256))"
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
            out.writeString("OK#9a")

        case .keyValuePairs(let info):
            out.writeString(info.map { (key, value) in "\(key):\(value);" }.joined().appendedChecksum)

        case .vContSupportedActions(let actions):
            out.writeString("vCont;\(actions.map { "\($0.rawValue);" }.joined())".appendedChecksum)

        case .raw(let str):
            out.writeString(str.appendedChecksum)

        case .empty:
            out.writeString("".appendedChecksum)
        }
    }
}
