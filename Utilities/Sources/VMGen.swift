import Foundation

/// A utility to generate internal VM instruction related code.
enum VMGen {

    struct Immediate {
        let name: String?
        let type: String

        var label: String {
            name ?? VMGen.camelCase(pascalCase: String(type.split(separator: ".").last!))
        }
    }
    enum RegisterUse {
        case none
        case read
        case write
    }

    /// A parameter passed to the `doExecute` method. Expected to be bound to a
    /// physical register.
    struct ExecParam: CaseIterable {
        let label: String
        let type: String

        static let sp = ExecParam(label: "sp", type: "Sp")
        static let pc = ExecParam(label: "pc", type: "Pc")
        static let md = ExecParam(label: "md", type: "Md")
        static let ms = ExecParam(label: "ms", type: "Ms")

        static var allCases = [sp, pc, md, ms]
    }

    struct Instruction {
        var name: String
        var isControl: Bool
        var mayThrow: Bool
        var mayUpdateFrame: Bool
        var mayUpdateSp: Bool = false
        var hasData: Bool
        var useCurrentMemory: RegisterUse
        var useRawOperand: Bool = false
        var immediates: [Immediate]

        var mayUpdatePc: Bool {
            self.isControl || self.hasData
        }

        init(
            name: String, isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            hasData: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            immediates: [Immediate]
        ) {
            self.name = name
            self.isControl = isControl
            self.mayThrow = mayThrow
            self.mayUpdateFrame = mayUpdateFrame
            self.hasData = hasData
            self.useCurrentMemory = useCurrentMemory
            self.immediates = immediates
            assert(isControl || !mayUpdateFrame, "non-control instruction should not update frame")
        }

        func withRawOperand() -> Instruction {
            var copy = self
            copy.useRawOperand = true
            return copy
        }

        typealias Parameter = (label: String, type: String, isInout: Bool)
        var parameters: [Parameter] {
            var vregs: [(reg: ExecParam, isInout: Bool)] = []
            if self.mayUpdateFrame {
                vregs += [(ExecParam.sp, true)]
            } else {
                vregs += [(ExecParam.sp, false)]
            }
            if self.mayUpdatePc {
                vregs += [(ExecParam.pc, false)]
            }
            switch useCurrentMemory {
            case .none: break
            case .read:
                vregs += [(ExecParam.md, false), (ExecParam.ms, false)]
            case .write:
                vregs += [(ExecParam.md, true), (ExecParam.ms, true)]
            }
            var parameters: [Parameter] = vregs.map { ($0.reg.label, $0.reg.type, $0.isInout) }
            parameters += immediates.map {
                return ($0.label, $0.type, false)
            }
            return parameters
        }
    }

    struct OpInstruction {
        let op: String
        let inputType: String
        let resultType: String
        let base: Instruction

        static func binop(op: String, type: String) -> OpInstruction {
            let base = Instruction(
                name: "\(type)\(op)", immediates: [Immediate(name: nil, type: "Instruction.BinaryOperand")]
            )
            return OpInstruction(op: op, inputType: type, resultType: type, base: base)
        }
        static func binop(op: String, inputType: String, resultType: String) -> OpInstruction {
            let base = Instruction(
                name: "\(inputType)\(op)", immediates: [Immediate(name: nil, type: "Instruction.BinaryOperand")]
            )
            return OpInstruction(op: op, inputType: inputType, resultType: resultType, base: base)
        }
        static func unop(op: String, type: String, resultType: String) -> OpInstruction {
            let base = Instruction(name: "\(type)\(op)", immediates: [Immediate(name: nil, type: "Instruction.UnaryOperand")]).withRawOperand()
            return OpInstruction(op: op, inputType: type, resultType: resultType, base: base)
        }
    }

    struct BinOpInfo {
        let op: String
        let name: String
        let lhsType: String
        let rhsType: String
        let resultType: String
        var mayThrow: Bool = false

        var instruction: Instruction {
            Instruction(
                name: name,
                mayThrow: mayThrow,
                immediates: [Immediate(name: nil, type: "Instruction.BinaryOperand")]
            ).withRawOperand()
        }
    }

