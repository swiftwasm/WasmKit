#if ComponentModel
    import ComponentModel
    package import WAT
    import WIT

    /// Serializes WIT world definitions into the component-type custom section
    /// binary format for WasmKit component linking.
    package enum ComponentTypeSerializer {

        package enum Error: Swift.Error, Equatable {
            case worldNotFound(String)
            case unsupportedFeature(String)
        }

        /// Encode a WIT world as a component-type custom section payload.
        ///
        /// The returned bytes form a complete component binary (header + sections)
        /// suitable for embedding as a `"component-type"` custom section in a core
        /// Wasm module.
        package static func encodeComponentType(
            context: SemanticsContext,
            worldName: String,
            encodingVersion: UInt32 = 4
        ) throws -> [UInt8] {
            guard let (world, _) = findWorld(name: worldName, in: context) else {
                throw Error.worldNotFound(worldName)
            }

            let pkgName = context.rootPackage.packageName
            let fqWorldName = "\(pkgName.namespace.text):\(pkgName.name.text)/\(worldName)"

            var encoder = Encoder()

            // Component header (8 bytes)
            encoder.output.append(contentsOf: [
                0x00, 0x61, 0x73, 0x6D,  // magic
                0x0D, 0x00,  // version 13
                0x01, 0x00,  // layer 1 (component)
            ])

            // Custom section: wit-component-encoding + version
            encoder.section(id: ComponentSectionID.custom.rawValue) { enc in
                enc.encode("wit-component-encoding")
                enc.writeUnsignedLEB128(encodingVersion)
            }

            // Type section: 1 outer componenttype
            try encoder.section(id: ComponentSectionID.type.rawValue) { enc in
                enc.writeUnsignedLEB128(UInt32(1))
                try encodeOuterComponentType(
                    world: world.syntax,
                    fqWorldName: fqWorldName,
                    context: context,
                    encoder: &enc
                )
            }

            // Export section: world short name → type 0
            encoder.section(id: ComponentSectionID.export.rawValue) { enc in
                enc.writeUnsignedLEB128(UInt32(1))
                encodeImportExportName(worldName, encoder: &enc)
                enc.output.append(ComponentSortOpcode.type.rawValue)
                enc.writeUnsignedLEB128(UInt32(0))
                enc.output.append(0x00)  // externdesc absent (0x00 marker per Binary.md export section)
            }

            return encoder.output
        }

        // MARK: - World lookup

        private static func findWorld(
            name: String,
            in context: SemanticsContext
        ) -> (world: SyntaxNode<WorldSyntax>, sourceFile: SyntaxNode<SourceFileSyntax>)? {
            for sourceFile in context.rootPackage.sourceFiles {
                for case .world(let world) in sourceFile.items {
                    if world.name.text == name {
                        return (world, sourceFile)
                    }
                }
            }
            return nil
        }

        // MARK: - Outer componenttype

        /// Encodes the outer componenttype: [type(inner), export(fq-name → component(0))]
        private static func encodeOuterComponentType(
            world: WorldSyntax,
            fqWorldName: String,
            context: SemanticsContext,
            encoder: inout Encoder
        ) throws {
            encoder.output.append(DefinedTypeOpcode.componentType.rawValue)  // 0x41
            encoder.writeUnsignedLEB128(UInt32(2))  // 2 declarations

            // Decl 0: type(inner componenttype)
            encoder.output.append(TypeDeclTag.type.rawValue)  // 0x01
            try encodeWorldComponentType(world: world, context: context, encoder: &encoder)

            // Decl 1: export(fq-name → component(0))
            encoder.output.append(TypeDeclTag.export.rawValue)  // 0x04
            encodeImportExportName(fqWorldName, encoder: &encoder)
            encoder.output.append(ExternDescKind.component.rawValue)  // 0x04
            encoder.writeUnsignedLEB128(UInt32(0))
        }

        // MARK: - Inner componenttype (the world)

        private static func encodeWorldComponentType(
            world: WorldSyntax,
            context: SemanticsContext,
            encoder: inout Encoder
        ) throws {
            var declEncoder = Encoder()
            var declCount: UInt32 = 0
            var nextTypeIndex: UInt32 = 0
            var worldNamedTypes: [String: UInt32] = [:]

            for item in world.items {
                switch item {
                case .import(let importSyntax):
                    try encodeWorldExtern(
                        kind: importSyntax.kind,
                        isImport: true,
                        context: context,
                        worldNamedTypes: &worldNamedTypes,
                        encoder: &declEncoder,
                        declCount: &declCount,
                        nextTypeIndex: &nextTypeIndex
                    )
                case .export(let exportSyntax):
                    try encodeWorldExtern(
                        kind: exportSyntax.kind,
                        isImport: false,
                        context: context,
                        worldNamedTypes: &worldNamedTypes,
                        encoder: &declEncoder,
                        declCount: &declCount,
                        nextTypeIndex: &nextTypeIndex
                    )
                case .type(let typeDefNode):
                    let typeDef = typeDefNode.syntax
                    declEncoder.output.append(TypeDeclTag.type.rawValue)
                    try encodeTypeDefBody(typeDef.body, namedTypes: worldNamedTypes, encoder: &declEncoder)
                    worldNamedTypes[typeDef.name.text] = nextTypeIndex
                    nextTypeIndex += 1
                    declCount += 1

                    declEncoder.output.append(TypeDeclTag.export.rawValue)
                    encodeImportExportName(typeDef.name.text, encoder: &declEncoder)
                    declEncoder.output.append(ExternDescKind.type.rawValue)
                    declEncoder.output.append(TypeBoundOpcode.eq.rawValue)
                    declEncoder.writeUnsignedLEB128(worldNamedTypes[typeDef.name.text]!)
                    declCount += 1
                case .use:
                    throw Error.unsupportedFeature("use in world")
                case .include:
                    throw Error.unsupportedFeature("include in world")
                }
            }

            encoder.output.append(DefinedTypeOpcode.componentType.rawValue)  // 0x41
            encoder.writeUnsignedLEB128(declCount)
            encoder.output.append(contentsOf: declEncoder.output)
        }

        // MARK: - World import/export encoding

        private static func encodeWorldExtern(
            kind: ExternKindSyntax,
            isImport: Bool,
            context: SemanticsContext,
            worldNamedTypes: inout [String: UInt32],
            encoder: inout Encoder,
            declCount: inout UInt32,
            nextTypeIndex: inout UInt32
        ) throws {
            let tag: UInt8 = isImport ? TypeDeclTag.import.rawValue : TypeDeclTag.export.rawValue

            switch kind {
            case .interface(let name, let items):
                let typeIdx = nextTypeIndex
                encoder.output.append(TypeDeclTag.type.rawValue)
                try encodeInstanceType(items: items, encoder: &encoder)
                nextTypeIndex += 1
                declCount += 1

                encoder.output.append(tag)
                encodeImportExportName(name.text, encoder: &encoder)
                encoder.output.append(ExternDescKind.instance.rawValue)
                encoder.writeUnsignedLEB128(typeIdx)
                declCount += 1

            case .path(let path):
                let (iface, fqName) = try resolveInterfacePath(path, context: context)
                let typeIdx = nextTypeIndex
                encoder.output.append(TypeDeclTag.type.rawValue)
                try encodeInstanceType(items: iface.items, encoder: &encoder)
                nextTypeIndex += 1
                declCount += 1

                encoder.output.append(tag)
                encodeImportExportName(fqName, encoder: &encoder)
                encoder.output.append(ExternDescKind.instance.rawValue)
                encoder.writeUnsignedLEB128(typeIdx)
                declCount += 1

            case .function(let name, let funcSyntax):
                let typeIdx = nextTypeIndex
                encoder.output.append(TypeDeclTag.type.rawValue)
                try encodeFuncType(funcSyntax, namedTypes: worldNamedTypes, encoder: &encoder)
                nextTypeIndex += 1
                declCount += 1

                encoder.output.append(tag)
                encodeImportExportName(name.text, encoder: &encoder)
                encoder.output.append(ExternDescKind.function.rawValue)
                encoder.writeUnsignedLEB128(typeIdx)
                declCount += 1
            }
        }

        // MARK: - Interface path resolution

        private static func resolveInterfacePath(
            _ path: UsePathSyntax,
            context: SemanticsContext
        ) throws -> (interface: SyntaxNode<InterfaceSyntax>, fullyQualifiedName: String) {
            switch path {
            case .id(let id):
                let (iface, _) = try context.lookupInterface(
                    name: id.text,
                    contextPackage: context.rootPackage
                )
                let pkg = context.rootPackage.packageName
                let fqName = "\(pkg.namespace.text):\(pkg.name.text)/\(id.text)"
                return (iface, fqName)

            case .package(let pkgName, let id):
                let fqName = "\(pkgName.namespace.text):\(pkgName.name.text)/\(id.text)"
                let rootPkg = context.rootPackage.packageName
                guard
                    rootPkg.namespace.text == pkgName.namespace.text
                        && rootPkg.name.text == pkgName.name.text
                else {
                    throw Error.unsupportedFeature("cross-package interface reference: \(fqName)")
                }
                let (iface, _) = try context.lookupInterface(
                    name: id.text,
                    contextPackage: context.rootPackage
                )
                return (iface, fqName)
            }
        }

        // MARK: - Instance type encoding (for WIT interfaces)

        private static func encodeInstanceType(
            items: [InterfaceItemSyntax],
            encoder: inout Encoder
        ) throws {
            var declEncoder = Encoder()
            var declCount: UInt32 = 0
            var nextTypeIndex: UInt32 = 0
            var localNamedTypes: [String: UInt32] = [:]

            for item in items {
                switch item {
                case .typeDef(let typeDefNode):
                    let typeDef = typeDefNode.syntax
                    declEncoder.output.append(TypeDeclTag.type.rawValue)
                    try encodeTypeDefBody(typeDef.body, namedTypes: localNamedTypes, encoder: &declEncoder)
                    localNamedTypes[typeDef.name.text] = nextTypeIndex
                    nextTypeIndex += 1
                    declCount += 1

                    declEncoder.output.append(TypeDeclTag.export.rawValue)
                    encodeImportExportName(typeDef.name.text, encoder: &declEncoder)
                    declEncoder.output.append(ExternDescKind.type.rawValue)
                    declEncoder.output.append(TypeBoundOpcode.eq.rawValue)
                    declEncoder.writeUnsignedLEB128(localNamedTypes[typeDef.name.text]!)
                    declCount += 1

                case .function(let funcNode):
                    let funcSyntax = funcNode.syntax
                    let typeIdx = nextTypeIndex
                    declEncoder.output.append(TypeDeclTag.type.rawValue)
                    try encodeFuncType(funcSyntax.function, namedTypes: localNamedTypes, encoder: &declEncoder)
                    nextTypeIndex += 1
                    declCount += 1

                    declEncoder.output.append(TypeDeclTag.export.rawValue)
                    encodeImportExportName(funcSyntax.name.text, encoder: &declEncoder)
                    declEncoder.output.append(ExternDescKind.function.rawValue)
                    declEncoder.writeUnsignedLEB128(typeIdx)
                    declCount += 1

                case .use:
                    throw Error.unsupportedFeature("use in interface")
                }
            }

            encoder.output.append(DefinedTypeOpcode.instanceType.rawValue)  // 0x42
            encoder.writeUnsignedLEB128(declCount)
            encoder.output.append(contentsOf: declEncoder.output)
        }

        // MARK: - Function type encoding

        private static func encodeFuncType(
            _ function: FunctionSyntax,
            namedTypes: [String: UInt32],
            encoder: inout Encoder
        ) throws {
            encoder.output.append(DefinedTypeOpcode.funcSync.rawValue)  // 0x40

            // Parameters
            encoder.writeUnsignedLEB128(UInt32(function.parameters.count))
            for param in function.parameters {
                encoder.encode(param.name.text)
                try encodeValType(param.type, namedTypes: namedTypes, encoder: &encoder)
            }

            // Results
            switch function.results {
            case .anon(let type):
                encoder.output.append(ResultMarker.hasResult.rawValue)  // 0x00
                try encodeValType(type, namedTypes: namedTypes, encoder: &encoder)
            case .named(let params):
                encoder.output.append(ResultMarker.namedResults.rawValue)  // 0x01
                encoder.writeUnsignedLEB128(UInt32(params.count))
                for param in params {
                    encoder.encode(param.name.text)
                    try encodeValType(param.type, namedTypes: namedTypes, encoder: &encoder)
                }
            }
        }

        // MARK: - Value type encoding

        private static func encodeValType(
            _ typeRepr: TypeReprSyntax,
            namedTypes: [String: UInt32],
            encoder: inout Encoder
        ) throws {
            switch typeRepr {
            // Primitives
            case .bool: encoder.output.append(PrimitiveValTypeOpcode.bool.rawValue)
            case .s8: encoder.output.append(PrimitiveValTypeOpcode.s8.rawValue)
            case .u8: encoder.output.append(PrimitiveValTypeOpcode.u8.rawValue)
            case .s16: encoder.output.append(PrimitiveValTypeOpcode.s16.rawValue)
            case .u16: encoder.output.append(PrimitiveValTypeOpcode.u16.rawValue)
            case .s32: encoder.output.append(PrimitiveValTypeOpcode.s32.rawValue)
            case .u32: encoder.output.append(PrimitiveValTypeOpcode.u32.rawValue)
            case .s64: encoder.output.append(PrimitiveValTypeOpcode.s64.rawValue)
            case .u64: encoder.output.append(PrimitiveValTypeOpcode.u64.rawValue)
            case .float32: encoder.output.append(PrimitiveValTypeOpcode.float32.rawValue)
            case .float64: encoder.output.append(PrimitiveValTypeOpcode.float64.rawValue)
            case .char: encoder.output.append(PrimitiveValTypeOpcode.char.rawValue)
            case .string: encoder.output.append(PrimitiveValTypeOpcode.string.rawValue)

            // Named type reference
            case .name(let id):
                if let idx = namedTypes[id.text] {
                    encoder.writeUnsignedLEB128(idx)
                } else {
                    switch id.text {
                    case "f32": encoder.output.append(PrimitiveValTypeOpcode.float32.rawValue)
                    case "f64": encoder.output.append(PrimitiveValTypeOpcode.float64.rawValue)
                    default:
                        throw Error.unsupportedFeature("unknown type reference: \(id.text)")
                    }
                }

            // Composite inline types
            case .list(let elem):
                encoder.output.append(CompositeValTypeOpcode.list.rawValue)
                try encodeValType(elem, namedTypes: namedTypes, encoder: &encoder)

            case .option(let inner):
                encoder.output.append(CompositeValTypeOpcode.option.rawValue)
                try encodeValType(inner, namedTypes: namedTypes, encoder: &encoder)

            case .result(let resultSyntax):
                encoder.output.append(CompositeValTypeOpcode.result.rawValue)
                if let ok = resultSyntax.ok {
                    encoder.output.append(OptionalMarker.present.rawValue)
                    try encodeValType(ok, namedTypes: namedTypes, encoder: &encoder)
                } else {
                    encoder.output.append(OptionalMarker.absent.rawValue)
                }
                if let err = resultSyntax.error {
                    encoder.output.append(OptionalMarker.present.rawValue)
                    try encodeValType(err, namedTypes: namedTypes, encoder: &encoder)
                } else {
                    encoder.output.append(OptionalMarker.absent.rawValue)
                }

            case .tuple(let elems):
                encoder.output.append(CompositeValTypeOpcode.tuple.rawValue)
                encoder.writeUnsignedLEB128(UInt32(elems.count))
                for elem in elems {
                    try encodeValType(elem, namedTypes: namedTypes, encoder: &encoder)
                }

            case .handle, .future, .stream:
                throw Error.unsupportedFeature("handle/future/stream types not yet supported")
            }
        }

        // MARK: - Type definition body encoding

        private static func encodeTypeDefBody(
            _ body: TypeDefBodySyntax,
            namedTypes: [String: UInt32],
            encoder: inout Encoder
        ) throws {
            switch body {
            case .record(let recordSyntax):
                encoder.output.append(CompositeValTypeOpcode.record.rawValue)
                encoder.writeUnsignedLEB128(UInt32(recordSyntax.fields.count))
                for field in recordSyntax.fields {
                    encoder.encode(field.name.text)
                    try encodeValType(field.type, namedTypes: namedTypes, encoder: &encoder)
                }

            case .enum(let enumSyntax):
                encoder.output.append(CompositeValTypeOpcode.enum.rawValue)
                encoder.writeUnsignedLEB128(UInt32(enumSyntax.cases.count))
                for enumCase in enumSyntax.cases {
                    encoder.encode(enumCase.name.text)
                }

            case .flags(let flagsSyntax):
                encoder.output.append(CompositeValTypeOpcode.flags.rawValue)
                encoder.writeUnsignedLEB128(UInt32(flagsSyntax.flags.count))
                for flag in flagsSyntax.flags {
                    encoder.encode(flag.name.text)
                }

            case .variant(let variantSyntax):
                encoder.output.append(CompositeValTypeOpcode.variant.rawValue)
                encoder.writeUnsignedLEB128(UInt32(variantSyntax.cases.count))
                for variantCase in variantSyntax.cases {
                    encoder.encode(variantCase.name.text)
                    if let type = variantCase.type {
                        encoder.output.append(OptionalMarker.present.rawValue)
                        try encodeValType(type, namedTypes: namedTypes, encoder: &encoder)
                    } else {
                        encoder.output.append(OptionalMarker.absent.rawValue)
                    }
                    encoder.output.append(0x00)  // refines: none
                }

            case .alias(let aliasSyntax):
                try encodeValType(aliasSyntax.typeRepr, namedTypes: namedTypes, encoder: &encoder)

            case .resource:
                throw Error.unsupportedFeature("resource types not yet supported")
            case .union:
                throw Error.unsupportedFeature("union types not yet supported")
            }
        }

        // MARK: - Import/export name encoding

        private static func encodeImportExportName(
            _ name: String,
            encoder: inout Encoder
        ) {
            encoder.output.append(NameVariant.plain.rawValue)  // 0x00
            encoder.encode(name)
        }
    }

#endif
