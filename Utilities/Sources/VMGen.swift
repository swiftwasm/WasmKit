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
        static let x0 = ExecParam(label: "x0", type: "X0")
        static let d0 = ExecParam(label: "d0", type: "D0")
        static let pc = ExecParam(label: "pc", type: "Pc")
        static let md = ExecParam(label: "md", type: "Md")
        static let ms = ExecParam(label: "ms", type: "Ms")

        static var allCases = [sp, x0, d0, pc, md, ms]
    }

    struct Instruction {
        var name: String
        var isControl: Bool
        var mayThrow: Bool
        var mayUpdateFrame: Bool
        var mayUpdateSp: Bool = false
        var useCurrentMemory: RegisterUse
        var useX0: RegisterUse
        var useD0: RegisterUse
        var immediate: Immediate?

        var mayUpdatePc: Bool {
            self.isControl
        }

        init(
            name: String, isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            useX0: RegisterUse = .none, useD0: RegisterUse = .none,
            immediate: Immediate? = nil
        ) {
            self.name = name
            self.isControl = isControl
            self.mayThrow = mayThrow
            self.mayUpdateFrame = mayUpdateFrame
            self.useCurrentMemory = useCurrentMemory
            self.immediate = immediate
            self.useX0 = useX0
            self.useD0 = useD0
            assert(isControl || !mayUpdateFrame, "non-control instruction should not update frame")
        }

        typealias Parameter = (label: String, type: String, isInout: Bool)
        var parameters: [Parameter] {
            var vregs: [(reg: ExecParam, isInout: Bool)] = []
            if self.mayUpdateFrame {
                vregs += [(ExecParam.sp, true)]
            } else {
                vregs += [(ExecParam.sp, false)]
            }
            switch useX0 {
            case .none: break
            case .read:
                vregs += [(ExecParam.x0, false)]
            case .write:
                vregs += [(ExecParam.x0, true)]
            }
            switch useD0 {
            case .none: break
            case .read:
                vregs += [(ExecParam.d0, false)]
            case .write:
                vregs += [(ExecParam.d0, true)]
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
            if let immediate = self.immediate {
                parameters += [(immediate.label, immediate.type, false)]
            }
            return parameters
        }
    }

    enum ValueType {
        case i32
        case i64
        case f32
        case f64

        func selectExecParam() -> ExecParam {
            switch self {
            case .i32, .i64: return .x0
            case .f32, .f64: return .d0
            }
        }

        func uppercased() -> String {
            switch self {
            case .i32: return "I32"
            case .i64: return "I64"
            case .f32: return "F32"
            case .f64: return "F64"
            }
        }
        func lowercased() -> String {
            switch self {
            case .i32: return "i32"
            case .i64: return "i64"
            case .f32: return "f32"
            case .f64: return "f64"
            }
        }
    }

    enum OperandSource {
        case stack
        case register

        var marker: String {
            switch self {
            case .stack: return "S"
            case .register: return "R"
            }
        }
    }

    struct OperandInfo {
        var type: ValueType
        var source: OperandSource
    }


    struct BinOpInfo {
        var op: String
        var name: String
        var lhsType: ValueType
        var rhsType: ValueType
        var resultType: ValueType
        var mayThrow: Bool = false
        var isCommutative: Bool = false
        var useFastPath: Bool = false

        var operandSources: [(lhs: OperandSource, rhs: OperandSource)] {
            assert(useFastPath)
            var sources: [(lhs: OperandSource, rhs: OperandSource)] = []
            sources += [
                (.stack, .stack),
                (.stack, .register),
            ]
            if !isCommutative {
                sources += [
                    (.register, .stack),
                ]
            }
            return sources
        }

        func instruction(lhs: OperandSource, rhs: OperandSource) -> Instruction {
            assert(useFastPath)
            return Instruction(
                name: name + lhs.marker + rhs.marker,
                mayThrow: mayThrow,
                useX0: .write,
                immediate: Immediate(name: nil, type: "Instruction.BinaryOperand\(lhs.marker)\(rhs.marker)")
            )
        }

        var instruction: [Instruction] {
            guard useFastPath else {
                return [Instruction(
                    name: name, mayThrow: mayThrow,
                    immediate: Immediate(name: nil, type: "Instruction.BinaryOperand")
                )]
            }
            var instructions: [Instruction] = []
            for (lhs, rhs) in operandSources {
                instructions.append(instruction(lhs: lhs, rhs: rhs))
            }
            return instructions
        }
    }

    struct UnOpInfo {
        var op: String
        var name: String
        var inputType: ValueType
        var resultType: ValueType
        var mayThrow: Bool = false

        var instruction: Instruction {
            Instruction(name: name, mayThrow: mayThrow, immediate: Immediate(name: nil, type: "Instruction.UnaryOperand"))
        }
    }

    static let intValueTypes: [ValueType] = [.i32, .i64]
    static let floatValueTypes: [ValueType] = [.f32, .f64]
    static let valueTypes = intValueTypes + floatValueTypes

    // MARK: - Int instructions

    static func buildIntBinOps() -> [BinOpInfo] {
        var results: [BinOpInfo] = []
        // (T, T) -> T for all T in int types
        // Commutative
        results += [
            "Add", "Mul", "And", "Or", "Xor",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: $0, isCommutative: true, useFastPath: true) }
        }
        // Non-commutative
        results += [
            "Sub", "Shl", "ShrS", "ShrU", "Rotl", "Rotr",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: $0, isCommutative: false, useFastPath: true) }
        }
        results += [
            "DivS", "DivU", "RemS", "RemU",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: $0, mayThrow: true, isCommutative: false, useFastPath: true) }
        }

        // (T, T) -> i32 for all T in int types
        results += [
            "Eq", "Ne",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: .i32, isCommutative: true, useFastPath: true) }
        }
        results += [
            "LtS", "LtU", "GtS", "GtU", "LeS", "LeU", "GeS", "GeU",
        ].flatMap { op -> [BinOpInfo] in
            intValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: .i32, isCommutative: false, useFastPath: true) }
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
            intValueTypes.map { UnOpInfo(op: op, name: "\($0)\(op)", inputType: $0, resultType: .i32) }
        }
        // (i64) -> i32
        results += [UnOpInfo(op: "Wrap", name: "i32WrapI64", inputType: .i64, resultType: .i32)]
        // (i32) -> i64
        results += ["ExtendI32S", "ExtendI32U"].map { op -> UnOpInfo in
            UnOpInfo(op: op, name: "i64\(op)", inputType: .i32, resultType: .i64)
        }
        // (T) -> T for all T in int types
        results += ["Extend8S", "Extend16S"].flatMap { op -> [UnOpInfo] in
            intValueTypes.map { UnOpInfo(op: op, name: "\($0)\(op)", inputType: $0, resultType: $0) }
        }
        // (i64) -> i64
        results += ["Extend32S"].map { op -> UnOpInfo in
            UnOpInfo(op: op, name: "i64\(op)", inputType: .i64, resultType: .i64)
        }
        // Truncation
        let truncInOut: [(source: ValueType, result: ValueType)] = [
            (.f32, .i32), (.f64, .i32), (.f32, .i64), (.f64, .i64)
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
        let convInOut: [(source: ValueType, result: ValueType)] = [
            (.i32, .f32), (.i64, .f32), (.i32, .f64), (.i64, .f64)
        ]
        results += convInOut.flatMap { source, result in
            [
                UnOpInfo(op: "ConvertTo\(result.uppercased())S", name: "\(result)Convert\(source.uppercased())S", inputType: source, resultType: result),
                UnOpInfo(op: "ConvertTo\(result.uppercased())U", name: "\(result)Convert\(source.uppercased())U", inputType: source, resultType: result),
            ]
        }
        // Reinterpret
        let reinterpretInOut: [(source: ValueType, result: ValueType)] = [
            (.i32, .f32), (.i64, .f64), (.f32, .i32), (.f64, .i64)
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
            floatValueTypes.map { BinOpInfo(op: op, name: "\($0)\(op)", lhsType: $0, rhsType: $0, resultType: .i32) }
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
            UnOpInfo(op: op, name: "f64\(op)", inputType: .f32, resultType: .f64)
        }
        // (f64) -> f32
        results += ["DemoteF64"].map { op -> UnOpInfo in
            UnOpInfo(op: op, name: "f32\(op)", inputType: .f64, resultType: .f32)
        }
        return results
    }
    static let floatUnaryOps: [UnOpInfo] = buildFloatUnaryOps()

    // MARK: - Minor numeric instructions

    static let numericOtherInsts: [Instruction] = [
        // Numeric
        Instruction(name: "constI32", useX0: .write, immediate: Immediate(name: nil, type: "Instruction.Const32Operand")),
        Instruction(name: "constI64", useX0: .write, immediate: Immediate(name: nil, type: "Instruction.Const64Operand")),
        Instruction(name: "constF32", useD0: .write, immediate: Immediate(name: nil, type: "Instruction.Const32Operand")),
        Instruction(name: "constF64", useD0: .write, immediate: Immediate(name: nil, type: "Instruction.Const64Operand")),
    ]

    // MARK: - Memory instructions

    struct LoadInstruction {
        let name: String
        let loadAs: String
        let resultType: ValueType
        let castToValue: String

        func instruction(_ operand: OperandSource) -> Instruction {
            switch resultType {
            case .i32, .i64:
                return Instruction(
                    name: name + operand.marker,
                    mayThrow: true, useCurrentMemory: .read, useX0: .write,
                    immediate: Immediate(name: nil, type: "Instruction.LoadOperand\(operand.marker)")
                )
            case .f32, .f64:
                return Instruction(
                    name: name + operand.marker,
                    mayThrow: true, useCurrentMemory: .read, useX0: .read, useD0: .write,
                    immediate: Immediate(name: nil, type: "Instruction.LoadOperand\(operand.marker)")
                )
            }
        }

        var operandSources: [OperandSource] {
            [.stack, .register]
        }

        var instructions: [Instruction] {
            operandSources.map(instruction)
        }
    }

    static let memoryLoadInsts: [LoadInstruction] = [
        (.i32, "i32Load", "Int32", "Int32"),
        (.i64, "i64Load", "Int64", "Int64"),
        (.f32, "f32Load", "Float32", "Float32"),
        (.f64, "f64Load", "Float64", "Float64"),
        (.i32, "i32Load8S", "Int8", "Int32"),
        (.i32, "i32Load8U", "UInt8", "UInt32"),
        (.i32, "i32Load16S", "Int16", "Int32"),
        (.i32, "i32Load16U", "UInt16", "UInt32"),
        (.i64, "i64Load8S", "Int8", "Int64"),
        (.i64, "i64Load8U", "UInt8", "UInt64"),
        (.i64, "i64Load16S", "Int16", "Int64"),
        (.i64, "i64Load16U", "UInt16", "UInt64"),
        (.i64, "i64Load32S", "Int32", "Int64"),
        (.i64, "i64Load32U", "UInt32", "UInt64"),
    ].map { (resultType: ValueType, name, loadAs, castToValue) in
        return LoadInstruction(name: name, loadAs: loadAs, resultType: resultType, castToValue: castToValue)
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
        let base = Instruction(name: name, mayThrow: true, useCurrentMemory: .read, immediate: Immediate(name: nil, type: "Instruction.StoreOperand"))
        return StoreInstruction(castFromValue: castFromValue, base: base)
    }
    static let memoryLoadStoreInsts: [Instruction] = memoryLoadInsts.flatMap(\.instructions) + memoryStoreInsts.map(\.base)
    static let memoryOpInsts: [Instruction] = [
        Instruction(name: "memorySize", immediate: Immediate(name: nil, type: "Instruction.MemorySizeOperand")),
        Instruction(name: "memoryGrow", mayThrow: true, useCurrentMemory: .write, immediate: Immediate(name: nil, type: "Instruction.MemoryGrowOperand")),
        Instruction(name: "memoryInit", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.MemoryInitOperand")),
        Instruction(name: "memoryDataDrop", immediate: Immediate(name: nil, type: "DataIndex")),
        Instruction(name: "memoryCopy", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.MemoryCopyOperand")),
        Instruction(name: "memoryFill", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.MemoryFillOperand")),
    ]

    // MARK: - Misc instructions

    static let miscInsts: [Instruction] = [
        // Parametric
        Instruction(name: "select", immediate: Immediate(name: nil, type: "Instruction.SelectOperand")),
        // Reference
        Instruction(name: "refNull", immediate: Immediate(name: nil, type: "Instruction.RefNullOperand")),
        Instruction(name: "refIsNull", immediate: Immediate(name: nil, type: "Instruction.RefIsNullOperand")),
        Instruction(name: "refFunc", immediate: Immediate(name: nil, type: "Instruction.RefFuncOperand")),
        // Table
        Instruction(name: "tableGet", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.TableGetOperand")),
        Instruction(name: "tableSet", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.TableSetOperand")),
        Instruction(name: "tableSize", immediate: Immediate(name: nil, type: "Instruction.TableSizeOperand")),
        Instruction(name: "tableGrow", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.TableGrowOperand")),
        Instruction(name: "tableFill", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.TableFillOperand")),
        Instruction(name: "tableCopy", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.TableCopyOperand")),
        Instruction(name: "tableInit", mayThrow: true, immediate: Immediate(name: nil, type: "Instruction.TableInitOperand")),
        Instruction(name: "tableElementDrop", immediate: Immediate(name: nil, type: "ElementIndex")),
        // Profiling
        Instruction(name: "onEnter", immediate: Immediate(name: nil, type: "Instruction.OnEnterOperand")),
        Instruction(name: "onExit", immediate: Immediate(name: nil, type: "Instruction.OnExitOperand")),
    ]

    // MARK: - Instruction generation

    static func buildInstructions() -> [Instruction] {
        var instructions: [Instruction] = [
            // Variable
            Instruction(name: "copyStack", immediate: Immediate(name: nil, type: "Instruction.CopyStackOperand")),
            Instruction(name: "copyX0ToStackI32", useX0: .read, immediate: Immediate(name: "dest", type: "LLVReg")),
            Instruction(name: "copyX0ToStackI64", useX0: .read, immediate: Immediate(name: "dest", type: "LLVReg")),
            Instruction(name: "copyD0ToStackF32", useD0: .read, immediate: Immediate(name: "dest", type: "LLVReg")),
            Instruction(name: "copyD0ToStackF64", useD0: .read, immediate: Immediate(name: "dest", type: "LLVReg")),
            Instruction(name: "globalGet", immediate: Immediate(name: nil, type: "Instruction.GlobalGetOperand")),
            Instruction(name: "globalSet", immediate: Immediate(name: nil, type: "Instruction.GlobalSetOperand")),
            // Controls
            Instruction(
                name: "call", isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write,
                immediate: Immediate(name: nil, type: "Instruction.CallOperand")
                ),
            Instruction(
                name: "compilingCall", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediate: Immediate(name: nil, type: "Instruction.CompilingCallOperand")
                ),
            Instruction(
                name: "internalCall", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediate:
                    Immediate(name: nil, type: "Instruction.InternalCallOperand")
                ),
            Instruction(
                name: "callIndirect", isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write,
                immediate:
                    Immediate(name: nil, type: "Instruction.CallIndirectOperand")
                ),
            Instruction(name: "unreachable", isControl: true, mayThrow: true),
            Instruction(name: "nop"),
            Instruction(
                name: "br", isControl: true, mayUpdateFrame: false,
                immediate:
                    Immediate(name: "offset", type: "Int32")
                ),
            Instruction(
                name: "brIf", isControl: true, mayUpdateFrame: false,
                immediate:
                    Immediate(name: nil, type: "Instruction.BrIfOperand")
                ),
            Instruction(
                name: "brIfNot", isControl: true, mayUpdateFrame: false,
                immediate:
                    Immediate(name: nil, type: "Instruction.BrIfOperand")
                ),
            Instruction(
                name: "brTable", isControl: true, mayUpdateFrame: false,
                immediate:
                    Immediate(name: nil, type: "Instruction.BrTable")
                ),
            Instruction(name: "_return", isControl: true, mayUpdateFrame: true, useCurrentMemory: .write),
            Instruction(name: "endOfExecution", isControl: true, mayThrow: true, mayUpdateFrame: true),
        ]
        instructions += memoryLoadStoreInsts
        instructions += memoryOpInsts
        instructions += numericOtherInsts
        instructions += intBinOps.flatMap(\.instruction)
        instructions += intUnaryInsts.map(\.instruction)
        instructions += floatBinOps.flatMap(\.instruction)
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
            if op.useFastPath {
                func operand(_ name: String, _ source: OperandSource, _ type: ValueType) -> String {
                    switch source {
                    case .stack: return "sp[\(name)].\(type.lowercased())"
                    case .register: return "readPReg\(String(describing: type).uppercased())(" + type.selectExecParam().label + ")"
                    }
                }
                for (lhs, rhs) in op.operandSources {
                    let inst = op.instruction(lhs: lhs, rhs: rhs)
                    output += """

                        mutating \(instMethodDecl(inst)) {
                    """
                    output += " "
                    let result = op.resultType.selectExecParam().label
                    let immediate = inst.immediate!.label
                    output += """
                    \(op.mayThrow ? "try " : "")writePReg(&\(result), \(operand("\(immediate).lhs", lhs, op.lhsType)).\(camelCase(pascalCase: op.op))(\(operand("\(immediate).rhs", rhs, op.rhsType))))
                    """
                    output += " }"
                }
            } else {
                output += """

                    @inline(__always) mutating \(instMethodDecl(op.instruction[0])) {
                        sp[\(op.resultType): binaryOperand.result] = \(op.mayThrow ? "try " : "")sp[\(op.lhsType): binaryOperand.lhs].\(camelCase(pascalCase: op.op))(sp[\(op.rhsType): binaryOperand.rhs])
                    }
                """
            }
        }
        for op in intUnaryInsts + floatUnaryOps {
            output += """

                mutating \(instMethodDecl(op.instruction)) {
                    sp[\(op.resultType): unaryOperand.result] = \(op.mayThrow ? "try " : "")sp[\(op.inputType): unaryOperand.input].\(camelCase(pascalCase: op.op))
                }
            """
        }

        for loadInst in memoryLoadInsts {
            for operand in loadInst.operandSources {
                let inst = loadInst.instruction(operand)
                let pointer: String
                switch operand {
                case .stack: pointer = "sp[\(inst.immediate!.label).pointer].asAddressOffset()"
                case .register: pointer = "readPRegAddress(x0)"
                }
                let offset = "\(inst.immediate!.label).offset"
                let result = loadInst.resultType.selectExecParam().label
                output += """

                    @inline(__always) mutating \(instMethodDecl(inst)) {
                        writePReg(&\(result), try \(loadInst.castToValue)(memoryLoad(sp: sp, md: md, ms: ms, offset: \(offset), pointer: \(pointer), loadAs: \(loadInst.loadAs).self)))
                    }
                """
            }
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
            if let immediate = inst.immediate {
                output += "("
                if let name = immediate.name {
                    output += name + ": " + immediate.type
                } else {
                    output += immediate.type
                }
                output += ")"
            }
            output += "\n"
        }
        output += "}\n\n"

        output += """
        extension Instruction {
            var rawImmediate: (any InstructionImmediate)? {
                switch self {

        """
        for inst in instructions {
            guard let immediate = inst.immediate else { continue }
            output += "        case .\(inst.name)(let \(immediate.label)): return \(immediate.label)\n"
        }
        output += """
                default: return nil
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
            if let immediate = inst.immediate {
                output += """
                        let \(immediate.label) = \(immediate.type).load(from: &pc.pointee)

                """
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
        output += "\n\n"
        output += "extension Instruction {\n"
        for binOp in intBinOps {
            guard binOp.useFastPath else { continue }
            if binOp.isCommutative {
                output += "    static let \(binOp.name) = Commutative("
                output += "ss: \(binOp.instruction(lhs: .stack, rhs: .stack).name), "
                output += "sr: \(binOp.instruction(lhs: .stack, rhs: .register).name)"
                output += ")\n"
            } else {
                output += "    static let \(binOp.name) = NonCommutative("
                output += "ss: \(binOp.instruction(lhs: .stack, rhs: .stack).name), "
                output += "sr: \(binOp.instruction(lhs: .stack, rhs: .register).name), "
                output += "rs: \(binOp.instruction(lhs: .register, rhs: .stack).name)"
                output += ")\n"
            }
        }
        for loadInst in memoryLoadInsts {
            output += "    static let \(loadInst.name) = LoadInfo("
            output += "s: \(loadInst.instruction(.stack).name), "
            output += "r: \(loadInst.instruction(.register).name)"
            output += ")\n"
        }
        output += "}\n"
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
                return ((wasmkit_tc_exec)(*(void **)pc))(\(params.map { $0.label }.joined(separator: ", ")), state);
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
