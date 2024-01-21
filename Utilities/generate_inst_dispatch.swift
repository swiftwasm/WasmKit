import Foundation

struct Immediate {
    let name: String?
    let type: String
}
struct Instruction {
    let name: String
    let isControl: Bool
    let immediates: [Immediate]

    init(name: String, isControl: Bool = false, immediates: [Immediate]) {
        self.name = name
        self.isControl = isControl
        self.immediates = immediates
    }
}

let instructions = [
    // Controls
    Instruction(name: "unreachable", isControl: true, immediates: []),
    Instruction(name: "nop", isControl: true, immediates: []),
    Instruction(name: "block", isControl: true, immediates: [
        Immediate(name: "endRef", type: "ExpressionRef"),
        Immediate(name: "type", type: "ResultType")
    ]),
    Instruction(name: "loop", isControl: true, immediates: [
        Immediate(name: "type", type: "ResultType")
    ]),
    Instruction(name: "ifThen", isControl: true, immediates: [
        Immediate(name: "endRef", type: "ExpressionRef"),
        Immediate(name: "type", type: "ResultType")
    ]),
    Instruction(name: "ifThenElse", isControl: true, immediates: [
        Immediate(name: "elseRef", type: "ExpressionRef"),
        Immediate(name: "endRef", type: "ExpressionRef"),
        Immediate(name: "type", type: "ResultType")
    ]),
    Instruction(name: "end", isControl: true, immediates: []),
    Instruction(name: "`else`", isControl: true, immediates: []),
    Instruction(name: "br", isControl: true, immediates: [
        Immediate(name: "labelIndex", type: "LabelIndex")
    ]),
    Instruction(name: "brIf", isControl: true, immediates: [
        Immediate(name: "labelIndex", type: "LabelIndex")
    ]),
    Instruction(name: "brTable", isControl: true, immediates: [
        Immediate(name: nil, type: "BrTable"),
    ]),
    Instruction(name: "`return`", isControl: true, immediates: []),
    Instruction(name: "call", isControl: true, immediates: [
        Immediate(name: "functionIndex", type: "UInt32")
    ]),
    Instruction(name: "callIndirect", isControl: true, immediates: [
        Immediate(name: "tableIndex", type: "TableIndex"),
        Immediate(name: "typeIndex", type: "TypeIndex")
    ]),
    Instruction(name: "endOfFunction", isControl: true, immediates: []),
]
// Memory
+ [
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
        Instruction(name: $0, immediates: [Immediate(name: "memarg", type: "Memarg")])
    }
+ [
    Instruction(name: "memorySize", immediates: []),
    Instruction(name: "memoryGrow", immediates: []),
    Instruction(name: "memoryInit", immediates: [Immediate(name: nil, type: "DataIndex")]),
    Instruction(name: "memoryDataDrop", immediates: [Immediate(name: nil, type: "DataIndex")]),
    Instruction(name: "memoryCopy", immediates: []),
    Instruction(name: "memoryFill", immediates: []),
    // Numeric
    Instruction(name: "numericConst", immediates: [Immediate(name: nil, type: "Value")]),
    Instruction(name: "numericIntUnary", immediates: [Immediate(name: nil, type: "NumericInstruction.IntUnary")]),
    Instruction(name: "numericFloatUnary", immediates: [Immediate(name: nil, type: "NumericInstruction.FloatUnary")]),
    Instruction(name: "numericBinary", immediates: [Immediate(name: nil, type: "NumericInstruction.Binary")]),
    Instruction(name: "numericIntBinary", immediates: [Immediate(name: nil, type: "NumericInstruction.IntBinary")]),
    Instruction(name: "numericFloatBinary", immediates: [Immediate(name: nil, type: "NumericInstruction.FloatBinary")]),
    Instruction(name: "numericConversion", immediates: [Immediate(name: nil, type: "NumericInstruction.Conversion")]),
    // Parametric
    Instruction(name: "drop", immediates: []),
    Instruction(name: "select", immediates: []),
    // Reference
    Instruction(name: "refNull", immediates: [Immediate(name: nil, type: "ReferenceType")]),
    Instruction(name: "refIsNull", immediates: []),
    Instruction(name: "refFunc", immediates: [Immediate(name: nil, type: "FunctionIndex")]),
    // Table
    Instruction(name: "tableGet", immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableSet", immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableSize", immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableGrow", immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableFill", immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableCopy", immediates: [Immediate(name: "dest", type: "TableIndex"), Immediate(name: "src", type: "TableIndex")]),
    Instruction(name: "tableInit", immediates: [Immediate(name: nil, type: "TableIndex"), Immediate(name: nil, type: "ElementIndex")]),
    Instruction(name: "tableElementDrop", immediates: [Immediate(name: nil, type: "ElementIndex")]),
    // Variable
    Instruction(name: "localGet", immediates: [Immediate(name: "index", type: "LocalIndex")]),
    Instruction(name: "localSet", immediates: [Immediate(name: "index", type: "LocalIndex")]),
    Instruction(name: "localTee", immediates: [Immediate(name: "index", type: "LocalIndex")]),
    Instruction(name: "globalGet", immediates: [Immediate(name: "index", type: "GlobalIndex")]),
    Instruction(name: "globalSet", immediates: [Immediate(name: "index", type: "GlobalIndex")]),
]

func camelCase(pascalCase: String) -> String {
    let first = pascalCase.first!.lowercased()
    return first + pascalCase.dropFirst()
}

func generateDispatcher(instructions: [Instruction]) -> String {
    var output = """
    extension ExecutionState {
        @_transparent
        mutating func doExecute(_ instruction: Instruction, runtime: Runtime) throws {
            switch instruction {
    """

    for inst in instructions {
        if inst.immediates.isEmpty {
            output += """

                    case .\(inst.name):
                        try self.\(inst.name)(runtime: runtime)
            """
        } else {
            let labels = inst.immediates.map {
                $0.name ?? camelCase(pascalCase: String($0.type.split(separator: ".").last!))
            }
            output += """

                    case .\(inst.name)(\(labels.map { "let \($0)" }.joined(separator: ", "))):
                        try self.\(inst.name)(runtime: runtime, \(labels.map { "\($0): \($0)" }.joined(separator: ", ")))
            """
        }
        if inst.isControl {
            output += """

                        return
            """
        }
    }
    output += """

            }
            programCounter += 1
        }
    }
    """
    return output
}

func generatePrototype(instructions: [Instruction]) -> String {
    var output = """

    extension ExecutionState {
    """
    for inst in instructions {
        if inst.immediates.isEmpty {
            output += """

            mutating func \(inst.name)(runtime: Runtime) throws {
                fatalError("Unimplemented instruction: \(inst.name)")
            }
        """
        } else {
            let labelTypes = inst.immediates.map {
                let label = $0.name ?? camelCase(pascalCase: String($0.type.split(separator: ".").last!))
                return (label, $0.type)
            }
            output += """

            mutating func \(inst.name)(runtime: Runtime, \(labelTypes.map { "\($0): \($1)" }.joined(separator: ", "))) throws {
                fatalError("Unimplemented instruction: \(inst.name)")
            }
        """
        }
    }
    output += """

    }

    """
    return output
}

func generateInstName(instructions: [Instruction]) -> String {
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

func generateEnumDefinition(instructions: [Instruction]) -> String {
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

func main(arguments: [String]) throws {
    let sourceRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    if arguments.count > 1 {
        switch arguments[1] {
        case "prototype":
            print(generatePrototype(instructions: instructions))
            return
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
}

try main(arguments: CommandLine.arguments)
