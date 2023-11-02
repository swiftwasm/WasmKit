import Foundation

public enum CanonicalABI {
    public enum CoreType: Equatable {
        case i32, i64, f32, f64
    }

    struct RawArgument {
        let name: String
        let type: CoreType
    }

    /// The direction of cross-component function call
    /// A cross-component function call is proxied by host runtime, so there are
    /// two call directions, caller component to host and host to callee component.
    public enum CallDirection {
        /// A component is calling a function imported from another component.
        /// Component-level values are being lowered to core-level types.
        case lower
        /// An exported function defined in a component is called from another component.
        /// Lowered core-level values are being lifted to component-level types.
        case lift
    }

    public typealias LabelPath = [String]

    public struct SignatureSegment {
        public var label: LabelPath
        public var type: CoreType

        func prepending(label: String) -> SignatureSegment {
            return SignatureSegment(label: [label] + self.label, type: type)
        }
    }

    public struct CoreSignature {
        public var parameters: [SignatureSegment]
        public var results: [SignatureSegment]
        public var isIndirectResult: Bool
    }

    /// Flatten the given WIT function signature into core function signature
    public static func flattenSignature(
        function: FunctionSyntax,
        typeResolver: (TypeReprSyntax) throws -> WITType
    ) throws -> CoreSignature {
        let parameters = try function.parameters.enumerated().map { i, param in
            let type = try typeResolver(param.type)
            return (param.name.text, type)
        }
        let results = try {
            switch function.results {
            case .named(let parameterList):
                return try parameterList.enumerated().map { i, result in
                    let type = try typeResolver(result.type)
                    return (result.name.text, type)
                }
            case .anon(let typeReprSyntax):
                let type = try typeResolver(typeReprSyntax)
                return [("ret", type)]
            }
        }()
        return CanonicalABI.flatten(
            parameters: parameters,
            results: results,
            direction: .lift
        )
    }

    /// https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md#flattening
    public static func flatten(
        parameters: some Sequence<(label: String, type: WITType)>,
        results: some Sequence<(label: String, type: WITType)>,
        direction: CallDirection
    ) -> CoreSignature {
        var flatParameters = parameters.flatMap { (label, type) in
            flatten(type: type).map { $0.prepending(label: label) }
        }
        let MAX_FLAT_PARAMS = 16
        if flatParameters.count > MAX_FLAT_PARAMS {
            flatParameters = [.init(label: ["args"], type: .i32)]
        }

        var flatResults = results.flatMap { (label, type) in
            flatten(type: type).map { $0.prepending(label: label) }
        }
        // To be practical, Canonical ABI specifies not to use multi-value returns
        var indirectResult: Bool = false
        let MAX_FLAT_RESULTS = 1
        if flatResults.count > MAX_FLAT_RESULTS {
            indirectResult = true
            // To reduce `realloc`/`free` calls, caller side is
            // responsible to allocate return value space and tell
            // the address to the intermediate host runtime, then
            // host runtime performs a copy from the address returned
            // by the callee into caller specified return pointer.
            // Note that this cross-component copy is required due to
            // shared-nothing property.
            switch direction {
            case .lower:
                flatParameters.append(.init(label: ["ret"], type: .i32))
                flatResults = []
            case .lift:
                flatResults = [.init(label: ["ret"], type: .i32)]
            }
        }
        return CoreSignature(
            parameters: flatParameters,
            results: flatResults,
            isIndirectResult: indirectResult
        )
    }