    struct UnOpInfo {
        var op: String
        var name: String
        var inputType: String
        var resultType: String
        var mayThrow: Bool = false

        var instruction: Instruction {
            Instruction(name: name, mayThrow: mayThrow, immediates: [Immediate(name: nil, type: "Instruction.UnaryOperand")]).withRawOperand()
        }
    }

    static let intValueTypes = ["i32", "i64"]
    static let floatValueTypes = ["f32", "f64"]
    static let valueTypes = intValueTypes + floatValueTypes

    // MARK: - Int instructions

    static func buildIntBinOps() -> [BinOpInfo] {
        var results: [BinOpInfo] = []
        // (T, T) -> T for all T in int types
        results += [
            "Add", "Sub", "Mul",
            "And", "Or", "Xor", "Shl", "ShrS", "ShrU", "Rotl", "Rotr",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: $0) }
        }
        results += [
            "DivS", "DivU", "RemS", "RemU",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: $0, mayThrow: true) }
        }
        // (T, T) -> i32 for all T in int types
        results += [
            "Eq", "Ne", "LtS", "LtU", "GtS", "GtU", "LeS", "LeU", "GeS", "GeU",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: "i32") }
        }
        return results
    }
    static let intBinOps: [BinOpInfo] = buildIntBinOps()

    static func buildIntUnaryInsts() -> [UnOpInfo] {
        var results: [UnOpInfo] = []
        // (T) -> T for all T in int types
        results += ["Clz", "Ctz", "Popcnt"].flatMap { op -> [UnOpInfo] in
            intValueTypes.map { UnOpInfo(op: op, name: "\($0)\(op)", inputType: $0, resultType: $0) }
        }
        // (T) -> i32 for all T in int types
        results += ["Eqz"].flatMap { op -> [UnOpInfo] in
            intValueTypes.map { UnOpInfo(op: op, name: "\($0)\(op)", inputType: $0, resultType: "i32") }
        }
        // (i64) -> i32
        results += [UnOpInfo(op: "Wrap", name: "i32WrapI64", inputType: "i64", resultType: "i32")]
        // (i32) -> i64
        results += ["ExtendI32S", "ExtendI32U"].map { op -> UnOpInfo in
            UnOpInfo(op: op, name: "i64\(op)", inputType: "i32", resultType: "i64")
        }
        // (T) -> T for all T in int types
        results += ["Extend8S", "Extend16S"].flatMap { op -> [UnOpInfo] in
            intValueTypes.map { UnOpInfo(op: op, name: "\($0)\(op)", inputType: $0, resultType: $0) }
        }
        // (i64) -> i64
        results += ["Extend32S"].map { op -> UnOpInfo in
            UnOpInfo(op: op, name: "i64\(op)", inputType: "i64", resultType: "i64")
        }
        // Truncation
        let truncInOut: [(source: String, result: String)] = [
            ("f32", "i32"), ("f64", "i32"), ("f32", "i64"), ("f64", "i64")
        ]
        results += truncInOut.flatMap { source, result in
            [
                UnOpInfo(op: "TruncTo\(result.uppercased())S", name: "\(result)Trunc\(source.uppercased())S", inputType: source, resultType: result, mayThrow: true),
                UnOpInfo(op: "TruncTo\(result.uppercased())U", name: "\(result)Trunc\(source.uppercased())U", inputType: source, resultType: result, mayThrow: true),
                UnOpInfo(op: "TruncSatTo\(result.uppercased())S", name: "\(result)TruncSat\(source.uppercased())S", inputType: source, resultType: result, mayThrow: true),
                UnOpInfo(op: "TruncSatTo\(result.uppercased())U", name: "\(result)TruncSat\(source.uppercased())U", inputType: source, resultType: result, mayThrow: true)
            ]
        }
        // Conversion
        let convInOut: [(source: String, result: String)] = [
            ("i32", "f32"), ("i64", "f32"), ("i32", "f64"), ("i64", "f64")
        ]
        results += convInOut.flatMap { source, result in
            [
                UnOpInfo(op: "ConvertTo\(result.uppercased())S", name: "\(result)Convert\(source.uppercased())S", inputType: source, resultType: result),
                UnOpInfo(op: "ConvertTo\(result.uppercased())U", name: "\(result)Convert\(source.uppercased())U", inputType: source, resultType: result),
            ]
        }
        // Reinterpret
        let reinterpretInOut: [(source: String, result: String)] = [
            ("i32", "f32"), ("i64", "f64"), ("f32", "i32"), ("f64", "i64")
        ]
        results += reinterpretInOut.flatMap { source, result in
            [
                UnOpInfo(op: "ReinterpretTo\(result.uppercased())", name: "\(result)Reinterpret\(source.uppercased())", inputType: source, resultType: result),
            ]
        }
        return results
    }
    static let intUnaryInsts: [UnOpInfo] = buildIntUnaryInsts()


    // MARK: - Float instructions

    static func buildFloatBinOps() -> [BinOpInfo] {
        var results: [BinOpInfo] = []
        // (T, T) -> T for all T in float types
        results += [
            "Add", "Sub", "Mul", "Div",
            "Min", "Max", "CopySign",
        ].flatMap { op -> [BinOpInfo] in
            floatValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: $0) }
        }
        // (T, T) -> i32 for all T in float types
        results += [
            "Eq", "Ne", "Lt", "Gt", "Le", "Ge"
        ].flatMap { op -> [BinOpInfo] in
            floatValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: "i32") }
        }
        return results
    }
    static let floatBinOps: [BinOpInfo] = buildFloatBinOps()

    static func buildFloatUnaryOps() -> [UnOpInfo] {
        var results: [UnOpInfo] = []
        // (T) -> T for all T in float types
        results += ["Abs", "Neg", "Ceil", "Floor", "Trunc", "Nearest", "Sqrt"].flatMap { op -> [UnOpInfo] in
            floatValueTypes.map { UnOpInfo(op: op, name: "\($0)\(op)", inputType: $0, resultType: $0) }
        }
        // (f32) -> f64
        results += ["PromoteF32"].map { op -> UnOpInfo in
            UnOpInfo(op: op, name: "f64\(op)", inputType: "f32", resultType: "f64")
        }
        // (f64) -> f32
        results += ["DemoteF64"].map { op -> UnOpInfo in
            UnOpInfo(op: op, name: "f32\(op)", inputType: "f64", resultType: "f32")
        }
        return results
    }
    static let floatUnaryOps: [UnOpInfo] = buildFloatUnaryOps()

    // MARK: - Minor numeric instructions

    static let numericOtherInsts: [Instruction] = [
        // Numeric
        Instruction(name: "const32", immediates: [
            Immediate(name: nil, type: "Instruction.Const32Operand")
        ]).withRawOperand(),
        Instruction(name: "const64", hasData: true, immediates: [
            Immediate(name: nil, type: "Instruction.Const64Operand")
        ]).withRawOperand(),
    ]

    // MARK: - Memory instructions

    struct LoadInstruction {
        let loadAs: String
        let castToValue: String
        let base: Instruction
    }

    static let memoryLoadInsts: [LoadInstruction] = [
        ("i32Load", "UInt32", ".i32($0)"),
        ("i64Load", "UInt64", ".i64($0)"),
        ("f32Load", "UInt32", ".rawF32($0)"),
        ("f64Load", "UInt64", ".rawF64($0)"),
        ("i32Load8S", "Int8", ".init(signed: Int32($0))"),
        ("i32Load8U", "UInt8", ".i32(UInt32($0))"),
        ("i32Load16S", "Int16", ".init(signed: Int32($0))"),
        ("i32Load16U", "UInt16", ".i32(UInt32($0))"),
        ("i64Load8S", "Int8", ".init(signed: Int64($0))"),
        ("i64Load8U", "UInt8", ".i64(UInt64($0))"),
        ("i64Load16S", "Int16", ".init(signed: Int64($0))"),
        ("i64Load16U", "UInt16", ".i64(UInt64($0))"),
        ("i64Load32S", "Int32", ".init(signed: Int64($0))"),
        ("i64Load32U", "UInt32", ".i64(UInt64($0))"),
    ].map { (name, loadAs, castToValue) in
        let base = Instruction(name: name, mayThrow: true, useCurrentMemory: .read, immediates: [Immediate(name: nil, type: "Instruction.LoadOperand")]).withRawOperand()
        return LoadInstruction(loadAs: loadAs, castToValue: castToValue, base: base)
    }

    struct StoreInstruction {
        let castFromValue: String
        let base: Instruction
    }
    static let memoryStoreInsts: [StoreInstruction] = [
        ("i32Store", "$0.i32"),
        ("i64Store", "$0.i64"),
        ("f32Store", "$0.rawF32"),
        ("f64Store", "$0.rawF64"),
        ("i32Store8", "UInt8(truncatingIfNeeded: $0.i32)"),
        ("i32Store16", "UInt16(truncatingIfNeeded: $0.i32)"),
        ("i64Store8", "UInt8(truncatingIfNeeded: $0.i64)"),
        ("i64Store16", "UInt16(truncatingIfNeeded: $0.i64)"),
        ("i64Store32", "UInt32(truncatingIfNeeded: $0.i64)"),
    ].map { (name, castFromValue) in
        let base = Instruction(name: name, mayThrow: true, useCurrentMemory: .read, immediates: [Immediate(name: nil, type: "Instruction.StoreOperand")]).withRawOperand()
        return StoreInstruction(castFromValue: castFromValue, base: base)
    }
    static let memoryLoadStoreInsts: [Instruction] = memoryLoadInsts.map(\.base) + memoryStoreInsts.map(\.base)
    static let memoryOpInsts: [Instruction] = [
        Instruction(name: "memorySize", immediates: [Immediate(name: nil, type: "Instruction.MemorySizeOperand")]),
        Instruction(name: "memoryGrow", mayThrow: true, useCurrentMemory: .write, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryGrowOperand"),
        ]),
        Instruction(name: "memoryInit", mayThrow: true, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryInitOperand"),
        ]).withRawOperand(),
        Instruction(name: "memoryDataDrop", immediates: [Immediate(name: nil, type: "DataIndex")]),
        Instruction(name: "memoryCopy", mayThrow: true, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryCopyOperand"),
        ]),
        Instruction(name: "memoryFill", mayThrow: true, immediates: [
            Immediate(name: nil, type: "Instruction.MemoryFillOperand"),
        ]),
    ]

    // MARK: - Misc instructions

    static let miscInsts: [Instruction] = [
        // Parametric
        Instruction(name: "select", hasData: true, immediates: []),
        // Reference
        Instruction(name: "refNull", immediates: [Immediate(name: nil, type: "Instruction.RefNullOperand")]),
        Instruction(name: "refIsNull", immediates: [Immediate(name: nil, type: "Instruction.RefIsNullOperand")]),
        Instruction(name: "refFunc", immediates: [Immediate(name: nil, type: "Instruction.RefFuncOperand")]),
        // Table
        Instruction(name: "tableGet", mayThrow: true, hasData: true, immediates: [Immediate(name: nil, type: "Instruction.TableGetOperand")]),
        Instruction(name: "tableSet", mayThrow: true, hasData: true, immediates: [Immediate(name: nil, type: "Instruction.TableSetOperand")]),
        Instruction(name: "tableSize", immediates: [Immediate(name: nil, type: "Instruction.TableSizeOperand")]),
        Instruction(name: "tableGrow", mayThrow: true, hasData: true, immediates: [Immediate(name: nil, type: "Instruction.TableGrowOperand")]),
        Instruction(name: "tableFill", mayThrow: true, hasData: true, immediates: [Immediate(name: nil, type: "Instruction.TableFillOperand")]),
        Instruction(name: "tableCopy", mayThrow: true, hasData: true, immediates: [Immediate(name: nil, type: "Instruction.TableCopyOperand")]),
        Instruction(name: "tableInit", mayThrow: true, hasData: true, immediates: [Immediate(name: nil, type: "Instruction.TableInitOperand")]),
        Instruction(name: "tableElementDrop", immediates: [Immediate(name: nil, type: "ElementIndex")]),
        // Profiling
        Instruction(name: "onEnter", immediates: [Immediate(name: nil, type: "Instruction.OnEnterOperand")]).withRawOperand(),
        Instruction(name: "onExit", immediates: [Immediate(name: nil, type: "Instruction.OnExitOperand")]).withRawOperand(),
    ]

    // MARK: - Instruction generation

    static func buildInstructions() -> [Instruction] {
        var instructions: [Instruction] = [
            // Variable
            Instruction(name: "copyStack", immediates: [Immediate(name: nil, type: "Instruction.CopyStackOperand")]).withRawOperand(),
            Instruction(name: "globalGet", hasData: true, immediates: [Immediate(name: nil, type: "Instruction.GlobalGetOperand")]).withRawOperand(),
            Instruction(name: "globalSet", hasData: true, immediates: [Immediate(name: nil, type: "Instruction.GlobalSetOperand")]).withRawOperand(),
            // Controls
            Instruction(
                name: "call", isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write,
                immediates: [
                    Immediate(name: nil, type: "Instruction.CallOperand")
                ]).withRawOperand(),
            Instruction(
                name: "compilingCall", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.CompilingCallOperand")
                ]).withRawOperand(),
            Instruction(
                name: "internalCall", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediates: [
                    Immediate(name: nil, type: "Instruction.InternalCallOperand")
                ]).withRawOperand(),
            Instruction(
                name: "callIndirect", isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write,
                immediates: [
                    Immediate(name: nil, type: "Instruction.CallIndirectOperand")
                ]).withRawOperand(),
            Instruction(name: "unreachable", isControl: true, mayThrow: true, immediates: []),
            Instruction(name: "nop", isControl: true, immediates: []),
            Instruction(
                name: "br", isControl: true, mayUpdateFrame: false,
                immediates: [
                    Immediate(name: "offset", type: "Int32"),
                ]),
            Instruction(
                name: "brIf", isControl: true, mayUpdateFrame: false,
                immediates: [
                    Immediate(name: nil, type: "Instruction.BrIfOperand")
                ]).withRawOperand(),
            Instruction(
                name: "brIfNot", isControl: true, mayUpdateFrame: false,
                immediates: [
                    Immediate(name: nil, type: "Instruction.BrIfOperand")
                ]).withRawOperand(),
            Instruction(
                name: "brTable", isControl: true, mayUpdateFrame: false,
                immediates: [
                    Immediate(name: nil, type: "Instruction.BrTable")
                ]).withRawOperand(),
            Instruction(name: "_return", isControl: true, mayUpdateFrame: true, useCurrentMemory: .write, immediates: []),
            Instruction(name: "endOfExecution", isControl: true, mayThrow: true, mayUpdateFrame: true, immediates: []),
        ]
        instructions += memoryLoadStoreInsts
        instructions += memoryOpInsts
        instructions += numericOtherInsts
        instructions += intBinOps.map(\.instruction)
        instructions += intUnaryInsts.map(\.instruction)
        instructions += floatBinOps.map(\.instruction)
        instructions += floatUnaryOps.map(\.instruction)
        instructions += miscInsts
        return instructions
    }

    static let instructions: [Instruction] = buildInstructions()

    static func camelCase(pascalCase: String) -> String {
        let first = pascalCase.first!.lowercased()
        return first + pascalCase.dropFirst()
    }

    static func generateDispatcher(instructions: [Instruction]) -> String {
        let doExecuteParams: [Instruction.Parameter] =
            [("instruction", "UInt64", false)]
            + ExecParam.allCases.map { ($0.label, $0.type, true) }
        var output = """
            extension ExecutionState {
                @inline(__always)
                mutating func doExecute(_ \(doExecuteParams.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", "))) throws {
                    switch instruction {
            """

        for (index, inst) in instructions.enumerated() {
            let tryPrefix = inst.mayThrow ? "try " : ""
            let args = ExecParam.allCases.map { "\($0.label): &\($0.label)" }
            output += """

                        case \(index): \(tryPrefix)self.execute_\(inst.name)(\(args.joined(separator: ", ")))
                """
        }
        output += """

                    default: preconditionFailure("Unknown instruction!?")

                    }
                }
            }
            """
        return output
    }

    static func generateBasicInstImplementations() -> String {
        var output = """
            extension ExecutionState {
            """

        for op in intBinOps + floatBinOps {
            output += """

                @inline(__always) mutating \(instMethodDecl(op.instruction)) {
                    sp[\(op.resultType): binaryOperand.result] = \(op.mayThrow ? "try " : "")sp[\(op.lhsType): binaryOperand.lhs].\(camelCase(pascalCase: op.op))(sp[\(op.rhsType): binaryOperand.rhs])
                }
            """
        }
        for op in intUnaryInsts + floatUnaryOps {
            output += """

                mutating \(instMethodDecl(op.instruction)) {
                    sp[\(op.resultType): unaryOperand.result] = \(op.mayThrow ? "try " : "")sp[\(op.inputType): unaryOperand.input].\(camelCase(pascalCase: op.op))
                }
            """
        }

        for inst in memoryLoadInsts {
            output += """

                @inline(__always) mutating \(instMethodDecl(inst.base)) {
                    return try memoryLoad(sp: sp, md: md, ms: ms, loadOperand: loadOperand, loadAs: \(inst.loadAs).self, castToValue: { \(inst.castToValue) })
                }
            """
        }
        for inst in memoryStoreInsts {
            output += """

                @inline(__always) mutating \(instMethodDecl(inst.base)) {
                    return try memoryStore(sp: sp, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { \(inst.castFromValue) })
                }
            """
        }

        output += """

            }

            """
        return output
    }

    static func instMethodDecl(_ inst: Instruction) -> String {
        let throwsKwd = inst.mayThrow ? " throws" : ""
        let returnClause = inst.mayUpdatePc ? " -> Pc" : ""
        let args = inst.parameters
        return "func \(inst.name)(\(args.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", ")))\(throwsKwd)\(returnClause)"
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
            guard file.lastPathComponent != "InstructionSupport.swift" else {
                continue
            }
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
        output += "\n"
        output += "extension Instruction {\n"
        output += "    var hasImmediate: Bool {\n"
        output += "        switch self {\n"
        for inst in instructions {
            output += "        case .\(inst.name): return \(inst.immediates.isEmpty ? "false" : "true")\n"
        }
        output += "        }\n"
        output += "    }\n"
        output += "}\n"
        output += "\n"
        output += """
        extension Instruction {
            var useRawOperand: Bool {
                switch self {

        """
        for inst in instructions {
            guard inst.useRawOperand else { continue }
            output += "        case .\(inst.name): return true\n"
        }
        output += """
                default: return false
                }
            }
        }

        """

        output += """
        extension Instruction {
            var rawImmediate: any InstructionImmediate {
                switch self {

        """
        for inst in instructions {
            guard let immediate = inst.immediates.first, inst.useRawOperand else {
                continue
            }
            output += "        case .\(inst.name)(let \(immediate.label)): return \(immediate.label)\n"
        }
        output += """
                default: preconditionFailure()
                }
            }
        }

        """

        output += """
        extension Instruction {
            enum Tagged {

        """
        for inst in instructions {
            guard !inst.useRawOperand, !inst.immediates.isEmpty else { continue }
            output += "        case \(inst.name)(\(inst.immediates.map { $0.type }.joined(separator: ", ")))\n"
        }
        output += """
            }

            var tagged: Tagged {
                switch self {

        """
        for inst in instructions {
            guard !inst.useRawOperand, !inst.immediates.isEmpty else { continue }
            output += "        case let .\(inst.name)(\(inst.immediates.map { $0.label }.joined(separator: ", "))): return .\(inst.name)(\(inst.immediates.map { $0.label }.joined(separator: ", ")))\n"
        }
        output += """
                default: preconditionFailure()
                }
            }
        }

        """
        return output
    }

    static func generateDirectThreadedCode(instructions: [Instruction]) -> String {
        var output = """
            extension ExecutionState {
            """
        for inst in instructions {
            let args = inst.parameters.map { label, _, isInout in
                let isExecParam = ExecParam.allCases.contains { $0.label == label }
                if isExecParam {
                    return "\(label): \(isInout ? "&" : "")\(label).pointee"
                } else {
                    return "\(label): \(isInout ? "&" : "")\(label)"
                }
            }.joined(separator: ", ")
            let throwsKwd = inst.mayThrow ? " throws" : ""
            let tryKwd = inst.mayThrow ? "try " : ""
            let mayAssignPc = inst.mayUpdatePc ? "pc.pointee = " : ""
            output += """

                @_silgen_name("wasmkit_execute_\(inst.name)") @inline(__always)
                mutating func execute_\(inst.name)(\(ExecParam.allCases.map { "\($0.label): UnsafeMutablePointer<\($0.type)>" }.joined(separator: ", ")))\(throwsKwd) {

            """
            if !inst.immediates.isEmpty {
                if inst.useRawOperand {
                    let immediate = inst.immediates[0]
                    output += """
                            let \(immediate.label) = \(immediate.type).load(from: &pc.pointee)

                    """
                } else {
                    output += """
                            let inst = pc.pointee.read(Instruction.Tagged.self)
                            guard case let .\(inst.name)(\(inst.immediates.map { $0.label }.joined(separator: ", "))) = inst else {
                                preconditionFailure()
                            }

                    """
                }
            }
            output += """
                    \(mayAssignPc)\(tryKwd)self.\(inst.name)(\(args))
                }
            """
        }
        output += """

            }
            """

        output += "\n\n"
        output += """
        extension Instruction {
            var rawIndex: Int {
                switch self {

        """
        for (i, inst) in instructions.enumerated() {
            output += "        case .\(inst.name): return \(i)\n"
        }
        output += """
                }
            }
        }

        """
        return output
    }

    static func generateDirectThreadedCodeOfCPart(instructions: [Instruction]) -> String {
        var output = ""

        func handlerName(_ inst: Instruction) -> String {
            "wasmkit_tc_\(inst.name)"
        }

        for inst in instructions {
            let params = ExecParam.allCases
            output += """
            SWIFT_CC(swiftasync) static inline void \(handlerName(inst))(\(params.map { "\($0.type) \($0.label)" }.joined(separator: ", ")), SWIFT_CONTEXT void *state) {
                SWIFT_CC(swift) void wasmkit_execute_\(inst.name)(\(params.map { "\($0.type) *\($0.label)" }.joined(separator: ", ")), SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
                pc += sizeof(uint64_t);
                void * _Nullable error = NULL;
                INLINE_CALL wasmkit_execute_\(inst.name)(\(params.map { "&\($0.label)" }.joined(separator: ", ")), state, &error);\n
            """
            if inst.mayThrow {
                output += "    if (error) return wasmkit_execution_state_set_error(error, state);\n"
            }
            output += """
                return ((wasmkit_tc_exec)(*(void **)pc))(sp, pc, md, ms, state);
            }

            """
        }

        output += """
        static const uint64_t wasmkit_tc_exec_handlers[] = {

        """
        for inst in instructions {
            output += "    (uint64_t)((wasmkit_tc_exec)&\(handlerName(inst))),\n"
        }
        output += """
        };

        """

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
            output += "\n\n"
            output += generateBasicInstImplementations()
            output += "\n\n"
            output += generateDirectThreadedCode(instructions: instructions)

            output += """


            import _CWasmKit.InlineCode

            extension Instruction {
                private static let handlers: [UInt64] = withUnsafePointer(to: wasmkit_tc_exec_handlers) {
                    let count = MemoryLayout.size(ofValue: wasmkit_tc_exec_handlers) / MemoryLayout<wasmkit_tc_exec>.size
                    return $0.withMemoryRebound(to: UInt64.self, capacity: count) {
                        Array(UnsafeBufferPointer(start: $0, count: count))
                    }
                }

                @inline(never)
                var handler: UInt64 {
                    return Self.handlers[rawIndex]
                }
            }

            """

            let outputFile = sourceRoot.appending(path: "Sources/WasmKit/Execution/Runtime/InstDispatch.swift")
            try output.write(to: outputFile, atomically: true, encoding: .utf8)
        }

        do {
            let outputFile = sourceRoot.appending(path: "Sources/_CWasmKit/include/DirectThreadedCode.inc")
            let output = generateDirectThreadedCodeOfCPart(instructions: instructions)
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
