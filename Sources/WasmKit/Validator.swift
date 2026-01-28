import WasmParser

/// Represents an error that occurs during validation
public struct ValidationError: Error, CustomStringConvertible {
    /// Represents a validation error message.
    struct Message {
        let text: String

        init(_ text: String) {
            self.text = text
        }
    }

    /// The error message.
    let message: Message

    /// The offset in the input WebAssembly module binary where the error occurred.
    /// NOTE: This field is set when the error is temporarily caught by the ``InstructionTranslator``.
    var offset: Int?

    /// The error description.
    public var description: String {
        if let offset = offset {
            return "\(message.text) at offset 0x\(String(offset, radix: 16))"
        } else {
            return message.text
        }
    }

    init(_ message: Message) {
        self.message = message
    }
}

extension ValidationError.Message {
    static var simdNotSupported: Self {
        Self("SIMD is not supported")
    }

    static func invalidMemArgAlignment(memarg: MemArg, naturalAlignment: Int) -> Self {
        Self("alignment 2**\(memarg.align) is out of limit \(naturalAlignment)")
    }

    static var globalSetConstant: Self {
        Self("cannot set a constant global")
    }

    static var multipleMemoriesNotPermitted: Self {
        Self("multiple memories are not permitted")
    }

    static func startFunctionInvalidParameters() -> Self {
        Self("start function must have no parameters and no results")
    }

    static var memory64FeatureRequired: Self {
        Self("memory64 feature is required for 64-bit memories")
    }

    static func sizeMinimumExceeded(max: UInt64) -> Self {
        Self("size minimum must not be greater than \(max)")
    }

    static func sizeMaximumExceeded(max: UInt64) -> Self {
        Self("size maximum must not be greater than \(max)")
    }

    static var referenceTypesFeatureRequiredForSharedMemories: Self {
        Self("reference-types feature is required for shared memories")
    }

    static var referenceTypesFeatureRequiredForNonFuncrefTables: Self {
        Self("reference-types feature is required for non-funcref tables")
    }

    static var dataCountSectionRequired: Self {
        Self("data count section is required but not found")
    }

    static func indexOutOfBounds<Index: Numeric, Max: Numeric>(_ entity: StaticString, _ index: Index, max: Max) -> Self {
        #if !$Embedded
        return Self("\(entity) index out of bounds: \(index) (max: \(max))")
        #else
        return Self("\(entity) index out of bounds: \(index) (max: \(max))")
        #endif
    }

    static func tableElementTypeMismatch(tableType: String, elementType: String) -> Self {
        #if !$Embedded
        return Self("table element type mismatch: \(tableType) != \(elementType)")
        #else
        return Self("table element type mismatch: \(tableType) != \(elementType)")
        #endif
    }

    static func expectTypeButGot(expected: String, got: String) -> Self {
        #if !$Embedded
        return Self("expect \(expected) but got \(got)")
        #else
        return Self("expect a value but got \(got)")
        #endif
    }

    static var sizeMinimumMustNotExceedMaximum: Self {
        Self("size minimum must not be greater than maximum")
    }

    static func functionIndexNotDeclared(index: FunctionIndex) -> Self {
        #if !$Embedded
        return Self("function index \(index) is not declared but referenced as a function reference")
        #else
        return Self("function index \(index) is not declared but referenced as a function reference")
        #endif
    }

    static func duplicateExportName(name: String) -> Self {
        #if !$Embedded
        return Self("duplicate export name: \(name)")
        #else
        return Self("duplicate export name: \(name)")
        #endif
    }

    static func elementSegmentTypeMismatch(
        elementType: ReferenceType,
        tableElementType: ReferenceType
    ) -> Self {
        #if !$Embedded
        return Self("element segment type \(elementType) does not match table element type \(tableElementType)")
        #else
        return Self("element segment type \(elementType) does not match table element type \(tableElementType)")
        #endif
    }

    static var controlStackEmpty: Self {
        #if !$Embedded
        return Self("control stack is empty. Instruction cannot be appeared after \"end\" of function")
        #else
        return Self("control stack is empty. Instruction cannot be appeared after \"end\" of function")
        #endif
    }

    static func relativeDepthOutOfRange(relativeDepth: UInt32) -> Self {
        #if !$Embedded
        return Self("relative depth \(relativeDepth) is out of range")
        #else
        return Self("relative depth \(relativeDepth) is out of range")
        #endif
    }

    static var expectedIfControlFrame: Self {
        #if !$Embedded
        return Self("expected `if` control frame on top of the stack for `else`")
        #else
        return Self("expected `if` control frame on top of the stack for `else`")
        #endif
    }

    static var valuesRemainingAtEndOfBlock: Self {
        #if !$Embedded
        return Self("values remaining on stack at end of block")
        #else
        return Self("values remaining on the stack at end of block")
        #endif
    }

