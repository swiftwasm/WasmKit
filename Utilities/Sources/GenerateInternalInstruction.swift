import Foundation

/// A utility to generate internal VM instruction related code.
enum GenerateInternalInstruction {

    struct Immediate {
        let name: String?
        let type: String
    }
    struct Instruction {
        let name: String
        let isControl: Bool
        let mayThrow: Bool
        let mayUpdateFrame: Bool
        let hasLocals: Bool
        let immediates: [Immediate]

        init(name: String, isControl: Bool = false, mayThrow: Bool = false, mayUpdateFrame: Bool = false, hasLocals: Bool = false, immediates: [Immediate]) {
            self.name = name
            self.isControl = isControl
            self.mayThrow = mayThrow
            self.mayUpdateFrame = mayUpdateFrame
            self.hasLocals = hasLocals
            self.immediates = immediates
            assert(isControl || !mayUpdateFrame, "non-control instruction should not update frame")
        }

        static var commonParameters: [(label: String, type: String, isInout: Bool)] {
            [("runtime", "Runtime", false), ("stack", "Stack", true)]
        }

        var parameters: [(label: String, type: String, isInout: Bool)] {
            let immediates = immediates.map {
                let label = $0.name ?? camelCase(pascalCase: String($0.type.split(separator: ".").last!))
                return (label, $0.type, false)
            }
            return
                (Self.commonParameters
                + (hasLocals ? [("locals", "UnsafeMutablePointer<Value>", false)] : [])
                + immediates)
        }
    }

    static let intValueTypes = ["i32", "i64"]
    static let valueTypes = intValueTypes + ["f32", "f64"]
    static let numericBinaryInsts: [Instruction] = ["Add", "Sub", "Mul", "Eq", "Ne"].flatMap { op -> [Instruction] in
        valueTypes.map { type in
            Instruction(name: "\(type)\(op)", immediates: [Immediate(name: nil, type: "Instruction.BinaryOperand")])
        }
    }
    static let numericIntBinaryInsts: [Instruction] = ["LtS", "LtU", "GtS", "GtU", "LeS", "LeU", "GeS", "GeU"].flatMap { op -> [Instruction] in
        intValueTypes.map { type in
            Instruction(name: "\(type)\(op)", immediates: [Immediate(name: nil, type: "Instruction.BinaryOperand")])
        }
    }
    static let numericIntUnaryInsts: [Instruction] = ["Clz", "Ctz", "Popcnt", "Eqz"].flatMap { op -> [Instruction] in
        intValueTypes.map { type in
            Instruction(name: "\(type)\(op)", immediates: [Immediate(name: nil, type: "Instruction.UnaryOperand")])
        }
    }
    static let numericOtherInsts: [Instruction] = [
        // Numeric
        Instruction(name: "numericConst", immediates: [
            Immediate(name: nil, type: "Instruction.ConstOperand")
        ]),
        Instruction(name: "numericFloatUnary", immediates: [
            Immediate(name: nil, type: "NumericInstruction.FloatUnary"),
            Immediate(name: nil, type: "Instruction.UnaryOperand"),
        ]),
        Instruction(name: "numericIntBinary", mayThrow: true, immediates: [
            Immediate(name: nil, type: "NumericInstruction.IntBinary"),
            Immediate(name: nil, type: "Instruction.BinaryOperand"),
        ]),
        Instruction(name: "numericFloatBinary", immediates: [
            Immediate(name: nil, type: "NumericInstruction.FloatBinary"),
            Immediate(name: nil, type: "Instruction.BinaryOperand"),
        ]),
        Instruction(name: "numericConversion", mayThrow: true, immediates: [
            Immediate(name: nil, type: "NumericInstruction.Conversion"),
            Immediate(name: nil, type: "Instruction.UnaryOperand"),
        ]),
    ]

