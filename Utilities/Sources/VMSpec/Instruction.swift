/// This file defines the instruction set of the internal VM.
///
/// Most of the instructions are directly mapped from the WebAssembly instruction set.
/// Some instructions are added for internal use or for performance reasons.

extension VMGen {

    /// A parameter passed to an instruction execution function.
    /// Expected to be bound to a physical register.
    struct ExecutionParameter: CaseIterable {
        /// The label of the parameter.
        let label: String
        /// The type of the parameter.
        let type: String

        static let sp = Self(label: "sp", type: "Sp")
        static let pc = Self(label: "pc", type: "Pc")
        static let md = Self(label: "md", type: "Md")
        static let ms = Self(label: "ms", type: "Ms")

        /// All cases of `ExecParam`.
        static var allCases = [sp, pc, md, ms]
    }

    /// An immediate operand of an instruction.
    struct Immediate: ExpressibleByStringLiteral {
        let name: String?
        let type: String

        init(name: String? = nil, type: String) {
            self.name = name
            self.type = type
        }

        init(stringLiteral value: String) {
            self.name = nil
            self.type = value
        }

        var label: String {
            name ?? "immediate"
        }
    }

    /// The use of a register in an instruction.
    enum RegisterUse {
        case none
        case read
        case write
    }

    /// An instruction definition for the internal VM.
    struct Instruction {
        var name: String
        var isControl: Bool
        var mayThrow: Bool
        var mayUpdateFrame: Bool
        var mayUpdateSp: Bool = false
        var useCurrentMemory: RegisterUse
        var immediate: Immediate?
        var immediateLayout: ImmediateLayout?

        var mayUpdatePc: Bool {
            self.isControl
        }

        private init(
            name: String, isControl: Bool,
            mayThrow: Bool, mayUpdateFrame: Bool,
            mayUpdateSp: Bool,
            useCurrentMemory: RegisterUse,
            immediate: Immediate?,
            immediateLayout: ImmediateLayout?
        ) {
            self.name = name
            self.isControl = isControl
            self.mayThrow = mayThrow
            self.mayUpdateFrame = mayUpdateFrame
            self.mayUpdateSp = mayUpdateSp
            self.useCurrentMemory = useCurrentMemory
            self.immediate = immediate
            self.immediateLayout = immediateLayout
            assert(isControl || !mayUpdateFrame, "non-control instruction should not update frame")
        }

        init(
            name: String, isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            immediate: String? = nil
        ) {
            self.init(
                name: name, isControl: isControl,
                mayThrow: mayThrow, mayUpdateFrame: mayUpdateFrame,
                mayUpdateSp: false,
                useCurrentMemory: useCurrentMemory,
                immediate: immediate.map { Immediate(type: "Instruction." + $0) },
                immediateLayout: nil
            )
        }

        init(
            name: String, isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            layout: (inout ImmediateLayout) -> Void
        ) {
            let immediateName = pascalCase(camelCase: name) + "Operand"
            var building = ImmediateLayout(name: immediateName)
            layout(&building)
            self.init(
                name: name, isControl: isControl,
                mayThrow: mayThrow, mayUpdateFrame: mayUpdateFrame,
                mayUpdateSp: false,
                useCurrentMemory: useCurrentMemory,
                immediate: Immediate(type: "Instruction." + immediateName),
                immediateLayout: building
            )
        }

        init(
            name: String, isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            immediateLayout: ImmediateLayout
        ) {
            self.init(
                name: name, isControl: isControl,
                mayThrow: mayThrow, mayUpdateFrame: mayUpdateFrame,
                mayUpdateSp: false,
                useCurrentMemory: useCurrentMemory,
                immediate: Immediate(type: "Instruction." + immediateLayout.name),
                immediateLayout: immediateLayout
            )
        }

        typealias Parameter = (label: String, type: String, isInout: Bool)

        /// The parameters of the execution function of this instruction.
        var parameters: [Parameter] {
            var vregs: [(reg: ExecutionParameter, isInout: Bool)] = []
            if self.mayUpdateFrame {
                vregs += [(.sp, true)]
            } else {
                vregs += [(.sp, false)]
            }
            if self.mayUpdatePc {
                vregs += [(.pc, false)]
            }
            switch useCurrentMemory {
            case .none: break
            case .read:
                vregs += [(.md, false), (.ms, false)]
            case .write:
                vregs += [(.md, true), (.ms, true)]
            }
            var parameters: [Parameter] = vregs.map { ($0.reg.label, $0.reg.type, $0.isInout) }
            if let immediate = self.immediate {
                parameters += [(immediate.label, immediate.type, false)]
            }
            return parameters
        }
    }

    /// A binary operation information.
    struct BinOpInfo {
        let op: String
        let name: String
        let lhsType: String
        let rhsType: String
        let resultType: String
        var mayThrow: Bool = false

        /// The instruction definition of this binary operation.
        var instruction: Instruction {
            Instruction(name: name, mayThrow: mayThrow, immediateLayout: .binary)
        }
    }

    /// A unary operation information.
    struct UnOpInfo {
        var op: String
        var name: String
        var inputType: String
        var resultType: String
        var mayThrow: Bool = false

