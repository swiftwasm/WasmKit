import WasmParser
import WasmTypes

/// A unified error type for the WasmKit module, encompassing validation, translation,
/// and module parsing errors.
public struct WasmKitError: Swift.Error {
    public struct Message: Sendable {
        package let text: String

        package init(_ text: String) {
            self.text = text
        }
    }

    @usableFromInline
    package enum Kind: Sendable {
        case message(Message)
        case parserError(WasmParserError)
    }

    package let kind: Kind
    package var location: Int?

    @usableFromInline
    package init(kind: Kind, offset: Int? = nil) {
        self.kind = kind
        self.location = offset
    }
}

extension WasmKitError {
    @usableFromInline
    package init(message: Message, offset: Int? = nil) {
        self.kind = .message(message)
        self.location = offset
    }

    @usableFromInline
    package init(_ string: String, offset: Int? = nil) {
        self.kind = .message(.init(string))
        self.location = offset
    }

    @usableFromInline
    package init(_ parserError: WasmParserError) {
        self.kind = .parserError(parserError)
        self.location = parserError.location
    }
}

extension WasmKitError {
    /// Wrap a closure that throws WasmParserError into one that throws WasmKitError.
    @usableFromInline
    static func wrap<T>(_ body: () throws(WasmParserError) -> T) throws(WasmKitError) -> T {
        do {
            return try body()
        } catch {
            throw WasmKitError(error)
        }
    }
}

extension WasmKitError: CustomStringConvertible {
    public var description: String {
        switch self.kind {
        case .message(let message):
            if let offset = self.location {
                return "\"\(message)\" at offset 0x\(String(offset, radix: 16))"
            } else {
                return message.text
            }
        case .parserError(let error):
            return error.description
        }
    }
}

// MARK: - Validation Messages

extension WasmKitError.Message {
    static var simdNotSupported: Self {
        Self("SIMD is not supported")
    }

    static func invalidLaneIndex(lane: UInt8, laneCount: UInt8) -> Self {
        Self("invalid lane index \(lane) (laneCount: \(laneCount))")
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

    static var multipleTablesNotPermitted: Self {
        Self("multiple tables")
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

    static var threadsFeatureRequiredForSharedMemories: Self {
        Self("threads feature is required for shared memories")
    }

    static var sharedMemoryMustHaveMaximum: Self {
        Self("shared memory must have maximum")
    }

    static var referenceTypesFeatureRequiredForNonFuncrefTables: Self {
        Self("reference-types feature is required for non-funcref tables")
    }

    static var dataCountSectionRequired: Self {
        Self("data count section is required but not found")
    }

    static func indexOutOfBounds<Index: Numeric, Max: Numeric>(_ entity: StaticString, _ index: Index, max: Max) -> Self {
        Self("\(entity) index out of bounds: \(index) (max: \(max))")
    }

    static func tableElementTypeMismatch(tableType: String, elementType: String) -> Self {
        Self("table element type mismatch: \(tableType) != \(elementType)")
    }

    static func expectTypeButGot(expected: String, got: String) -> Self {
        Self("expect \(expected) but got \(got)")
    }

    static var sizeMinimumMustNotExceedMaximum: Self {
        Self("size minimum must not be greater than maximum")
    }

    static func functionIndexNotDeclared(index: FunctionIndex) -> Self {
        Self("function index \(index) is not declared but referenced as a function reference")
    }

    static func duplicateExportName(name: String) -> Self {
        Self("duplicate export name: \(name)")
    }

    static func elementSegmentTypeMismatch(
        elementType: ReferenceType,
        tableElementType: ReferenceType
    ) -> Self {
        Self("element segment type \(elementType) does not match table element type \(tableElementType)")
    }

    static var controlStackEmpty: Self {
        Self("control stack is empty. Instruction cannot be appeared after \"end\" of function")
    }

    static func relativeDepthOutOfRange(relativeDepth: UInt32) -> Self {
        Self("relative depth \(relativeDepth) is out of range")
    }

    static var expectedIfControlFrame: Self {
        Self("expected `if` control frame on top of the stack for `else`")
    }

    static var valuesRemainingAtEndOfBlock: Self {
        Self("values remaining on stack at end of block")
    }

    static func parameterResultTypeMismatch(blockType: FunctionType) -> Self {
        Self("expected the same parameter and result types for `if` block but got \(blockType)")
    }

    static func stackHeightUnderflow(available: Int, required: Int) -> Self {
        Self("stack height underflow: available \(available), required \(required)")
    }

    static func expectedTypeOnStack(expected: ValueType, actual: ValueType) -> Self {
        Self("expected \(expected) on the stack top but got \(actual)")
    }

    static func expectedTypeOnStackButEmpty(expected: ValueType?) -> Self {
        let typeHint = expected.map(String.init(describing:)) ?? "a value"
        return Self("expected \(typeHint) on the stack top but it's empty")
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
