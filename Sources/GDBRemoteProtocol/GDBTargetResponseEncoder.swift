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

        case .string(let str):
            out.writeString(str.appendedChecksum)

        case .hexEncodedBinary(let binary):
            let hexDump = ByteBuffer(bytes: binary).hexDump(format: .compact)
            out.writeString(hexDump.appendedChecksum)

        case .empty:
            out.writeString("".appendedChecksum)
        }
    }
}
