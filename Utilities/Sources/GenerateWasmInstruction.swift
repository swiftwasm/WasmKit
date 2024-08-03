import Foundation

/// A utility for generating Core Wasm instruction related code based on the `Instructions.json` file.
enum GenerateWasmInstruction {

    struct Instruction: Decodable {
        let feature: String
        let name: String?
        let prefix: UInt8?
        let opcode: UInt8
        let enumCaseName: String
        let visitMethodName: String
        let immediates: [Immediate]

        struct Immediate: Comparable, Hashable {
            let label: String
            let type: String

            static func < (lhs: Immediate, rhs: Immediate) -> Bool {
                guard lhs.label != rhs.label else {
                    return lhs.type < rhs.type
                }
                return lhs.label < rhs.label
            }
        }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            func decodeHex() throws -> UInt8 {
                let hexString = try container.decode(String.self)
                return UInt8(hexString.dropFirst(2), radix: 16)!
            }
            feature = try container.decode(String.self)
            if (try? container.decodeNil()) == true {
                name = nil
            } else {
                name = try container.decode(String.self)
            }
            if (try? container.decodeNil()) == true {
                prefix = nil
            } else {
                prefix = try decodeHex()
            }
            opcode = try decodeHex()
            enumCaseName = try container.decode(String.self)
            visitMethodName = try container.decode(String.self)
            let rawImmediates: [[String]]
            if container.isAtEnd {
                rawImmediates = []
            } else {
                rawImmediates = try container.decode([[String]].self)
            }
            immediates = rawImmediates.map { Immediate(label: $0[0], type: $0[1]) }
        }
    }

    typealias InstructionSet = [Instruction]

    static func generateVisitorProtocol(_ instructions: InstructionSet) -> String {
        var code = """
            /// A visitor for WebAssembly instructions.
            ///
            /// The visitor pattern is used while parsing WebAssembly expressions to allow for easy extensibility.
            /// See the following parsing functions:
            /// - ``parseExpression(bytes:features:hasDataCount:visitor:)``
            /// - ``parseExpression(stream:features:hasDataCount:visitor:)``
            public protocol InstructionVisitor {

                /// The return type of visitor methods.
                associatedtype Output
            """

        for instruction in instructions {
            code += "\n"
            code += "    /// Visiting `\(instruction.name ?? instruction.enumCaseName)` instruction.\n"
            code += "    mutating func \(instruction.visitMethodName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.type)"
            }.joined(separator: ", ")
            code += ") throws -> Output"
        }

        code += """

            }
            """

        code += """


        extension InstructionVisitor {
            /// Visits an instruction.
            public mutating func visit(_ instruction: Instruction) throws -> Output {
                switch instruction {

        """

        for instruction in instructions {
            if instruction.immediates.isEmpty {
                code += "        case .\(instruction.enumCaseName): return try \(instruction.visitMethodName)()\n"
            } else {
                code += "        case let .\(instruction.enumCaseName)("
                code += instruction.immediates.map(\.label).joined(separator: ", ")
                code += "): return try \(instruction.visitMethodName)("
                code += instruction.immediates.map {
                    "\($0.label): \($0.label)"
                }.joined(separator: ", ")
                code += ")\n"
            }
        }

        code += "        }\n"
        code += "    }\n"
        code += "}\n"


        code += """


            /// A visitor for WebAssembly instructions that returns `Void` with default implementations.
            public protocol VoidInstructionVisitor: InstructionVisitor where Output == Void {}

            extension VoidInstructionVisitor {

            """
        for instruction in instructions {
            code += "    public mutating func \(instruction.visitMethodName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.type)"
            }.joined(separator: ", ")
            code += ") throws -> Void {}\n"
        }
        code += "}\n"

        return code
    }

    static func generateInstructionEnum(_ instructions: InstructionSet) -> String {
        var code = """
            public enum Instruction: Equatable {

            """

        for instruction in instructions {
            code += "    case `\(instruction.enumCaseName)`"
            if !instruction.immediates.isEmpty {
                code +=
                    "("
                    + instruction.immediates.map {
                        "\($0.label): \($0.type)"
                    }.joined(separator: ", ") + ")"
            }
            code += "\n"
        }

        code += "}"

        return code
    }

    static func buildInstructionInstanceFromContext(_ instruction: Instruction) -> String {
        var code = ""
        if instruction.immediates.isEmpty {
            code += ".\(instruction.enumCaseName)"
        } else {
            code += ".\(instruction.enumCaseName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.label)"
            }.joined(separator: ", ")
            code += ")"
        }
        return code
    }

    static func generateAnyInstructionVisitor(_ instructions: InstructionSet) -> String {
        var code = """
            /// A visitor that visits all instructions by a single visit method.
            public protocol AnyInstructionVisitor: InstructionVisitor {
                /// Visiting any instruction.
                mutating func visit(_ instruction: Instruction) throws -> Output
            }

            extension AnyInstructionVisitor {

            """

        for instruction in instructions {
            code += "    public mutating func \(instruction.visitMethodName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.type)"
            }.joined(separator: ", ")
            code += ") throws -> Output { "
            code += "return try self.visit(" + buildInstructionInstanceFromContext(instruction) + ")"
            code += " }\n"
        }

        code += "}"

        return code
    }

    static func generateTracingVisitor(_ instructions: InstructionSet) -> String {
        var code = """
            /// A visitor that traces the instructions visited.
            public struct InstructionTracingVisitor<V: InstructionVisitor>: InstructionVisitor {
                /// A closure that is invoked with the visited instruction.
                public let trace: (Instruction) -> Void
                /// The visitor to forward the instructions to.
                public var visitor: V

                /// Creates a new tracing visitor.
                ///
                /// - Parameters:
                ///   - trace: A closure that is invoked with the visited instruction.
                ///   - visitor: The visitor to forward the instructions to.
                public init(trace: @escaping (Instruction) -> Void, visitor: V) {
                    self.trace = trace
                    self.visitor = visitor
                }

            """

        for instruction in instructions {
            code += "    public mutating func \(instruction.visitMethodName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.type)"
            }.joined(separator: ", ")
            code += ") throws -> V.Output {\n"
            code += "       trace("
            code += buildInstructionInstanceFromContext(instruction)
            code += ")\n"
            code += "       return try visitor.\(instruction.visitMethodName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.label)"
            }.joined(separator: ", ")
            code += ")\n"
            code += "    }\n"
        }

        code += "}"

        return code
    }

    static func generateTextParser(_ instructions: InstructionSet) -> String {
        var code = """
            import WasmParser

            /// Parses a text instruction, consuming immediate tokens as necessary.
            /// - Parameters:
            ///   - keyword: The keyword of the instruction.
            ///   - expressionParser: The expression parser.
            /// - Returns: A closure that invokes the corresponding visitor method. Nil if the keyword is not recognized.
            ///
            /// Note: The returned closure does not consume any tokens.
            func parseTextInstruction<V: InstructionVisitor>(keyword: String, expressionParser: inout ExpressionParser<V>, wat: inout Wat) throws -> ((inout V) throws -> V.Output)? {
                switch keyword {

            """

        for instruction in instructions {
            guard let name = instruction.name else {
                continue
            }
            code += "    case \"\(name)\":"
            if !instruction.immediates.isEmpty {
                code += "\n"
                code += "        let ("
                code += instruction.immediates.map(\.label).joined(separator: ", ")
                code += ") = try expressionParser.\(instruction.visitMethodName)(wat: &wat)\n"
                code += "        "
            } else {
                code += " "
            }
            code += "return { return try $0.\(instruction.visitMethodName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.label)"
            }.joined(separator: ", ")
            code += ") }\n"
        }
        code += "    default: return nil\n"
        code += "    }\n"
        code += "}\n"

        /*
         // Generate placeholder implementations
         code += """

         extension ExpressionParser {

         """
         for instruction in instructions {
         guard !instruction.immediates.isEmpty else {
         continue
         }
         code += "    mutating func \(instruction.visitMethodName)() throws -> "
         if instruction.immediates.count == 1 {
         code += instruction.immediates[0].type
         } else {
         code += "(" + instruction.immediates.map { i in
         "\(i.label): \(i.type)"
         }.joined(separator: ", ") + ")"
         }
         code += " {\n"
         code += "        try notImplemented()\n"
         code += "    }\n"
         }
         code += "}\n"
         */
        return code
    }

    static func generateInstructionEncoder(_ instructions: InstructionSet) -> String {
        var code = """

            protocol InstructionEncoder: InstructionVisitor {
                mutating func encodeInstruction(_ opcode: UInt8, _ prefix: UInt8?) throws

            """

        var immediateTypes: Set<[Instruction.Immediate]> = []
        for instruction in instructions {
            guard !instruction.immediates.isEmpty else { continue }
            immediateTypes.insert(instruction.immediates)
        }
        let immediateTypesArray = immediateTypes.sorted(by: {
            if $0.count != $1.count {
                return $0.count < $1.count
            }
            for (lhs, rhs) in zip($0, $1) {
                if lhs.label != rhs.label {
                    return lhs.label < rhs.label
                }
                if lhs.type != rhs.type {
                    return lhs.type < rhs.type
                }
            }
            return false
        })
        for immediates in immediateTypesArray {
            code += "    mutating func encodeImmediates("
            code += immediates.map { i in
                "\(i.label): \(i.type)"
            }.joined(separator: ", ")
            code += ") throws\n"
        }

        code += """
            }

            extension InstructionEncoder {

            """

        for instruction in instructions {
            var encodeInstrCall = "try encodeInstruction("
            encodeInstrCall += [
                String(format: "0x%02X", instruction.opcode),
                instruction.prefix.map { String(format: "0x%02X", $0) } ?? "nil",
            ].joined(separator: ", ")
            encodeInstrCall += ")"

            code += "    mutating func \(instruction.visitMethodName)("
            code += instruction.immediates.map { i in
                "\(i.label): \(i.type)"
            }.joined(separator: ", ")
            code += ") throws {"
            if instruction.immediates.isEmpty {
                code += " \(encodeInstrCall) "
            } else {
                code += "\n"
                code += "        \(encodeInstrCall)\n"
                code += "        try encodeImmediates("
                code += instruction.immediates.map { "\($0.label): \($0.label)" }.joined(separator: ", ")
                code += ")\n"
                code += "    "
            }

            code += "}\n"
        }

        code += "}\n"

        return code
    }

    static func formatInstructionSet(_ instructions: InstructionSet) -> String {
        var json = ""
        json += "[\n"

        struct ColumnInfo {
            var header: String
            var maxWidth: Int
            var value: (Instruction) -> String
        }

        var columns: [ColumnInfo] = [
            ColumnInfo(header: "Feature", maxWidth: 0, value: { "\"" + $0.feature + "\"" }),
            ColumnInfo(
                header: "Name", maxWidth: 0,
                value: {
                    $0.name.map { "\"" + $0 + "\"" } ?? "null"
                }),
            ColumnInfo(
                header: "Prefix", maxWidth: 0,
                value: { i in
                    if let prefix = i.prefix {
                        return "\"" + String(format: "0x%02X", prefix) + "\""
                    } else {
                        return "null"
                    }
                }),
            ColumnInfo(header: "Opcode", maxWidth: 0, value: { "\"" + String(format: "0x%02X", $0.opcode) + "\"" }),
            ColumnInfo(header: "Enum Case", maxWidth: 0, value: { "\"" + $0.enumCaseName + "\"" }),
            ColumnInfo(header: "Visit Method", maxWidth: 0, value: { "\"" + $0.visitMethodName + "\"" }),
            ColumnInfo(
                header: "Immediates", maxWidth: 0,
                value: { i in
                    return "["
                        + i.immediates.map { i in
                            "[\"\(i.label)\", \"\(i.type)\"]"
                        }.joined(separator: ", ") + "]"
                }),
        ]
        for instruction in instructions {
            for columnIndex in columns.indices {
                var column = columns[columnIndex]
                let value = column.value(instruction)
                column.maxWidth = max(column.maxWidth, value.count)
                columns[columnIndex] = column
            }
        }

        for (index, instruction) in instructions.enumerated() {
            json += "    ["
            for (columnIndex, column) in columns.enumerated() {
                let value = column.value(instruction)
                json += value.padding(toLength: column.maxWidth, withPad: " ", startingAt: 0)
                if columnIndex != columns.count - 1 {
                    json += ", "
                }
            }

            if index == instructions.count - 1 {
                json += "]\n"
            } else {
                json += "],\n"
            }
        }
        json += "]\n"
        return json
    }

    static func main(args: [String]) throws {
        let sourceRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: sourceRoot.appending(path: "Utilities/Instructions.json"))
        let instructions = try JSONDecoder().decode(InstructionSet.self, from: data)

        if args.count > 1, args[1] == "format" {
            print(formatInstructionSet(instructions))
            return
        }

        do {
            let outputFile = sourceRoot.appending(path: "Sources/WasmParser/InstructionVisitor.swift")
            var output = """
                // swift-format-ignore-file
                // This file is generated by Utilities/generate_inst_visitor.swift

                """
            output += generateInstructionEnum(instructions)
            output += "\n\n"
            output += generateAnyInstructionVisitor(instructions)
            output += "\n\n"
            output += generateTracingVisitor(instructions)
            output += "\n\n"
            output += generateVisitorProtocol(instructions)
            output += "\n"
            try output.write(to: outputFile, atomically: true, encoding: .utf8)
        }

        do {
            let outputFile = sourceRoot.appending(path: "Sources/WAT/ParseInstruction.swift")
            var output = """
                // swift-format-ignore-file
                // This file is generated by Utilities/generate_inst_visitor.swift

                """
            output += generateTextParser(instructions)
            output += "\n"
            output += generateInstructionEncoder(instructions)
            try output.write(to: outputFile, atomically: true, encoding: .utf8)
        }
    }
}
