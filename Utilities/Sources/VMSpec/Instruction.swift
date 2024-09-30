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
        var documentation: String?
        var isControl: Bool
        var mayThrow: Bool
        var mayUpdateFrame: Bool
        var mayUpdateSp: Bool = false
        var useCurrentMemory: RegisterUse
        /// The immediate operand of the instruction.
        var immediate: Immediate?
        /// The layout of the immediate operand.
        var immediateLayout: ImmediateLayout?

        var mayUpdatePc: Bool {
            self.isControl
        }

        private init(
            name: String,
            documentation: String?,
            isControl: Bool,
            mayThrow: Bool, mayUpdateFrame: Bool,
            mayUpdateSp: Bool,
            useCurrentMemory: RegisterUse,
            immediate: Immediate?,
            immediateLayout: ImmediateLayout?
        ) {
            self.name = name
            self.documentation = documentation
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
            name: String,
            documentation: String? = nil,
            isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            immediate: String? = nil
        ) {
            self.init(
                name: name, documentation: documentation, isControl: isControl,
                mayThrow: mayThrow, mayUpdateFrame: mayUpdateFrame,
                mayUpdateSp: false,
                useCurrentMemory: useCurrentMemory,
                immediate: immediate.map { Immediate(type: "Instruction." + $0) },
                immediateLayout: nil
            )
        }

        init(
            name: String,
            documentation: String? = nil,
            isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            layout: (inout ImmediateLayout) -> Void
        ) {
            let immediateName = pascalCase(camelCase: name) + "Operand"
            var building = ImmediateLayout(name: immediateName)
            layout(&building)
            self.init(
                name: name, documentation: documentation, isControl: isControl,
                mayThrow: mayThrow, mayUpdateFrame: mayUpdateFrame,
                mayUpdateSp: false,
                useCurrentMemory: useCurrentMemory,
                immediate: Immediate(type: "Instruction." + immediateName),
                immediateLayout: building
            )
        }

        init(
            name: String,
            documentation: String? = nil,
            isControl: Bool = false,
            mayThrow: Bool = false, mayUpdateFrame: Bool = false,
            useCurrentMemory: RegisterUse = .none,
            immediateLayout: ImmediateLayout
        ) {
            self.init(
                name: name, documentation: documentation, isControl: isControl,
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
            Instruction(name: name, documentation: "WebAssembly Core Instruction `\(lhsType).\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: mayThrow, immediateLayout: .binary)
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
            Instruction(name: name, documentation: "WebAssembly Core Instruction `\(inputType).\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: mayThrow, immediateLayout: .unary)
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
        Instruction(name: "const32", documentation: "Assign a 32-bit constant to a register") {
            $0.field(name: "value", type: .UInt32)
            $0.field(name: "result", type: .LVReg)
        },
        Instruction(name: "const64", documentation: "Assign a 64-bit constant to a register") {
            $0.field(name: "value", type: .UntypedValue)
            $0.field(name: "result", type: .LLVReg)
        },
    ]

    // MARK: - Memory instructions

    struct LoadOpInfo {
        let type: String
        let op: String
        let loadAs: String
        let castToValue: String
        var instruction: Instruction {
            Instruction(name: "\(type)\(op)", documentation: "WebAssembly Core Instruction `\(type).\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: true, useCurrentMemory: .read, immediateLayout: .load)
        }
    }

    static let memoryLoadOps: [LoadOpInfo] = [
        ("i32", "Load", "UInt32", ".i32($0)"),
        ("i64", "Load", "UInt64", ".i64($0)"),
        ("f32", "Load", "UInt32", ".rawF32($0)"),
        ("f64", "Load", "UInt64", ".rawF64($0)"),
        ("i32", "Load8S", "Int8", ".init(signed: Int32($0))"),
        ("i32", "Load8U", "UInt8", ".i32(UInt32($0))"),
        ("i32", "Load16S", "Int16", ".init(signed: Int32($0))"),
        ("i32", "Load16U", "UInt16", ".i32(UInt32($0))"),
        ("i64", "Load8S", "Int8", ".init(signed: Int64($0))"),
        ("i64", "Load8U", "UInt8", ".i64(UInt64($0))"),
        ("i64", "Load16S", "Int16", ".init(signed: Int64($0))"),
        ("i64", "Load16U", "UInt16", ".i64(UInt64($0))"),
        ("i64", "Load32S", "Int32", ".init(signed: Int64($0))"),
        ("i64", "Load32U", "UInt32", ".i64(UInt64($0))"),
    ].map { (type, op, loadAs, castToValue) in
        return LoadOpInfo(type: type, op: op, loadAs: loadAs, castToValue: castToValue)
    }

    struct StoreOpInfo {
        let type: String
        let op: String
        let castFromValue: String
        var instruction: Instruction {
            Instruction(name: "\(type)\(op)", documentation: "WebAssembly Core Instruction `\(type).\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: true, useCurrentMemory: .read, immediateLayout: .store)
        }
    }
    static let memoryStoreOps: [StoreOpInfo] = [
        ("i32", "Store", "$0.i32"),
        ("i64", "Store", "$0.i64"),
        ("f32", "Store", "$0.rawF32"),
        ("f64", "Store", "$0.rawF64"),
        ("i32", "Store8", "UInt8(truncatingIfNeeded: $0.i32)"),
        ("i32", "Store16", "UInt16(truncatingIfNeeded: $0.i32)"),
        ("i64", "Store8", "UInt8(truncatingIfNeeded: $0.i64)"),
        ("i64", "Store16", "UInt16(truncatingIfNeeded: $0.i64)"),
        ("i64", "Store32", "UInt32(truncatingIfNeeded: $0.i64)"),
    ].map { (type, op, castFromValue) in
        return StoreOpInfo(type: type, op: op, castFromValue: castFromValue)
    }
    static let memoryLoadStoreInsts: [Instruction] = memoryLoadOps.map(\.instruction) + memoryStoreOps.map(\.instruction)
    static let memoryOpInsts: [Instruction] = [
        Instruction(name: "memorySize", documentation: "WebAssembly Core Instruction `memory.size`") {
            $0.field(name: "memoryIndex", type: .MemoryIndex)
            $0.field(name: "result", type: .LVReg)
        },
        Instruction(name: "memoryGrow", documentation: "WebAssembly Core Instruction `memory.grow`", mayThrow: true, useCurrentMemory: .write) {
            $0.field(name: "result", type: .VReg)
            $0.field(name: "delta", type: .VReg)
            $0.field(name: "memory", type: .MemoryIndex)
        },
        Instruction(name: "memoryInit", documentation: "WebAssembly Core Instruction `memory.init`", mayThrow: true) {
            $0.field(name: "segmentIndex", type: .UInt32)
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "sourceOffset", type: .VReg)
            $0.field(name: "size", type: .VReg)
        },
        Instruction(name: "memoryDataDrop", documentation: "WebAssembly Core Instruction `memory.drop`") {
            $0.field(name: "segmentIndex", type: .UInt32)
        },
        Instruction(name: "memoryCopy", documentation: "WebAssembly Core Instruction `memory.copy`", mayThrow: true) {
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "sourceOffset", type: .VReg)
            $0.field(name: "size", type: .LVReg)
        },
        Instruction(name: "memoryFill", documentation: "WebAssembly Core Instruction `memory.fill`", mayThrow: true) {
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "value", type: .VReg)
            $0.field(name: "size", type: .LVReg)
        },
    ]

    // MARK: - Misc instructions

    static let miscInsts: [Instruction] = [
        // Parametric
        Instruction(name: "select", documentation: "WebAssembly Core Instruction `select`") {
            $0.field(name: "result", type: .VReg)
            $0.field(name: "condition", type: .VReg)
            $0.field(name: "onTrue", type: .VReg)
            $0.field(name: "onFalse", type: .VReg)
        },
        // Reference
        Instruction(name: "refNull", documentation: "WebAssembly Core Instruction `ref.null`") {
            $0.field(name: "result", type: .VReg)
            $0.field(name: "rawType", type: .UInt8)
        },
        Instruction(name: "refIsNull", documentation: "WebAssembly Core Instruction `ref.is_null`") {
            $0.field(name: "value", type: .LVReg)
            $0.field(name: "result", type: .LVReg)
        },
        Instruction(name: "refFunc", documentation: "WebAssembly Core Instruction `ref.func`") {
            $0.field(name: "index", type: .FunctionIndex)
            $0.field(name: "result", type: .LVReg)
        },
        // Table
        Instruction(name: "tableGet", documentation: "WebAssembly Core Instruction `table.get`", mayThrow: true) {
            $0.field(name: "index", type: .VReg)
            $0.field(name: "result", type: .VReg)
            $0.field(name: "tableIndex", type: .UInt32)
        },
        Instruction(name: "tableSet", documentation: "WebAssembly Core Instruction `table.set`", mayThrow: true) {
            $0.field(name: "index", type: .VReg)
            $0.field(name: "value", type: .VReg)
            $0.field(name: "tableIndex", type: .UInt32)
        },
        Instruction(name: "tableSize", documentation: "WebAssembly Core Instruction `table.size`") {
            $0.field(name: "tableIndex", type: .UInt32)
            $0.field(name: "result", type: .LVReg)
        },
        Instruction(name: "tableGrow", documentation: "WebAssembly Core Instruction `table.grow`", mayThrow: true) {
            $0.field(name: "tableIndex", type: .UInt32)
            $0.field(name: "result", type: .VReg)
            $0.field(name: "delta", type: .VReg)
            $0.field(name: "value", type: .VReg)
        },
        Instruction(name: "tableFill", documentation: "WebAssembly Core Instruction `table.fill`", mayThrow: true) {
            $0.field(name: "tableIndex", type: .UInt32)
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "value", type: .VReg)
            $0.field(name: "size", type: .VReg)
        },
        Instruction(name: "tableCopy", documentation: "WebAssembly Core Instruction `table.copy`", mayThrow: true) {
            $0.field(name: "sourceIndex", type: .UInt32)
            $0.field(name: "destIndex", type: .UInt32)
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "sourceOffset", type: .VReg)
            $0.field(name: "size", type: .VReg)
        },
        Instruction(name: "tableInit", documentation: "WebAssembly Core Instruction `table.init`", mayThrow: true) {
            $0.field(name: "tableIndex", type: .UInt32)
            $0.field(name: "segmentIndex", type: .UInt32)
            $0.field(name: "destOffset", type: .VReg)
            $0.field(name: "sourceOffset", type: .VReg)
            $0.field(name: "size", type: .VReg)
        },
        Instruction(name: "tableElementDrop", documentation: "WebAssembly Core Instruction `table.drop`") {
            $0.field(name: "index", type: .ElementIndex)
        },
        // Profiling
        Instruction(name: "onEnter", documentation: "Intercept the entry of a function", immediate: "OnEnterOperand"),
        Instruction(name: "onExit", documentation: "Intercept the exit of a function", immediate: "OnExitOperand"),
    ]

    // MARK: - Instruction generation

    static func buildInstructions() -> [Instruction] {
        var instructions: [Instruction] = [
            // Variable
            Instruction(name: "copyStack", documentation: "Copy a register value to another register") {
                $0.field(name: "source", type: .LVReg)
                $0.field(name: "dest", type: .LVReg)
            },
            Instruction(name: "globalGet", documentation: "WebAssembly Core Instruction `global.get`", immediateLayout: .globalAndVRegOperand),
            Instruction(name: "globalSet", documentation: "WebAssembly Core Instruction `global.set`", immediateLayout: .globalAndVRegOperand),
            // Controls
            Instruction(
                name: "call", documentation: "WebAssembly Core Instruction `call`",
                isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write, immediateLayout: .call
            ),
            Instruction(
                name: "compilingCall", documentation: """
                Compile a callee function (if not compiled) and call it.

                This instruction is replaced by `internalCall` after the callee is compiled.
                """,
                isControl: true, mayThrow: true, mayUpdateFrame: true, immediateLayout: .call
            ),
            Instruction(
                name: "internalCall", documentation: """
                Call a function defined in the current module

                This instruction can skip switching the current instance.
                """,
                isControl: true, mayThrow: true, mayUpdateFrame: true, immediateLayout: .call
            ),
            Instruction(name: "callIndirect", documentation: "WebAssembly Core Instruction `call_indirect`",
                        isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write) {
                $0.field(name: "tableIndex", type: .UInt32)
                $0.field(name: "rawType", type: .UInt32)
                $0.field(name: "index", type: .VReg)
                $0.field(name: "spAddend", type: .VReg)
            },
            Instruction(name: "unreachable", documentation: "WebAssembly Core Instruction `unreachable`",
                        isControl: true, mayThrow: true),
            Instruction(name: "nop", documentation: "WebAssembly Core Instruction `nop`"),
            Instruction(
                name: "br", documentation: "Unconditional pc-relative branch",
                isControl: true, mayUpdateFrame: false,
                immediate: "BrOperand"),
            Instruction(
                name: "brIf", documentation: "Conditional pc-relative branch if the condition is true",
                isControl: true, mayUpdateFrame: false, immediateLayout: .brIfOperand),
            Instruction(
                name: "brIfNot", documentation: "Conditional pc-relative branch if the condition is false",
                isControl: true, mayUpdateFrame: false, immediateLayout: .brIfOperand),
            Instruction(name: "brTable", documentation: "WebAssembly Core Instruction `br_table`",
                        isControl: true, mayUpdateFrame: false) {
                $0.field(name: "rawBaseAddress", type: .UInt64)
                $0.field(name: "count", type: .UInt16)
                $0.field(name: "index", type: .VReg)
            },
            Instruction(name: "_return", documentation: "Return from a function",
                        isControl: true, mayUpdateFrame: true, useCurrentMemory: .write),
            Instruction(name: "endOfExecution", documentation: """
                        End the execution of the VM

                        This instruction is used to signal the end of the execution of the VM at
                        the root frame.
                        """,
                        isControl: true, mayThrow: true, mayUpdateFrame: true),
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
