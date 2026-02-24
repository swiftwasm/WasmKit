#if ComponentModel
    import WasmTypes
    import ComponentModel

    /// A streaming parser for WebAssembly Component Model binary format.
    /// For proposed production rules refer to https://github.com/WebAssembly/component-model/blob/7479890cb506d0f8f687595a4d41361ff8a2a194/design/mvp/Binary.md
    public struct ComponentParser<Stream: ByteStream> {
        @usableFromInline
        let stream: Stream
        @usableFromInline
        let features: WasmFeatureSet

        @usableFromInline
        enum NextParseTarget {
            case header
            case section
        }
        @usableFromInline
        var nextParseTarget: NextParseTarget

        public var offset: Int {
            return stream.currentIndex
        }

        public init(stream: Stream, features: WasmFeatureSet = .default) {
            self.stream = stream
            self.features = features
            self.nextParseTarget = .header
        }

        @usableFromInline
        internal func makeError(_ message: WasmKitError.Message) -> WasmKitError {
            return WasmKitError(message: message, offset: offset)
        }
    }

    extension ComponentParser where Stream == StaticByteStream {
        /// Initialize a new parser with the given bytes
        ///
        /// - Parameters:
        ///   - bytes: The bytes of the WebAssembly component binary file to parse
        ///   - features: Enabled WebAssembly features for parsing
        public init(bytes: [UInt8], features: WasmFeatureSet = .default) {
            self.init(stream: StaticByteStream(bytes: bytes), features: features)
        }
    }

    // MARK: - Component Parsing Payload

    /// The parsed output of a component section.
    public enum ComponentParsingPayload {
        /// The component header with version bytes
        case header(version: [UInt8])

        /// A custom section (section 0)
        case customSection(CustomSection)

        /// An embedded core module (section 1)
        case coreModule(ArraySlice<UInt8>)

        /// Core instance definitions (section 2)
        case coreInstanceSection([CoreInstanceDefinition])

        /// Core type definitions (section 3)
        case coreTypeSection([CoreTypeDef])

        /// A nested component (section 4)
        case component(ArraySlice<UInt8>)

        /// Component instance definitions (section 5)
        case instanceSection([ComponentInstanceDefinition])

        /// Alias definitions (section 6)
        case aliasSection([ComponentAlias])

        /// Component type definitions (section 7)
        case typeSection([ComponentTypeDef])

        /// Canonical definitions (section 8)
        case canonSection([CanonicalDefinition])

        /// Start definition (section 9)
        case startSection(ComponentStart)

        /// Import definitions (section 10)
        case importSection([ComponentImportDef])

        /// Export definitions (section 11)
        case exportSection([ComponentExportDef])

        /// Value definitions (section 12)
        case valueSection([ComponentValueDef])
    }

    // MARK: - Core Type Definitions (Parser-specific - depends on WasmParser types)

    /// A core type definition (from binary section 3).
    public enum CoreTypeDef {
        /// A core function type
        case function(FunctionType)
        /// A core module type
        case module(CoreModuleType)
    }

    /// A core module type definition.
    public struct CoreModuleType {
        public var declarations: [CoreModuleDecl]

        public init(declarations: [CoreModuleDecl]) {
            self.declarations = declarations
        }
    }

    /// A declaration within a core module type.
    public enum CoreModuleDecl {
        case `import`(Import)
        case type(CoreTypeDef)
        case alias(ComponentAlias)
        case exportDecl(name: String, descriptor: ImportDescriptor)
    }

    // MARK: - Component Type Definitions (Parser-specific - depends on CoreTypeDef)

    /// A component type definition (from binary section 7).
    public enum ComponentTypeDef {
        /// A defined value type
        case definedValue(ComponentValueType)
        /// A function type
        case function(ComponentFuncType)
        /// A component type
        case component(ComponentTypeDecl)
        /// An instance type
        case instance(InstanceTypeDecl)
        /// A resource type
        case resource(destructor: UInt32?)
    }

    /// Declarations within a component type.
    public struct ComponentTypeDecl {
        public var declarations: [ComponentOrInstanceDecl]

        public init(declarations: [ComponentOrInstanceDecl]) {
            self.declarations = declarations
        }
    }

    /// Declarations within an instance type.
    public struct InstanceTypeDecl {
        public var declarations: [InstanceDecl]

        public init(declarations: [InstanceDecl]) {
            self.declarations = declarations
        }
    }

    /// A declaration that can appear in a component type.
    public enum ComponentOrInstanceDecl {
        case importDecl(ComponentImportDecl)
        case instanceDecl(InstanceDecl)
    }

    /// A declaration that can appear in an instance type.
    public enum InstanceDecl {
        case coreType(CoreTypeDef)
        case type(ComponentTypeDef)
        case alias(ComponentAlias)
        case exportDecl(ComponentExportDecl)
    }

    // MARK: - Parser Implementation

    extension ComponentParser {
        /// Parse the component magic number and version.
        @usableFromInline
        func parsePreamble() throws(WasmKitError) ->[UInt8] {
            // Magic number: 0x00 0x61 0x73 0x6D (same as core wasm)
            let magic = try stream.consume(count: 4)
            guard magic.elementsEqual(WASM_MAGIC) else {
                throw makeError(.invalidMagicNumber(.init(magic)))
            }

            // Version: 0x0d 0x00 (component model version 13)
            // Layer: 0x01 0x00 (indicates component, not module)
            let version = try stream.consume(count: 4)
            guard version.elementsEqual([0x0d, 0x00, 0x01, 0x00]) else {
                throw makeError(.unknownVersion(Array(version)))
            }

            return Array(version)
        }

        @inlinable
        func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws(WasmKitError) -> T {
            try stream.parseUnsigned(T.self)
        }

        @inlinable
        func parseVector<Content>(content parser: () throws(WasmKitError) -> Content) throws(WasmKitError) -> [Content] {
            try stream.parseVector(content: parser)
        }

        func parseCoreSort() throws(WasmKitError) ->CoreDefSort {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00: return .func
            case 0x01: return .table
            case 0x02: return .memory
            case 0x03: return .global
            case 0x10: return .type
            case 0x11: return .module
            case 0x12: return .instance
            default:
                throw makeError(.malformedSectionID(byte))
            }
        }

        func parseSort() throws(WasmKitError) ->ComponentDefSort {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00:
                let coreSort = try parseCoreSort()
                return .core(coreSort)
            case 0x01: return .func
            case 0x02: return .value
            case 0x03: return .type
            case 0x04: return .component
            case 0x05: return .instance
            default:
                throw makeError(.malformedSectionID(byte))
            }
        }

        func parseSortIdx() throws(WasmKitError) ->(sort: ComponentDefSort, index: UInt32) {
            let sort = try parseSort()
            let index: UInt32 = try parseUnsigned()
            return (sort, index)
        }

        func parseCanonicalOptions() throws(WasmKitError) ->[CanonicalOption] {
            try parseVector {
                let byte = try stream.consumeAny()
                guard let tag = CanonOptionTag(rawValue: byte) else {
                    throw makeError(.unknownCanonOptionTag(byte))
                }
                switch tag {
                case .stringEncodingUtf8: return .utf8
                case .stringEncodingUtf16: return .utf16
                case .stringEncodingLatin1Utf16: return .latin1UTF16
                case .memory:
                    let idx: UInt32 = try parseUnsigned()
                    return .memory(memoryIndex: idx)
                case .realloc:
                    let idx: UInt32 = try parseUnsigned()
                    return .realloc(funcIndex: idx)
                case .postReturn:
                    let idx: UInt32 = try parseUnsigned()
                    return .postReturn(funcIndex: idx)
                case .async: return .async
                case .callback:
                    let idx: UInt32 = try parseUnsigned()
                    return .callback(funcIndex: idx)
                }
            }
        }

        /// Parse a value type (primitive or type index).
        func parseValType() throws(WasmKitError) ->ComponentValueType {
            let byte = try stream.peek() ?? 0
            // Check if it's a type index (non-negative SLEB128)
            if byte < 0x64 {
                let idx: UInt32 = try parseUnsigned()
                return .indexed(ComponentTypeIndex(rawValue: Int(idx)))
            } else {
                let opcode = try stream.consumeAny()
                return try parsePrimValTypeFromOpcode(opcode)
            }
        }

        /// Parse an optional value type.
        func parseOptionalValType() throws(WasmKitError) ->ComponentTypeIndex? {
            let present = try stream.consumeAny()
            if present == 0x00 {
                return nil
            } else {
                let idx: UInt32 = try parseUnsigned()
                return ComponentTypeIndex(rawValue: Int(idx))
            }
        }

        /// Parse a defined value type.
        func parseDefValType() throws(WasmKitError) ->ComponentValueType {
            let byte = try stream.peek() ?? 0

            // Check for type index first
            if byte < 0x64 {
                let idx: UInt32 = try parseUnsigned()
                return .indexed(ComponentTypeIndex(rawValue: Int(idx)))
            }

            let opcode = try stream.consumeAny()

            // Primitive types (0x73...0x7f and 0x64 are not in CompositeValTypeOpcode)
            if PrimitiveValTypeOpcode(rawValue: opcode) != nil {
                return try parsePrimValTypeFromOpcode(opcode)
            }

            guard let compositeType = CompositeValTypeOpcode(rawValue: opcode) else {
                throw makeError(.malformedValueType(opcode))
            }
            switch compositeType {
            case .record:
                let fields = try parseVector {
                    let name = try stream.parseName()
                    let typeIdx: UInt32 = try parseUnsigned()
                    return ComponentRecordField(name: name, type: ComponentTypeIndex(rawValue: Int(typeIdx)))
                }
                return .record(fields)

            case .variant:
                let cases = try parseVector {
                    let name = try stream.parseName()
                    let typeIdx = try parseOptionalValType()
                    _ = try stream.consumeAny()  // consume 0x00 terminator
                    return ComponentCaseField(name: name, type: typeIdx)
                }
                return .variant(cases)

            case .list:
                let elemIdx: UInt32 = try parseUnsigned()
                return .list(ComponentTypeIndex(rawValue: Int(elemIdx)))

            case .tuple:
                let typeIndices: [UInt32] = try parseVector { try parseUnsigned() }
                return .tuple(typeIndices.map { ComponentTypeIndex(rawValue: Int($0)) })

            case .flags:
                let labels = try parseVector { try stream.parseName() }
                return .flags(labels)

            case .enum:
                let labels = try parseVector { try stream.parseName() }
                return .enum(labels)

            case .option:
                let someIdx: UInt32 = try parseUnsigned()
                return .option(ComponentTypeIndex(rawValue: Int(someIdx)))

            case .result:
                let okIdx = try parseOptionalValType()
                let errIdx = try parseOptionalValType()
                return .result(ok: okIdx, error: errIdx)

            case .stream:
                let elemIdx = try parseOptionalValType()
                return .stream(element: elemIdx, end: nil)

            case .future:
                let elemIdx = try parseOptionalValType()
                return .future(elemIdx)

            case .own, .borrow, .listFixed:
                throw makeError(.malformedValueType(opcode))
            }
        }

        /// Parse a primitive value type from an already-consumed opcode.
        func parsePrimValTypeFromOpcode(_ opcode: UInt8) throws(WasmKitError) ->ComponentValueType {
            guard let type = PrimitiveValTypeOpcode(rawValue: opcode) else {
                throw makeError(.malformedValueType(opcode))
            }

            switch type {
            case .bool: return .bool
            case .s8: return .s8
            case .u8: return .u8
            case .s16: return .s16
            case .u16: return .u16
            case .s32: return .s32
            case .u32: return .u32
            case .s64: return .s64
            case .u64: return .u64
            case .float32: return .float32
            case .float64: return .float64
            case .char: return .char
            case .string: return .string
            case .errorContext: return .errorContext
            }
        }

        /// Parse an extern descriptor.
        func parseExternDesc() throws(WasmKitError) ->ComponentExternDesc {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00:
                let moduleMarker = try stream.consumeAny()
                guard moduleMarker == 0x11 else {
                    throw makeError(.malformedSectionID(moduleMarker))
                }
                let idx: UInt32 = try parseUnsigned()
                return .coreModule(typeIndex: idx)
            case 0x01:
                let idx: UInt32 = try parseUnsigned()
                return .function(typeIndex: idx)
            case 0x02:
                let bound = try parseValueBound()
                return .value(bound)
            case 0x03:
                let bound = try parseTypeBound()
                return .type(bound)
            case 0x04:
                let idx: UInt32 = try parseUnsigned()
                return .component(typeIndex: idx)
            case 0x05:
                let idx: UInt32 = try parseUnsigned()
                return .instance(typeIndex: idx)
            default:
                throw makeError(.malformedSectionID(byte))
            }
        }

        /// Parse a value bound.
        func parseValueBound() throws(WasmKitError) ->ComponentValueBound {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00:
                let idx: UInt32 = try parseUnsigned()
                return .eq(valueIndex: idx)
            case 0x01:
                let valType = try parseValType()
                return .type(valType)
            default:
                throw makeError(.malformedSectionID(byte))
            }
        }

        /// Parse a type bound.
        func parseTypeBound() throws(WasmKitError) ->ComponentTypeBound {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00:
                let idx: UInt32 = try parseUnsigned()
                return .eq(typeIndex: idx)
            case 0x01:
                return .subResource
            default:
                throw makeError(.malformedSectionID(byte))
            }
        }

        /// Parse an import/export name with optional version suffix.
        func parseImportExportName() throws(WasmKitError) ->String {
            let prefix = try stream.consumeAny()
            let len: UInt32 = try parseUnsigned()
            let nameBytes = try stream.consume(count: Int(len))

            var name = ""
            var iterator = nameBytes.makeIterator()
            var decoder = UTF8()
            loop: while true {
                switch decoder.decode(&iterator) {
                case .scalarValue(let scalar): name.append(Character(scalar))
                case .emptyInput: break loop
                case .error: throw makeError(.invalidUTF8(Array(nameBytes)))
                }
            }

            // Handle version suffix if present
            if prefix == 0x01 {
                let suffixLen: UInt32 = try parseUnsigned()
                #warning("Version suffix skipped in `parseImportExportName` as not implemented yet")
                _ = try stream.consume(count: Int(suffixLen))  // Skip version suffix for now
            }

            return name
        }
    }

    // MARK: - Section Parsers

    extension ComponentParser {
        /// Parse a custom section.
        func parseCustomSection(size: UInt32) throws(WasmKitError) ->CustomSection {
            let preNameIndex = stream.currentIndex
            let name = try stream.parseName()
            let nameSize = stream.currentIndex - preNameIndex
            let contentSize = Int(size) - nameSize

            guard contentSize >= 0 else {
                throw makeError(.invalidSectionSize(size))
            }

            let bytes = try stream.consume(count: contentSize)
            return CustomSection(name: name, bytes: bytes)
        }

        /// Parse core instance section (section 2).
        func parseCoreInstanceSection() throws(WasmKitError) ->[CoreInstanceDefinition] {
            try parseVector {
                let kind = try stream.consumeAny()
                switch kind {
                case 0x00:
                    let moduleIdx: UInt32 = try parseUnsigned()
                    let args = try parseVector {
                        let name = try stream.parseName()
                        let marker = try stream.consumeAny()
                        guard marker == 0x12 else {
                            throw makeError(.malformedSectionID(marker))
                        }
                        let instanceIdx: UInt32 = try parseUnsigned()
                        return CoreInstantiateArg(name: name, instanceIndex: instanceIdx)
                    }
                    return .instantiate(moduleIndex: moduleIdx, args: args)
                case 0x01:
                    let exports = try parseVector {
                        let name = try stream.parseName()
                        let sort = try parseCoreSort()
                        let idx: UInt32 = try parseUnsigned()
                        return CoreInlineExport(name: name, sort: sort, index: idx)
                    }
                    return .exports(exports)
                default:
                    throw makeError(.malformedSectionID(kind))
                }
            }
        }

        /// Parse component instance section (section 5).
        func parseInstanceSection() throws(WasmKitError) ->[ComponentInstanceDefinition] {
            try parseVector {
                let kind = try stream.consumeAny()
                switch kind {
                case 0x00:
                    let componentIdx: UInt32 = try parseUnsigned()
                    let args = try parseVector {
                        let name = try stream.parseName()
                        let (sort, idx) = try parseSortIdx()
                        return ComponentInstantiateArg(name: name, sort: sort, index: idx)
                    }
                    return .instantiate(componentIndex: componentIdx, args: args)
                case 0x01:
                    let exports = try parseVector {
                        let name = try parseImportExportName()
                        let (sort, idx) = try parseSortIdx()
                        return ComponentInlineExport(name: name, sort: sort, index: idx)
                    }
                    return .exports(exports)
                default:
                    throw makeError(.malformedSectionID(kind))
                }
            }
        }

        /// Parse alias section (section 6).
        func parseAliasSection() throws(WasmKitError) ->[ComponentAlias] {
            try parseVector {
                let sort = try parseSort()
                let targetKind = try stream.consumeAny()
                let target: ComponentAliasTarget
                switch targetKind {
                case 0x00:
                    let instanceIdx: UInt32 = try parseUnsigned()
                    let name = try stream.parseName()
                    target = .export(instanceIndex: instanceIdx, name: name)
                case 0x01:
                    let instanceIdx: UInt32 = try parseUnsigned()
                    let name = try stream.parseName()
                    target = .coreExport(instanceIndex: instanceIdx, name: name)
                case 0x02:
                    let count: UInt32 = try parseUnsigned()
                    let idx: UInt32 = try parseUnsigned()
                    target = .outer(count: count, index: idx)
                default:
                    throw makeError(.malformedSectionID(targetKind))
                }
                return ComponentAlias(sort: sort, target: target)
            }
        }

        /// Parse type section (section 7).
        func parseTypeSection() throws(WasmKitError) ->[ComponentTypeDef] {
            try parseVector {
                try parseTypeDef()
            }
        }

        /// Parse a single type definition.
        func parseTypeDef() throws(WasmKitError) ->ComponentTypeDef {
            let byte = try stream.peek() ?? 0

            // Check if it's a defined value type (primitive or composite)
            if byte >= 0x64 || byte < 0x40 {
                let valType = try parseDefValType()
                return .definedValue(valType)
            }

            let opcode = try stream.consumeAny()
            switch opcode {
            case 0x40:  // functype
                let params = try parseVector {
                    let name = try stream.parseName()
                    let valType = try parseValType()
                    return ComponentFuncType.Param(name: name, type: valType)
                }
                let resultKind = try stream.consumeAny()
                let result: ComponentValueType?
                if resultKind == 0x00 {
                    result = try parseValType()
                } else {
                    // 0x01 0x00 means no result
                    _ = try stream.consumeAny()
                    result = nil
                }
                return .function(ComponentFuncType(params: params, result: result))

            case 0x41:  // componenttype
                let decls = try parseVector { try parseComponentOrInstanceDecl(isComponent: true) }
                return .component(ComponentTypeDecl(declarations: decls))

            case 0x42:  // instancetype
                let decls = try parseVector { try parseInstanceDeclOnly() }
                return .instance(InstanceTypeDecl(declarations: decls))

            case 0x3f:  // resourcetype
                _ = try stream.consumeAny()  // 0x7f rep type marker
                let hasDtor = try stream.consumeAny()
                let dtor: UInt32? = hasDtor == 0x01 ? try parseUnsigned() : nil
                return .resource(destructor: dtor)

            default:
                throw makeError(.malformedSectionID(opcode))
            }
        }

        /// Parse component or instance declaration.
        func parseComponentOrInstanceDecl(isComponent: Bool) throws(WasmKitError) ->ComponentOrInstanceDecl {
            let kind = try stream.consumeAny()
            switch kind {
            case 0x03 where isComponent:
                let name = try parseImportExportName()
                let externDesc = try parseExternDesc()
                return .importDecl(ComponentImportDecl(name: name, externDesc: externDesc))
            default:
                // Parse as instance decl
                return try .instanceDecl(parseInstanceDecl(fromKind: kind))
            }
        }

        /// Parse instance declaration only.
        func parseInstanceDeclOnly() throws(WasmKitError) ->InstanceDecl {
            let kind = try stream.consumeAny()
            return try parseInstanceDecl(fromKind: kind)
        }

        /// Parse instance declaration from kind byte.
        func parseInstanceDecl(fromKind kind: UInt8) throws(WasmKitError) ->InstanceDecl {
            switch kind {
            case 0x00:
                // core type
                let coreType = try parseCoreTypeDef()
                return .coreType(coreType)
            case 0x01:
                // type
                let typeDef = try parseTypeDef()
                return .type(typeDef)
            case 0x02:
                // alias
                let alias = try parseSingleAlias()
                return .alias(alias)
            case 0x04:
                // export decl
                let name = try parseImportExportName()
                let externDesc = try parseExternDesc()
                return .exportDecl(ComponentExportDecl(name: name, externDesc: externDesc))
            default:
                throw makeError(.malformedSectionID(kind))
            }
        }

        /// Parse a single alias (not in a vector).
        func parseSingleAlias() throws(WasmKitError) ->ComponentAlias {
            let sort = try parseSort()
            let targetKind = try stream.consumeAny()
            let target: ComponentAliasTarget
            switch targetKind {
            case 0x00:
                let instanceIdx: UInt32 = try parseUnsigned()
                let name = try stream.parseName()
                target = .export(instanceIndex: instanceIdx, name: name)
            case 0x01:
                let instanceIdx: UInt32 = try parseUnsigned()
                let name = try stream.parseName()
                target = .coreExport(instanceIndex: instanceIdx, name: name)
            case 0x02:
                let count: UInt32 = try parseUnsigned()
                let idx: UInt32 = try parseUnsigned()
                target = .outer(count: count, index: idx)
            default:
                throw makeError(.malformedSectionID(targetKind))
            }
            return ComponentAlias(sort: sort, target: target)
        }

        /// Parse a core type definition.
        func parseCoreTypeDef() throws(WasmKitError) ->CoreTypeDef {
            let byte = try stream.peek() ?? 0
            if byte == 0x50 {
                _ = try stream.consumeAny()
                // Module type
                let decls = try parseVector { try parseCoreModuleDecl() }
                return .module(CoreModuleType(declarations: decls))
            } else if byte == 0x60 {
                // Function type
                _ = try stream.consumeAny()
                let params = try parseVector { try parseCoreValueType() }
                let results = try parseVector { try parseCoreValueType() }
                return .function(FunctionType(parameters: params, results: results))
            } else {
                throw makeError(.malformedSectionID(byte))
            }
        }

        /// Parse core value type.
        func parseCoreValueType() throws(WasmKitError) ->ValueType {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x7F: return .i32
            case 0x7E: return .i64
            case 0x7D: return .f32
            case 0x7C: return .f64
            case 0x7B: return .v128
            default:
                throw makeError(.malformedValueType(byte))
            }
        }

        /// Parse core module declaration.
        func parseCoreModuleDecl() throws(WasmKitError) ->CoreModuleDecl {
            let kind = try stream.consumeAny()
            switch kind {
            case 0x00:
                // import
                let module = try stream.parseName()
                let name = try stream.parseName()
                let desc = try parseCoreImportDesc()
                return .import(Import(module: module, name: name, descriptor: desc))
            case 0x01:
                // type
                let typeDef = try parseCoreTypeDef()
                return .type(typeDef)
            case 0x02:
                // alias
                let sort = try parseCoreSort()
                _ = try stream.consumeAny()  // 0x01 for outer
                let count: UInt32 = try parseUnsigned()
                let idx: UInt32 = try parseUnsigned()
                return .alias(ComponentAlias(sort: .core(sort), target: .outer(count: count, index: idx)))
            case 0x03:
                // export decl
                let name = try stream.parseName()
                let desc = try parseCoreImportDesc()
                return .exportDecl(name: name, descriptor: desc)
            default:
                throw makeError(.malformedSectionID(kind))
            }
        }

        /// Parse core import descriptor.
        func parseCoreImportDesc() throws(WasmKitError) ->ImportDescriptor {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00:
                let idx: UInt32 = try parseUnsigned()
                return .function(idx)
            case 0x01:
                let elemType = try parseReferenceType()
                let limits = try parseLimits()
                return .table(TableType(elementType: elemType, limits: limits))
            case 0x02:
                let limits = try parseLimits()
                return .memory(limits)
            case 0x03:
                let valType = try parseCoreValueType()
                let mutability = try parseMutability()
                return .global(GlobalType(mutability: mutability, valueType: valType))
            default:
                throw makeError(.malformedSectionID(byte))
            }
        }

        /// Parse reference type.
        func parseReferenceType() throws(WasmKitError) ->ReferenceType {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x70: return .funcRef
            case 0x6F: return .externRef
            default:
                throw makeError(.malformedValueType(byte))
            }
        }

        /// Parse limits.
        func parseLimits() throws(WasmKitError) ->Limits {
            let flags = try stream.consumeAny()
            let hasMax = (flags & 0x01) != 0
            let min: UInt64 = try UInt64(parseUnsigned(UInt32.self))
            let max: UInt64? = hasMax ? try UInt64(parseUnsigned(UInt32.self)) : nil
            return Limits(min: min, max: max, isMemory64: false, shared: false)
        }

        /// Parse mutability.
        func parseMutability() throws(WasmKitError) ->Mutability {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00: return .constant
            case 0x01: return .variable
            default:
                throw makeError(.malformedMutability(byte))
            }
        }

        /// Parse canon section (section 8).
        func parseCanonSection() throws(WasmKitError) ->[CanonicalDefinition] {
            try parseVector {
                let kind = try stream.consumeAny()
                switch kind {
                case 0x00:
                    let sortMarker = try stream.consumeAny()
                    guard sortMarker == 0x00 else {
                        throw makeError(.malformedSectionID(sortMarker))
                    }
                    let funcIdx: UInt32 = try parseUnsigned()
                    let opts = try parseCanonicalOptions()
                    let typeIdx: UInt32 = try parseUnsigned()
                    return .lift(coreFuncIndex: funcIdx, options: opts, typeIndex: typeIdx)

                case 0x01:
                    let sortMarker = try stream.consumeAny()
                    guard sortMarker == 0x00 else {
                        throw makeError(.malformedSectionID(sortMarker))
                    }
                    let funcIdx: UInt32 = try parseUnsigned()
                    let opts = try parseCanonicalOptions()
                    return .lower(funcIndex: funcIdx, options: opts)

                case 0x02:
                    let typeIdx: UInt32 = try parseUnsigned()
                    return .resourceNew(typeIndex: typeIdx)

                case 0x03:
                    let typeIdx: UInt32 = try parseUnsigned()
                    return .resourceDrop(typeIndex: typeIdx)

                case 0x04:
                    let typeIdx: UInt32 = try parseUnsigned()
                    return .resourceRep(typeIndex: typeIdx)

                default:
                    // Skip other canon builtins for now
                    throw makeError(.malformedSectionID(kind))
                }
            }
        }

        /// Parse start section (section 9).
        func parseStartSection() throws(WasmKitError) ->ComponentStart {
            let funcIdx: UInt32 = try parseUnsigned()
            let args: [UInt32] = try parseVector { try parseUnsigned() }
            let resultCount: UInt32 = try parseUnsigned()
            return ComponentStart(funcIndex: funcIdx, args: args, resultCount: resultCount)
        }

        /// Parse import section (section 10).
        func parseImportSection() throws(WasmKitError) ->[ComponentImportDef] {
            try parseVector {
                let name = try parseImportExportName()
                let externDesc = try parseExternDesc()
                return ComponentImportDef(name: name, externDesc: externDesc)
            }
        }

        /// Parse export section (section 11).
        func parseExportSection() throws(WasmKitError) ->[ComponentExportDef] {
            try parseVector {
                let name = try parseImportExportName()
                let (sort, idx) = try parseSortIdx()
                // Parse optional extern desc
                // 0x00 = no extern desc present
                // 0x01-0x05 = extern desc type prefix
                let marker = try stream.peek() ?? 0
                let externDesc: ComponentExternDesc?
                if marker == 0x00 {
                    _ = try stream.consumeAny()  // consume the absence marker
                    externDesc = nil
                } else if marker >= 0x01 && marker <= 0x05 {
                    externDesc = try parseExternDesc()
                } else {
                    externDesc = nil
                }
                return ComponentExportDef(name: name, sort: sort, index: idx, externDesc: externDesc)
            }
        }

        /// Parse value section (section 12).
        func parseValueSection() throws(WasmKitError) ->[ComponentValueDef] {
            try parseVector {
                let valType = try parseValType()
                let len: UInt32 = try parseUnsigned()
                let valueBytes = try stream.consume(count: Int(len))
                return ComponentValueDef(type: valType, value: Array(valueBytes))
            }
        }
    }

    // MARK: - Main Parse Loop

    extension ComponentParser {
        /// Attempts to parse a chunk of the component binary stream.
        ///
        /// - Returns: A `ComponentParsingPayload` if parsing was successful, otherwise `nil`.
        public mutating func parseNext() throws(WasmKitError) ->ComponentParsingPayload? {
            switch nextParseTarget {
            case .header:
                let version = try parsePreamble()
                self.nextParseTarget = .section
                return .header(version: version)

            case .section:
                guard try !stream.hasReachedEnd() else {
                    return nil
                }

                let sectionRawID = try stream.consumeAny()
                let sectionSize: UInt32 = try parseUnsigned()
                let sectionStart = stream.currentIndex

                let payload: ComponentParsingPayload

                guard let sectionID = ComponentSectionID(rawValue: sectionRawID) else {
                    throw makeError(.malformedSectionID(sectionRawID))
                }

                switch sectionID {
                case .custom:
                    payload = .customSection(try parseCustomSection(size: sectionSize))

                case .coreModule:
                    let moduleBytes = try stream.consume(count: Int(sectionSize))
                    payload = .coreModule(moduleBytes)

                case .coreInstance:
                    payload = .coreInstanceSection(try parseCoreInstanceSection())

                case .coreType:
                    let coreTypes = try parseVector { try parseCoreTypeDef() }
                    payload = .coreTypeSection(coreTypes)

                case .component:
                    let componentBytes = try stream.consume(count: Int(sectionSize))
                    payload = .component(componentBytes)

                case .instance:
                    payload = .instanceSection(try parseInstanceSection())

                case .alias:
                    payload = .aliasSection(try parseAliasSection())

                case .type:
                    payload = .typeSection(try parseTypeSection())

                case .canon:
                    payload = .canonSection(try parseCanonSection())

                case .start:
                    payload = .startSection(try parseStartSection())

                case .import:
                    payload = .importSection(try parseImportSection())

                case .export:
                    payload = .exportSection(try parseExportSection())

                case .value:
                    payload = .valueSection(try parseValueSection())
                }

                let expectedSectionEnd = sectionStart + Int(sectionSize)
                guard expectedSectionEnd == stream.currentIndex else {
                    throw makeError(.sectionSizeMismatch(sectionID: sectionRawID, expected: expectedSectionEnd, actual: offset))
                }

                return payload
            }
        }
    }
#endif