    static func parameterResultTypeMismatch(blockType: FunctionType) -> Self {
        #if !$Embedded
        return Self("expected the same parameter and result types for `if` block but got \(blockType)")
        #else
        return Self("expected the same parameter and result types for `if` block but got \(blockType)")
        #endif
    }

    static func stackHeightUnderflow(available: Int, required: Int) -> Self {
        #if !$Embedded
        return Self("stack height underflow: available \(available), required \(required)")
        #else
        return Self("stack height underflow: available \(available), required \(required)")
        #endif
    }

    static func expectedTypeOnStack(expected: ValueType, actual: ValueType) -> Self {
        #if !$Embedded
        return Self("expected \(expected) on the stack top but got \(actual)")
        #else
        return Self("expected a value on the stack top but got \(actual)")
        #endif
    }

    static func expectedTypeOnStackButEmpty(expected: ValueType?) -> Self {
        #if !$Embedded
        let typeHint = expected.map(String.init(describing:)) ?? "a value"
        return Self("expected \(typeHint) on the stack top but it's empty")
        #else
        return Self("expected a value on the stack top but it's empty")
        #endif
    }

    static func expectedMoreEndInstructions(count: Int) -> Self {
        Self("expect \(count) more `end` instructions")
    }

    static func expectedSameCopyTypes(
        frameCopyTypes: [ValueType],
        defaultFrameCopyTypes: [ValueType]
    ) -> Self {
        Self("expected the same copy types for all branches in `br_table` but got \(frameCopyTypes) and \(defaultFrameCopyTypes)")
    }

    static var cannotSelectOnReferenceTypes: Self {
        Self("cannot `select` on reference types")
    }

    static func typeMismatchOnSelect(expected: ValueType, actual: ValueType) -> Self {
        Self("type mismatch on `select`. Expected \(expected) and \(actual) to be same")
    }

    static var unexpectedGlobalValueType: Self {
        Self("unexpected global value type for element initializer expression")
    }

    static func unexpectedElementInitializer(expression: String) -> Self {
        Self("unexpected element initializer expression: \(expression)")
    }

    static func unexpectedOffsetInitializer(expected: ValueType, got: Value) -> Self {
        Self("expect \(expected) offset but got \(got)")
    }

    static var expectedEndAtOffsetExpression: Self {
        Self("expect `end` at the end of offset expression")
    }

    static func illegalConstExpressionInstruction(_ constInst: WasmParser.Instruction) -> Self {
        Self("illegal const expression instruction: \(constInst)")
    }

    static func inconsistentFunctionAndCodeLength(functionCount: Int, codeCount: Int) -> Self {
        Self("Inconsistent function and code length: \(functionCount) vs \(codeCount)")
    }

    static func inconsistentDataCountAndDataSectionLength(dataCount: UInt32, dataSection: Int) -> Self {
        Self("Inconsistent data count and data section length: \(dataCount) vs \(dataSection)")
    }

    static func typeMismatchOnReturnCall(expected: [ValueType], actual: [ValueType]) -> Self {
        Self("return signatures have inconsistent types: expected \(expected) but got \(actual)")
    }
}

/// Validates instructions within a given context.
struct InstructionValidator {
    let context: InternalInstance

    func validateMemArg(_ memarg: MemArg, naturalAlignment: Int) throws(ValidationError) {
        if memarg.align > naturalAlignment {
            throw ValidationError(.invalidMemArgAlignment(memarg: memarg, naturalAlignment: naturalAlignment))
        }
    }

    func validateGlobalSet(_ type: GlobalType) throws(ValidationError) {
        switch type.mutability {
        case .constant:
            throw ValidationError(.globalSetConstant)
        case .variable:
            break
        }
    }

    func validateTableInit(elemIndex: UInt32, table: UInt32) throws(ValidationError) {
        let tableType = try context.tableType(table)
        let elementType = try context.elementType(elemIndex)
        guard tableType.elementType == elementType else {
            throw ValidationError(.tableElementTypeMismatch(tableType: "\(tableType.elementType)", elementType: "\(elementType)"))
        }
    }

    func validateTableCopy(dest: UInt32, source: UInt32) throws(ValidationError) {
        let tableType1 = try context.tableType(source)
        let tableType2 = try context.tableType(dest)
        guard tableType1.elementType == tableType2.elementType else {
            throw ValidationError(.tableElementTypeMismatch(tableType: "\(tableType1.elementType)", elementType: "\(tableType2.elementType)"))
        }
    }

    func validateRefFunc(functionIndex: UInt32) throws(ValidationError) {
        try context.validateFunctionIndex(functionIndex)
    }

