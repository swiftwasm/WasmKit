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

extension String {
    /// Computes a GDB RP checksum of characters in a given string.
    fileprivate var appendedChecksum: String {
        "\(self)#\(HexEncoding.encodeByteUppercase(UInt8(self.utf8.reduce(0, { $0 + Int($1) }) % 256)))"
    }
}

/// Encoder of GDB RP target responses, that takes ``GDBTargetResponse`` as an input
/// and encodes it per https://sourceware.org/gdb/current/onlinedocs/gdb.html/Overview.html#Overview
/// format into raw bytes as output. The encoder is transport-agnostic
/// (sans-IO): write the returned bytes to any transport.
package final class GDBTargetResponseEncoder {
    private var isNoAckModeActive = false

    private let logger: GDBLogger

    package init(logger: GDBLogger) {
        self.logger = logger
    }

    package func encode(data: GDBTargetResponse) -> [UInt8] {
        var out = [UInt8]()
        if !isNoAckModeActive {
            out.append(UInt8(ascii: "+"))
        }
        if data.isNoAckModeActive {
            self.isNoAckModeActive = true
        }
        out.append(UInt8(ascii: "$"))

        switch data.kind {
        case .ok:
            out.append(contentsOf: "OK#9a".utf8)

        case .keyValuePairs(let info):
            out.append(contentsOf: info.map { (key, value) in "\(key):\(value);" }.joined().appendedChecksum.utf8)

        case .vContSupportedActions(let actions):
            out.append(contentsOf: "vCont;\(actions.map { "\($0.rawValue);" }.joined())".appendedChecksum.utf8)

        case .string(let str):
            out.append(contentsOf: str.appendedChecksum.utf8)

        case .hexEncodedBinary(let binary):
            let hexDumpResponse = HexEncoding.encode(binary).appendedChecksum
            self.logger.trace("GDBTargetResponseEncoder encoded a response: \(hexDumpResponse)")
            out.append(contentsOf: hexDumpResponse.utf8)

        case .empty:
            out.append(contentsOf: "".appendedChecksum.utf8)
        }
        return out
    }
}
