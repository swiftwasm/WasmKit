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
        case threadStopInfo
        case symbolLookup
        case jsonThreadsInfo
        case jsonThreadExtendedInfo
        case resumeThreads
        case `continue`
        case kill
        case insertSoftwareBreakpoint
        case removeSoftwareBreakpoint
        case wasmLocal
        case memoryRegionInfo
        case detach

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
            case "qSymbol":
                self = .symbolLookup
            case "jThreadsInfo":
                self = .jsonThreadsInfo
            case "jThreadExtendedInfo":
                self = .jsonThreadExtendedInfo
            case "c":
                self = .continue
            case "k":
                self = .kill
            case "qWasmLocal":
                self = .wasmLocal
            case "qMemoryRegionInfo":
                self = .memoryRegionInfo
            case "D":
                self = .detach

            default:
                return nil
            }
        }
    }

    /// The kind of a host command for the target to act upon.
    package let kind: Kind

    /// Arguments supplied with a host command.
    package let arguments: String

    /// Helper type for representing parsing prefixes in host commands.
    private struct ParsingRule {
        /// Kind of the host command parsed by this rul.
        let kind: Kind

        /// String prefix required for the raw string to match for the rule
        /// to yield a parsed command.
        let prefix: String

        /// Whether command arguments use a `:` delimiter, which usually otherwise
        /// separates command kind from arguments.
        var argumentsContainColonDelimiter = false
    }

    private static let parsingRules: [ParsingRule] = [
        .init(
            kind: .readMemoryBinaryData,
            prefix: "x"
        ),
        .init(
            kind: .readMemory,
            prefix: "m"
        ),
        .init(
            kind: .insertSoftwareBreakpoint,
            prefix: "Z0"
        ),
        .init(
            kind: .removeSoftwareBreakpoint,
            prefix: "z0"
        ),
        .init(
            kind: .registerInfo,
            prefix: "qRegisterInfo"
        ),
        .init(
            kind: .threadStopInfo,
            prefix: "qThreadStopInfo"
        ),
        .init(
            kind: .resumeThreads,
            prefix: "vCont;",
            argumentsContainColonDelimiter: true
        ),
    ]

    /// Initialize a host command from raw strings sent from a host.
    /// - Parameters:
    ///   - kindString: raw ``String`` that denotes kind of the command.
    ///   - arguments: raw arguments that immediately follow kind of the command.
    package init(kindString: String, arguments: String) throws(GDBHostCommandDecoder.Error) {
        for rule in Self.parsingRules {
            if kindString.starts(with: rule.prefix) {
                self.kind = rule.kind
                let prependedArguments = kindString.dropFirst(rule.prefix.count)

                if rule.argumentsContainColonDelimiter {
                    self.arguments = "\(prependedArguments):\(arguments)"
                } else {
                    self.arguments = prependedArguments + arguments
                }
                return
            }
        }

        if let kind = Kind(rawValue: kindString) {
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
