#if ComponentModel
    import WasmTypes
    import ComponentModel

    /// A streaming parser for WebAssembly Component Model binary format.
    /// For proposed production rules refer to https://github.com/WebAssembly/component-model/blob/7479890cb506d0f8f687595a4d41361ff8a2a194/design/mvp/Binary.md
    package struct ComponentParser<Source: ByteStreamSource> {
        @usableFromInline
        var stream: ByteStream<Source>
        @usableFromInline
        let features: WasmFeatureSet

        @usableFromInline
        enum NextParseTarget {
            case header
            case section
        }
        @usableFromInline
        var nextParseTarget: NextParseTarget

        package var offset: Int {
            return stream.currentIndex
        }

        package init(stream: Source, features: WasmFeatureSet = .default) {
            self.stream = ByteStream(stream)
            self.features = features
            self.nextParseTarget = .header
        }

        @usableFromInline
        internal func makeError(_ message: WasmParserError.Message) -> WasmParserError {
            return WasmParserError(message: message, offset: offset)
        }

        @usableFromInline
        internal func makeUnexpectedByteError(_ byte: UInt8, for context: String) -> WasmParserError {
            makeError(.init("invalid leading byte (0x\(String(byte, radix: 16))) for \(context)"))
        }
    }

    extension ComponentParser where Source == StaticByteStreamSource {
        /// Initialize a new parser with the given bytes
        ///
        /// - Parameters:
        ///   - bytes: The bytes of the WebAssembly component binary file to parse
        ///   - features: Enabled WebAssembly features for parsing
        package init(bytes: [UInt8], features: WasmFeatureSet = .default) {
            self.init(stream: StaticByteStreamSource(bytes: bytes), features: features)
        }
    }

    // MARK: - Component Parsing Payload

    /// The parsed output of a component section.
    package enum ComponentParsingPayload {
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
    package enum CoreTypeDef {
        /// A core function type
        case function(FunctionType)
        /// A core module type
        case module(CoreModuleType)
    }

    /// A core module type definition.
    package struct CoreModuleType {
        package var declarations: [CoreModuleDecl]

        package init(declarations: [CoreModuleDecl]) {
            self.declarations = declarations
        }
    }

    /// A declaration within a core module type.
    package enum CoreModuleDecl {
        case `import`(Import)
        case type(CoreTypeDef)
        case alias(CoreAlias)
        case exportDecl(name: String, descriptor: ImportDescriptor)
    }

    // MARK: - Component Type Definitions (Parser-specific - depends on CoreTypeDef)

    /// A component type definition (from binary section 7).
    package enum ComponentTypeDef {
        /// A defined value type
        case definedValue(ComponentDefValType)
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
    package struct ComponentTypeDecl {
        package var declarations: [ComponentOrInstanceDecl]

        package init(declarations: [ComponentOrInstanceDecl]) {
            self.declarations = declarations
        }
    }

    /// Declarations within an instance type.
    package struct InstanceTypeDecl {
        package var declarations: [InstanceDecl]

        package init(declarations: [InstanceDecl]) {
            self.declarations = declarations
        }
    }

    /// A declaration that can appear in a component type.
    package enum ComponentOrInstanceDecl {
        case importDecl(ComponentImportDecl)
        case instanceDecl(InstanceDecl)
    }

    /// A declaration that can appear in an instance type.
    package enum InstanceDecl {
        case coreType(CoreTypeDef)
        case type(ComponentTypeDef)
        case alias(ComponentAlias)
        case exportDecl(ComponentExportDecl)
    }

    // MARK: - Parser Implementation

    extension ComponentParser {
        /// Parse the component magic number and version.
        @usableFromInline
        mutating func parsePreamble() throws(WasmParserError) -> [UInt8] {
            // Magic number: 0x00 0x61 0x73 0x6D (same as core wasm)
            let magic = try stream.consume(count: 4)
            guard magic.elementsEqual(WASM_MAGIC) else {
                throw makeError(.invalidMagicNumber(.init(magic)))
            }

            // Version: 0x0d 0x00 (component model version 13)
            let version = try stream.consume(count: 2)
            guard version.elementsEqual([0x0d, 0x00]) else {
                throw makeError(.unknownVersion(Array(version)))
            }

            // Layer: 0x01 0x00 (indicates component, not module)
            let layer = try stream.consume(count: 2)
            guard layer.elementsEqual([0x01, 0x00]) else {
                throw makeError(.unknownVersion(Array(version) + Array(layer)))
            }

            return Array(version) + Array(layer)
        }

        @inlinable
        mutating func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws(WasmParserError) -> T {
            try stream.parseUnsigned(T.self)
        }

        @inlinable
        mutating func parseVector<Content>(
            content parser: (inout ComponentParser) throws(WasmParserError) -> Content
        ) throws(WasmParserError) -> [Content] {
            var contents = [Content]()
            let count: UInt32 = try parseUnsigned()
            for _ in 0..<count {
                try contents.append(parser(&self))
            }
            return contents
        }

        /// Parse a core sort discriminator.
        mutating func parseCoreSort() throws(WasmParserError) -> CoreDefSort {
            let byte = try stream.consumeAny()
            guard let sort = CoreDefSort(rawValue: byte) else {
                throw makeUnexpectedByteError(byte, for: "core sort")
            }
            return sort
        }

        /// Parse a component sort discriminator.
        mutating func parseSort() throws(WasmParserError) -> ComponentDefSort {
            let byte = try stream.consumeAny()
            guard let sort = ComponentSortOpcode(rawValue: byte) else {
                throw makeUnexpectedByteError(byte, for: "component sort")
            }
            switch sort {
            case .core: return .core(try parseCoreSort())
            case .function: return .func
            case .value: return .value
            case .type: return .type
            case .component: return .component
            case .instance: return .instance
            }
        }

        /// Parse a sort and index pair.
        mutating func parseSortIdx() throws(WasmParserError) -> (sort: ComponentDefSort, index: UInt32) {
            let sort = try parseSort()
            let index: UInt32 = try parseUnsigned()
            return (sort, index)
        }

        mutating func parseCanonicalOptions() throws(WasmParserError) -> [CanonicalOption] {
            try parseVector { p throws(WasmParserError) -> CanonicalOption in
                let byte = try p.stream.consumeAny()
                guard let tag = CanonOptionTag(rawValue: byte) else {
                    throw p.makeError(.unknownCanonOptionTag(byte))
                }
                switch tag {
                case .stringEncodingUtf8: return .utf8
                case .stringEncodingUtf16: return .utf16
                case .stringEncodingLatin1Utf16: return .latin1UTF16
                case .memory:
                    let idx: UInt32 = try p.parseUnsigned()
                    return .memory(memoryIndex: idx)
                case .realloc:
                    let idx: UInt32 = try p.parseUnsigned()
                    return .realloc(funcIndex: idx)
                case .postReturn:
                    let idx: UInt32 = try p.parseUnsigned()
                    return .postReturn(funcIndex: idx)
                case .async: return .async
                case .callback:
                    let idx: UInt32 = try p.parseUnsigned()
                    return .callback(funcIndex: idx)
                }
            }
        }

        /// Parse a value type (primitive or type index).
        mutating func parseValType() throws(WasmParserError) -> ComponentValType {
            let byte = try stream.peek() ?? 0
            // Type opcodes are negative SLEB128: single bytes in [0x64, 0x7F].
            // Type indices are non-negative SLEB128: single byte [0x00, 0x63]
            // or multi-byte with high bit set [0x80, 0xFF].
            if byte >= 0x64 && byte <= 0x7F {
                let opcode = try stream.consumeAny()
                guard let primitive = ComponentPrimValType(rawValue: opcode) else {
                    throw makeError(.malformedValueType(opcode))
                }
                return .primitive(primitive)
            } else {
                let idx: UInt32 = try parseUnsigned()
                return .index(ComponentTypeIndex(rawValue: Int(idx)))
            }
        }

        /// Parse an optional value type.
        mutating func parseOptionalValType() throws(WasmParserError) -> ComponentValType? {
            let present = try stream.consumeAny()
            if present == OptionalMarker.absent.rawValue {
                return nil
            } else {
                return try parseValType()
            }
        }

        /// Parse a defined value type.
        mutating func parseDefValType() throws(WasmParserError) -> ComponentDefValType {
            let byte = try stream.peek() ?? 0

            // Type indices are non-negative SLEB128: single byte [0x00, 0x63]
            // or multi-byte with high bit set [0x80, 0xFF].
            // Type/composite opcodes are in [0x64, 0x7F].
            if byte < 0x64 || byte >= 0x80 {
                let idx: UInt32 = try parseUnsigned()
                return .indexed(ComponentTypeIndex(rawValue: Int(idx)))
            }

            let opcode = try stream.consumeAny()

            // Primitive types (0x73...0x7f and 0x64 are not in CompositeValTypeOpcode)
            if let primitive = ComponentPrimValType(rawValue: opcode) {
                return .primitive(primitive)
            }

            guard let compositeType = CompositeValTypeOpcode(rawValue: opcode) else {
                throw makeError(.malformedValueType(opcode))
            }
            switch compositeType {
            case .record:
                let fields = try parseVector { p throws(WasmParserError) -> ComponentRecordField in
                    let name = try p.stream.parseName()
                    let valType = try p.parseValType()
                    return ComponentRecordField(name: name, type: valType)
                }
                return .record(fields)

            case .variant:
                let cases = try parseVector { p throws(WasmParserError) -> ComponentCaseField in
                    let name = try p.stream.parseName()
                    let valType = try p.parseOptionalValType()
                    let terminator = try p.stream.consumeAny()
                    guard terminator == OptionalMarker.absent.rawValue else {
                        throw p.makeUnexpectedByteError(terminator, for: "variant case terminator")
                    }
                    return ComponentCaseField(name: name, type: valType)
                }
                return .variant(cases)

            case .list:

                let valType = try parseValType()
                return .list(valType)

            case .tuple:
                return .tuple(try parseVector { p throws(WasmParserError) -> ComponentValType in try p.parseValType() })

            case .flags:
                let labels = try parseVector { p throws(WasmParserError) -> String in try p.stream.parseName() }
                return .flags(labels)

            case .enum:
                let labels = try parseVector { p throws(WasmParserError) -> String in try p.stream.parseName() }
                return .enum(labels)

            case .option:
                let someType = try parseValType()
                return .option(someType)

            case .result:
                let okIdx = try parseOptionalValType()
                let errIdx = try parseOptionalValType()
                return .result(ok: okIdx, error: errIdx)

            case .own:  // own
                let resourceIdx: UInt32 = try parseUnsigned()
                return .own(ResourceTypeIndex(rawValue: Int(resourceIdx)))

            case .borrow:  // borrow
                let resourceIdx: UInt32 = try parseUnsigned()
                return .borrow(ResourceTypeIndex(rawValue: Int(resourceIdx)))

            case .stream where features.contains(.componentModelAsync):  // stream
                let elemIdx = try parseOptionalValType()
                return .stream(element: elemIdx, end: nil)

            case .future where features.contains(.componentModelAsync):
                let elemIdx = try parseOptionalValType()
                return .future(elemIdx)

            default:
                throw makeError(.malformedValueType(opcode))
            }
        }

        /// Parse an extern descriptor.
        mutating func parseExternDesc() throws(WasmParserError) -> ComponentExternDesc {
            let byte = try stream.consumeAny()
            guard let kind = ExternDescKind(rawValue: byte) else {
                throw makeUnexpectedByteError(byte, for: "extern descriptor")
            }
            switch kind {
            case .coreModule:
                let moduleMarker = try stream.consumeAny()
                guard moduleMarker == CoreDefSort.module.rawValue else {
                    throw makeUnexpectedByteError(moduleMarker, for: "core module extern descriptor")
                }
                let idx: UInt32 = try parseUnsigned()
                return .coreModule(typeIndex: idx)
            case .function:
                let idx: UInt32 = try parseUnsigned()
                return .function(typeIndex: idx)
            case .value:
                let bound = try parseValueBound()
                return .value(bound)
            case .type:
                let bound = try parseTypeBound()
                return .type(bound)
            case .component:
                let idx: UInt32 = try parseUnsigned()
                return .component(typeIndex: idx)
            case .instance:
                let idx: UInt32 = try parseUnsigned()
                return .instance(typeIndex: idx)
            }
        }

        /// Parse a value bound.
        mutating func parseValueBound() throws(WasmParserError) -> ComponentValueBound {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00:
                let idx: UInt32 = try parseUnsigned()
                return .eq(valueIndex: idx)
            case 0x01:
                let valType = try parseValType()
                return .type(.inlined(valType))
            default:
                throw makeUnexpectedByteError(byte, for: "value bound")
            }
        }

        /// Parse a type bound.
        mutating func parseTypeBound() throws(WasmParserError) -> ComponentTypeBound {
            let byte = try stream.consumeAny()
            guard let bound = TypeBoundOpcode(rawValue: byte) else {
                throw makeUnexpectedByteError(byte, for: "type bound")
            }
            switch bound {
            case .eq:
                let idx: UInt32 = try parseUnsigned()
                return .eq(typeIndex: idx)
            case .subResource:
                return .subResource
            }
        }

        /// Parse an import/export name.
        mutating func parseImportExportName() throws(WasmParserError) -> String {
            let prefix = try stream.consumeAny()
            guard prefix == 0x00 || prefix == 0x01 else {
                throw makeError(.init("invalid import/export name prefix: 0x\(String(prefix, radix: 16))"))
            }
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

            // A 0x01 prefix is the legacy form of 0x00 and has no version suffix.
            return name
        }
    }

    // MARK: - Section Parsers

    extension ComponentParser {
        /// Parse a custom section.
        mutating func parseCustomSection(size: UInt32) throws(WasmParserError) -> CustomSection {
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
        mutating func parseCoreInstanceSection() throws(WasmParserError) -> [CoreInstanceDefinition] {
            try parseVector { p throws(WasmParserError) -> CoreInstanceDefinition in
                let kind = try p.stream.consumeAny()
                guard let form = InstanceForm(rawValue: kind) else {
                    throw p.makeUnexpectedByteError(kind, for: "core instance")
                }
                switch form {
                case .instantiate:
                    let moduleIdx: UInt32 = try p.parseUnsigned()
                    let args = try p.parseVector { q throws(WasmParserError) -> CoreInstantiateArg in
                        let name = try q.stream.parseName()
                        let marker = try q.stream.consumeAny()
                        guard marker == CoreDefSort.instance.rawValue else {
                            throw q.makeUnexpectedByteError(marker, for: "core instantiate argument")
                        }
                        let instanceIdx: UInt32 = try q.parseUnsigned()
                        return CoreInstantiateArg(name: name, instanceIndex: instanceIdx)
                    }
                    return .instantiate(moduleIndex: moduleIdx, args: args)
                case .inlineExports:
                    let exports = try p.parseVector { q throws(WasmParserError) -> CoreInlineExport in
                        let name = try q.stream.parseName()
                        let sort = try q.parseCoreSort()
                        let idx: UInt32 = try q.parseUnsigned()
                        return CoreInlineExport(name: name, sort: sort, index: idx)
                    }
                    return .exports(exports)
                }
            }
        }

        /// Parse component instance section (section 5).
        mutating func parseInstanceSection() throws(WasmParserError) -> [ComponentInstanceDefinition] {
            try parseVector { p throws(WasmParserError) -> ComponentInstanceDefinition in
                let kind = try p.stream.consumeAny()
                guard let form = InstanceForm(rawValue: kind) else {
                    throw p.makeUnexpectedByteError(kind, for: "component instance")
                }
                switch form {
                case .instantiate:
                    let componentIdx: UInt32 = try p.parseUnsigned()
                    let args = try p.parseVector { q throws(WasmParserError) -> ComponentInstantiateArg in
                        let name = try q.stream.parseName()
                        let (sort, idx) = try q.parseSortIdx()
                        return ComponentInstantiateArg(name: name, sort: sort, index: idx)
                    }
                    return .instantiate(componentIndex: componentIdx, args: args)
                case .inlineExports:
                    let exports = try p.parseVector { q throws(WasmParserError) -> ComponentInlineExport in
                        let name = try q.parseImportExportName()
                        let (sort, idx) = try q.parseSortIdx()
                        return ComponentInlineExport(name: name, sort: sort, index: idx)
                    }
                    return .exports(exports)
                }
            }
        }

        /// Parse alias section (section 6).
        mutating func parseAliasSection() throws(WasmParserError) -> [ComponentAlias] {
            try parseVector { p throws(WasmParserError) -> ComponentAlias in try p.parseSingleAlias() }
        }

        /// Parse type section (section 7).
        mutating func parseTypeSection() throws(WasmParserError) -> [ComponentTypeDef] {
            try parseVector { p throws(WasmParserError) -> ComponentTypeDef in
                try p.parseTypeDef()
            }
        }

        /// Parse a single type definition.
        mutating func parseTypeDef() throws(WasmParserError) -> ComponentTypeDef {
            let byte = try stream.peek() ?? 0

            // Check if it's a defined value type (primitive or composite)
            if byte >= 0x64 {
                let valType = try parseDefValType()
                return .definedValue(valType)
            }

            let opcode = try stream.consumeAny()
            switch DefinedTypeOpcode(rawValue: opcode) {
            case .funcSync?:
                return try parseFuncTypeBody(isAsync: false)

            case .funcAsync? where features.contains(.componentModelAsync):
                return try parseFuncTypeBody(isAsync: true)

            case .componentType?:
                let decls = try parseVector { p throws(WasmParserError) -> ComponentOrInstanceDecl in
                    try p.parseComponentOrInstanceDecl(isComponent: true)
                }
                return .component(ComponentTypeDecl(declarations: decls))

            case .instanceType?:
                let decls = try parseVector { p throws(WasmParserError) -> InstanceDecl in try p.parseInstanceDeclOnly() }
                return .instance(InstanceTypeDecl(declarations: decls))

            case .resourceSync?:
                _ = try stream.consumeAny()  // 0x7f rep type marker
                let hasDtor = try stream.consumeAny()
                let dtor: UInt32? = hasDtor == OptionalMarker.present.rawValue ? try parseUnsigned() : nil
                return .resource(destructor: dtor)

            default:
                throw makeUnexpectedByteError(opcode, for: "component type")
            }
        }

        /// Parse the body of a component function type (shared by sync `0x40` and async `0x43`).
        /// The two opcodes have byte-identical paramlist/resultlist encodings; only `isAsync` differs.
        mutating func parseFuncTypeBody(isAsync: Bool) throws(WasmParserError) -> ComponentTypeDef {
            let params = try parseVector { p throws(WasmParserError) -> ComponentFuncType.Param in
                let name = try p.stream.parseName()
                let valType = try p.parseValType()
                return ComponentFuncType.Param(name: name, type: .inlined(valType))
            }
            let result = try parseResultList()
            return .function(ComponentFuncType(params: params, result: result, isAsync: isAsync))
        }

        /// Parse a component function `resultlist`: `0x00 t:<valtype>` (one result) or
        /// `0x01 0x00` (empty named-results = no result). Shared by `parseFuncTypeBody`
        /// and the `task.return` async canon op. Non-zero named-result counts are rejected.
        mutating func parseResultList() throws(WasmParserError) -> ComponentDefValType? {
            let resultKind = try stream.consumeAny()
            guard let marker = ResultMarker(rawValue: resultKind) else {
                throw makeUnexpectedByteError(resultKind, for: "component function results")
            }
            switch marker {
            case .hasResult:
                return try .inlined(parseValType())
            case .namedResults:
                let count: UInt32 = try parseUnsigned()
                if count != 0 {
                    throw makeError(.init("named results must be empty, got count \(count)"))
                }
                return nil
            }
        }

        /// Parse component or instance declaration.
        mutating func parseComponentOrInstanceDecl(isComponent: Bool) throws(WasmParserError) -> ComponentOrInstanceDecl {
            let kind = try stream.consumeAny()
            switch TypeDeclTag(rawValue: kind) {
            case .import? where isComponent:
                let name = try parseImportExportName()
                let externDesc = try parseExternDesc()
                return .importDecl(ComponentImportDecl(name: name, externDesc: externDesc))
            default:
                // Parse as instance decl
                return try .instanceDecl(parseInstanceDecl(fromKind: kind))
            }
        }

        /// Parse instance declaration only.
        mutating func parseInstanceDeclOnly() throws(WasmParserError) -> InstanceDecl {
            let kind = try stream.consumeAny()
            return try parseInstanceDecl(fromKind: kind)
        }

        /// Parse instance declaration from kind byte.
        mutating func parseInstanceDecl(fromKind kind: UInt8) throws(WasmParserError) -> InstanceDecl {
            switch TypeDeclTag(rawValue: kind) {
            case .coreType?:
                let coreType = try parseCoreTypeDef()
                return .coreType(coreType)
            case .type?:
                let typeDef = try parseTypeDef()
                return .type(typeDef)
            case .alias?:
                let alias = try parseSingleAlias()
                return .alias(alias)
            case .export?:
                let name = try parseImportExportName()
                let externDesc = try parseExternDesc()
                return .exportDecl(ComponentExportDecl(name: name, externDesc: externDesc))
            default:
                throw makeUnexpectedByteError(kind, for: "instance declaration")
            }
        }

        mutating func parseSingleAlias() throws(WasmParserError) -> ComponentAlias {
            let sort = try parseSort()
            let targetKind = try stream.consumeAny()
            guard let targetOpcode = AliasTargetOpcode(rawValue: targetKind) else {
                throw makeUnexpectedByteError(targetKind, for: "alias target")
            }
            let target: ComponentAliasTarget
            switch targetOpcode {
            case .export:
                let instanceIdx: UInt32 = try parseUnsigned()
                let name = try stream.parseName()
                target = .export(instanceIndex: instanceIdx, name: name)
            case .coreExport:
                let instanceIdx: UInt32 = try parseUnsigned()
                let name = try stream.parseName()
                target = .coreExport(instanceIndex: instanceIdx, name: name)
            case .outer:
                let count: UInt32 = try parseUnsigned()
                let idx: UInt32 = try parseUnsigned()
                target = .outer(count: count, index: idx)
            }
            return ComponentAlias(sort: sort, target: target)
        }

        /// Parse a core type definition.
        mutating func parseCoreTypeDef() throws(WasmParserError) -> CoreTypeDef {
            let byte = try stream.peek() ?? 0
            if byte == DefinedTypeOpcode.coreModule.rawValue {
                _ = try stream.consumeAny()
                // Module type
                let decls = try parseVector { p throws(WasmParserError) -> CoreModuleDecl in try p.parseCoreModuleDecl() }
                return .module(CoreModuleType(declarations: decls))
            } else if byte == DefinedTypeOpcode.coreFunc.rawValue {
                // Function type
                _ = try stream.consumeAny()
                let params = try parseVector { p throws(WasmParserError) -> ValueType in try p.parseCoreValueType() }
                let results = try parseVector { p throws(WasmParserError) -> ValueType in try p.parseCoreValueType() }
                return .function(FunctionType(parameters: params, results: results))
            } else {
                throw makeUnexpectedByteError(byte, for: "core type")
            }
        }

        /// Parse core value type.
        mutating func parseCoreValueType() throws(WasmParserError) -> ValueType {
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
        mutating func parseCoreModuleDecl() throws(WasmParserError) -> CoreModuleDecl {
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
                return .alias(CoreAlias(sort: sort, target: .outer(count: count, index: idx)))
            case 0x03:
                // export decl
                let name = try stream.parseName()
                let desc = try parseCoreImportDesc()
                return .exportDecl(name: name, descriptor: desc)
            default:
                throw makeUnexpectedByteError(kind, for: "core module declaration")
            }
        }

        /// Parse core import descriptor.
        mutating func parseCoreImportDesc() throws(WasmParserError) -> ImportDescriptor {
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
            case 0x04 where features.contains(.exceptionHandling):
                let attribute: UInt8 = try parseUnsigned()
                guard attribute == 0 else { throw makeError(.invalidTagAttribute(attribute)) }
                let typeIndex: UInt32 = try parseUnsigned()
                return .tag(typeIndex)
            default:
                throw makeUnexpectedByteError(byte, for: "core import descriptor")
            }
        }

        /// Parse reference type.
        mutating func parseReferenceType() throws(WasmParserError) -> ReferenceType {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x69: return .exnRef
            case 0x70: return .funcRef
            case 0x6F: return .externRef
            default:
                throw makeError(.malformedValueType(byte))
            }
        }

        /// Parse limits.
        mutating func parseLimits() throws(WasmParserError) -> Limits {
            let flags = try stream.consumeAny()
            let hasMax = (flags & 0x01) != 0
            let min: UInt64 = try UInt64(parseUnsigned(UInt32.self))
            let max: UInt64? = hasMax ? try UInt64(parseUnsigned(UInt32.self)) : nil
            return Limits(min: min, max: max, isMemory64: false, shared: false)
        }

        /// Parse mutability.
        mutating func parseMutability() throws(WasmParserError) -> Mutability {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00: return .constant
            case 0x01: return .variable
            default:
                throw makeError(.malformedMutability(byte))
            }
        }

        /// Parse canon section (section 8).
        mutating func parseCanonSection() throws(WasmParserError) -> [CanonicalDefinition] {
            try parseVector { p throws(WasmParserError) -> CanonicalDefinition in
                let kind = try p.stream.consumeAny()
                switch CanonOpcode(rawValue: kind) {
                case .lift?:
                    let sortMarker = try p.stream.consumeAny()
                    guard sortMarker == CoreDefSort.func.rawValue else {
                        throw p.makeUnexpectedByteError(sortMarker, for: "canon core function sort")
                    }
                    let funcIdx: UInt32 = try p.parseUnsigned()
                    let opts = try p.parseCanonicalOptions()
                    let typeIdx: UInt32 = try p.parseUnsigned()
                    return .lift(coreFuncIndex: funcIdx, options: opts, typeIndex: typeIdx)

                case .lower?:
                    let sortMarker = try p.stream.consumeAny()
                    guard sortMarker == CoreDefSort.func.rawValue else {
                        throw p.makeUnexpectedByteError(sortMarker, for: "canon core function sort")
                    }
                    let funcIdx: UInt32 = try p.parseUnsigned()
                    let opts = try p.parseCanonicalOptions()
                    return .lower(funcIndex: funcIdx, options: opts)

                case .resourceNew?:
                    let typeIdx: UInt32 = try p.parseUnsigned()
                    return .resourceNew(typeIndex: typeIdx)

                case .resourceDrop?:
                    let typeIdx: UInt32 = try p.parseUnsigned()
                    return .resourceDrop(typeIndex: typeIdx)

                case .resourceRep?:
                    let typeIdx: UInt32 = try p.parseUnsigned()
                    return .resourceRep(typeIndex: typeIdx)

                case let opcode? where p.features.contains(.componentModelAsync) && opcode.isSupportedAsyncBuiltin:
                    let immediates = try p.parseAsyncCanonicalImmediates(for: opcode)
                    return .asyncBuiltin(AsyncCanonicalBuiltin(opcode: opcode, immediates: immediates))

                default:
                    throw p.makeUnexpectedByteError(kind, for: "canon definition")
                }
            }
        }

        /// Decode the immediate bytes following a supported async canon opcode.
        /// The opcode determines the shape (one arm per ``AsyncCanonicalImmediates`` case).
        mutating func parseAsyncCanonicalImmediates(for opcode: CanonOpcode) throws(WasmParserError) -> AsyncCanonicalImmediates {
            switch opcode {
            case .taskCancel, .subtaskDrop, .threadIndex, .waitableSetNew, .waitableSetDrop, .waitableJoin,
                .backpressureInc, .backpressureDec:
                return .none
            case .streamNew, .streamDropReadable, .streamDropWritable,
                .futureNew, .futureDropReadable, .futureDropWritable:
                return .type(try parseUnsigned())
            case .streamRead, .streamWrite, .futureRead, .futureWrite:
                let typeIndex: UInt32 = try parseUnsigned()
                return .typeWithOptions(typeIndex, options: try parseCanonicalOptions())
            case .streamCancelRead, .streamCancelWrite, .futureCancelRead, .futureCancelWrite:
                let typeIndex: UInt32 = try parseUnsigned()
                return .typeWithAsyncFlag(typeIndex, async: try parseFlagByte())
            case .subtaskCancel:
                return .asyncFlag(try parseFlagByte())
            case .threadYield, .threadSuspend:
                return .cancellableFlag(try parseFlagByte())
            case .waitableSetWait, .waitableSetPoll:
                let cancellable = try parseFlagByte()
                return .cancellableWithMemory(cancellable, memoryIndex: try parseUnsigned())
            case .taskReturn:
                return .resultListWithOptions(try parseResultList(), options: try parseCanonicalOptions())
            case .contextGetI32, .contextSetI32:
                let valueType = try parseContextValueType()
                return .context(valueType, slot: try parseUnsigned())
            case .threadNewIndirect:
                let typeIndex: UInt32 = try parseUnsigned()
                return .typeWithTable(typeIndex, tableIndex: try parseUnsigned())
            default:
                // Unreachable: the caller gates on `isSupportedAsyncBuiltin`.
                throw makeUnexpectedByteError(opcode.rawValue, for: "async canon built-in")
            }
        }

        /// Decode a single-byte `async?`/`cancel?` flag (`0x00` = false, `0x01` = true).
        mutating func parseFlagByte() throws(WasmParserError) -> Bool {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x00: return false
            case 0x01: return true
            default: throw makeUnexpectedByteError(byte, for: "flag")
            }
        }

        /// Decode the core value type byte of a `context.get`/`context.set` slot
        /// (`i32` = `0x7f`, `i64` = `0x7e`; ABI-restricted to these two).
        mutating func parseContextValueType() throws(WasmParserError) -> CanonicalContextValueType {
            let byte = try stream.consumeAny()
            switch byte {
            case 0x7f: return .i32
            case 0x7e: return .i64
            default: throw makeUnexpectedByteError(byte, for: "context value type")
            }
        }

        /// Parse start section (section 9).
        mutating func parseStartSection() throws(WasmParserError) -> ComponentStart {
            let funcIdx: UInt32 = try parseUnsigned()
            let args: [UInt32] = try parseVector { p throws(WasmParserError) -> UInt32 in try p.parseUnsigned() }
            let resultCount: UInt32 = try parseUnsigned()
            return ComponentStart(funcIndex: funcIdx, args: args, resultCount: resultCount)
        }

        /// Parse import section (section 10).
        mutating func parseImportSection() throws(WasmParserError) -> [ComponentImportDef] {
            try parseVector { p throws(WasmParserError) -> ComponentImportDef in
                let name = try p.parseImportExportName()
                let externDesc = try p.parseExternDesc()
                return ComponentImportDef(name: name, externDesc: externDesc)
            }
        }

        /// Parse export section (section 11).
        mutating func parseExportSection() throws(WasmParserError) -> [ComponentExportDef] {
            try parseVector { p throws(WasmParserError) -> ComponentExportDef in
                let name = try p.parseImportExportName()
                let (sort, idx) = try p.parseSortIdx()
                let marker = try p.stream.consumeAny()
                guard let ascription = OptionalMarker(rawValue: marker) else {
                    throw p.makeUnexpectedByteError(marker, for: "export type ascription")
                }
                let externDesc: ComponentExternDesc?
                switch ascription {
                case .absent: externDesc = nil
                case .present: externDesc = try p.parseExternDesc()
                }
                return ComponentExportDef(name: name, sort: sort, index: idx, externDesc: externDesc)
            }
        }

        /// Parse value section (section 12).
        mutating func parseValueSection() throws(WasmParserError) -> [ComponentValueDef] {
            try parseVector { p throws(WasmParserError) -> ComponentValueDef in
                let valType = try p.parseValType()
                let len: UInt32 = try p.parseUnsigned()
                let valueBytes = try p.stream.consume(count: Int(len))
                return ComponentValueDef(type: .inlined(valType), value: Array(valueBytes))
            }
        }
    }

    // MARK: - Main Parse Loop

    extension ComponentParser {
        /// Attempts to parse a chunk of the component binary stream.
        ///
        /// - Returns: A `ComponentParsingPayload` if parsing was successful, otherwise `nil`.
        package mutating func parseNext() throws(WasmParserError) -> ComponentParsingPayload? {
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
                    let coreTypes = try parseVector { p throws(WasmParserError) -> CoreTypeDef in try p.parseCoreTypeDef() }
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
