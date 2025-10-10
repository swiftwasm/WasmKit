import Foundation

/// A utility for generating Core Wasm instruction related code based on the `Instructions.json` file.
enum WasmGen {

    static func pascalCase(camelCase: String) -> String {
        camelCase.prefix(1).uppercased() + camelCase.dropFirst()
    }

    struct Instruction: Decodable {
        let feature: String
        let name: Name
        let opcode: [UInt8]
        let immediates: [Immediate]
        let category: String?

        var visitMethodName: String {
            if let explicitCategory = category {
                return "visit" + WasmGen.pascalCase(camelCase: explicitCategory)
            } else {
                return "visit" + WasmGen.pascalCase(camelCase: name.enumCase)
            }
        }

        enum Name: Decodable {
            struct WithEnumCase: Decodable {
                let enumCase: String
            }
            /// The instruction name in the Wasm text format.
            case textual(String)
            /// The instruction name in Swift enum case.
            case withEnumCase(WithEnumCase)

            var text: String? {
                switch self {
                case let .textual(text): return text
                case .withEnumCase: return nil
                }
            }

            var enumCase: String {
                switch self {
                case .textual(let name):
                    // e.g. i32.load -> i32Load, br_table -> brTable
                    let components = name.split(separator: ".").flatMap {
                        $0.split(separator: "_")
                    }
                    return components.first! + components.dropFirst().map(\.capitalized).joined()
                case let .withEnumCase(name): return name.enumCase
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let withEnumCase = try? container.decode(WithEnumCase.self) {
                    self = .withEnumCase(withEnumCase)
                } else {
                    self = .textual(try container.decode(String.self))
                }
            }
        }

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
            func decodeHexArray() throws -> [UInt8] {
                let hexStrings = try container.decode([String].self)
                return hexStrings.map { UInt8($0.dropFirst(2), radix: 16)! }
            }
            feature = try container.decode(String.self)
            name = try container.decode(Name.self)
            opcode = try decodeHexArray()
            let rawImmediates = try container.decode([[String]].self)
            immediates = rawImmediates.map { Immediate(label: $0[0], type: $0[1]) }
            category = try? container.decode(String.self)
        }
    }

    typealias InstructionSet = [Instruction]

    static func generateVisitorProtocol(_ instructions: InstructionSet) -> String {
        var code = """
            /// A visitor for WebAssembly instructions.
            ///
            /// The visitor pattern is used while parsing WebAssembly expressions to allow for easy extensibility.
            /// See the expression parsing method ``Code/parseExpression(visitor:)``
            public protocol InstructionVisitor {
                /// Current offset in visitor's instruction stream.
                var currentOffset: Int { get set }
            """

        for instruction in instructions.categorized {
            code += "\n"
            code += "    /// Visiting \(instruction.description) instruction.\n"
            code += "    mutating func \(instruction.visitMethodName)("
            code += instruction.associatedValues.map { i in
                "\(i.argumentName ?? "_"): \(i.type)"
            }.joined(separator: ", ")
            code += ") throws"
        }

        code += """

                /// Returns: `true` if the parser should silently proceed parsing.
                mutating func visitUnknown(_ opcode: [UInt8]) throws -> Bool
            }
            """

        code += """


            extension InstructionVisitor {
                /// Visits an instruction.
                public mutating func visit(_ instruction: Instruction) throws {
                    switch instruction {

            """

        for instruction in instructions.categorized {
            if instruction.associatedValues.isEmpty {
                code += "        case .\(instruction.enumCaseName): return try \(instruction.visitMethodName)()\n"
            } else {
                code += "        case let .\(instruction.enumCaseName)("
                code += instruction.associatedValues.map(\.parameterName).joined(separator: ", ")
                code += "): return try \(instruction.visitMethodName)("
                code += instruction.associatedValues.map {
                    if let label = $0.argumentName {
                        return "\(label): \(label)"
                    } else {
                        return $0.parameterName
                    }
                }.joined(separator: ", ")
                code += ")\n"
            }
        }

        code += "        }\n"
        code += "    }\n"
        code += "}\n"

        code += """

            // MARK: - Placeholder implementations
            extension InstructionVisitor {

            """
        for instruction in instructions.categorized {
            code += "    public mutating func \(instruction.visitMethodName)("
            code += instruction.associatedValues.map { i in
                if i.argumentName == i.parameterName {
                    return "\(i.parameterName): \(i.type)"
                } else {
                    return "\(i.argumentName ?? "_") \(i.parameterName): \(i.type)"
                }
            }.joined(separator: ", ")
            code += ") throws {}\n"
        }
        code += """
            public mutating func visitUnknown(_ opcode: [UInt8]) throws -> Bool { false }
        }

        """

        return code
    }