        /// The instruction definition of this unary operation.
        var instruction: Instruction {
            Instruction(name: name, mayThrow: mayThrow, immediateLayout: .unary)
        }
    }

    static let intValueTypes = ["i32", "i64"]
    static let floatValueTypes = ["f32", "f64"]

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
        Instruction(name: "const32") {
            $0.field(name: "value", type: .UInt32)
            $0.field(name: "result", type: .LVReg)
        },
        Instruction(name: "const64") {
            $0.field(name: "value", type: .UntypedValue)
            $0.field(name: "result", type: .LLVReg)
        },
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
        let base = Instruction(name: name, mayThrow: true, useCurrentMemory: .read, immediateLayout: .load)
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
        let base = Instruction(name: name, mayThrow: true, useCurrentMemory: .read, immediateLayout: .store)
        return StoreInstruction(castFromValue: castFromValue, base: base)
    }
    static let memoryLoadStoreInsts: [Instruction] = memoryLoadInsts.map(\.base) + memoryStoreInsts.map(\.base)
    static let memoryOpInsts: [Instruction] = [
        Instruction(name: "memorySize") {
            $0.field(name: "memoryIndex", type: .MemoryIndex)
            $0.field(name: "result", type: .LVReg)
        },
        Instruction(name: "memoryGrow", mayThrow: true, useCurrentMemory: .write) {
            $0.field(name: "result", type: .VReg)
            $0.field(name: "delta", type: .VReg)
            $0.field(name: "memory", type: .MemoryIndex)
        },
        Instruction(name: "memoryInit", mayThrow: true) {
            $0.field(name: "segmentIndex", type: .UInt32)
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "sourceOffset", type: .VReg)
            $0.field(name: "size", type: .VReg)
        },
        Instruction(name: "memoryDataDrop") {
            $0.field(name: "segmentIndex", type: .UInt32)
        },
        Instruction(name: "memoryCopy", mayThrow: true) {
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "sourceOffset", type: .VReg)
            $0.field(name: "size", type: .LVReg)
        },
        Instruction(name: "memoryFill", mayThrow: true) {
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "value", type: .VReg)
            $0.field(name: "size", type: .LVReg)
        },
    ]

    // MARK: - Misc instructions

    static let miscInsts: [Instruction] = [
        // Parametric
        Instruction(name: "select", immediate: "SelectOperand"),
        // Reference
        Instruction(name: "refNull", immediate: "RefNullOperand"),
        Instruction(name: "refIsNull", immediate: "RefIsNullOperand"),
        Instruction(name: "refFunc", immediate: "RefFuncOperand"),
        // Table
        Instruction(name: "tableGet", mayThrow: true, immediate: "TableGetOperand"),
        Instruction(name: "tableSet", mayThrow: true, immediate: "TableSetOperand"),
        Instruction(name: "tableSize", immediate: "TableSizeOperand"),
        Instruction(name: "tableGrow", mayThrow: true, immediate: "TableGrowOperand"),
        Instruction(name: "tableFill", mayThrow: true, immediate: "TableFillOperand"),
        Instruction(name: "tableCopy", mayThrow: true, immediate: "TableCopyOperand"),
        Instruction(name: "tableInit", mayThrow: true, immediate: "TableInitOperand"),
        Instruction(name: "tableElementDrop", immediate: "TableElementDropOperand"),
        // Profiling
        Instruction(name: "onEnter", immediate: "OnEnterOperand"),
        Instruction(name: "onExit", immediate: "OnExitOperand"),
    ]

    // MARK: - Instruction generation

    static func buildInstructions() -> [Instruction] {
        var instructions: [Instruction] = [
            // Variable
            Instruction(name: "copyStack", immediate: "CopyStackOperand"),
            Instruction(name: "globalGet", immediate: "GlobalGetOperand"),
            Instruction(name: "globalSet", immediate: "GlobalSetOperand"),
            // Controls
            Instruction(
                name: "call", isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write,
                immediate: "CallOperand"
                ),
            Instruction(
                name: "compilingCall", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediate: "CompilingCallOperand"
                ),
            Instruction(
                name: "internalCall", isControl: true, mayThrow: true, mayUpdateFrame: true,
                immediate: 
                    "InternalCallOperand"
                ),
            Instruction(
                name: "callIndirect", isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write,
                immediate:
                    "CallIndirectOperand"
                ),
            Instruction(name: "unreachable", isControl: true, mayThrow: true),
            Instruction(name: "nop"),
            Instruction(
                name: "br", isControl: true, mayUpdateFrame: false,
                immediate: "BrOperand"
                ),
            Instruction(
                name: "brIf", isControl: true, mayUpdateFrame: false,
                immediate:
                    "BrIfOperand"
                ),
            Instruction(
                name: "brIfNot", isControl: true, mayUpdateFrame: false,
                immediate: "BrIfOperand"
                ),
            Instruction(
                name: "brTable", isControl: true, mayUpdateFrame: false,
                immediate:
                    "BrTable"
                ),
            Instruction(name: "_return", isControl: true, mayUpdateFrame: true, useCurrentMemory: .write),
            Instruction(name: "endOfExecution", isControl: true, mayThrow: true, mayUpdateFrame: true),
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
}