    func validateDataSegment(_ dataIndex: DataIndex) throws(ValidationError) {
        guard let dataCount = context.dataCount else {
            throw ValidationError(.dataCountSectionRequired)
        }
        guard dataIndex < dataCount else {
            throw ValidationError(.indexOutOfBounds("data", dataIndex, max: dataCount))
        }
    }

    func validateReturnCallLike(calleeType: FunctionType, callerType: FunctionType) throws(ValidationError) {
        guard calleeType.results == callerType.results else {
            throw ValidationError(.typeMismatchOnReturnCall(expected: callerType.results, actual: calleeType.results))
        }
    }
}

enum ModuleValidationError: Error {
    case translation(TranslationError)
    case validation(ValidationError)
}

/// Validates a WebAssembly module.
struct ModuleValidator {
    let module: Module
    init(module: Module) {
        self.module = module
    }

    func validate() throws(ModuleValidationError) {
        if module.memoryTypes.count > 1 {
            throw ModuleValidationError.validation(ValidationError(.multipleMemoriesNotPermitted))
        }
        for memoryType in module.memoryTypes {
            do {
                try Self.checkMemoryType(memoryType, features: module.features)
            } catch {
                throw ModuleValidationError.validation(error)
            }
        }
        for tableType in module.tableTypes {
            do {
                try Self.checkTableType(tableType, features: module.features)
            } catch {
                throw ModuleValidationError.validation(error)
            }
        }
        try checkStartFunction()
    }

    func checkStartFunction() throws(ModuleValidationError) {
        if let startFunction = module.start {
            let type: FunctionType
            do {
                type = try module.resolveFunctionType(startFunction)
            } catch {
                throw ModuleValidationError.translation(error)
            }

            guard type.parameters.isEmpty, type.results.isEmpty else {
                throw ModuleValidationError.validation(ValidationError(.startFunctionInvalidParameters()))
            }
        }
    }

    static func checkMemoryType(_ type: MemoryType, features: WasmFeatureSet) throws(ValidationError) {
        try checkLimit(type)

        if type.isMemory64 {
            guard features.contains(.memory64) else {
                throw ValidationError(.memory64FeatureRequired)
            }
        }

        let hardMax = MemoryEntity.maxPageCount(isMemory64: type.isMemory64)

        if type.min > hardMax {
            throw ValidationError(.sizeMinimumExceeded(max: hardMax))
        }

        if let max = type.max, max > hardMax {
            throw ValidationError(.sizeMaximumExceeded(max: hardMax))
        }

        if type.shared {
            guard features.contains(.threads) else {
                throw ValidationError(.referenceTypesFeatureRequiredForSharedMemories)
            }
        }
    }

    static func checkTableType(_ type: TableType, features: WasmFeatureSet) throws(ValidationError) {
        if type.elementType != .funcRef, !features.contains(.referenceTypes) {
            throw ValidationError(.referenceTypesFeatureRequiredForNonFuncrefTables)
        }
        try checkLimit(type.limits)

        if type.limits.isMemory64 {
            guard features.contains(.memory64) else {
                throw ValidationError(.memory64FeatureRequired)
            }
        }

        let hardMax = TableEntity.maxSize(isMemory64: type.limits.isMemory64)

        if type.limits.min > hardMax {
            throw ValidationError(.sizeMinimumExceeded(max: hardMax))
        }

        if let max = type.limits.max, max > hardMax {
            throw ValidationError(.sizeMaximumExceeded(max: hardMax))
        }
    }

    private static func checkLimit(_ limit: Limits) throws(ValidationError) {
        guard let max = limit.max else { return }
        if limit.min > max {
            throw ValidationError(.sizeMinimumMustNotExceedMaximum)
        }
    }
}

extension WasmTypes.Reference {
    /// Checks if the reference type matches the expected type.
    func checkType(_ type: WasmTypes.ReferenceType) throws(ValidationError) {
        switch (self, type.heapType, type.isNullable) {
        case (.function(_?), .funcRef, _): return
        case (.function(nil), .funcRef, true): return
        case (.extern(_?), .externRef, _): return
        case (.extern(nil), .externRef, true): return
        default:
            throw ValidationError(.expectTypeButGot(expected: "\(type)", got: "\(self)"))
        }
    }
}

extension Value {
    /// Checks if the value type matches the expected type.
    func checkType(_ type: WasmTypes.ValueType) throws(ValidationError) {
        switch (self, type) {
        case (.i32, .i32): return
        case (.i64, .i64): return
        case (.f32, .f32): return
        case (.f64, .f64): return
        case (.ref(let ref), .ref(let refType)):
            try ref.checkType(refType)
        default:
            throw ValidationError(.expectTypeButGot(expected: "\(type)", got: "\(self)"))
        }
    }
}
