import Foundation

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
}

let intValueTypes = ["i32", "i64"]
let valueTypes = intValueTypes + ["f32", "f64"]
let numericBinaryInsts: [Instruction] = ["Add", "Sub", "Mul", "Eq", "Ne"].flatMap { op -> [Instruction] in
    valueTypes.map { type in
        Instruction(name: "\(type)\(op)", immediates: [])
    }
}
let numericIntBinaryInsts: [Instruction] = ["LtS", "LtU", "GtS", "GtU", "LeS", "LeU", "GeS", "GeU"].flatMap { op -> [Instruction] in
    intValueTypes.map { type in
        Instruction(name: "\(type)\(op)", immediates: [])
    }
}

let instructions = [
    // Controls
    Instruction(name: "unreachable", isControl: true, mayThrow: true, immediates: []),
    Instruction(name: "nop", isControl: true, mayThrow: true, immediates: []),
    Instruction(name: "block", isControl: true, immediates: [
        Immediate(name: "endRef", type: "ExpressionRef"),
        Immediate(name: "type", type: "BlockType")
    ]),
    Instruction(name: "loop", isControl: true, immediates: [
        Immediate(name: "type", type: "BlockType")
    ]),
    Instruction(name: "ifThen", isControl: true, immediates: [
        Immediate(name: "endRef", type: "ExpressionRef"),
        Immediate(name: "type", type: "BlockType")
    ]),
    Instruction(name: "ifThenElse", isControl: true, immediates: [
        Immediate(name: "elseRef", type: "ExpressionRef"),
        Immediate(name: "endRef", type: "ExpressionRef"),
        Immediate(name: "type", type: "BlockType")
    ]),
    Instruction(name: "end", isControl: true, immediates: []),
    Instruction(name: "`else`", isControl: true, immediates: []),
    // NOTE: A branch can unwind a frame by "br 0"
    Instruction(name: "br", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: "labelIndex", type: "LabelIndex")
    ]),
    Instruction(name: "brIf", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: "labelIndex", type: "LabelIndex")
    ]),
    Instruction(name: "brTable", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: nil, type: "BrTable"),
    ]),
    Instruction(name: "`return`", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: []),
    Instruction(name: "call", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: "functionIndex", type: "UInt32")
    ]),
    Instruction(name: "callIndirect", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: "tableIndex", type: "TableIndex"),
        Immediate(name: "typeIndex", type: "TypeIndex")
    ]),
    Instruction(name: "endOfFunction", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: []),
    Instruction(name: "endOfExecution", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: []),
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
        Instruction(name: $0, mayThrow: true, immediates: [Immediate(name: "memarg", type: "Memarg")])
    }
+ [
    Instruction(name: "memorySize", immediates: []),
    Instruction(name: "memoryGrow", mayThrow: true, immediates: []),
    Instruction(name: "memoryInit", mayThrow: true, immediates: [Immediate(name: nil, type: "DataIndex")]),
    Instruction(name: "memoryDataDrop", immediates: [Immediate(name: nil, type: "DataIndex")]),
    Instruction(name: "memoryCopy", mayThrow: true, immediates: []),
    Instruction(name: "memoryFill", mayThrow: true, immediates: []),
    // Numeric
    Instruction(name: "numericConst", immediates: [Immediate(name: nil, type: "Value")]),
    Instruction(name: "numericIntUnary", immediates: [Immediate(name: nil, type: "NumericInstruction.IntUnary")]),
    Instruction(name: "numericFloatUnary", immediates: [Immediate(name: nil, type: "NumericInstruction.FloatUnary")]),
    Instruction(name: "numericIntBinary", mayThrow: true, immediates: [Immediate(name: nil, type: "NumericInstruction.IntBinary")]),
    Instruction(name: "numericFloatBinary", immediates: [Immediate(name: nil, type: "NumericInstruction.FloatBinary")]),
    Instruction(name: "numericConversion", mayThrow: true, immediates: [Immediate(name: nil, type: "NumericInstruction.Conversion")]),
]
+ numericBinaryInsts
+ numericIntBinaryInsts
+ [
    // Parametric
    Instruction(name: "drop", immediates: []),
    Instruction(name: "select", mayThrow: true, immediates: []),
    // Reference
    Instruction(name: "refNull", immediates: [Immediate(name: nil, type: "ReferenceType")]),
    Instruction(name: "refIsNull", immediates: []),
    Instruction(name: "refFunc", immediates: [Immediate(name: nil, type: "FunctionIndex")]),
    // Table
    Instruction(name: "tableGet", mayThrow: true, immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableSet", mayThrow: true, immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableSize", immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableGrow", immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableFill", mayThrow: true, immediates: [Immediate(name: nil, type: "TableIndex")]),
    Instruction(name: "tableCopy", mayThrow: true, immediates: [Immediate(name: "dest", type: "TableIndex"), Immediate(name: "src", type: "TableIndex")]),
    Instruction(name: "tableInit", mayThrow: true, immediates: [Immediate(name: nil, type: "TableIndex"), Immediate(name: nil, type: "ElementIndex")]),
    Instruction(name: "tableElementDrop", immediates: [Immediate(name: nil, type: "ElementIndex")]),
    // Variable
    Instruction(name: "localGet", hasLocals: true, immediates: [Immediate(name: "index", type: "LocalIndex")]),
    Instruction(name: "localSet", hasLocals: true, immediates: [Immediate(name: "index", type: "LocalIndex")]),
    Instruction(name: "localTee", hasLocals: true, immediates: [Immediate(name: "index", type: "LocalIndex")]),
    Instruction(name: "globalGet", mayThrow: true, immediates: [Immediate(name: "index", type: "GlobalIndex")]),
    Instruction(name: "globalSet", mayThrow: true, immediates: [Immediate(name: "index", type: "GlobalIndex")]),
]

func camelCase(pascalCase: String) -> String {
    let first = pascalCase.first!.lowercased()
    return first + pascalCase.dropFirst()
}

func generateDispatcher(instructions: [Instruction]) -> String {
    var output = """
    extension ExecutionState {
        @inline(__always)
        mutating func doExecute(_ instruction: Instruction, runtime: Runtime, locals: UnsafeMutablePointer<Value>) throws -> Bool {
            switch instruction {
    """

    for inst in instructions {
        let tryPrefix = inst.mayThrow ? "try " : ""
        let labels = inst.immediates.map {
            $0.name ?? camelCase(pascalCase: String($0.type.split(separator: ".").last!))
        }
        let args = (["runtime"] + (inst.hasLocals ? ["locals"] : []) + labels).map { "\($0): \($0)" }
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

func generatePrototype(instructions: [Instruction]) -> String {
    var output = """

    extension ExecutionState {
    """
    for inst in instructions {
        let throwsKwd = inst.mayThrow ? " throws" : ""
        if inst.immediates.isEmpty {
            output += """

            mutating func \(inst.name)(runtime: Runtime)\(throwsKwd) {
                fatalError("Unimplemented instruction: \(inst.name)")
            }
        """
        } else {
            let labelTypes = inst.immediates.map {
                let label = $0.name ?? camelCase(pascalCase: String($0.type.split(separator: ".").last!))
                return (label, $0.type)
            }
            output += """

            mutating func \(inst.name)(runtime: Runtime, \(labelTypes.map { "\($0): \($1)" }.joined(separator: ", ")))\(throwsKwd) {
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
