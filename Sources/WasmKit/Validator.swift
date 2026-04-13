import WasmParser

/// Validates instructions within a given context.
struct InstructionValidator {
    let context: InternalInstance

    func validateMemArg(_ memarg: MemArg, naturalAlignment: Int) throws(WasmKitError) {
        if memarg.align > naturalAlignment {
            throw WasmKitError(message: .invalidMemArgAlignment(memarg: memarg, naturalAlignment: naturalAlignment))
        }
    }

    func validateGlobalSet(_ type: GlobalType) throws(WasmKitError) {
        switch type.mutability {
        case .constant:
            throw WasmKitError(message: .globalSetConstant)
        case .variable:
            break
        }
    }

    func validateTableInit(elemIndex: UInt32, table: UInt32) throws(WasmKitError) {
        let tableType = try context.tableType(table)
        let elementType = try context.elementType(elemIndex)
        guard tableType.elementType == elementType else {
            throw WasmKitError(
                message: .tableElementTypeMismatch(tableType: "\(tableType.elementType)", elementType: "\(elementType)")
            )
        }
    }

    func validateTableCopy(dest: UInt32, source: UInt32) throws(WasmKitError) {
        let tableType1 = try context.tableType(source)
        let tableType2 = try context.tableType(dest)
        guard tableType1.elementType == tableType2.elementType else {
            throw WasmKitError(
                message:
                    .tableElementTypeMismatch(
                        tableType: "\(tableType1.elementType)",
                        elementType: "\(tableType2.elementType)"
                    )
            )
        }
    }

    func validateRefFunc(functionIndex: UInt32) throws(WasmKitError) {
        try context.validateFunctionIndex(functionIndex)
    }

    func validateDataSegment(_ dataIndex: DataIndex) throws(WasmKitError) {
        guard let dataCount = context.dataCount else {
            throw WasmKitError(message: .dataCountSectionRequired)
        }
        guard dataIndex < dataCount else {
            throw WasmKitError(message: .indexOutOfBounds("data", dataIndex, max: dataCount))
        }
    }

    func validateReturnCallLike(calleeType: FunctionType, callerType: FunctionType) throws(WasmKitError) {
        guard calleeType.results == callerType.results else {
            throw WasmKitError(
                message: .typeMismatchOnReturnCall(expected: callerType.results, actual: calleeType.results)
            )
        }
    }
}

/// Validates a WebAssembly module.
struct ModuleValidator {
    let module: Module
    init(module: Module) {
        self.module = module
    }

    func validate() throws(WasmKitError) {
        if module.memoryTypes.count > 1 {
            throw WasmKitError(message: .multipleMemoriesNotPermitted)
        }
        // Multiple tables are allowed with reference types feature
        if module.tableTypes.count > 1 && !module.features.contains(.referenceTypes) {
            throw WasmKitError(message: .multipleTablesNotPermitted)
        }
        for memoryType in module.memoryTypes {
            try Self.checkMemoryType(memoryType, features: module.features)
        }
        for tableType in module.tableTypes {
            try Self.checkTableType(tableType, features: module.features)
        }
        try checkStartFunction()
    }

    func checkStartFunction() throws(WasmKitError) {
        if let startFunction = module.start {
            let type = try module.resolveFunctionType(startFunction)
            guard type.parameters.isEmpty, type.results.isEmpty else {
                throw WasmKitError(message: .startFunctionInvalidParameters())
            }
        }
    }

    static func checkMemoryType(_ type: MemoryType, features: WasmFeatureSet) throws(WasmKitError) {
        try checkLimit(type)

        if type.isMemory64 {
            guard features.contains(.memory64) else {
                throw WasmKitError(message: .memory64FeatureRequired)
            }
        }

        let hardMax = MemoryEntity.maxPageCount(isMemory64: type.isMemory64)

        if type.min > hardMax {
            throw WasmKitError(message: .sizeMinimumExceeded(max: hardMax))
        }

        if let max = type.max, max > hardMax {
            throw WasmKitError(message: .sizeMaximumExceeded(max: hardMax))
        }

        if type.shared {
            guard features.contains(.threads) else {
                throw WasmKitError(message: .threadsFeatureRequiredForSharedMemories)
            }
            guard type.max != nil else {
                throw WasmKitError(message: .sharedMemoryMustHaveMaximum)
            }
        }
    }

    static func checkTableType(_ type: TableType, features: WasmFeatureSet) throws(WasmKitError) {
        if type.elementType != .funcRef, !features.contains(.referenceTypes) {
            throw WasmKitError(message: .referenceTypesFeatureRequiredForNonFuncrefTables)
        }
        try checkLimit(type.limits)

        if type.limits.isMemory64 {
            guard features.contains(.memory64) else {
                throw WasmKitError(message: .memory64FeatureRequired)
            }
        }

        let hardMax = TableEntity.maxSize(isMemory64: type.limits.isMemory64)

        if type.limits.min > hardMax {
            throw WasmKitError(message: .sizeMinimumExceeded(max: hardMax))
        }

        if let max = type.limits.max, max > hardMax {
            throw WasmKitError(message: .sizeMaximumExceeded(max: hardMax))
        }
    }

    private static func checkLimit(_ limit: Limits) throws(WasmKitError) {
        guard let max = limit.max else { return }
        if limit.min > max {
            throw WasmKitError(message: .sizeMinimumMustNotExceedMaximum)
        }
    }
}

extension WasmTypes.Reference {
    /// Checks if the reference type matches the expected type.
    func checkType(_ type: WasmTypes.ReferenceType) throws(WasmKitError) {
        switch (self, type.heapType, type.isNullable) {
        case (.function(_?), .funcRef, _): return
        case (.function(nil), .funcRef, true): return
        case (.extern(_?), .externRef, _): return
        case (.extern(nil), .externRef, true): return
        default:
            throw WasmKitError(message: .expectTypeButGot(expected: "\(type)", got: "\(self)"))
        }
    }
}

extension Value {
    /// Checks if the value type matches the expected type.
    func checkType(_ type: WasmTypes.ValueType) throws(WasmKitError) {
        switch (self, type) {
        case (.i32, .i32): return
        case (.i64, .i64): return
        case (.f32, .f32): return
        case (.f64, .f64): return
        case (.v128, .v128): return
        case (.ref(let ref), .ref(let refType)):
            try ref.checkType(refType)
        default:
            throw WasmKitError(message: .expectTypeButGot(expected: "\(type)", got: "\(self)"))
        }
    }
}
