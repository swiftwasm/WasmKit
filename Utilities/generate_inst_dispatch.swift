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

    static var commonParameters: [(label: String, type: String, isInout: Bool)] {
        [("runtime", "Runtime", false), ("stack", "Stack", true)]
    }

    var parameters: [(label: String, type: String, isInout: Bool)] {
        let immediates = immediates.map {
            let label = $0.name ?? camelCase(pascalCase: String($0.type.split(separator: ".").last!))
            return (label, $0.type, false)
        }
        return (
            Self.commonParameters
            + (hasLocals ? [("locals", "UnsafeMutablePointer<Value>", false)] : [])
            + immediates
        )
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
let numericIntUnaryInsts: [Instruction] = ["Clz", "Ctz", "Popcnt", "Eqz"].flatMap { op -> [Instruction] in
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
    Instruction(name: "br", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: "labelIndex", type: "LabelIndex"),
        Immediate(name: "offset", type: "Int32"),
        // Number of values that will be copied if the branch is taken
        Immediate(name: "copyCount", type: "UInt32"),
        // Number of values that will be popped if the branch is taken
        Immediate(name: "popCount", type: "UInt32"),
    ]),
    Instruction(name: "brIf", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: "labelIndex", type: "LabelIndex"),
        Immediate(name: "offset", type: "Int32"),
        // Number of values that will be copied if the branch is taken
        Immediate(name: "copyCount", type: "UInt32"),
        // Number of values that will be popped if the branch is taken
        Immediate(name: "popCount", type: "UInt32"),
    ]),
    Instruction(name: "brTable", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: [
        Immediate(name: nil, type: "Instruction.BrTable"),
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
    Instruction(name: "numericFloatUnary", immediates: [Immediate(name: nil, type: "NumericInstruction.FloatUnary")]),
    Instruction(name: "numericIntBinary", mayThrow: true, immediates: [Immediate(name: nil, type: "NumericInstruction.IntBinary")]),
    Instruction(name: "numericFloatBinary", immediates: [Immediate(name: nil, type: "NumericInstruction.FloatBinary")]),
    Instruction(name: "numericConversion", mayThrow: true, immediates: [Immediate(name: nil, type: "NumericInstruction.Conversion")]),
]
+ numericBinaryInsts
+ numericIntBinaryInsts
+ numericIntUnaryInsts
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
    let doExecuteParams = [("instruction", "Instruction", false)]
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

func instMethodDecl(_ inst: Instruction) -> String {
    let throwsKwd = inst.mayThrow ? " throws" : ""
    let args = inst.parameters
    return "func \(inst.name)(\(args.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", ")))\(throwsKwd)"
}

func generatePrototype(instructions: [Instruction]) -> String {
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

func replaceInstMethodSignature(_ inst: Instruction) throws {
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

    let files = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "Sources/WasmKit/Execution/Instructions"), includingPropertiesForKeys: nil)
    for file in files {
        if try tryReplace(file: file) {
            print("Replaced \(inst.name) in \(file.lastPathComponent)")
            return
        }
    }
}
func replaceMethodSignature(instructions: [Instruction]) throws {
    for inst in instructions {
        try replaceInstMethodSignature(inst)
    }
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
        case "replace":
            try replaceMethodSignature(instructions: instructions)
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
    try replaceMethodSignature(instructions: instructions)
}

try main(arguments: CommandLine.arguments)
