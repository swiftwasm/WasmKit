import Foundation
import NIOCore

extension String {
    fileprivate var appendedChecksum: String.UTF8View {
        "\(self)#\(String(format:"%02X", self.utf8.reduce(0, { $0 + Int($1) }) % 256))".utf8
    }
}

package struct GDBTargetResponseEncoder: MessageToByteEncoder {
    package init() {}
    package func encode(data: TargetResponse, out: inout ByteBuffer) throws {
        if !data.isNoAckModeActive {
            out.writeInteger(UInt8(ascii: "+"))
        }
        out.writeInteger(UInt8(ascii: "$"))

        switch data.kind {
        case .ok:
            out.writeBytes("ok#da".utf8)

        case .hostInfo(let info):
            out.writeBytes(info.map { (key, value) in "\(key):\(value);"}.joined().appendedChecksum)

        case .vContSupportedActions(let actions):
            out.writeBytes("vCont;\(actions.map(\.rawValue).joined())".appendedChecksum)

        case .raw(let str):
            out.writeBytes(str.appendedChecksum)

        case .empty:
            out.writeBytes("".appendedChecksum)
        }
    }
}
