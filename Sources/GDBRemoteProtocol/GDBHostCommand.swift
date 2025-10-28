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

/// A command sent from a debugger host (GDB or LLDB) to a debugger target (a device
/// or a virtual machine being debugged).
/// See GDB and LLDB remote protocol documentation for more details:
/// * https://sourceware.org/gdb/current/onlinedocs/gdb.html/General-Query-Packets.html
/// * https://lldb.llvm.org/resources/lldbgdbremote.html
package struct GDBHostCommand: Equatable {
    /// Kind of the command sent from the debugger host to the debugger target.
    package enum Kind: String, Equatable {
        // Currently listed in the order that LLDB sends them in.
        case startNoAckMode
        case supportedFeatures
        case isThreadSuffixSupported
        case listThreadsInStopReply
        case hostInfo
        case vContSupportedActions
        case isVAttachOrWaitSupported
        case enableErrorStrings
        case processInfo
        case currentThreadID
        case firstThreadInfo
        case subsequentThreadInfo
        case targetStatus
        case registerInfo
        case structuredDataPlugins
        case transfer
        case readMemoryBinaryData
        case readMemory
        case wasmCallStack

        case generalRegisters

        /// Decodes kind of a command from a raw string sent from a host.
        package init?(rawValue: String) {
            switch rawValue {
            case "g":
                self = .generalRegisters
            case "QStartNoAckMode":
                self = .startNoAckMode
            case "qSupported":
                self = .supportedFeatures
            case "QThreadSuffixSupported":
                self = .isThreadSuffixSupported
            case "QListThreadsInStopReply":
                self = .listThreadsInStopReply
            case "qHostInfo":
                self = .hostInfo
            case "vCont?":
                self = .vContSupportedActions
            case "qVAttachOrWaitSupported":
                self = .isVAttachOrWaitSupported
            case "QEnableErrorStrings":
                self = .enableErrorStrings
            case "qProcessInfo":
                self = .processInfo
            case "qC":
                self = .currentThreadID
            case "qfThreadInfo":
                self = .firstThreadInfo
            case "qsThreadInfo":
                self = .subsequentThreadInfo
            case "?":
                self = .targetStatus
            case "qStructuredDataPlugins":
                self = .structuredDataPlugins
            case "qXfer":
                self = .transfer
            case "qWasmCallStack":
                self = .wasmCallStack

            default:
                return nil
            }
        }
    }

    /// The kind of a host command for the target to act upon.
    package let kind: Kind

    /// Arguments supplied with a host command.
    package let arguments: String

    /// Initialize a host command from raw strings sent from a host.
    /// - Parameters:
    ///   - kindString: raw ``String`` that denotes kind of the command.
    ///   - arguments: raw arguments that immediately follow kind of the command.
    package init(kindString: String, arguments: String) throws(GDBHostCommandDecoder.Error) {
        let registerInfoPrefix = "qRegisterInfo"

        if kindString.starts(with: "x") {
            self.kind = .readMemoryBinaryData
            self.arguments = String(kindString.dropFirst())
            return
        } else if kindString.starts(with: "m") {
            self.kind = .readMemory
            self.arguments = String(kindString.dropFirst())
            return
        } else if kindString.starts(with: registerInfoPrefix) {
            self.kind = .registerInfo

            guard arguments.isEmpty else {
                throw GDBHostCommandDecoder.Error.unexpectedArgumentsValue
            }
            self.arguments = String(kindString.dropFirst(registerInfoPrefix.count))
            return
        } else if let kind = Kind(rawValue: kindString) {
            self.kind = kind
        } else {
            throw GDBHostCommandDecoder.Error.unknownCommand(kind: kindString, arguments: arguments)
        }

        self.arguments = arguments
    }

    /// Member-wise initializer of `GDBHostCommand` type.
    package init(kind: Kind, arguments: String) {
        self.kind = kind
        self.arguments = arguments
    }
}