    public static func flatten(type: WITType) -> [SignatureSegment] {
        switch type {
        case .bool, .u8, .u16, .u32, .s8, .s16, .s32, .char:
            return [.init(label: [], type: .i32)]
        case .u64, .s64: return [.init(label: [], type: .i64)]
        case .float32: return [.init(label: [], type: .f32)]
        case .float64: return [.init(label: [], type: .f64)]
        case .string:
            return [.init(label: ["ptr"], type: .i32), .init(label: ["len"], type: .i32)]
        case .list:
            return [.init(label: ["ptr"], type: .i32), .init(label: ["len"], type: .i32)]
        case .handleOwn, .handleBorrow:
            return [.init(label: [], type: .i32)]
        case .tuple(let types):
            return types.enumerated().flatMap { i, type in
                flatten(type: type).map { $0.prepending(label: i.description) }
            }
        case .record(let record):
            return record.fields.flatMap { field in
                flatten(type: field.type).map { $0.prepending(label: field.name) }
            }
        case .option(let type):
            return flatten(variants: [type, nil])
        case .result(let ok, let error):
            return flatten(variants: [ok, error])
        case .union(let union):
            return flatten(variants: union.cases.map(\.type))
        case .variant(let variant):
            return flatten(variants: variant.cases.map(\.type))
        case .enum(let `enum`):
            return flatten(variants: `enum`.cases.map { _ in nil })
        case .future: return [.init(label: [], type: .i32)]
        case .stream: return [.init(label: [], type: .i32)]
        case .flags(let flags):
            return Array(repeating: CoreType.i32, count: numberOfInt32(flagsCount: flags.flags.count)).enumerated().map {
                SignatureSegment(label: [$0.description], type: $1)
            }
        case .resource:
            fatalError("TODO: resource type is not supported yet")
        }
    }

    static func flatten(variants: [WITType?]) -> [SignatureSegment] {
        let discriminant = flatten(type: discriminantType(numberOfCases: UInt32(variants.count)).asWITType)
        return discriminant.map { $0.prepending(label: "disc") }
            + flattenVariantPayload(variants: variants).enumerated().map {
                SignatureSegment(label: [$0.description], type: $1)
            }
    }

    /// Flatten the given WIT variant type into core types.
    public static func flattenVariantPayload(variants: [WITType?]) -> [CoreType] {
        var results: [CoreType] = []
        for variantType in variants {
            guard let variantType else { continue }
            for (i, flatten) in flatten(type: variantType).enumerated() {
                if i < results.count {
                    results[i] = join(results[i], flatten.type)
                } else {
                    results.append(flatten.type)
                }
            }
        }
        return results
        /// Return a minimum sized type that fits for two parameter types
        func join(_ a: CoreType, _ b: CoreType) -> CoreType {
            switch (a, b) {
            case (.i32, .f32), (.f32, .i32),
                (.f32, .f32), (.i32, .i32):
                return .i32
            case (_, .i64), (.i64, _),
                (_, .f64), (.f64, _):
                return .i64
            }
        }
    }

    /// A type that represents the discriminant of a variant/enum type.
    public enum DiscriminantType {
        case u8, u16, u32

        public var asWITType: WITType {
            switch self {
            case .u8: return .u8
            case .u16: return .u16
            case .u32: return .u32
            }
        }
    }

    /// Return the smallest integer type that can represent the given number of cases.
    public static func discriminantType(numberOfCases: UInt32) -> DiscriminantType {
        switch Int(ceil(log2(Double(numberOfCases)) / 8)) {
        case 0: return .u8
        case 1: return .u8
        case 2: return .u16
        case 3: return .u32
        default: fatalError("`ceil(log2(UInt32)) / 8` cannot be greater than 3")
        }
    }

    static func numberOfInt32(flagsCount: Int) -> Int {
        return Int(ceil(Double(flagsCount) / 32))
    }

    static func alignUp(_ offset: Int, to align: Int) -> Int {
        let mask = align &- 1
        return (offset &+ mask) & ~mask
    }

    static func payloadOffset(cases: [WITType?]) -> Int {
        let discriminantType = Self.discriminantType(numberOfCases: UInt32(cases.count))
        let discriminantSize = Self.size(type: discriminantType.asWITType)
        let payloadAlign = maxCaseAlignment(cases: cases)
        return alignUp(discriminantSize, to: payloadAlign)
    }

    public static func fieldOffsets(fields: [WITType]) -> [(WITType, Int)] {
        var current = 0
        return fields.map { field in
            let aligned = alignUp(current, to: alignment(type: field))
            current = aligned + size(type: field)
            return (field, aligned)
        }
    }

