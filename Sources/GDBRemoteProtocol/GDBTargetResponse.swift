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

import NIOCore

/// Actions supported in the `vCont` host command.
package enum VContActions: String {
    case `continue` = "c"
    case continueWithSignal = "C"
    case step = "s"
    case stepWithSignal = "S"
    case stop = "t"
    case stepInRange = "r"
}

package struct GDBTargetResponse {
    package enum Kind {
        case ok
        case keyValuePairs(KeyValuePairs<String, String>)
        case vContSupportedActions([VContActions])
        case string(String)
        case hexEncodedBinary(ByteBufferView)
        case empty
    }

    package let kind: Kind
    package let isNoAckModeActivated: Bool

    package init(kind: Kind, isNoAckModeActivated: Bool) {
        self.kind = kind
        self.isNoAckModeActivated = isNoAckModeActivated
    }
}
