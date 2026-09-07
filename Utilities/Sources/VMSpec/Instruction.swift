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
        /// A key identifying the machine code of this instruction's direct-threaded handler.
        ///
        /// Several instructions differ only in the *static* WebAssembly type they
        /// operate on and compile to bit-identical handler bodies (`i32.load` and
        /// `f32.load` both zero-extend a 32-bit load into the 64-bit stack slot, for
        /// example). Instructions sharing a non-nil identity get a single
        /// `wasmkit_tc_*` handler; every opcode in the group points its handler-table
        /// entry at it. Without this the compiler's function merging pass folds the
        /// duplicates anyway and leaves a `b <canonical>` thunk behind, which costs an
        /// extra taken branch on every dispatch to the duplicated opcode.
        ///
        /// The identity must describe the *raw* slot-to-slot behaviour of the handler,
        /// so it has to be derived from the same fields that generate the body.
        /// Control instructions must never share an identity: the debugger maps a
        /// direct-threaded head slot back to an opcode ID, which requires handlers of
        /// control instructions to be distinct.
        var handlerIdentity: String? = nil

        /// Whether the handler body can return the head slot of a trap pseudo-instruction
        /// instead of falling through to the next instruction (see `memoryTrapInsts`).
        ///
        /// Such a handler has two exits, so the generated wrapper loads the next
        /// instruction's head slot and bumps `pc` *before* running the body: otherwise the
        /// two exits get tail-merged and the fast path pays an extra address computation
        /// and a branch to reach the shared load. Only valid for a body that neither reads
        /// `pc` nor throws.
        var mayDispatchToTrap: Bool = false

        /// Whether this is a trap pseudo-instruction (see `memoryTrapInsts`): never
        /// emitted by the translator, only dispatched to by another handler. The
        /// generator gives each one a constant-foldable head-slot accessor so that a
        /// handler's cold path can reach it without materialising an `Instruction`.
        var isTrapPseudoInstruction: Bool = false

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
        /// See `Instruction.handlerIdentity`.
        var handlerIdentity: String? = nil

        /// The instruction definition of this unary operation.
        var instruction: Instruction {
            var inst = Instruction(name: name, documentation: "WebAssembly Core Instruction `\(inputType).\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: mayThrow, immediateLayout: .unary)
            inst.handlerIdentity = handlerIdentity
            return inst
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
            // `i64.extend_i32_u` reads the low 32 bits of the slot and zero-extends
            // them back into it, which is exactly a 32-bit slot move.
            let identity = op == "ExtendI32U" ? "move(32)" : nil
            return UnOpInfo(op: op, name: "i64\(op)", inputType: "i32", resultType: "i64", handlerIdentity: identity)
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
            // A reinterpret is a pure slot move of the value's bit width.
            let width = source.hasSuffix("32") ? 32 : 64
            return [
                UnOpInfo(op: "ReinterpretTo\(result.uppercased())", name: "\(result)Reinterpret\(source.uppercased())", inputType: source, resultType: result, handlerIdentity: "move(\(width))"),
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
        let isSigned: Bool
        let isFloatingPoint: Bool
        /// The raw behaviour of the handler: load `loadAs` from memory and widen it
        /// into the 64-bit stack slot. Unsigned loads always zero-extend, so the
        /// result type does not matter (`.i32`, `.i64`, `.rawF32` and `.rawF64` all
        /// zero-extend); signed loads sign-extend to the width of the result type.
        private var identitySuffix: String {
            "\(loadAs),\(isSigned ? "sext\(type)" : "zext")"
        }
        var instruction: Instruction {
            var inst = Instruction(name: "\(type)\(op)", documentation: "WebAssembly Core Instruction `\(type).\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: false, useCurrentMemory: .read, immediateLayout: .load)
            inst.mayDispatchToTrap = true
            inst.handlerIdentity = "load(\(identitySuffix))"
            return inst
        }
        var atomicInstruction: Instruction {
            var inst = Instruction(name: "\(type)Atomic\(op)", documentation: "WebAssembly Core Instruction `\(type).atomic.\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: false, useCurrentMemory: .read, immediateLayout: .load)
            inst.mayDispatchToTrap = true
            inst.handlerIdentity = "atomicLoad(\(identitySuffix))"
            return inst
        }
        /// The two-code-slot form used when the memory is 32-bit and the static offset
        /// fits in `UInt32`. See `ImmediateLayout.loadNarrow`.
        var narrowInstruction: Instruction {
            var inst = Instruction(name: "\(type)\(op)Narrow", documentation: "WebAssembly Core Instruction `\(type).\(VMGen.snakeCase(pascalCase: op))` on a 32-bit memory with a 32-bit offset",
                        mayThrow: false, useCurrentMemory: .read, immediateLayout: .loadNarrow)
            inst.mayDispatchToTrap = true
            inst.handlerIdentity = "loadNarrow(\(identitySuffix))"
            return inst
        }
    }

    static let memoryLoadOps: [LoadOpInfo] = [
        ("i32", "Load", "UInt32", ".i32($0)", false, false),
        ("i64", "Load", "UInt64", ".i64($0)", false, false),
        ("f32", "Load", "UInt32", ".rawF32($0)", false, true),
        ("f64", "Load", "UInt64", ".rawF64($0)", false, true),
        ("i32", "Load8S", "Int8", ".init(signed: Int32($0))", true, false),
        ("i32", "Load8U", "UInt8", ".i32(UInt32($0))", false, false),
        ("i32", "Load16S", "Int16", ".init(signed: Int32($0))", true, false),
        ("i32", "Load16U", "UInt16", ".i32(UInt32($0))", false, false),
        ("i64", "Load8S", "Int8", ".init(signed: Int64($0))", true, false),
        ("i64", "Load8U", "UInt8", ".i64(UInt64($0))", false, false),
        ("i64", "Load16S", "Int16", ".init(signed: Int64($0))", true, false),
        ("i64", "Load16U", "UInt16", ".i64(UInt64($0))", false, false),
        ("i64", "Load32S", "Int32", ".init(signed: Int64($0))", true, false),
        ("i64", "Load32U", "UInt32", ".i64(UInt64($0))", false, false),
    ].map { (type, op, loadAs, castToValue, isSigned, isFloatingPoint) in
        return LoadOpInfo(type: type, op: op, loadAs: loadAs, castToValue: castToValue, isSigned: isSigned, isFloatingPoint: isFloatingPoint)
    }

    static let memoryAtomicLoadOps = memoryLoadOps.filter { !$0.isFloatingPoint && !$0.isSigned }

    struct StoreOpInfo {
        let type: String
        /// The number of bits actually written to memory. Every store truncates the
        /// 64-bit stack slot to this width, so the width alone determines the code
        /// (`i32.store`, `f32.store` and `i64.store32` all store the low 32 bits).
        let storeWidth: Int
        let op: String
        let castFromValue: String
        let isFloatingPoint: Bool

        var instruction: Instruction {
            var inst = Instruction(name: "\(type)\(op)", documentation: "WebAssembly Core Instruction `\(type).\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: false, useCurrentMemory: .read, immediateLayout: .store)
            inst.mayDispatchToTrap = true
            inst.handlerIdentity = "store(\(storeWidth))"
            return inst
        }
        var atomicInstruction: Instruction {
            var inst = Instruction(name: "\(type)Atomic\(op)", documentation: "WebAssembly Core Instruction `\(type).atomic.\(VMGen.snakeCase(pascalCase: op))`",
                        mayThrow: false, useCurrentMemory: .read, immediateLayout: .store)
            inst.mayDispatchToTrap = true
            inst.handlerIdentity = "atomicStore(\(storeWidth))"
            return inst
        }
        /// The two-code-slot form used when the memory is 32-bit and the static offset
        /// fits in `UInt32`. See `ImmediateLayout.storeNarrow`.
        var narrowInstruction: Instruction {
            var inst = Instruction(name: "\(type)\(op)Narrow", documentation: "WebAssembly Core Instruction `\(type).\(VMGen.snakeCase(pascalCase: op))` on a 32-bit memory with a 32-bit offset",
                        mayThrow: false, useCurrentMemory: .read, immediateLayout: .storeNarrow)
            inst.mayDispatchToTrap = true
            inst.handlerIdentity = "storeNarrow(\(storeWidth))"
            return inst
        }
    }
    static let memoryStoreOps: [StoreOpInfo] = [
        ("i32", 32, "Store", "$0.i32", false),
        ("i64", 64, "Store", "$0.i64", false),
        ("f32", 32, "Store", "$0.rawF32", true),
        ("f64", 64, "Store", "$0.rawF64", true),
        ("i32", 8, "Store8", "UInt8(truncatingIfNeeded: $0.i32)", false),
        ("i32", 16, "Store16", "UInt16(truncatingIfNeeded: $0.i32)", false),
        ("i64", 8, "Store8", "UInt8(truncatingIfNeeded: $0.i64)", false),
        ("i64", 16, "Store16", "UInt16(truncatingIfNeeded: $0.i64)", false),
        ("i64", 32, "Store32", "UInt32(truncatingIfNeeded: $0.i64)", false),
    ].map { (type, storeWidth, op, castFromValue, isFloatingPoint) in
        return StoreOpInfo(type: type, storeWidth: storeWidth, op: op, castFromValue: castFromValue, isFloatingPoint: isFloatingPoint)
    }
    static let memoryAtomicStoreOps = memoryStoreOps.filter { !$0.isFloatingPoint }
    static let memoryLoadStoreInsts: [Instruction] = memoryLoadOps.map(\.instruction) + memoryStoreOps.map(\.instruction)
    /// The two-code-slot forms of the loads and stores, for a 32-bit memory with a
    /// `UInt32` offset. The translator picks between these and the wide forms.
    static let memoryLoadStoreNarrowInsts: [Instruction] = memoryLoadOps.map(\.narrowInstruction) + memoryStoreOps.map(\.narrowInstruction)
    static let memoryAtomicInsts: [Instruction] = memoryAtomicLoadOps.map(\.atomicInstruction) + memoryAtomicStoreOps.map(\.atomicInstruction)

    // MARK: - Atomic RMW Operations

    struct RmwOpInfo {
        let type: String
        let op: String
        let size: String?
        let castFromValue: String
        let castToValue: String
        var instruction: Instruction {
            let name: String
            if let size = size {
                name = "\(type)AtomicRmw\(size)\(op)U"
            } else {
                name = "\(type)AtomicRmw\(op)"
            }
            let doc: String
            if let size = size {
                doc = "WebAssembly Core Instruction `\(type).atomic.rmw\(size).\(VMGen.snakeCase(pascalCase: op))_u`"
            } else {
                doc = "WebAssembly Core Instruction `\(type).atomic.rmw.\(VMGen.snakeCase(pascalCase: op))`"
            }
            var inst = Instruction(name: name, documentation: doc,
                        mayThrow: false, useCurrentMemory: .read, immediateLayout: .rmw)
            inst.mayDispatchToTrap = true
            // The handler truncates the operand to `accessWidth` bits, applies the
            // atomic operation and zero-extends the old value back into the slot, so
            // the operation and the access width fully determine the code
            // (`i32.atomic.rmw.add` and `i64.atomic.rmw32.add_u` are the same).
            inst.handlerIdentity = "rmw(\(op),\(size ?? (type == "i32" ? "32" : "64")))"
            return inst
        }
    }

    static let atomicRmwOps: [RmwOpInfo] = [
        ("i32", "Add", nil, "$0.i32", ".i32($0)", false),
        ("i64", "Add", nil, "$0.i64", ".i64($0)", false),
        ("i32", "Sub", nil, "$0.i32", ".i32($0)", false),
        ("i64", "Sub", nil, "$0.i64", ".i64($0)", false),
        ("i32", "And", nil, "$0.i32", ".i32($0)", false),
        ("i64", "And", nil, "$0.i64", ".i64($0)", false),
        ("i32", "Or", nil, "$0.i32", ".i32($0)", false),
        ("i64", "Or", nil, "$0.i64", ".i64($0)", false),
        ("i32", "Xor", nil, "$0.i32", ".i32($0)", false),
        ("i64", "Xor", nil, "$0.i64", ".i64($0)", false),
        ("i32", "Xchg", nil, "$0.i32", ".i32($0)", false),
        ("i64", "Xchg", nil, "$0.i64", ".i64($0)", false),
    ].map { (type, op, size, castFromValue, castToValue, _) in
        return RmwOpInfo(type: type, op: op, size: size, castFromValue: castFromValue, castToValue: castToValue)
    }

    static let atomicRmw8Ops: [RmwOpInfo] = [
        ("i32", "Add", "8", "UInt8(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Add", "8", "UInt8(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Sub", "8", "UInt8(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Sub", "8", "UInt8(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "And", "8", "UInt8(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "And", "8", "UInt8(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Or", "8", "UInt8(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Or", "8", "UInt8(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Xor", "8", "UInt8(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Xor", "8", "UInt8(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Xchg", "8", "UInt8(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Xchg", "8", "UInt8(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
    ].map { (type, op, size, castFromValue, castToValue, _) in
        return RmwOpInfo(type: type, op: op, size: size, castFromValue: castFromValue, castToValue: castToValue)
    }

    static let atomicRmw16Ops: [RmwOpInfo] = [
        ("i32", "Add", "16", "UInt16(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Add", "16", "UInt16(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Sub", "16", "UInt16(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Sub", "16", "UInt16(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "And", "16", "UInt16(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "And", "16", "UInt16(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Or", "16", "UInt16(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Or", "16", "UInt16(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Xor", "16", "UInt16(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Xor", "16", "UInt16(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i32", "Xchg", "16", "UInt16(truncatingIfNeeded: $0.i32)", ".i32(UInt32($0))", false),
        ("i64", "Xchg", "16", "UInt16(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
    ].map { (type, op, size, castFromValue, castToValue, _) in
        return RmwOpInfo(type: type, op: op, size: size, castFromValue: castFromValue, castToValue: castToValue)
    }

    static let atomicRmw32Ops: [RmwOpInfo] = [
        ("i64", "Add", "32", "UInt32(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i64", "Sub", "32", "UInt32(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i64", "And", "32", "UInt32(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i64", "Or", "32", "UInt32(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i64", "Xor", "32", "UInt32(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
        ("i64", "Xchg", "32", "UInt32(truncatingIfNeeded: $0.i64)", ".i64(UInt64($0))", false),
    ].map { (type, op, size, castFromValue, castToValue, _) in
        return RmwOpInfo(type: type, op: op, size: size, castFromValue: castFromValue, castToValue: castToValue)
    }

    /// The compare-exchange instructions, as (instruction name, WebAssembly name, accessed width).
    /// Like the other RMW handlers, the accessed width alone determines the machine code.
    static let atomicCmpxchgOps: [Instruction] = [
        ("i32AtomicRmwCmpxchg", "i32.atomic.rmw.cmpxchg", 32),
        ("i64AtomicRmwCmpxchg", "i64.atomic.rmw.cmpxchg", 64),
        ("i32AtomicRmw8CmpxchgU", "i32.atomic.rmw8.cmpxchg_u", 8),
        ("i32AtomicRmw16CmpxchgU", "i32.atomic.rmw16.cmpxchg_u", 16),
        ("i64AtomicRmw8CmpxchgU", "i64.atomic.rmw8.cmpxchg_u", 8),
        ("i64AtomicRmw16CmpxchgU", "i64.atomic.rmw16.cmpxchg_u", 16),
        ("i64AtomicRmw32CmpxchgU", "i64.atomic.rmw32.cmpxchg_u", 32),
    ].map { (name, wasmName, width) in
        var inst = Instruction(name: name, documentation: "WebAssembly Core Instruction `\(wasmName)`",
                    mayThrow: false, useCurrentMemory: .read, immediateLayout: .cmpxchg)
        inst.mayDispatchToTrap = true
        inst.handlerIdentity = "rmw(Cmpxchg,\(width))"
        return inst
    }

    /// Pseudo-instructions that raise a memory trap.
    ///
    /// They are never emitted into an instruction sequence. The memory load/store and
    /// atomic handlers dispatch to them -- by returning their head slot as the "next"
    /// instruction -- instead of throwing. That keeps the out-of-bounds path a tail call
    /// (`b`) with no live state, so the fast path needs no native frame at all; a `throw`
    /// out of the handler body would be a `bl` and force a prologue/epilogue onto every
    /// load and store. See `.track/issues/015`.
    static let memoryTrapInsts: [Instruction] = [
        Instruction(name: "memoryOutOfBoundsTrap", documentation: "Raise `Trap(.memoryOutOfBounds)`. Dispatched to by the memory handlers; never emitted.", mayThrow: true),
        Instruction(name: "unalignedAtomicTrap", documentation: "Raise `Trap(.unalignedAtomic)`. Dispatched to by the atomic handlers; never emitted.", mayThrow: true),
    ].map {
        var inst = $0
        inst.isTrapPseudoInstruction = true
        return inst
    }

    static let atomicWaitNotifyInsts: [Instruction] = [
        Instruction(name: "memoryAtomicWait32", documentation: "WebAssembly Core Instruction `memory.atomic.wait32`",
                    mayThrow: true, useCurrentMemory: .read, immediateLayout: .atomicWait),
        Instruction(name: "memoryAtomicWait64", documentation: "WebAssembly Core Instruction `memory.atomic.wait64`",
                    mayThrow: true, useCurrentMemory: .read, immediateLayout: .atomicWait),
        Instruction(name: "memoryAtomicNotify", documentation: "WebAssembly Core Instruction `memory.atomic.notify`",
                    mayThrow: true, useCurrentMemory: .read, immediateLayout: .atomicNotify),
        Instruction(name: "atomicFence", documentation: "WebAssembly Core Instruction `atomic.fence`"),
    ]
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

        // Debugging
        Instruction(name: "breakpoint",
            documentation: """
            Stop the VM on this instruction as a breakpoint

            This instruction is used in debugging scenarios.
            """,
            isControl: true, mayThrow: true, mayUpdateFrame: true
        ),
    ]

    // MARK: - Exception handling instructions

    static let exceptionHandlingInsts: [Instruction] = [
        Instruction(name: "throwTag", documentation: "WebAssembly Exception Handling `throw`",
                    isControl: true, mayThrow: true) {
            $0.field(name: "tagIndex", type: .UInt32)
            $0.field(name: "payloadBase", type: .VReg)
        },
        Instruction(name: "throwRef", documentation: "WebAssembly Exception Handling `throw_ref`",
                    isControl: true, mayThrow: true) {
            $0.field(name: "exnRef", type: .VReg)
        },
        Instruction(name: "catchHandlers", documentation: "Register exception handlers for a `try_table` block",
                    isControl: true) {
            $0.field(name: "rawBaseAddress", type: .UInt64)
            $0.field(name: "count", type: .UInt16)
        },
        Instruction(name: "catchHandlersEnd", documentation: "Unregister exception handlers for a `try_table` block") {
            $0.field(name: "count", type: .UInt16)
        },
    ]

    // MARK: - Fused compare + branch instructions

    /// The integer comparison operators that have a fused compare+branch form.
    ///
    /// Only integer comparisons are fused: the complement of an integer
    /// comparison is another integer comparison, so a `br_if_not` on a compare
    /// can be expressed by flipping the operator. Float comparisons have no such
    /// complement because of NaN, so they are left unfused.
    static let brIfCmpOps = [
        "Eq", "Ne", "LtS", "LtU", "GtS", "GtU", "LeS", "LeU", "GeS", "GeU",
    ]

    static func buildBrIfCmpInsts() -> [Instruction] {
        var results: [Instruction] = []
        for type in intValueTypes {
            for op in brIfCmpOps {
                let typeName = type.uppercased()
                results.append(
                    Instruction(
                        name: "brIf\(typeName)\(op)",
                        documentation: """
                            Conditional pc-relative branch if `\(type).\(VMGen.snakeCase(pascalCase: op))` holds

                            Fused form of `\(type).\(VMGen.snakeCase(pascalCase: op))` followed by `br_if`.
                            """,
                        isControl: true, mayUpdateFrame: false,
                        immediateLayout: .brIfCmpOperand
                    )
                )
            }
        }
        return results
    }

    static let brIfCmpInsts: [Instruction] = buildBrIfCmpInsts()

    // MARK: - Instruction generation

    static func buildInstructions() -> [Instruction] {
        var instructions: [Instruction] = [
            // Variable
            Instruction(name: "copyStack", documentation: "Copy a register value to another register") {
                $0.field(name: "source", type: .LVReg)
                $0.field(name: "dest", type: .LVReg)
            },
            Instruction(name: "globalGet", documentation: "WebAssembly Core Instruction `global.get` for a scalar (64-bit slot) global", immediateLayout: .globalAndVRegOperand),
            Instruction(name: "globalSet", documentation: "WebAssembly Core Instruction `global.set` for a scalar (64-bit slot) global", immediateLayout: .globalAndVRegOperand),
            Instruction(name: "globalGetV128", documentation: "WebAssembly Core Instruction `global.get` for a `v128` global", immediateLayout: .globalAndVRegOperand),
            Instruction(name: "globalSetV128", documentation: "WebAssembly Core Instruction `global.set` for a `v128` global", immediateLayout: .globalAndVRegOperand),
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
            Instruction(name: "resizeFrameHeader", documentation: """
                        Resize the frame header by increasing param/result slots and copying `sizeToCopy`
                        slots placed after the header
                        """,
                        mayThrow: true, mayUpdateFrame: true) {
                $0.field(name: "delta", type: .VReg)
                $0.field(name: "sizeToCopy", type: .VReg)
            },
            Instruction(name: "returnCall", documentation: "WebAssembly Core Instruction `return_call`",
                        isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write) {
                $0.field(name: "rawCallee", type: .UInt64)
            },
            Instruction(name: "returnCallIndirect", documentation: "WebAssembly Core Instruction `return_call_indirect`",
                        isControl: true, mayThrow: true, mayUpdateFrame: true, useCurrentMemory: .write) {
                $0.field(name: "tableIndex", type: .UInt32)
                $0.field(name: "rawType", type: .UInt32)
                $0.field(name: "index", type: .VReg)
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
        let simdInsts: [Instruction] = [
            Instruction(name: "v128Const", documentation: "WebAssembly SIMD Instruction `v128.const`", immediateLayout: .v128Const),
            Instruction(name: "i8x16Shuffle", documentation: "WebAssembly SIMD Instruction `i8x16.shuffle`", immediateLayout: .i8x16Shuffle),
            Instruction(name: "simd", documentation: "WebAssembly SIMD instruction (runtime-dispatched)", mayThrow: true, useCurrentMemory: .read, immediateLayout: .simd),
        ]
        instructions += memoryLoadStoreInsts
        instructions += memoryOpInsts
        instructions += simdInsts
        instructions += numericOtherInsts
        instructions += intBinOps.map(\.instruction)
        instructions += intUnaryInsts.map(\.instruction)
        instructions += floatBinOps.map(\.instruction)
        instructions += floatUnaryOps.map(\.instruction)
        instructions += miscInsts
        instructions += memoryAtomicInsts
        instructions += atomicRmwOps.map(\.instruction)
        instructions += atomicRmw8Ops.map(\.instruction)
        instructions += atomicRmw16Ops.map(\.instruction)
        instructions += atomicRmw32Ops.map(\.instruction)
        instructions += atomicCmpxchgOps
        instructions += atomicWaitNotifyInsts
        // Exception handling
        instructions += exceptionHandlingInsts
        instructions += brIfCmpInsts
        instructions += [
            Instruction(
                name: "returnCrossInstance",
                documentation: """
                    Return from a function whose caller runs in another instance

                    Never emitted by the translator. `_return` dispatches to this when the
                    frame it pops was entered from a different instance, so that the common
                    intra-module return handler contains no call and therefore needs no
                    stack frame. It receives the *unmodified* `sp`/`pc` of the `_return`
                    that handed off to it.
                    """,
                isControl: true, mayUpdateFrame: true, useCurrentMemory: .write
            )
        ]
        instructions += memoryTrapInsts
        instructions += memoryLoadStoreNarrowInsts
        return instructions
    }

    static let instructions: [Instruction] = buildInstructions()
}