    static func generateInstructionEnum(_ instructions: InstructionSet) -> String {
        var code = """
            import WasmTypes

            public enum Instruction: Equatable {

            """

        let categorized = instructions.categorized

        for instruction in categorized {
            guard let categoryTypeName = instruction.categoryTypeName else { continue }
            code += "    public enum \(categoryTypeName): Equatable {\n"
            for sourceInstruction in instruction.sourceInstructions {
                code += "        case \(sourceInstruction.name.enumCase)\n"
            }
            code += "    }\n"
        }

        for instruction in categorized {
            code += "    case `\(instruction.enumCaseName)`"
            let associatedValues = instruction.associatedValues
            if !associatedValues.isEmpty {
                code +=
                    "("
                    + associatedValues.map {
                        if let label = $0.argumentName {
                            return "\(label): \($0.type)"
                        } else {
                            return $0.type
                        }
                    }.joined(separator: ", ") + ")"
            }
            code += "\n"
        }

        code += "}"

        return code
    }

    static func buildInstructionInstanceFromContext(_ instruction: CategorizedInstruction) -> String {
        var code = ""
        if instruction.associatedValues.isEmpty {
            code += ".\(instruction.enumCaseName)"
        } else {
            code += ".\(instruction.enumCaseName)("
            code += instruction.associatedValues.map { i in
                if let label = i.argumentName {
                    return "\(label): \(label)"
                } else {
                    return i.parameterName
                }
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
                mutating func visit(_ instruction: Instruction) throws
            }

            extension AnyInstructionVisitor {

            """

        for instruction in instructions.categorized {
            code += "    public mutating func \(instruction.visitMethodName)("
            code += instruction.associatedValues.map { i in
                if i.argumentName == i.parameterName {
                    return "\(i.parameterName): \(i.type)"
                } else {
                    return "\(i.argumentName ?? "_") \(i.parameterName): \(i.type)"
                }
            }.joined(separator: ", ")
            code += ") throws { "
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

        for instruction in instructions.categorized {
            code += "    public mutating func \(instruction.visitMethodName)("
            code += instruction.associatedValues.map { i in
                if i.argumentName == i.parameterName {
                    return "\(i.parameterName): \(i.type)"
                } else {
                    return "\(i.argumentName ?? "_") \(i.parameterName): \(i.type)"
                }
            }.joined(separator: ", ")
            code += ") throws {\n"
            code += "       trace("
            code += buildInstructionInstanceFromContext(instruction)
            code += ")\n"
            code += "       return try visitor.\(instruction.visitMethodName)("
            code += instruction.associatedValues.map { i in
                if let label = i.argumentName {
                    "\(label): \(i.parameterName)"
                } else {
                    i.parameterName
                }
            }.joined(separator: ", ")
            code += ")\n"
            code += "    }\n"
        }

        code += "}"

        return code
    }

    static func generateTextInstructionParser(_ instructions: InstructionSet) -> String {
        var code = """
            import WasmParser
            import WasmTypes

            /// Parses a text instruction, consuming immediate tokens as necessary.
            /// - Parameters:
            ///   - keyword: The keyword of the instruction.
            ///   - expressionParser: The expression parser.
            /// - Returns: A closure that invokes the corresponding visitor method. Nil if the keyword is not recognized.
            ///
            /// Note: The returned closure does not consume any tokens.
            func parseTextInstruction<V: InstructionVisitor>(keyword: String, expressionParser: inout ExpressionParser<V>, wat: inout Wat) throws -> ((inout V) throws -> Void)? {
                switch keyword {

            """

        for instruction in instructions {
            guard let name = instruction.name.text else {
                continue
            }
            code += "    case \"\(name)\":"
            if !instruction.immediates.isEmpty {
                code += "\n"
                code += "        let ("
                code += instruction.immediates.map(\.label).joined(separator: ", ")
                code += ") = try expressionParser.\(instruction.visitMethodName)("
                if instruction.category != nil {
                    code += ".\(instruction.name.enumCase), "
                }
                code += "wat: &wat"
                code += ")\n"
                code += "        "
            } else {
                code += " "
            }
            code += "return { return try $0.\(instruction.visitMethodName)("
            var arguments: [(label: String?, value: String)] = []
            if instruction.category != nil {
                arguments.append((label: nil, value: ".\(instruction.name.enumCase)"))
            }
            for immediate in instruction.immediates {
                arguments.append((label: immediate.label, value: immediate.label))
            }
            code += arguments.map { i in
                if let label = i.label {
                    return "\(label): \(i.value)"
                } else {
                    return i.value
                }
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
         code += "    mutating func \(instruction.name.visitMethod)() throws -> "
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

    static func generateBinaryInstructionEncoder(_ instructions: InstructionSet) -> String {
        var code = """
            import WasmParser
            import WasmTypes

            /// An instruction encoder that is responsible for encoding opcodes and immediates
            /// in Wasm binary format.
            protocol BinaryInstructionEncoder: InstructionVisitor {
                /// Encodes an instruction opcode.
                mutating func encodeInstruction(_ opcode: [UInt8]) throws

                // MARK: - Immediates encoding

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

            // BinaryInstructionEncoder implements the InstructionVisitor protocol to call the corresponding encode method.
            extension BinaryInstructionEncoder {

            """

        for instruction in instructions.categorized {
            code += "    mutating func \(instruction.visitMethodName)("
            code += instruction.associatedValues.map { i in
                if i.argumentName == i.parameterName {
                    return "\(i.parameterName): \(i.type)"
                } else {
                    return "\(i.argumentName ?? "_") \(i.parameterName): \(i.type)"
                }
            }.joined(separator: ", ")
            code += ") throws {"

            var encodeInstrCall: String
            if let category = instruction.explicitCategory {
                code += "\n"
                code += "        let opcode: [UInt8]\n"
                code += "        switch \(category) {\n"
                for sourceInstruction in instruction.sourceInstructions {
                    code += "        case .\(sourceInstruction.name.enumCase): opcode = ["
                    code += sourceInstruction.opcode.map { String(format: "0x%02X", $0) }.joined(separator: ", ")
                    code += "]\n"
                }
                code += "        }\n"
                encodeInstrCall = "try encodeInstruction(opcode)"
            } else {
                let instruction = instruction.sourceInstructions[0]
                encodeInstrCall = "try encodeInstruction(["
                encodeInstrCall += instruction.opcode.map { String(format: "0x%02X", $0) }.joined(separator: ", ")
                encodeInstrCall += "])"
            }

            if instruction.immediates.isEmpty, instruction.explicitCategory == nil {
                code += " \(encodeInstrCall) "
            } else {
                code += "\n"
                code += "        \(encodeInstrCall)\n"
                if !instruction.immediates.isEmpty {
                    code += "        try encodeImmediates("
                    code += instruction.immediates.map { "\($0.label): \($0.label)" }.joined(separator: ", ")
                    code += ")\n"
                }
                code += "    "
            }

            code += "}\n"
        }

        code += "}\n"

        return code
    }

    static func generateBinaryInstructionDecoder(_ instructions: InstructionSet) -> String {
        struct Trie {
            var children: [UInt8: Trie] = [:]
            /// An instruction corresponding to this terminal trie node
            let instruction: Instruction?

            init(instruction: Instruction? = nil) {
                self.instruction = instruction
            }

            mutating func insert<S: Collection>(_ opcode: S, instruction: Instruction) where S.Element == UInt8 {
                guard let first = opcode.first else { return }
                let isTermination = opcode.count == 1
                if isTermination {
                    assert(children[first] == nil)
                    children[first] = Trie(instruction: instruction)
                } else {
                    children[first, default: Trie(instruction: nil)].insert(opcode.dropFirst(), instruction: instruction)
                }
            }
        }

        var root = Trie()
        for instruction in instructions {
            root.insert(instruction.opcode, instruction: instruction)
        }
        var code = """
        import WasmTypes

        @usableFromInline
        protocol BinaryInstructionDecoder {
            /// Claim the next byte to be decoded
            @inlinable func claimNextByte() throws -> UInt8

            /// Current offset in decoder's instruction stream.
            var currentOffset: Int { get }

            /// Throw an error due to unknown opcode.
            func throwUnknown(_ opcode: [UInt8]) throws -> Never

        """
        for instruction in instructions.categorized {
            guard !instruction.immediates.isEmpty else { continue }
            code += "    /// Decode \(instruction.description) immediates\n"
            code += "    @inlinable mutating func \(instruction.visitMethodName)("
            if let categoryType = instruction.categoryTypeName {
                code += "_: Instruction.\(categoryType)"
            }
            code += ") throws -> "
            if instruction.immediates.count == 1 {
                code += "\(instruction.immediates[0].type)"
            } else {
                code += "(" + instruction.immediates.map { "\($0.label): \($0.type)" }.joined(separator: ", ") + ")"
            }
            code += "\n"
        }
        code += """
        }

        """

        code += """

        @inlinable
        func parseBinaryInstruction(visitor: inout some InstructionVisitor, decoder: inout some BinaryInstructionDecoder) throws -> Bool {
        """

        func renderSwitchCase(_ root: Trie, depth: Int = 0) {
            let indent = String(repeating: " ", count: (depth + 1) * 4)
            func opcodeByteName(_ depth: Int) -> String { "opcode\(depth)" }
            let opcodeByte = opcodeByteName(depth)
            code += """

            \(indent)let \(opcodeByte) = try decoder.claimNextByte()
            \(indent)switch \(opcodeByte) {

            """
            for (opcode, trie) in root.children.sorted(by: { $0.key < $1.key }) {
                code += "\(indent)case \(String(format: "0x%02X", opcode)):\n"
                if let instruction = trie.instruction {
                    if !instruction.immediates.isEmpty {
                        code += "\(indent)    let ("
                        code += instruction.immediates.map(\.label).joined(separator: ", ")
                        code += ") = try decoder.\(instruction.visitMethodName)("
                        if instruction.category != nil {
                            code += ".\(instruction.name.enumCase)"
                        }
                        code += ")\n"
                    }

                    code += "\(indent)    try visitor.\(instruction.visitMethodName)("
                    var arguments: [(label: String?, value: String)] = []
                    if instruction.category != nil {
                        arguments.append((label: nil, value: ".\(instruction.name.enumCase)"))
                    }
                    for immediate in instruction.immediates {
                        arguments.append((label: immediate.label, value: immediate.label))
                    }
                    code += arguments.map { i in
                        if let label = i.label {
                            return "\(label): \(i.value)"
                        } else {
                            return i.value
                        }
                    }.joined(separator: ", ")
                    code += ")\n"
                    if instruction.name.text == "end" {
                        code += "\(indent)    return true\n"
                    }
                } else {
                    renderSwitchCase(trie, depth: depth + 1)
                }
            }
            code += "\(indent)default:\n"
            code += "\(indent)    if try !visitor.visitUnknown("
            let opcode = "[" + (0...depth).map { opcodeByteName($0) }.joined(separator: ", ") + "]"
            code += opcode
            code += ") { try decoder.throwUnknown(\(opcode)) }\n"
            code += "\(indent)}\n"
        }

        renderSwitchCase(root)
        code += "    return false\n"
        code += "}\n"
        return code
    }

    static func formatInstructionSet(_ instructions: InstructionSet) -> String {
        var json = ""
        json += "[\n"

        struct ColumnInfo {
            var header: String
            var maxWidth: Int = 0
            var value: (Instruction) -> String
        }

        var columns: [ColumnInfo] = [
            ColumnInfo(header: "Feature", value: { "\"" + $0.feature + "\"" }),
            ColumnInfo(
                header: "Name",
                value: {
                    switch $0.name {
                    case .textual(let name): return "\"" + name + "\""
                    case .withEnumCase(let name): return "{\"enumCase\": \"\(name.enumCase)\"}"
                    }
                }),
            ColumnInfo(header: "Opcode", value: {
                "[" + $0.opcode.map { "\"" + String(format: "0x%02X", $0) + "\"" }.joined(separator: ", ") + "]"
            }),
            ColumnInfo(
                header: "Immediates",
                value: { i in
                    return "["
                        + i.immediates.map { i in
                            "[\"\(i.label)\", \"\(i.type)\"]"
                        }.joined(separator: ", ") + "]"
                }),
            ColumnInfo(
                header: "Category",
                value: { i in
                    if let category = i.category {
                        return "\"" + category + "\""
                    } else {
                        return "null"
                    }
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
            json += "  ["
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
        json += "]"
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

        let header = """
            // swift-format-ignore-file
            //// Automatically generated by Utilities/Sources/WasmGen.swift
            //// DO NOT EDIT DIRECTLY


            """

        let projectSources = ["Sources"]


        let generatedFiles = [
            GeneratedFile(
                projectSources + ["WasmParser", "InstructionVisitor.swift"],
                header + generateInstructionEnum(instructions)
                    + "\n\n"
                    + generateAnyInstructionVisitor(instructions)
                    + "\n\n"
                    + generateVisitorProtocol(instructions)
                    + "\n"
            ),
            GeneratedFile(
                projectSources + ["WasmParser", "BinaryInstructionDecoder.swift"],
                header + generateBinaryInstructionDecoder(instructions)
            ),
            GeneratedFile(
                projectSources + ["WAT", "ParseTextInstruction.swift"],
                header + generateTextInstructionParser(instructions)
            ),
            GeneratedFile(
                projectSources + ["WAT", "BinaryInstructionEncoder.swift"],
                header + generateBinaryInstructionEncoder(instructions)
            ),
        ]

        for file in generatedFiles {
            try file.writeIfChanged(sourceRoot: sourceRoot)
        }
    }
}

extension WasmGen {
    struct CategorizedInstruction {
        let enumCaseName: String
        let visitMethodName: String
        let description: String
        let immediates: [Instruction.Immediate]
        let explicitCategory: String?
        var sourceInstructions: [Instruction] = []

        private var categoryValue: (argumentName: String?, parameterName: String, type: String)? {
            guard let explicitCategory = explicitCategory else {
                return nil
            }
            return (argumentName: nil, parameterName: explicitCategory, type: WasmGen.pascalCase(camelCase: explicitCategory))
        }

        var categoryTypeName: String? {
            categoryValue?.type
        }

        var associatedValues: [(argumentName: String?, parameterName: String, type: String)] {
            var results: [(argumentName: String?, parameterName: String, type: String)] = []
            if var categoryValue = categoryValue {
                categoryValue.type = "Instruction.\(categoryValue.type)"
                results.append(categoryValue)
            }
            results += immediates.map { ($0.label, $0.label, $0.type) }
            return results
        }
    }
}

extension WasmGen.InstructionSet {
    var categorized: [WasmGen.CategorizedInstruction] {
        var categoryOrder: [String] = []
        var categories: [String: WasmGen.CategorizedInstruction] = [:]

        for instruction in self {
            let category = instruction.category ?? instruction.name.enumCase
            var categorized: WasmGen.CategorizedInstruction
            if let existing = categories[category] {
                categorized = existing
                assert(categorized.immediates == instruction.immediates, "Inconsistent immediates for instruction \(instruction.name.text ?? instruction.name.enumCase) in category \(category)")
            } else {
                let enumCaseName: String
                let description: String
                if let explicitCategory = instruction.category {
                    enumCaseName = explicitCategory
                    description = "`\(explicitCategory)` category"
                } else {
                    enumCaseName = instruction.name.enumCase
                    description = "`\(instruction.name.text ?? instruction.name.enumCase)`"
                }
                categorized = WasmGen.CategorizedInstruction(
                    enumCaseName: enumCaseName,
                    visitMethodName: instruction.visitMethodName, description: description,
                    immediates: instruction.immediates,
                    explicitCategory: instruction.category
                )
                categoryOrder.append(category)
            }
            categorized.sourceInstructions.append(instruction)
            categories[category] = categorized
        }

        return categoryOrder.map { categories[$0]! }
    }
}
