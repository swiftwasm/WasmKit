// Canonical ABI lifting/lowering implementation. See `CanonicalABI.md` for more details:
// https://github.com/WebAssembly/component-model/blob/a565206aea8190e13d3a297e138261455a8b80ad/design/mvp/CanonicalABI.md

#if ComponentModel
    import ComponentModel

    extension ComponentValue {
        /// Lift core wasm values to a component value.
        /// Handles both flat primitives and heap-based types (strings).
        static func lift(
            from iterator: inout some IteratorProtocol<Value>,
            to type: ComponentDefValType,
            resolveType: (ComponentTypeIndex) throws -> ComponentDefValType,
            options: CanonOptions,
            store: Store
        ) throws -> ComponentValue {
            // First, resolve indexed types to their actual type
            let resolvedType: ComponentDefValType
            if case .inlined(.index(let typeIdx)) = type {
                resolvedType = try resolveType(typeIdx)
            } else {
                resolvedType = type
            }

            switch resolvedType {
            // Flat primitives
            case .inlined(.primitive(.bool)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for bool")
                }
                return .bool(v != 0)
            case .inlined(.primitive(.u8)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for u8")
                }
                return .u8(UInt8(truncatingIfNeeded: v))
            case .inlined(.primitive(.u16)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for u16")
                }
                return .u16(UInt16(truncatingIfNeeded: v))
            case .inlined(.primitive(.u32)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for u32")
                }
                return .u32(v)
            case .inlined(.primitive(.u64)):
                guard case .i64(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i64 for u64")
                }
                return .u64(v)
            case .inlined(.primitive(.s8)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for s8")
                }
                return .s8(Int8(truncatingIfNeeded: Int32(bitPattern: v)))
            case .inlined(.primitive(.s16)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for s16")
                }
                return .s16(Int16(truncatingIfNeeded: Int32(bitPattern: v)))
            case .inlined(.primitive(.s32)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for s32")
                }
                return .s32(Int32(bitPattern: v))
            case .inlined(.primitive(.s64)):
                guard case .i64(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i64 for s64")
                }
                return .s64(Int64(bitPattern: v))
            case .inlined(.primitive(.float32)):
                guard case .f32(let bits) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected f32 for float32")
                }
                return .float32(Float(bitPattern: bits))
            case .inlined(.primitive(.float64)):
                guard case .f64(let bits) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected f64 for float64")
                }
                return .float64(Double(bitPattern: bits))
            case .inlined(.primitive(.char)):
                guard case .i32(let v) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 for char")
                }
                guard let scalar = Unicode.Scalar(v) else {
                    throw CanonicalABIError(description: "invalid `char` bit pattern: \(v)")
                }
                return .char(scalar)

            // String - requires memory
            case .inlined(.primitive(.string)):
                guard case .i32(let pointer) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 pointer for string")
                }
                guard case .i32(let length) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 length for string")
                }
                return try liftString(pointer: pointer, length: length, options: options, store: store)

            // Enum - lift discriminant to case name
            case .enum(let caseNames):
                guard case .i32(let discriminant) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 discriminant for enum")
                }
                let caseIndex = Int(discriminant)
                guard caseIndex >= 0 && caseIndex < caseNames.count else {
                    throw CanonicalABIError(description: "Enum discriminant \(discriminant) out of range (0..<\(caseNames.count))")
                }
                return .enum(caseNames[caseIndex])

            // Flags - lift bit-packed integer(s) to flag set
            case .flags(let flagNames):
                let numberOfI32 = numberOfFlagsInt32(flagsCount: flagNames.count)
                var flagSet: Set<String> = []

                // Read i32 chunks and unpack bits
                for chunkIndex in 0..<numberOfI32 {
                    guard case .i32(let chunk) = iterator.next() else {
                        throw CanonicalABIError(description: "Expected i32 chunk for flags")
                    }
                    let baseIndex = chunkIndex * 32
                    for bitIndex in 0..<32 {
                        let flagIndex = baseIndex + bitIndex
                        if flagIndex < flagNames.count && (chunk & (1 << bitIndex)) != 0 {
                            flagSet.insert(flagNames[flagIndex])
                        }
                    }
                }
                return .flags(flagSet)

            // Tuple - lift each element recursively
            case .tuple(let elementValTypes):
                var elements: [ComponentValue] = []
                for valType in elementValTypes {
                    let elementType = try valType.resolve(resolveType)
                    let element = try Self.lift(from: &iterator, to: elementType, resolveType: resolveType, options: options, store: store)
                    elements.append(element)
                }
                return .tuple(elements)

            // Option - lift discriminant and optional payload
            case .option(let someValType):
                guard case .i32(let discriminant) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 discriminant for option")
                }
                let someType = try someValType.resolve(resolveType)
                if discriminant == 0 {
                    // none: consume payload space (zeros)
                    let flatCount = someType.flattenedCount
                    for _ in 0..<flatCount {
                        _ = iterator.next()
                    }
                    return .option(nil)
                } else {
                    // some: lift the value
                    let value = try Self.lift(from: &iterator, to: someType, resolveType: resolveType, options: options, store: store)
                    return .option(value)
                }

            // Record - lift each field recursively
            case .record(let fieldDefs):
                var fields: [(name: String, value: ComponentValue)] = []
                for fieldDef in fieldDefs {
                    let fieldType = try fieldDef.type.resolve(resolveType)
                    let value = try Self.lift(from: &iterator, to: fieldType, resolveType: resolveType, options: options, store: store)
                    fields.append((fieldDef.name, value))
                }
                return .record(fields)

            // Result - lift discriminant and payload
            case .result(let okValType, let errorValType):
                guard case .i32(let discriminant) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 discriminant for result")
                }

                let okType = try okValType.map { try $0.resolve(resolveType) }
                let errorType = try errorValType.map { try $0.resolve(resolveType) }

                // Calculate max payload size
                let okFlatCount = okType.map { $0.flattenedCount } ?? 0
                let errorFlatCount = errorType.map { $0.flattenedCount } ?? 0
                let maxPayloadCount = max(okFlatCount, errorFlatCount)

                if discriminant == 0 {
                    // ok case
                    if let okType = okType {
                        let value = try Self.lift(from: &iterator, to: okType, resolveType: resolveType, options: options, store: store)
                        // Consume padding
                        let consumed = okType.flattenedCount
                        for _ in consumed..<maxPayloadCount {
                            _ = iterator.next()
                        }
                        return .result(ok: value, error: nil)
                    } else {
                        // No ok type, consume padding
                        for _ in 0..<maxPayloadCount {
                            _ = iterator.next()
                        }
                        return .result(ok: nil, error: nil)
                    }
                } else {
                    // error case
                    if let errorType = errorType {
                        let value = try Self.lift(from: &iterator, to: errorType, resolveType: resolveType, options: options, store: store)
                        // Consume padding
                        let consumed = errorType.flattenedCount
                        for _ in consumed..<maxPayloadCount {
                            _ = iterator.next()
                        }
                        return .result(ok: nil, error: value)
                    } else {
                        // No error type, consume padding
                        for _ in 0..<maxPayloadCount {
                            _ = iterator.next()
                        }
                        return .result(ok: nil, error: nil)
                    }
                }

            // Variant - lift discriminant and payload
            case .variant(let cases):
                guard case .i32(let discriminant) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 discriminant for variant")
                }

                let caseIndex = Int(discriminant)
                guard caseIndex >= 0 && caseIndex < cases.count else {
                    throw CanonicalABIError(description: "Variant discriminant \(discriminant) out of range (0..<\(cases.count))")
                }

                // Calculate max payload size
                let maxPayloadCount =
                    try cases.map { variantCase -> Int in
                        if let valType = variantCase.type {
                            return try valType.resolve(resolveType).flattenedCount
                        }
                        return 0
                    }.max() ?? 0

                let variantCase = cases[caseIndex]
                if let valType = variantCase.type {
                    // Case with payload
                    let caseType = try valType.resolve(resolveType)
                    let value = try Self.lift(from: &iterator, to: caseType, resolveType: resolveType, options: options, store: store)
                    // Consume padding
                    let consumed = caseType.flattenedCount
                    for _ in consumed..<maxPayloadCount {
                        _ = iterator.next()
                    }
                    return .variant(caseName: variantCase.name, payload: value)
                } else {
                    // Case without payload - consume padding
                    for _ in 0..<maxPayloadCount {
                        _ = iterator.next()
                    }
                    return .variant(caseName: variantCase.name, payload: nil)
                }

            // List - lift pointer and length, then load elements from memory
            case .list(let elementValType):
                guard case .i32(let pointer) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 pointer for list")
                }
                guard case .i32(let length) = iterator.next() else {
                    throw CanonicalABIError(description: "Expected i32 length for list")
                }
                return try liftList(
                    pointer: pointer,
                    length: length,
                    elementValType: elementValType,
                    resolveType: resolveType,
                    options: options,
                    store: store
                )

            default:
                throw CanonicalABIError(description: "Cannot lift to \(type)")
            }
        }

        /// Lower a component value to core wasm values.
        /// Handles both flat primitives and heap-based types (strings).
        func lower(
            to type: ComponentDefValType,
            resolveType: (ComponentTypeIndex) throws -> ComponentDefValType,
            options: CanonOptions,
            store: Store
        ) throws -> [Value] {
            // First, resolve indexed types to their actual type
            let resolvedType: ComponentDefValType
            if case .inlined(.index(let typeIdx)) = type {
                resolvedType = try resolveType(typeIdx)
            } else {
                resolvedType = type
            }

            switch (self, resolvedType) {
            // Flat primitives - no memory needed
            case (.bool(let b), .inlined(.primitive(.bool))):
                return [.i32(b ? 1 : 0)]
            case (.u8(let v), .inlined(.primitive(.u8))):
                return [.i32(UInt32(v))]
            case (.u16(let v), .inlined(.primitive(.u16))):
                return [.i32(UInt32(v))]
            case (.u32(let v), .inlined(.primitive(.u32))):
                return [.i32(v)]
            case (.u64(let v), .inlined(.primitive(.u64))):
                return [.i64(v)]
            case (.s8(let v), .inlined(.primitive(.s8))):
                return [.i32(UInt32(bitPattern: Int32(v)))]
            case (.s16(let v), .inlined(.primitive(.s16))):
                return [.i32(UInt32(bitPattern: Int32(v)))]
            case (.s32(let v), .inlined(.primitive(.s32))):
                return [.i32(UInt32(bitPattern: v))]
            case (.s64(let v), .inlined(.primitive(.s64))):
                return [.i64(UInt64(bitPattern: v))]
            case (.float32(let v), .inlined(.primitive(.float32))):
                return [.f32(v.bitPattern)]
            case (.float64(let v), .inlined(.primitive(.float64))):
                return [.f64(v.bitPattern)]
            case (.char(let scalar), .inlined(.primitive(.char))):
                return [.i32(scalar.value)]

            // String - requires memory and realloc
            case (.string(let s), .inlined(.primitive(.string))):
                return try lowerString(s, options: options, store: store)

            // Enum - lower to discriminant value (u8, u16, or u32 based on case count)
            case (.enum(let caseName), .enum(let caseNames)):
                guard let caseIndex = caseNames.firstIndex(of: caseName) else {
                    throw CanonicalABIError(description: "Unknown enum case '\(caseName)' in enum with cases: \(caseNames)")
                }
                // Enum discriminants use the smallest integer type that fits
                // (u8 for ≤256 cases, u16 for ≤65536 cases, u32 otherwise)
                return [.i32(UInt32(caseIndex))]

            // Flags - lower to bit-packed integer(s)
            case (.flags(let flagSet), .flags(let flagNames)):
                let numberOfI32 = numberOfFlagsInt32(flagsCount: flagNames.count)
                var results: [Value] = []

                // Pack flags into i32 chunks
                for chunkIndex in 0..<numberOfI32 {
                    var chunk: UInt32 = 0
                    let baseIndex = chunkIndex * 32
                    for bitIndex in 0..<32 {
                        let flagIndex = baseIndex + bitIndex
                        if flagIndex < flagNames.count && flagSet.contains(flagNames[flagIndex]) {
                            chunk |= (1 << bitIndex)
                        }
                    }
                    results.append(.i32(chunk))
                }
                return results

            // Tuple - lower each element recursively
            case (.tuple(let elements), .tuple(let elementValTypes)):
                guard elements.count == elementValTypes.count else {
                    throw CanonicalABIError(description: "Tuple element count mismatch: expected \(elementValTypes.count), got \(elements.count)")
                }
                var results: [Value] = []
                for (element, valType) in zip(elements, elementValTypes) {
                    let elementType = try valType.resolve(resolveType)
                    let lowered = try element.lower(to: elementType, resolveType: resolveType, options: options, store: store)
                    results.append(contentsOf: lowered)
                }
                return results

            // Option - discriminant (0=none, 1=some) + optional payload
            case (.option(let maybeValue), .option(let someValType)):
                let someType = try someValType.resolve(resolveType)
                if let value = maybeValue {
                    // some: discriminant=1, followed by flattened value
                    var results: [Value] = [.i32(1)]
                    let lowered = try value.lower(to: someType, resolveType: resolveType, options: options, store: store)
                    results.append(contentsOf: lowered)
                    return results
                } else {
                    // none: discriminant=0, followed by zeros for payload space
                    let flatCount = someType.flattenedCount
                    var results: [Value] = [.i32(0)]
                    results.append(contentsOf: Array(repeating: .i32(0), count: flatCount))
                    return results
                }

            // Record - lower each field recursively
            case (.record(let fields), .record(let fieldDefs)):
                var results: [Value] = []
                for fieldDef in fieldDefs {
                    guard let fieldValue = fields.first(where: { $0.name == fieldDef.name })?.value else {
                        throw CanonicalABIError(description: "Missing record field: \(fieldDef.name)")
                    }
                    let fieldType = try fieldDef.type.resolve(resolveType)
                    let lowered = try fieldValue.lower(to: fieldType, resolveType: resolveType, options: options, store: store)
                    results.append(contentsOf: lowered)
                }
                return results

            // Result - discriminant (0=ok, 1=err) + payload with variant flattening
            case (.result(let ok, let error), .result(let okValType, let errorValType)):
                let okType = try okValType.map { try $0.resolve(resolveType) }
                let errorType = try errorValType.map { try $0.resolve(resolveType) }

                // Calculate max payload size for variant union
                let okFlatCount = okType.map { $0.flattenedCount } ?? 0
                let errorFlatCount = errorType.map { $0.flattenedCount } ?? 0
                let maxPayloadCount = max(okFlatCount, errorFlatCount)

                if let okValue = ok {
                    // ok case: discriminant=0
                    var lowered: [Value] = [.i32(0)]
                    if let okType = okType {
                        let okLowered = try okValue.lower(to: okType, resolveType: resolveType, options: options, store: store)
                        lowered.append(contentsOf: okLowered)
                        // Pad to max payload size
                        lowered.append(contentsOf: Array(repeating: .i32(0), count: maxPayloadCount - okLowered.count))
                    } else {
                        // No ok type, just zeros
                        lowered.append(contentsOf: Array(repeating: .i32(0), count: maxPayloadCount))
                    }
                    return lowered
                } else if let errorValue = error {
                    // error case: discriminant=1
                    var lowered: [Value] = [.i32(1)]
                    if let errorType = errorType {
                        let errorLowered = try errorValue.lower(to: errorType, resolveType: resolveType, options: options, store: store)
                        lowered.append(contentsOf: errorLowered)
                        // Pad to max payload size
                        lowered.append(contentsOf: Array(repeating: .i32(0), count: maxPayloadCount - errorLowered.count))
                    } else {
                        // No error type, just zeros
                        lowered.append(contentsOf: Array(repeating: .i32(0), count: maxPayloadCount))
                    }
                    return lowered
                } else {
                    throw CanonicalABIError(description: "Result must have either ok or error value")
                }

            // Variant - discriminant + payload with max-size union flattening
            case (.variant(let caseName, let payload), .variant(let cases)):
                guard let caseIndex = cases.firstIndex(where: { $0.name == caseName }) else {
                    throw CanonicalABIError(description: "Unknown variant case: \(caseName)")
                }

                // Calculate max payload size across all cases
                let maxPayloadCount =
                    try cases.map { variantCase -> Int in
                        if let valType = variantCase.type {
                            return try valType.resolve(resolveType).flattenedCount
                        }
                        return 0
                    }.max() ?? 0

                var lowered: [Value] = [.i32(UInt32(caseIndex))]

                if let valType = cases[caseIndex].type, let payloadValue = payload {
                    // Case with payload
                    let caseType = try valType.resolve(resolveType)
                    let caseLowered = try payloadValue.lower(to: caseType, resolveType: resolveType, options: options, store: store)
                    lowered.append(contentsOf: caseLowered)
                    // Pad to max payload size
                    lowered.append(contentsOf: Array(repeating: .i32(0), count: maxPayloadCount - caseLowered.count))
                } else {
                    // Case without payload - just zeros
                    lowered.append(contentsOf: Array(repeating: .i32(0), count: maxPayloadCount))
                }

                return lowered

            // List - allocate memory and write elements (requires memory + realloc)
            case (.list(let elements), .list(let elementValType)):
                return try lowerList(elements, elementValType: elementValType, resolveType: resolveType, options: options, store: store)

            default:
                throw CanonicalABIError(
                    description: "Cannot lower \(self) to \(type)"
                )
            }
        }
    }

    /// Lower a string to core wasm values (pointer, length).
    /// Allocates memory using realloc and writes encoded bytes.
    private func lowerString(
        _ string: String,
        options: CanonOptions,
        store: Store
    ) throws -> [Value] {
        guard let memory = options.memory else {
            throw CanonicalABIError(description: "String lowering requires memory option")
        }
        guard let realloc = options.realloc else {
            throw CanonicalABIError(description: "String lowering requires realloc option")
        }

        let memoryInstance = Memory(handle: memory, allocator: store.allocator)

        switch options.stringEncoding {
        case .utf8:
            // UTF-8: alignment=1, tagged_code_units = byte count
            let utf8Bytes = Array(string.utf8)
            let byteCount = UInt32(utf8Bytes.count)

            // Allocate memory: realloc(old_ptr=0, old_size=0, align=1, new_size)
            let allocResult = try realloc.invoke(
                [.i32(0), .i32(0), .i32(1), .i32(byteCount)],
                store: store
            )
            guard case .i32(let pointer) = allocResult.first else {
                throw CanonicalABIError(description: "realloc did not return i32 pointer")
            }

            // Write UTF-8 bytes to memory
            memoryInstance.withUnsafeMutableBufferPointer(offset: UInt(pointer), count: Int(byteCount)) { buffer in
                for (index, byte) in utf8Bytes.enumerated() {
                    buffer[index] = byte
                }
            }

            return [.i32(pointer), .i32(byteCount)]

        case .utf16:
            // UTF-16: alignment=2, tagged_code_units = code unit count (not byte count)
            let codeUnitCount = UInt32(string.utf16.count)
            let byteCount = codeUnitCount * 2

            // Allocate memory: realloc(old_ptr=0, old_size=0, align=2, new_size)
            let allocResult = try realloc.invoke(
                [.i32(0), .i32(0), .i32(2), .i32(byteCount)],
                store: store
            )
            guard case .i32(let pointer) = allocResult.first else {
                throw CanonicalABIError(description: "realloc did not return i32 pointer")
            }

            memoryInstance.lowerUTF16LE(pointer, byteCount, string)

            return [.i32(pointer), .i32(codeUnitCount)]

        case .latin1UTF16:
            // Latin1+UTF-16: Try Latin-1 first, fall back to UTF-16 if needed
            // Check if string can be represented in Latin-1 (all UTF-16 code units < 256)
            let canUseLatin1 = string.utf16.allSatisfy { $0 < 256 }

            if canUseLatin1 {
                // Use Latin-1 encoding: alignment=2, tagged_code_units = byte count (no UTF16_TAG)
                let latin1Bytes = string.utf16.map { UInt8($0) }
                let byteCount = UInt32(latin1Bytes.count)

                // Allocate memory: realloc(old_ptr=0, old_size=0, align=2, new_size)
                let allocResult = try realloc.invoke(
                    [.i32(0), .i32(0), .i32(2), .i32(byteCount)],
                    store: store
                )
                guard case .i32(let pointer) = allocResult.first else {
                    throw CanonicalABIError(description: "realloc did not return i32 pointer")
                }

                // Write Latin-1 bytes to memory
                memoryInstance.withUnsafeMutableBufferPointer(offset: UInt(pointer), count: Int(byteCount)) { buffer in
                    for (index, byte) in latin1Bytes.enumerated() {
                        buffer[index] = byte
                    }
                }

                // Return pointer and code units (no UTF16_TAG)
                return [.i32(pointer), .i32(byteCount)]
            } else {
                // Use UTF-16 encoding: alignment=2, tagged_code_units = code unit count | UTF16_TAG
                let codeUnitCount = UInt32(string.utf16.count)
                let byteCount = codeUnitCount * 2

                // Allocate memory: realloc(old_ptr=0, old_size=0, align=2, new_size)
                let allocResult = try realloc.invoke(
                    [.i32(0), .i32(0), .i32(2), .i32(byteCount)],
                    store: store
                )
                guard case .i32(let pointer) = allocResult.first else {
                    throw CanonicalABIError(description: "realloc did not return i32 pointer")
                }

                memoryInstance.lowerUTF16LE(pointer, byteCount, string)

                // Return pointer and code units with UTF16_TAG
                let UTF16_TAG: UInt32 = 1 << 31
                return [.i32(pointer), .i32(codeUnitCount | UTF16_TAG)]
            }
        }
    }

    /// Lower a list to core wasm values (pointer, length).
    /// Allocates memory using realloc and writes elements.
    private func lowerList(
        _ elements: [ComponentValue],
        elementValType: ComponentValType,
        resolveType: (ComponentTypeIndex) throws -> ComponentDefValType,
        options: CanonOptions,
        store: Store
    ) throws -> [Value] {
        guard let memory = options.memory else {
            throw CanonicalABIError(description: "List lowering requires memory option")
        }
        guard let realloc = options.realloc else {
            throw CanonicalABIError(description: "List lowering requires realloc option")
        }

        let elementType = try elementValType.resolve(resolveType)
        let elementCount = UInt32(elements.count)

        // Calculate element size in bytes based on type
        let elementSize = try sizeOf(elementType, resolveType: resolveType)
        let alignment = try alignmentOf(elementType, resolveType: resolveType)
        let totalBytes = elementSize * Int(elementCount)

        // Allocate memory: realloc(old_ptr=0, old_size=0, align, new_size)
        let allocResult = try realloc.invoke(
            [.i32(0), .i32(0), .i32(UInt32(alignment)), .i32(UInt32(totalBytes))],
            store: store
        )
        guard case .i32(let pointer) = allocResult.first else {
            throw CanonicalABIError(description: "realloc did not return i32 pointer")
        }

        // Write each element to memory
        let memoryInstance = Memory(handle: memory, allocator: store.allocator)
        var currentOffset = Int(pointer)

        for element in elements {
            try storeValue(
                element,
                type: elementType,
                at: currentOffset,
                memory: memoryInstance,
                resolveType: resolveType,
                options: options,
                store: store
            )
            currentOffset += elementSize
        }

        return [.i32(pointer), .i32(elementCount)]
    }

    /// Calculate the byte size of a component value type.
    private func sizeOf(
        _ type: ComponentDefValType,
        resolveType: (ComponentTypeIndex) throws -> ComponentDefValType
    ) throws -> Int {
        switch type {
        case .inlined(.primitive(let prim)):
            switch prim {
            case .bool, .s8, .u8: return 1
            case .s16, .u16: return 2
            case .s32, .u32, .float32, .char: return 4
            case .s64, .u64, .float64: return 8
            case .string: return 8  // pointer + length
            case .errorContext:
                throw CanonicalABIError(description: "sizeOf for \(type) not yet implemented")
            }
        case .list: return 8  // pointer + length
        case .tuple(let elementValTypes):
            return try elementValTypes.reduce(0) { sum, valType in
                try sum + sizeOf(valType.resolve(resolveType), resolveType: resolveType)
            }
        case .record(let fields):
            return try fields.reduce(0) { sum, field in
                try sum + sizeOf(field.type.resolve(resolveType), resolveType: resolveType)
            }
        case .option(let someValType):
            return try 4 + sizeOf(someValType.resolve(resolveType), resolveType: resolveType)  // discriminant + payload
        case .result(let okValType, let errorValType):
            let okSize = try okValType.map { try sizeOf($0.resolve(resolveType), resolveType: resolveType) } ?? 0
            let errSize = try errorValType.map { try sizeOf($0.resolve(resolveType), resolveType: resolveType) } ?? 0
            return 4 + max(okSize, errSize)  // discriminant + max payload
        case .variant(let cases):
            let maxPayloadSize =
                try cases.map { variantCase -> Int in
                    if let valType = variantCase.type {
                        return try sizeOf(valType.resolve(resolveType), resolveType: resolveType)
                    }
                    return 0
                }.max() ?? 0
            // Discriminant size varies based on number of cases
            let discriminantSize: Int
            let numCases = cases.count
            if numCases <= 256 {
                discriminantSize = 1  // u8
            } else if numCases <= 65536 {
                discriminantSize = 2  // u16
            } else {
                discriminantSize = 4  // u32
            }
            return discriminantSize + maxPayloadSize  // discriminant + max payload
        case .enum: return 4  // u32 discriminant
        case .flags(let flagNames):
            return numberOfFlagsInt32(flagsCount: flagNames.count) * 4
        case .future, .stream, .resource, .inlined(.index):
            throw CanonicalABIError(description: "sizeOf for \(type) not yet implemented")
        }
    }

    /// Calculate the alignment requirement of a component value type.
    private func alignmentOf(
        _ type: ComponentDefValType,
        resolveType: (ComponentTypeIndex) throws -> ComponentDefValType
    ) throws -> Int {
        switch type {
        case .inlined(.primitive(let prim)):
            switch prim {
            case .bool, .s8, .u8: return 1
            case .s16, .u16: return 2
            case .s32, .u32, .float32, .char: return 4
            case .s64, .u64, .float64: return 8
            case .string: return 4  // pointer/length use i32 alignment
            case .errorContext:
                throw CanonicalABIError(description: "alignmentOf for \(type) not yet implemented")
            }
        case .enum: return 4
        case .list: return 4  // pointer/length use i32 alignment
        case .tuple(let elementValTypes):
            return try elementValTypes.map { try alignmentOf($0.resolve(resolveType), resolveType: resolveType) }.max() ?? 1
        case .record(let fields):
            return try fields.map { try alignmentOf($0.type.resolve(resolveType), resolveType: resolveType) }.max() ?? 1
        case .option(let someValType):
            return max(4, try alignmentOf(someValType.resolve(resolveType), resolveType: resolveType))
        case .result(let okValType, let errorValType):
            let okAlign = try okValType.map { try alignmentOf($0.resolve(resolveType), resolveType: resolveType) } ?? 1
            let errAlign = try errorValType.map { try alignmentOf($0.resolve(resolveType), resolveType: resolveType) } ?? 1
            return max(4, max(okAlign, errAlign))
        case .variant(let cases):
            let maxPayloadAlign =
                try cases.compactMap { variantCase -> Int? in
                    guard let valType = variantCase.type else { return nil }
                    return try alignmentOf(valType.resolve(resolveType), resolveType: resolveType)
                }.max() ?? 1
            return max(4, maxPayloadAlign)
        case .flags: return 4  // i32 chunks
        case .future, .stream, .resource, .inlined(.index):
            throw CanonicalABIError(description: "alignmentOf for \(type) not yet implemented")
        }
    }

    /// Store a component value to memory at a given offset.
    private func storeValue(
        _ value: ComponentValue,
        type: ComponentDefValType,
        at offset: Int,
        memory: Memory,
        resolveType: (ComponentTypeIndex) throws -> ComponentDefValType,
        options: CanonOptions,
        store: Store
    ) throws {
        // First, resolve indexed types to their actual type
        let resolvedType: ComponentDefValType
        if case .inlined(.index(let typeIdx)) = type {
            resolvedType = try resolveType(typeIdx)
        } else {
            resolvedType = type
        }

        switch (value, resolvedType) {
        case (.bool(let b), .inlined(.primitive(.bool))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 1) { buffer in
                buffer.storeBytes(of: UInt8(b ? 1 : 0), as: UInt8.self)
            }
        case (.u8(let v), .inlined(.primitive(.u8))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 1) { buffer in
                buffer.storeBytes(of: v, as: UInt8.self)
            }
        case (.u16(let v), .inlined(.primitive(.u16))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 2) { buffer in
                buffer.storeBytes(of: v, as: UInt16.self)
            }
        case (.u32(let v), .inlined(.primitive(.u32))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.storeBytes(of: v, as: UInt32.self)
            }
        case (.u64(let v), .inlined(.primitive(.u64))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 8) { buffer in
                buffer.storeBytes(of: v, as: UInt64.self)
            }
        case (.s8(let v), .inlined(.primitive(.s8))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 1) { buffer in
                buffer.storeBytes(of: v, as: Int8.self)
            }
        case (.s16(let v), .inlined(.primitive(.s16))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 2) { buffer in
                buffer.storeBytes(of: v, as: Int16.self)
            }
        case (.s32(let v), .inlined(.primitive(.s32))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.storeBytes(of: v, as: Int32.self)
            }
        case (.s64(let v), .inlined(.primitive(.s64))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 8) { buffer in
                buffer.storeBytes(of: v, as: Int64.self)
            }
        case (.float32(let v), .inlined(.primitive(.float32))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.storeBytes(of: v.bitPattern, as: UInt32.self)
            }
        case (.float64(let v), .inlined(.primitive(.float64))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 8) { buffer in
                buffer.storeBytes(of: v.bitPattern, as: UInt64.self)
            }
        case (.char(let scalar), .inlined(.primitive(.char))):
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.storeBytes(of: scalar.value, as: UInt32.self)
            }
        case (.string(let s), .inlined(.primitive(.string))):
            // For strings in lists, we need to lower the string (allocate + write) and store the pointer/length
            let lowered = try lowerString(s, options: options, store: store)
            guard case .i32(let ptr) = lowered[0], case .i32(let len) = lowered[1] else {
                throw CanonicalABIError(description: "String lowering did not return i32 values")
            }
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: 8) { buffer in
                buffer.storeBytes(of: ptr, toByteOffset: 0, as: UInt32.self)
                buffer.storeBytes(of: len, toByteOffset: 4, as: UInt32.self)
            }

        case (.variant(let caseName, let payload), .variant(let cases)):
            // Store variant as discriminant + payload
            guard let caseIndex = cases.firstIndex(where: { $0.name == caseName }) else {
                throw CanonicalABIError(description: "Unknown variant case: \(caseName)")
            }

            // Determine discriminant size based on number of cases
            let discriminantSize: Int
            let numCases = cases.count
            if numCases <= 256 {
                discriminantSize = 1  // u8
            } else if numCases <= 65536 {
                discriminantSize = 2  // u16
            } else {
                discriminantSize = 4  // u32
            }

            // Write discriminant
            memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: discriminantSize) { buffer in
                switch discriminantSize {
                case 1:
                    buffer.storeBytes(of: UInt8(caseIndex), as: UInt8.self)
                case 2:
                    buffer.storeBytes(of: UInt16(caseIndex), as: UInt16.self)
                case 4:
                    buffer.storeBytes(of: UInt32(caseIndex), as: UInt32.self)
                default:
                    break
                }
            }

            // Write payload if present
            if let valType = cases[caseIndex].type, let payloadValue = payload {
                let caseType = try valType.resolve(resolveType)
                let payloadOffset = offset + max(4, try alignmentOf(caseType, resolveType: resolveType))
                try storeValue(
                    payloadValue,
                    type: caseType,
                    at: payloadOffset,
                    memory: memory,
                    resolveType: resolveType,
                    options: options,
                    store: store
                )
            }

        default:
            throw CanonicalABIError(description: "Storing \(resolvedType) to memory not yet implemented")
        }
    }

    extension Memory {
        fileprivate func lowerUTF16LE(_ pointer: UInt32, _ byteCount: UInt32, _ string: String) {
            // Write UTF-16LE code units to memory
            self.withUnsafeMutableBufferPointer(offset: UInt(pointer), count: Int(byteCount)) { buffer in
                for (index, codeUnit) in string.utf16.enumerated() {
                    let offset = index * 2
                    // Little-endian encoding
                    buffer[offset] = UInt8(codeUnit & 0xFF)
                    buffer[offset + 1] = UInt8((codeUnit >> 8) & 0xFF)
                }
            }
        }

        fileprivate func liftUTF16LE(pointer: UInt32, byteCount: Int, codeUnitCount: Int) throws -> String {
            // Read UTF-16LE code units from memory
            var codeUnits: [UInt16] = []
            codeUnits.reserveCapacity(codeUnitCount)

            self.withUnsafeBufferPointer(offset: UInt(pointer), count: byteCount) { buffer in
                for i in 0..<codeUnitCount {
                    let offset = i * 2
                    let low = UInt16(buffer[offset])
                    let high = UInt16(buffer[offset + 1])
                    let codeUnit = low | (high << 8)  // Little-endian
                    codeUnits.append(codeUnit)
                }
            }

            return String(decoding: codeUnits, as: UTF16.self)
        }
    }

    /// Lift a string from core wasm memory.
    /// Reads encoded bytes from (pointer, tagged_code_units) and constructs a String.
    private func liftString(
        pointer: UInt32,
        length: UInt32,
        options: CanonOptions,
        store: Store
    ) throws -> ComponentValue {
        guard let memory = options.memory else {
            throw CanonicalABIError(description: "String lifting requires memory option")
        }

        let memoryInstance = Memory(handle: memory, allocator: store.allocator)
        let memorySize = memoryInstance.byteCount

        let UTF16_TAG: UInt32 = 1 << 31

        switch options.stringEncoding {
        case .utf8:
            // UTF-8: alignment=1, length = byte count
            let byteCount = Int(length)

            // Bounds check for string data
            guard Int(pointer) + byteCount <= memorySize else {
                throw CanonicalABIError(description: "string pointer/length out of bounds of memory: ptr=\(pointer), len=\(length), memorySize=\(memorySize)")
            }

            // Alignment check
            // UTF-8 has alignment 1, so no check needed

            // Read UTF-8 bytes from memory
            let string = memoryInstance.withUnsafeBufferPointer(offset: UInt(pointer), count: byteCount) { buffer in
                let bytes = Array(buffer.bindMemory(to: UInt8.self))
                return String(decoding: bytes, as: UTF8.self)
            }

            return .string(string)

        case .utf16:
            // UTF-16: alignment=2, length = code unit count
            let codeUnitCount = Int(length)
            let byteCount = codeUnitCount * 2

            // Alignment check
            guard pointer % 2 == 0 else {
                throw CanonicalABIError(description: "UTF-16 string pointer not aligned: ptr=\(pointer)")
            }

            // Bounds check for string data
            guard Int(pointer) + byteCount <= memorySize else {
                throw CanonicalABIError(description: "string pointer/length out of bounds of memory: ptr=\(pointer), codeUnits=\(codeUnitCount), memorySize=\(memorySize)")
            }

            return .string(try memoryInstance.liftUTF16LE(pointer: pointer, byteCount: byteCount, codeUnitCount: codeUnitCount))

        case .latin1UTF16:
            // Latin1+UTF-16: Check UTF16_TAG to determine encoding
            if (length & UTF16_TAG) != 0 {
                // UTF-16 encoding: tagged_code_units has UTF16_TAG set
                let codeUnitCount = Int(length ^ UTF16_TAG)
                let byteCount = codeUnitCount * 2

                // Alignment check
                guard pointer % 2 == 0 else {
                    throw CanonicalABIError(description: "UTF-16 string pointer not aligned: ptr=\(pointer)")
                }

                // Bounds check
                guard Int(pointer) + byteCount <= memorySize else {
                    throw CanonicalABIError(description: "string pointer/length out of bounds of memory: ptr=\(pointer), codeUnits=\(codeUnitCount), memorySize=\(memorySize)")
                }

                return .string(try memoryInstance.liftUTF16LE(pointer: pointer, byteCount: byteCount, codeUnitCount: codeUnitCount))
            } else {
                // Latin-1 encoding: no UTF16_TAG
                let byteCount = Int(length)

                // Alignment check (Latin-1 in latin1+utf16 has alignment 2)
                guard pointer % 2 == 0 else {
                    throw CanonicalABIError(description: "Latin-1 string pointer not aligned: ptr=\(pointer)")
                }

                // Bounds check
                guard Int(pointer) + byteCount <= memorySize else {
                    throw CanonicalABIError(description: "string pointer/length out of bounds of memory: ptr=\(pointer), len=\(length), memorySize=\(memorySize)")
                }

                // Read Latin-1 bytes and decode
                let string = memoryInstance.withUnsafeBufferPointer(offset: UInt(pointer), count: byteCount) { buffer in
                    let bytes = Array(buffer.bindMemory(to: UInt8.self))
                    // Latin-1 maps directly to Unicode scalars 0-255
                    let scalars = bytes.map { Unicode.Scalar($0) }
                    return String(String.UnicodeScalarView(scalars))
                }

                return .string(string)
            }
        }
    }

    /// Lift a list from core wasm memory.
    /// Reads elements from (pointer, length) and constructs a list.
    private func liftList(
        pointer: UInt32,
        length: UInt32,
        elementValType: ComponentValType,
        resolveType: (ComponentTypeIndex) throws -> ComponentDefValType,
        options: CanonOptions,
        store: Store
    ) throws -> ComponentValue {
        guard let memory = options.memory else {
            throw CanonicalABIError(description: "List lifting requires memory option")
        }

        let elementType = try elementValType.resolve(resolveType)
        let elementSize = try sizeOf(elementType, resolveType: resolveType)
        let memoryInstance = Memory(handle: memory, allocator: store.allocator)
        let memorySize = memoryInstance.byteCount

        // Bounds check for list data
        let totalBytes = Int(length) * elementSize
        guard Int(pointer) + totalBytes <= memorySize else {
            throw CanonicalABIError(description: "list pointer/length out of bounds of memory: ptr=\(pointer), len=\(length), elementSize=\(elementSize), memorySize=\(memorySize)")
        }

        // Load each element from memory
        var elements: [ComponentValue] = []
        var currentOffset = Int(pointer)

        for _ in 0..<length {
            let element = try loadValue(
                type: elementType,
                at: currentOffset,
                memory: memoryInstance,
                resolveType: resolveType,
                options: options,
                store: store
            )
            elements.append(element)
            currentOffset += elementSize
        }

        return .list(elements)
    }

    /// Load a component value from memory at a given offset.
    /// Used for loading list elements from memory.
    private func loadValue(
        type: ComponentDefValType,
        at offset: Int,
        memory: Memory,
        resolveType: (ComponentTypeIndex) throws -> ComponentDefValType,
        options: CanonOptions,
        store: Store
    ) throws -> ComponentValue {
        let memorySize = memory.byteCount

        // Helper to check bounds before reading
        func checkBounds(count: Int) throws {
            guard offset + count <= memorySize else {
                throw CanonicalABIError(description: "Memory access out of bounds: offset=\(offset), count=\(count), memorySize=\(memorySize)")
            }
        }

        switch type {
        // Primitives
        case .inlined(.primitive(.bool)):
            try checkBounds(count: 1)
            let v: UInt8 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 1) { buffer in
                buffer.load(as: UInt8.self)
            }
            return .bool(v != 0)
        case .inlined(.primitive(.u8)):
            try checkBounds(count: 1)
            let v: UInt8 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 1) { buffer in
                buffer.load(as: UInt8.self)
            }
            return .u8(v)
        case .inlined(.primitive(.u16)):
            try checkBounds(count: 2)
            let v: UInt16 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 2) { buffer in
                buffer.load(as: UInt16.self)
            }
            return .u16(v)
        case .inlined(.primitive(.u32)):
            try checkBounds(count: 4)
            let v: UInt32 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.load(as: UInt32.self)
            }
            return .u32(v)
        case .inlined(.primitive(.u64)):
            try checkBounds(count: 8)
            let v: UInt64 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                buffer.load(as: UInt64.self)
            }
            return .u64(v)
        case .inlined(.primitive(.s8)):
            try checkBounds(count: 1)
            let v: Int8 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 1) { buffer in
                buffer.load(as: Int8.self)
            }
            return .s8(v)
        case .inlined(.primitive(.s16)):
            try checkBounds(count: 2)
            let v: Int16 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 2) { buffer in
                buffer.load(as: Int16.self)
            }
            return .s16(v)
        case .inlined(.primitive(.s32)):
            try checkBounds(count: 4)
            let v: Int32 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.load(as: Int32.self)
            }
            return .s32(v)
        case .inlined(.primitive(.s64)):
            try checkBounds(count: 8)
            let v: Int64 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                buffer.load(as: Int64.self)
            }
            return .s64(v)
        case .inlined(.primitive(.float32)):
            try checkBounds(count: 4)
            let bits: UInt32 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.load(as: UInt32.self)
            }
            return .float32(Float(bitPattern: bits))
        case .inlined(.primitive(.float64)):
            try checkBounds(count: 8)
            let bits: UInt64 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                buffer.load(as: UInt64.self)
            }
            return .float64(Double(bitPattern: bits))
        case .inlined(.primitive(.char)):
            try checkBounds(count: 4)
            let v: UInt32 = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                buffer.load(as: UInt32.self)
            }
            guard let scalar = Unicode.Scalar(v) else {
                throw CanonicalABIError(description: "invalid `char` bit pattern: \(v)")
            }
            return .char(scalar)
        case .inlined(.primitive(.string)):
            // String is stored as (pointer, length) pair
            try checkBounds(count: 8)
            let (ptr, len): (UInt32, UInt32) = memory.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                let ptr = buffer.load(fromByteOffset: 0, as: UInt32.self)
                let len = buffer.load(fromByteOffset: 4, as: UInt32.self)
                return (ptr, len)
            }
            return try liftString(pointer: ptr, length: len, options: options, store: store)
        default:
            throw CanonicalABIError(description: "Loading \(type) from memory not yet implemented")
        }
    }

    extension ComponentDefValType {
        /// Lift a component value from memory at a given offset.
        /// Used for indirect results when flattened count > MAX_FLAT_RESULTS.
        func liftValueFromMemory(
            at offset: UInt32,
            resolveType: (ComponentTypeIndex) throws -> ComponentDefValType,
            options: CanonOptions,
            store: Store
        ) throws -> ComponentValue {
            guard let memory = options.memory else {
                throw CanonicalABIError(description: "Indirect result lifting requires memory option")
            }

            let memoryInstance = Memory(handle: memory, allocator: store.allocator)
            let memorySize = memoryInstance.byteCount

            // Helper to check bounds before reading
            func checkBounds(offset: UInt, count: Int) throws {
                guard Int(offset) + count <= memorySize else {
                    throw CanonicalABIError(description: "Memory access out of bounds: offset=\(offset), count=\(count), memorySize=\(memorySize)")
                }
            }

            switch self {
            // Primitives (single values stored in memory)
            case .inlined(.primitive(.bool)):
                try checkBounds(offset: UInt(offset), count: 1)
                let v: UInt8 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 1) { buffer in
                    buffer.load(as: UInt8.self)
                }
                return .bool(v != 0)
            case .inlined(.primitive(.u8)):
                try checkBounds(offset: UInt(offset), count: 1)
                let v: UInt8 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 1) { buffer in
                    buffer.load(as: UInt8.self)
                }
                return .u8(v)
            case .inlined(.primitive(.s8)):
                try checkBounds(offset: UInt(offset), count: 1)
                let v: Int8 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 1) { buffer in
                    buffer.load(as: Int8.self)
                }
                return .s8(v)
            case .inlined(.primitive(.u16)):
                try checkBounds(offset: UInt(offset), count: 2)
                let v: UInt16 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 2) { buffer in
                    buffer.load(as: UInt16.self)
                }
                return .u16(v)
            case .inlined(.primitive(.s16)):
                try checkBounds(offset: UInt(offset), count: 2)
                let v: Int16 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 2) { buffer in
                    buffer.load(as: Int16.self)
                }
                return .s16(v)
            case .inlined(.primitive(.u32)):
                try checkBounds(offset: UInt(offset), count: 4)
                let v: UInt32 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                    buffer.load(as: UInt32.self)
                }
                return .u32(v)
            case .inlined(.primitive(.s32)):
                try checkBounds(offset: UInt(offset), count: 4)
                let v: Int32 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                    buffer.load(as: Int32.self)
                }
                return .s32(v)
            case .inlined(.primitive(.u64)):
                try checkBounds(offset: UInt(offset), count: 8)
                let v: UInt64 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                    buffer.load(as: UInt64.self)
                }
                return .u64(v)
            case .inlined(.primitive(.s64)):
                try checkBounds(offset: UInt(offset), count: 8)
                let v: Int64 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                    buffer.load(as: Int64.self)
                }
                return .s64(v)
            case .inlined(.primitive(.float32)):
                try checkBounds(offset: UInt(offset), count: 4)
                let bits: UInt32 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                    buffer.load(as: UInt32.self)
                }
                return .float32(Float(bitPattern: bits))
            case .inlined(.primitive(.float64)):
                try checkBounds(offset: UInt(offset), count: 8)
                let bits: UInt64 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                    buffer.load(as: UInt64.self)
                }
                return .float64(Double(bitPattern: bits))
            case .inlined(.primitive(.char)):
                try checkBounds(offset: UInt(offset), count: 4)
                let v: UInt32 = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 4) { buffer in
                    buffer.load(as: UInt32.self)
                }
                guard let scalar = Unicode.Scalar(v) else {
                    throw CanonicalABIError(description: "invalid `char` bit pattern: \(v)")
                }
                return .char(scalar)

            // String: (ptr, len) pair at the offset
            case .inlined(.primitive(.string)):
                try checkBounds(offset: UInt(offset), count: 8)
                let (ptr, len): (UInt32, UInt32) = memoryInstance.withUnsafeBufferPointer(offset: UInt(offset), count: 8) { buffer in
                    let ptr = buffer.load(fromByteOffset: 0, as: UInt32.self)
                    let len = buffer.load(fromByteOffset: 4, as: UInt32.self)
                    return (ptr, len)
                }
                return try liftString(pointer: ptr, length: len, options: options, store: store)

            default:
                throw CanonicalABIError(description: "Cannot lift \(self) from memory - not yet implemented")
            }
        }
    }

    /// Lower a component value to core wasm values (flat encoding only).
    /// This handles primitive types that map directly to core wasm types.
    func lowerFlat(_ value: ComponentValue, paramType: ComponentDefValType) throws -> [Value] {
        switch (value, paramType) {
        // Boolean -> i32
        case (.bool(let b), .inlined(.primitive(.bool))):
            return [.i32(b ? 1 : 0)]

        // Unsigned integers
        case (.u8(let v), .inlined(.primitive(.u8))):
            return [.i32(UInt32(v))]
        case (.u16(let v), .inlined(.primitive(.u16))):
            return [.i32(UInt32(v))]
        case (.u32(let v), .inlined(.primitive(.u32))):
            return [.i32(v)]
        case (.u64(let v), .inlined(.primitive(.u64))):
            return [.i64(v)]

        // Signed integers
        case (.s8(let v), .inlined(.primitive(.s8))):
            return [.i32(UInt32(bitPattern: Int32(v)))]
        case (.s16(let v), .inlined(.primitive(.s16))):
            return [.i32(UInt32(bitPattern: Int32(v)))]
        case (.s32(let v), .inlined(.primitive(.s32))):
            return [.i32(UInt32(bitPattern: v))]
        case (.s64(let v), .inlined(.primitive(.s64))):
            return [.i64(UInt64(bitPattern: v))]

        // Floating point
        case (.float32(let v), .inlined(.primitive(.float32))):
            return [.f32(v.bitPattern)]
        case (.float64(let v), .inlined(.primitive(.float64))):
            return [.f64(v.bitPattern)]

        // Character (Unicode scalar value as i32)
        case (.char(let scalar), .inlined(.primitive(.char))):
            return [.i32(scalar.value)]

        default:
            throw CanonicalABIError(
                description: "Cannot lower \(value) to \(paramType) - only flat primitives supported"
            )
        }
    }

    /// Lift core wasm values to a component value (flat encoding only).
    /// This handles primitive types that map directly from core wasm types.
    func liftFlat(_ values: [Value], to resultType: ComponentDefValType) throws -> [ComponentValue] {
        guard !values.isEmpty else {
            throw CanonicalABIError(description: "No values to lift - expected at least 1")
        }

        let value = values[0]

        switch (value, resultType) {
        // i32 -> Boolean (any non-zero is true)
        case (.i32(let v), .inlined(.primitive(.bool))):
            return [.bool(v != 0)]

        // i32 -> Unsigned integers (with truncation/masking)
        case (.i32(let v), .inlined(.primitive(.u8))):
            return [.u8(UInt8(truncatingIfNeeded: v))]
        case (.i32(let v), .inlined(.primitive(.u16))):
            return [.u16(UInt16(truncatingIfNeeded: v))]
        case (.i32(let v), .inlined(.primitive(.u32))):
            return [.u32(v)]
        case (.i64(let v), .inlined(.primitive(.u64))):
            return [.u64(v)]

        // i32 -> Signed integers (with sign extension)
        case (.i32(let v), .inlined(.primitive(.s8))):
            return [.s8(Int8(truncatingIfNeeded: Int32(bitPattern: v)))]
        case (.i32(let v), .inlined(.primitive(.s16))):
            return [.s16(Int16(truncatingIfNeeded: Int32(bitPattern: v)))]
        case (.i32(let v), .inlined(.primitive(.s32))):
            return [.s32(Int32(bitPattern: v))]
        case (.i64(let v), .inlined(.primitive(.s64))):
            return [.s64(Int64(bitPattern: v))]

        // Floating point
        case (.f32(let bits), .inlined(.primitive(.float32))):
            return [.float32(Float(bitPattern: bits))]
        case (.f64(let bits), .inlined(.primitive(.float64))):
            return [.float64(Double(bitPattern: bits))]

        // i32 -> Character
        case (.i32(let v), .inlined(.primitive(.char))):
            guard let scalar = Unicode.Scalar(v) else {
                throw CanonicalABIError(
                    description: "invalid `char` bit pattern: \(v)"
                )
            }
            return [.char(scalar)]

        default:
            throw CanonicalABIError(
                description: "Cannot lift \(value) to \(resultType) - only flat primitives supported"
            )
        }
    }

    /// Maximum number of flat results before using indirect return
    let MAX_FLAT_RESULTS = 1

    // MARK: - Canonical ABI Helpers for canon.lower

    /// Convert a component function type to a core wasm function type.
    /// This flattens component-level types to their core representations.
    func flattenComponentFuncType(_ funcType: ComponentFuncType) -> FunctionType {
        var coreParams: [ValueType] = []
        for param in funcType.params {
            let coreTypes = param.type.flattenedComponentDefValType
            coreParams.append(contentsOf: coreTypes)
        }

        var coreResults: [ValueType] = []
        if let resultType = funcType.result {
            let flatResults = resultType.flattenedComponentDefValType
            coreResults.append(contentsOf: flatResults)
        }

        return FunctionType(parameters: coreParams, results: coreResults)
    }

    extension ComponentDefValType {
        /// Returns the number of flat core values for a component value type.
        var flattenedCount: Int {
            return self.flattenedComponentDefValType.count
        }

        /// Flatten a component value type to core wasm value types.
        /// For primitive types, this returns a single core type.
        var flattenedComponentDefValType: [ValueType] {
            switch self {
            case .inlined(.primitive(.bool)), .inlined(.primitive(.s8)), .inlined(.primitive(.u8)),
                .inlined(.primitive(.s16)), .inlined(.primitive(.u16)), .inlined(.primitive(.s32)),
                .inlined(.primitive(.u32)):
                return [.i32]
            case .inlined(.primitive(.s64)), .inlined(.primitive(.u64)):
                return [.i64]
            case .inlined(.primitive(.float32)):
                return [.f32]
            case .inlined(.primitive(.float64)):
                return [.f64]
            case .inlined(.primitive(.char)):
                return [.i32]  // Unicode scalar as i32
            case .inlined(.primitive(.string)):
                return [.i32, .i32]  // (pointer, length)
            default:
                // For complex types, we'll need heap-based ABI
                // For now, return empty to avoid crashes - these will fail at runtime
                #warning("Complex types not supported in `flattenedComponentDefValType`")
                return []
            }
        }

        /// Lift a single core wasm value to a component value.
        /// This is the single-value version used by canon.lower.
        func liftFlatCoreValue(_ value: Value) throws -> ComponentValue {
            let results = try liftFlat([value], to: self)
            guard let first = results.first else {
                throw CanonicalABIError(description: "No component value produced when lifting \(value) to \(self)")
            }
            return first
        }
    }

    // MARK: - Helper Functions

    /// Calculate the number of i32 values needed to store the given number of flags.
    /// Flags are bit-packed, so we need ceil(flagsCount / 32) i32 values.
    private func numberOfFlagsInt32(flagsCount: Int) -> Int {
        assert(flagsCount >= 0)
        return (flagsCount + 31) / 32  // Integer division equivalent to ceil(flagsCount / 32)
    }

#endif