    public static func size(type: WITType) -> Int {
        switch type {
        case .bool, .u8, .s8: return 1
        case .u16, .s16: return 2
        case .u32, .s32: return 4
        case .u64, .s64: return 8
        case .float32: return 4
        case .float64: return 8
        case .char: return 4
        case .string: return 8
        case .list: return 8
        case .handleOwn, .handleBorrow:
            return 4
        case .tuple(let types):
            return size(fields: types)
        case .option(let type):
            return size(cases: [type, nil])
        case .result(let ok, let error):
            return size(cases: [ok, error])
        case .future:
            return 4
        case .stream:
            return 4
        case .record(let record):
            return size(fields: record.fields.map(\.type))
        case .flags(let flags):
            switch rawType(ofFlags: flags.flags.count) {
            case .u8: return 1
            case .u16: return 2
            case .u32: return 4
            }
        case .enum(let enumType):
            return size(cases: enumType.cases.map { _ in nil })
        case .variant(let variant):
            return size(cases: variant.cases.map(\.type))
        case .resource:
            fatalError("TODO: resource types are not supported yet")
        case .union:
            fatalError("FIXME: union types has been removed from the Component Model spec")
        }
    }

    static func size(fields: [WITType]) -> Int {
        var size = 0
        for field in fields {
            let fieldSize = Self.size(type: field)
            let fieldAlign = alignment(type: field)
            size = alignUp(size, to: fieldAlign) + fieldSize
        }
        return alignUp(size, to: alignment(fields: fields))
    }

    static func size(cases: [WITType?]) -> Int {
        var maxSize = 0
        for case .some(let caseType) in cases {
            maxSize = max(maxSize, size(type: caseType))
        }
        return alignUp(payloadOffset(cases: cases) + maxSize, to: alignment(cases: cases))
    }

    public static func alignment(type: WITType) -> Int {
        switch type {
        case .bool, .u8, .s8: return 1
        case .u16, .s16: return 2
        case .u32, .s32: return 4
        case .u64, .s64: return 8
        case .float32: return 4
        case .float64: return 8
        case .char: return 4
        case .string: return 4
        case .list: return 4
        case .handleOwn, .handleBorrow:
            return 4
        case .tuple(let types):
            return alignment(fields: types)
        case .option(let type):
            return alignment(cases: [type, nil])
        case .result(let ok, let error):
            return alignment(cases: [ok, error])
        case .future:
            return 4
        case .stream:
            return 4
        case .record(let record):
            return alignment(fields: record.fields.map(\.type))
        case .flags(let flags):
            switch rawType(ofFlags: flags.flags.count) {
            case .u8: return 1
            case .u16: return 2
            case .u32: return 4
            }
        case .enum(let enumType):
            return alignment(cases: enumType.cases.map { _ in nil })
        case .variant(let variant):
            return alignment(cases: variant.cases.map(\.type))
        case .resource:
            fatalError("TODO: resource type is not supported yet")
        case .union:
            fatalError("FIXME: union type is already removed from the spec")
        }
    }

    static func alignment(cases: [WITType?]) -> Int {
        max(
            alignment(type: discriminantType(numberOfCases: UInt32(cases.count)).asWITType),
            maxCaseAlignment(cases: cases)
        )
    }

    static func alignment(fields: [WITType]) -> Int {
        fields.map(Self.alignment(type:)).max() ?? 1
    }

    static func maxCaseAlignment(cases: [WITType?]) -> Int {
        var alignment = 1
        for caseType in cases {
            guard let caseType else { continue }
            alignment = max(alignment, Self.alignment(type: caseType))
        }
        return alignment
    }

    public enum FlagsRawRepresentation {
        case u8, u16
        case u32(Int)

        public var numberOfInt32: Int {
            switch self {
            case .u8, .u16: return 1
            case .u32(let v): return v
            }
        }
    }

    public static func rawType(ofFlags: Int) -> FlagsRawRepresentation {
        if ofFlags == 0 {
            return .u32(0)
        } else if ofFlags <= 8 {
            return .u8
        } else if ofFlags <= 16 {
            return .u16
        } else {
            return .u32(CanonicalABI.numberOfInt32(flagsCount: ofFlags))
        }
    }
}
