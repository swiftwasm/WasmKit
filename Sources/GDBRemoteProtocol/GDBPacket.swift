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

/// GDB host commands and target responses are wrapped with delimiters followed
/// by a single byte checksum value. This type denotes such a packet by attaching
/// a checksum value to the contained payload.
/// See GDB remote protocol overview for more details:
/// https://sourceware.org/gdb/current/onlinedocs/gdb.html/Overview.html#Overview
package struct GDBPacket<Payload: Sendable>: Sendable {
    package let payload: Payload
    package let checksum: UInt8

    package init(payload: Payload, checksum: UInt8) {
        self.payload = payload
        self.checksum = checksum
    }
}

extension GDBPacket: Equatable where Payload: Equatable {}