    static let memoryLoadInsts: [Instruction] = [
        "i32Load",
        "i64Load",
        "f32Load",
        "f64Load",
        "i32Load8S",
        "i32Load8U",
        "i32Load16S",
        "i32Load16U",
        "i64Load8S",
        "i64Load8U",
        "i64Load16S",
        "i64Load16U",
        "i64Load32S",
        "i64Load32U",
    ].map {
        Instruction(name: $0, mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.LoadOperand")])
    }
    static let memoryStoreInsts: [Instruction] = [
        "i32Store",
        "i64Store",
        "f32Store",
        "f64Store",
        "i32Store8",
        "i32Store16",
        "i64Store8",
        "i64Store16",
        "i64Store32",
    ].map {
        Instruction(name: $0, mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.StoreOperand")])
    }
    static let memoryLoadStoreInsts: [Instruction] = memoryLoadInsts + memoryStoreInsts
    static let memoryOpInsts: [Instruction] = [
        Instruction(name: "memorySize", immediates: [Immediate(name: nil, type: "Instruction.MemorySizeOperand")]),
        Instruction(name: "memoryGrow", mayThrow: true, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryGrowOperand"),
        ]),
        Instruction(name: "memoryInit", mayThrow: true, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryInitOperand"),
        ]),
        Instruction(name: "memoryDataDrop", immediates: [Immediate(name: nil, type: "DataIndex")]),
        Instruction(name: "memoryCopy", mayThrow: true, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryCopyOperand"),
        ]),
        Instruction(name: "memoryFill", mayThrow: true, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryFillOperand"),
        ]),
    ]

    static let miscInsts: [Instruction] = [
        // Parametric
        Instruction(name: "drop", immediates: []),
        Instruction(name: "select", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.SelectOperand")]),
        // Reference
        Instruction(name: "refNull", immediates: [Immediate(name: nil, type: "Instruction.RefNullOperand")]),
        Instruction(name: "refIsNull", immediates: [Immediate(name: nil, type: "Instruction.RefIsNullOperand")]),
        Instruction(name: "refFunc", immediates: [Immediate(name: nil, type: "Instruction.RefFuncOperand")]),
        // Table
        Instruction(name: "tableGet", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.TableGetOperand")]),
        Instruction(name: "tableSet", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.TableSetOperand")]),
        Instruction(name: "tableSize", immediates: [Immediate(name: nil, type: "Instruction.TableSizeOperand")]),
        Instruction(name: "tableGrow", immediates: [Immediate(name: nil, type: "Instruction.TableGrowOperand")]),
        Instruction(name: "tableFill", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.TableFillOperand")]),
        Instruction(name: "tableCopy", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.TableCopyOperand")]),
        Instruction(name: "tableInit", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.TableInitOperand")]),
        Instruction(name: "tableElementDrop", immediates: [Immediate(name: nil, type: "ElementIndex")]),
    ]

    static let instructions: [Instruction] =
        [
            // Variable
            Instruction(name: "localGet", hasLocals: true, immediates: [Immediate(name: nil, type: "Instruction.LocalGetOperand")]),
            Instruction(name: "localSet", hasLocals: true, immediates: [Immediate(name: nil, type: "Instruction.LocalSetOperand")]),
            Instruction(name: "localTee", hasLocals: true, immediates: [Immediate(name: nil, type: "Instruction.LocalTeeOperand")]),
            Instruction(name: "globalGet", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.GlobalGetOperand")]),
            Instruction(name: "globalSet", mayThrow: true, immediates: [Immediate(name: nil, type: "Instruction.GlobalSetOperand")]),
            Instruction(name: "copyStack", immediates: [Immediate(name: nil, type: "Instruction.CopyStackOperand")]),
            // Controls
            Instruction(name: "unreachable", isControl: true, mayThrow: true, immediates: []),
            Instruction(name: "nop", isControl: true, mayThrow: true, immediates: []),
            Instruction(
                name: "ifThen", isControl: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.IfOperand")
                ]),
            Instruction(name: "end", isControl: true, immediates: []),
            Instruction(
                name: "`else`", isControl: true,
                immediates: [
                    Immediate(name: "endRef", type: "ExpressionRef")
                ]),
            Instruction(
                name: "br", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: "offset", type: "Int32"),
                ]),
            Instruction(
                name: "brIf", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.BrIfOperand")
                ]),
            Instruction(
                name: "brIfNot", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.BrIfOperand")
                ]),
            Instruction(
                name: "brTable", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.BrTableOperand")
                ]),
            Instruction(name: "`return`", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
                Immediate(name: nil, type: "Instruction.ReturnOperand")
            ]),
            Instruction(
                name: "call", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.CallOperand")
                ]),
            Instruction(
                name: "callIndirect", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.CallIndirectOperand")
                ]),
            Instruction(name: "endOfFunction", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
                Immediate(name: nil, type: "Instruction.ReturnOperand")
            ]),
            Instruction(name: "endOfExecution", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: []),
        ]
        + memoryLoadStoreInsts
        + memoryOpInsts
        + numericOtherInsts
        + numericBinaryInsts
        + numericIntBinaryInsts
        + numericIntUnaryInsts
        + miscInsts

    static func camelCase(pascalCase: String) -> String {
        let first = pascalCase.first!.lowercased()
        return first + pascalCase.dropFirst()
    }

    static func generateDispatcher(instructions: [Instruction]) -> String {
        let doExecuteParams =
            [("instruction", "Instruction", false)]
            + Instruction.commonParameters
            + [("locals", "UnsafeMutablePointer<Value>", false)]
        var output = """
            extension ExecutionState {
                @inline(__always)
                mutating func doExecute(_ \(doExecuteParams.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", "))) throws -> Bool {
                    switch instruction {
            """

        for inst in instructions {
            let tryPrefix = inst.mayThrow ? "try " : ""
            let args = inst.parameters.map { label, _, isInout in
                "\(label): \(isInout ? "&" : "")\(label)"
            }
            if inst.immediates.isEmpty {
                output += """

                            case .\(inst.name):
                    """
            } else {
                let labels = inst.immediates.map {
                    $0.name ?? camelCase(pascalCase: String($0.type.split(separator: ".").last!))
                }
                output += """

                            case .\(inst.name)(\(labels.map { "let \($0)" }.joined(separator: ", "))):
                    """
            }
            output += """

                            \(tryPrefix)self.\(inst.name)(\(args.joined(separator: ", ")))
                """
            if inst.isControl {
                output += """

                                return \(!inst.mayUpdateFrame)
                    """
            }
        }
        output += """

                    }
                    programCounter += 1
                    return true
                }
            }
            """
        return output
    }

    static func instMethodDecl(_ inst: Instruction) -> String {
        let throwsKwd = inst.mayThrow ? " throws" : ""
        let args = inst.parameters
        return "func \(inst.name)(\(args.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", ")))\(throwsKwd)"
    }

    static func generatePrototype(instructions: [Instruction]) -> String {
        var output = """

            extension ExecutionState {
            """
        for inst in instructions {
            output += """

                    mutating \(instMethodDecl(inst)) {
                        fatalError("Unimplemented instruction: \(inst.name)")
                    }
                """
        }
        output += """

            }

            """
        return output
    }

    static func replaceInstMethodSignature(_ inst: Instruction, sourceRoot: URL) throws {
        func tryReplace(file: URL) throws -> Bool {
            var contents = try String(contentsOf: file)
            guard contents.contains("func \(inst.name)(") else {
                return false
            }
            // Replace the found line with the new signature
            var lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
            for (i, line) in lines.enumerated() {
                if let range = line.range(of: "func \(inst.name)(") {
                    lines[i] = lines[i][..<range.lowerBound] + instMethodDecl(inst) + " {"
                    break
                }
            }
            contents = lines.joined(separator: "\n")
            try contents.write(to: file, atomically: true, encoding: .utf8)
            return true
        }

        let files = try FileManager.default.contentsOfDirectory(at: sourceRoot.appendingPathComponent("Sources/WasmKit/Execution/Instructions"), includingPropertiesForKeys: nil)
        for file in files {
            if try tryReplace(file: file) {
                print("Replaced \(inst.name) in \(file.lastPathComponent)")
                return
            }
        }
    }
    static func replaceMethodSignature(instructions: [Instruction], sourceRoot: URL) throws {
        for inst in instructions {
            try replaceInstMethodSignature(inst, sourceRoot: sourceRoot)
        }
    }

    static func generateInstName(instructions: [Instruction]) -> String {
        var output = """
            extension Instruction {
                var name: String {
                    switch self {
            """
        for inst in instructions {
            output += """

                        case .\(inst.name): return "\(inst.name)"
                """
        }
        output += """

                    }
                }
            }

            """
        return output
    }

    static func generateEnumDefinition(instructions: [Instruction]) -> String {
        var output = "enum Instruction: Equatable {\n"
        for inst in instructions {
            output += "    case \(inst.name)"
            if !inst.immediates.isEmpty {
                output += "("
                output += inst.immediates.map { immediate in
                    if let name = immediate.name {
                        return name + ": " + immediate.type
                    } else {
                        return immediate.type
                    }
                }.joined(separator: ", ")
                output += ")"
            }
            output += "\n"
        }
        output += "}\n"
        return output
    }

    static func main(arguments: [String]) throws {
        let sourceRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

        if arguments.count > 1 {
            switch arguments[1] {
            case "prototype":
                print(generatePrototype(instructions: instructions))
                return
            case "replace":
                try replaceMethodSignature(instructions: instructions, sourceRoot: sourceRoot)
            default: break
            }
        }

        do {
            var output = """
                // This file is generated by Utilities/generate_inst_dispatch.swift

                """

            output += generateDispatcher(instructions: instructions)
            output += "\n\n"
            output += generateInstName(instructions: instructions)

            let outputFile = sourceRoot.appending(path: "Sources/WasmKit/Execution/Runtime/InstDispatch.swift")
            try output.write(to: outputFile, atomically: true, encoding: .utf8)
        }

        do {
            let outputFile = sourceRoot.appending(path: "Sources/WasmKit/Execution/Instructions/Instruction.swift")
            let output = generateEnumDefinition(instructions: instructions)
            try output.write(to: outputFile, atomically: true, encoding: .utf8)
        }
        try replaceMethodSignature(instructions: instructions, sourceRoot: sourceRoot)
    }
}
