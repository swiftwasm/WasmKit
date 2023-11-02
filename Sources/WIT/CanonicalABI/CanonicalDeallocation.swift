/// A type that provides a deallocation operation for WIT values.
public protocol CanonicalDeallocation {
    /// A type of a core value and a type of a WIT value.
    associatedtype Operand

    /// A type of a pointer representation.
    associatedtype Pointer

    /// Deallocates a WIT string value.
    ///
    /// - Parameters:
    ///   - pointer: A pointer that contains the byte representation of the string.
    ///   - length: A number of bytes in the string.
    func deallocateString(pointer: Operand, length: Operand)

    /// Deallocates a WIT list value.
    ///
    /// - Parameters:
    ///   - pointer: A pointer that contains the byte representation of the list elements.
    ///   - length: A number of elements in the list.
    ///   - element: A type of the list elements.
    ///   - deallocateElement: A closure that deallocates an element from the given pointer.
    func deallocateList(
        pointer: Operand, length: Operand, element: WITType,
        deallocateElement: (Pointer) throws -> Void
    ) throws

    /// Deallocates a WIT variant value.
    ///
    /// - Parameters:
    ///   - discriminant: An lifted integer value that represents a discriminant of the variant.
    ///   - cases: A list of types of the variant cases.
    ///   - deallocatePayload: A closure that deallocates a payload of the variant case at the given index.
    func deallocateVariantLike(
        discriminant: Operand, cases: [WITType?],
        deallocatePayload: (Int) throws -> Void
    ) throws
}

extension CanonicalABI {
    /// Performs a deallocation operation for the given WIT value at the given pointer.
    /// It recursively deallocates all the nested values.
    public static func deallocate<Deallocation: CanonicalDeallocation, Loading: CanonicalLoading>(
        type: WITType,
        pointer: Loading.Pointer,
        deallocation: Deallocation,
        loading: Loading
    ) throws -> Bool where Deallocation.Operand == Loading.Operand, Deallocation.Pointer == Loading.Pointer {
        func deallocateRecordLike(fields: [WITType]) throws -> Bool {
            var needsDeallocation = false
            for (fieldType, offset) in fieldOffsets(fields: fields) {
                let result = try deallocate(
                    type: fieldType,
                    pointer: pointer.advanced(by: Deallocation.Pointer.Stride(exactly: offset)!),
                    deallocation: deallocation, loading: loading
                )
                needsDeallocation = needsDeallocation || result
            }
            return needsDeallocation
        }

        func deallocateVariantLike(cases: [WITType?]) throws -> Bool {
            let discriminant = loadVariantDiscriminant(pointer: pointer, numberOfCases: cases.count, loading: loading)
            let payloadOffset = CanonicalABI.payloadOffset(cases: cases)
            let payloadPtr = pointer.advanced(by: .init(exactly: payloadOffset)!)
            var needsDeallocation = false
            try deallocation.deallocateVariantLike(
                discriminant: discriminant, cases: cases,
                deallocatePayload: { caseIndex in
                    guard let variantCase = cases[caseIndex] else { return }
                    let result = try deallocate(
                        type: variantCase, pointer: payloadPtr,
                        deallocation: deallocation, loading: loading
                    )
                    needsDeallocation = needsDeallocation || result
                }
            )
            return needsDeallocation
        }

        switch type {
        case .bool, .u8, .u16, .u32, .u64,
            .s8, .s16, .s32, .s64,
            .float32, .float64, .char:
            return false
        case .string:
            let (buffer, length) = loadList(loading: loading, pointer: pointer)
            deallocation.deallocateString(pointer: buffer, length: length)
            return true
        case .list(let element):
            let (buffer, length) = loadList(loading: loading, pointer: pointer)
            try deallocation.deallocateList(
                pointer: buffer, length: length, element: element,
                deallocateElement: { pointer in
                    _ = try deallocate(type: element, pointer: pointer, deallocation: deallocation, loading: loading)
                }
            )
            return true
        case .handleOwn, .handleBorrow:
            fatalError("TODO: resource type is not supported yet")
        case .tuple(let types):
            return try deallocateRecordLike(fields: types)
        case .record(let record):
            return try deallocateRecordLike(fields: record.fields.map(\.type))
        case .option(let wrapped):
            return try deallocateVariantLike(cases: [nil, wrapped])
        case .result(let ok, let error):
            return try deallocateVariantLike(cases: [ok, error])
        case .variant(let variant):
            return try deallocateVariantLike(cases: variant.cases.map(\.type))
        case .flags: return false
        case .enum: return false
        default:
            fatalError("TODO: deallocation for \"\(type)\" is unimplemented")
        }
    }
}
