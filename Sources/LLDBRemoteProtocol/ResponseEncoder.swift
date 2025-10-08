import Foundation
import NIOCore

package struct ResponseEncoder: MessageToByteEncoder {
    package init() {}
    package func encode(data: TargetResponse, out: inout ByteBuffer) throws {
        if !data.isNoAckModeActive {
            out.writeInteger(UInt8(ascii: "+"))
        }
        out.writeInteger(UInt8(ascii: "$"))

        switch data.kind {
        case .ok:
            out.writeBytes("ok#da".utf8)

        case .raw(let str):
            out.writeBytes(
                "\(str)#\(String(format:"%02X", str.utf8.reduce(0, { $0 + Int($1) }) % 256))".utf8)

        case .empty:
            fatalError("unhandled")
        }
    }
}
