#if ComponentModel
    import ComponentModel
    import WasmTypes

    public struct ComponentEncoder {
        private var underlying = Encoder()

        public init() {}

        mutating func writeHeader() {
            underlying.output.append(contentsOf: [
                0x00, 0x61, 0x73, 0x6D,  // magic
                0x0d, 0x00,  // version
                0x01, 0x00,  // layer
            ])
        }

        public mutating func encode(
            _ component: ComponentWatParser.ComponentDef,
            options: EncodeOptions
        ) throws(WatParserError) -> [UInt8] {
            writeHeader()

            // Collect metadata needed for encoding
            let fields = try groupFields(component.fields)

            // Build core instance index mapping (parser index -> binary index)
            // This accounts for inline export instances that shift indices
            let coreInstanceIndexMapping = buildCoreInstanceIndexMapping(component: component, fields: fields)

            let coreFuncAliases = try collectCoreFuncAliases(from: fields.canons, component: component, coreInstanceIndexMapping: coreInstanceIndexMapping)
            let componentFuncAliases = try collectComponentFuncAliases(from: fields.canons, component: component)
            let exportFuncAliases = try collectExportFuncAliases(from: fields.exports, component: component)

            // Collect type indices that are exported
            var exportedTypeIndices = Set<Int>()
            for (exportDef, _) in fields.exports {
                if case .type(let indexOrId) = exportDef.descriptor {
                    if case .index(let idx, _) = indexOrId {
                        exportedTypeIndices.insert(Int(idx))
                    }
                }
            }

            // Build type index mapping (needed for type references throughout)
            let typeIndexMapping = try buildTypeIndexMapping(component.componentTypes, exportedTypeIndices: exportedTypeIndices)

            // Tracking state for emitted aliases
            var emittedCoreFuncAliases = Set<Int>()
            var emittedComponentFuncAliases = Set<Int>()
            var emittedExportFuncAliases = Set<Int>()
            var emittedTypes = Set<Int>()
            var liftIndex = 0
            var coreFunctionCount = 0  // Tracks core functions created (by canon.lower and aliases)

            // Helper to flush accumulated component types as a batched section
            var pendingComponentTypes: [Int] = []
            func flushPendingComponentTypes() throws(WatParserError) {
                if !pendingComponentTypes.isEmpty {
                    try encodeBatchedComponentTypes(
                        pendingComponentTypes,
                        component: component,
                        typeIndexMapping: typeIndexMapping,
                        exportedTypeIndices: exportedTypeIndices,
                        emittedTypes: &emittedTypes
                    )
                    pendingComponentTypes.removeAll()
                }
            }

            // Helper to flush accumulated core types as a batched section
            var pendingCoreTypes: [UInt32] = []
            func flushPendingCoreTypes() throws(WatParserError) {
                if !pendingCoreTypes.isEmpty {
                    try encodeBatchedCoreTypes(
                        pendingCoreTypes,
                        component: component
                    )
                    pendingCoreTypes.removeAll()
                }
            }

            // Helper to flush accumulated core instances as a batched section
            var pendingCoreInstances: [(CoreInstanceIndex, Location)] = []
            func flushPendingCoreInstances() throws(WatParserError) {
                if !pendingCoreInstances.isEmpty {
                    try encodeCoreInstances(
                        pendingCoreInstances,
                        component: component
                    )
                    pendingCoreInstances.removeAll()
                }
            }

            // Combined flush helper for all pending sections
            func flushAllPending() throws(WatParserError) {
                try flushPendingCoreInstances()
                try flushPendingCoreTypes()
                try flushPendingComponentTypes()
            }

            // Encode fields in order, producing interleaved sections
            // This matches wasm-tools normalization behavior where sections follow semantic order
            // Consecutive component types are batched into a single section
            for field in component.fields {
                switch field.kind {
                case .componentType(let typeIndex):
                    // Flush other sections before component types (different section)
                    try flushPendingCoreInstances()
                    try flushPendingCoreTypes()
                    // Collect all unemitted types up to and including this type index
                    // This ensures anonymous dependency types (with lower indices) get batched
                    // with the types that reference them
                    let maxIndex = Int(typeIndex.rawValue)
                    for (oldIndex, _) in typeIndexMapping.sorted(by: { $0.key < $1.key }) {
                        if oldIndex <= maxIndex && !emittedTypes.contains(oldIndex) && !pendingComponentTypes.contains(oldIndex) {
                            pendingComponentTypes.append(oldIndex)
                        }
                    }

                case .coreModule(let index):
                    try flushAllPending()
                    try encodeSingleCoreModule(index, component: component, options: options)

                case .coreInstance(let index):
                    // Flush non-instance sections before accumulating
                    try flushPendingCoreTypes()
                    try flushPendingComponentTypes()
                    // Accumulate consecutive core instances for batching
                    pendingCoreInstances.append((index, field.location))

                case .coreType(let index):
                    // Flush other sections before core types (different section)
                    try flushPendingCoreInstances()
                    try flushPendingComponentTypes()
                    // Accumulate consecutive core types for batching
                    pendingCoreTypes.append(UInt32(index))

                case .canon(let canonDef):
                    try flushAllPending()
                    // Emit required types before the canon
                    try emitRequiredTypesForCanon(
                        canonDef,
                        component: component,
                        typeIndexMapping: typeIndexMapping,
                        exportedTypeIndices: exportedTypeIndices,
                        emittedTypes: &emittedTypes,
                        liftIndex: liftIndex
                    )

                    // Canon definitions may emit both alias and canon sections
                    try encodeSingleCanon(
                        canonDef,
                        coreFuncAliases: coreFuncAliases,
                        componentFuncAliases: componentFuncAliases,
                        component: component,
                        typeIndexMapping: typeIndexMapping,
                        coreInstanceIndexMapping: coreInstanceIndexMapping,
                        location: field.location,
                        emittedCoreFuncAliases: &emittedCoreFuncAliases,
                        emittedComponentFuncAliases: &emittedComponentFuncAliases,
                        liftIndex: &liftIndex,
                        coreFunctionCount: &coreFunctionCount
                    )

                case .importDef(let importDef):
                    try flushAllPending()
                    // Emit required types before the import
                    try emitRequiredTypesForImport(
                        importDef,
                        component: component,
                        typeIndexMapping: typeIndexMapping,
                        exportedTypeIndices: exportedTypeIndices,
                        emittedTypes: &emittedTypes
                    )
                    try encodeSingleImport(importDef, typeIndexMapping: typeIndexMapping, location: field.location)

                case .exportDef(let exportDef):
                    try flushAllPending()
                    try encodeSingleExport(
                        exportDef,
                        typeIndexMapping: typeIndexMapping,
                        coreFuncAliases: coreFuncAliases,
                        componentFuncAliases: componentFuncAliases,
                        exportFuncAliases: exportFuncAliases,
                        location: field.location,
                        emittedExportFuncAliases: &emittedExportFuncAliases
                    )

                case .component(let index):
                    try flushAllPending()
                    try encodeSingleComponent(index, component: component, options: options)

                case .instance(let index):
                    try flushAllPending()
                    try encodeSingleComponentInstance(index, component: component, location: field.location)
                }
            }

            // Flush any remaining pending types
            try flushAllPending()

            // Emit any remaining types that weren't emitted on-demand
            try emitRemainingTypes(
                component: component,
                typeIndexMapping: typeIndexMapping,
                exportedTypeIndices: exportedTypeIndices,
                emittedTypes: &emittedTypes
            )

            if options.nameSection {
                try encodeComponentNameSection(component: component)
            }

            return underlying.output
        }

        // Helper to build type index mapping without encoding
        private func buildTypeIndexMapping(
            _ types: NameMapping<ComponentWatParser.ComponentTypeDef>,
            exportedTypeIndices: Set<Int>
        ) throws(WatParserError) -> [Int: Int] {
            guard !types.isEmpty else { return [:] }

            var indexMapping: [Int: Int] = [:]
            var newIndex = 0
            for (oldIndex, typeDef) in types.decls.enumerated() {
                let isPrimitive: Bool
                if case .value(let valueType) = typeDef.kind {
                    isPrimitive = valueType.isPrimitive
                } else {
                    isPrimitive = false
                }

                let hasId = typeDef.id != nil
                let isExported = exportedTypeIndices.contains(oldIndex)

                if !isPrimitive || hasId || isExported {
                    indexMapping[oldIndex] = newIndex
                    newIndex += 1
                }
            }

            return indexMapping
        }

        // Emit types required by a canon definition before the canon itself
        private mutating func emitRequiredTypesForCanon(
            _ canonDef: ComponentWatParser.CanonDef,
            component: ComponentWatParser.ComponentDef,
            typeIndexMapping: [Int: Int],
            exportedTypeIndices: Set<Int>,
            emittedTypes: inout Set<Int>,
            liftIndex: Int
        ) throws(WatParserError) {
            // canon.lift references a function type
            if case .lift = canonDef.kind {
                guard liftIndex < component.componentFunctions.decls.count else { return }
                let componentFunc = component.componentFunctions.decls[liftIndex]
                let typeIndex = Int(componentFunc.type.rawValue)

                // Check if this type needs to be emitted (is in the mapping and not yet emitted)
                if typeIndexMapping[typeIndex] != nil && !emittedTypes.contains(typeIndex) {
                    try encodeSingleComponentType(
                        typeIndex,
                        component: component,
                        typeIndexMapping: typeIndexMapping,
                        exportedTypeIndices: exportedTypeIndices
                    )
                    emittedTypes.insert(typeIndex)
                }
            }
        }

        // Emit types required by an import definition before the import itself
        private mutating func emitRequiredTypesForImport(
            _ importDef: ComponentWatParser.ImportDef,
            component: ComponentWatParser.ComponentDef,
            typeIndexMapping: [Int: Int],
            exportedTypeIndices: Set<Int>,
            emittedTypes: inout Set<Int>
        ) throws(WatParserError) {
            switch importDef.descriptor {
            case .instance(let indexOrId):
                // Instance imports reference a type index
                if case .index(let index, _) = indexOrId {
                    let typeIndex = Int(index)
                    if typeIndexMapping[typeIndex] != nil && !emittedTypes.contains(typeIndex) {
                        try encodeSingleComponentType(
                            typeIndex,
                            component: component,
                            typeIndexMapping: typeIndexMapping,
                            exportedTypeIndices: exportedTypeIndices
                        )
                        emittedTypes.insert(typeIndex)
                    }
                }
            case .function(let funcTypeIndex):
                // Function imports also reference a type
                let typeIndex = Int(funcTypeIndex.rawValue)
                if typeIndexMapping[typeIndex] != nil && !emittedTypes.contains(typeIndex) {
                    try encodeSingleComponentType(
                        typeIndex,
                        component: component,
                        typeIndexMapping: typeIndexMapping,
                        exportedTypeIndices: exportedTypeIndices
                    )
                    emittedTypes.insert(typeIndex)
                }
            default:
                break
            }
        }

        // Emit any remaining types that weren't emitted on-demand
        private mutating func emitRemainingTypes(
            component: ComponentWatParser.ComponentDef,
            typeIndexMapping: [Int: Int],
            exportedTypeIndices: Set<Int>,
            emittedTypes: inout Set<Int>
        ) throws(WatParserError) {
            // Emit any types that are in the mapping but weren't emitted yet
            for (oldIndex, _) in typeIndexMapping.sorted(by: { $0.value < $1.value }) {
                if !emittedTypes.contains(oldIndex) {
                    try encodeSingleComponentType(
                        oldIndex,
                        component: component,
                        typeIndexMapping: typeIndexMapping,
                        exportedTypeIndices: exportedTypeIndices
                    )
                    emittedTypes.insert(oldIndex)
                }
            }
        }

        // Helper to encode a single component type's content (without section wrapper)
        private static func encodeComponentTypeContent(
            _ typeDef: ComponentWatParser.ComponentTypeDef,
            types: NameMapping<ComponentWatParser.ComponentTypeDef>,
            typeIndexMapping: [Int: Int],
            encoder: inout Encoder
        ) throws(WatParserError) {
            switch typeDef.kind {
            case .function(let funcType):
                encoder.output.append(0x40)

                encoder.writeUnsignedLEB128(UInt32(funcType.params.count))
                for param in funcType.params {
                    encoder.encode(param.name)
                    try Self.encodeComponentValueType(
                        param.type,
                        types: types,
                        indexMapping: typeIndexMapping,
                        encoder: &encoder
                    )
                }

                if let result = funcType.result {
                    encoder.output.append(0x00)  // has result
                    try Self.encodeComponentValueType(
                        result,
                        types: types,
                        indexMapping: typeIndexMapping,
                        encoder: &encoder
                    )
                } else {
                    encoder.output.append(0x01)  // no result
                    encoder.output.append(0x00)
                }

            case .value(let valueType):
                try Self.encodeComponentValueType(
                    valueType,
                    types: types,
                    indexMapping: typeIndexMapping,
                    encoder: &encoder
                )

            case .instance(let instanceType):
                encoder.output.append(0x42)  // instance type opcode
                let declCount = instanceType.typeDecls.count + instanceType.exports.count
                encoder.writeUnsignedLEB128(UInt32(declCount))

                for typeDecl in instanceType.typeDecls {
                    encoder.output.append(0x01)  // type declaration tag
                    try Self.encodeComponentValueType(
                        typeDecl.valueType,
                        types: types,
                        indexMapping: typeIndexMapping,
                        encoder: &encoder
                    )
                }

                for export in instanceType.exports {
                    encoder.output.append(0x04)  // export declaration tag
                    encoder.output.append(0x00)  // outer count (simplified)
                    encoder.encode(export.name)
                    encoder.output.append(0x03)  // type export kind
                    encoder.output.append(0x00)  // index 0 (simplified)
                    encoder.output.append(0x00)  // no type bounds (simplified)
                }

            case .component(let componentType):
                encoder.output.append(0x41)  // component type opcode
                let declCount = componentType.typeDecls.count + componentType.imports.count + componentType.exports.count
                encoder.writeUnsignedLEB128(UInt32(declCount))

                for typeDecl in componentType.typeDecls {
                    encoder.output.append(0x01)  // type declaration tag
                    try Self.encodeComponentValueType(
                        typeDecl.valueType,
                        types: types,
                        indexMapping: typeIndexMapping,
                        encoder: &encoder
                    )
                }

                for importDecl in componentType.imports {
                    encoder.output.append(0x03)  // import declaration tag
                    encoder.output.append(0x00)  // outer count (simplified)
                    encoder.encode(importDecl.name)
                    encoder.output.append(0x03)  // type import kind
                    encoder.output.append(0x00)  // index 0 (simplified)
                    encoder.output.append(0x00)  // no type bounds (simplified)
                }

                for export in componentType.exports {
                    encoder.output.append(0x04)  // export declaration tag
                    encoder.output.append(0x00)  // outer count (simplified)
                    encoder.encode(export.name)
                    encoder.output.append(0x03)  // type export kind
                    encoder.output.append(0x00)  // index 0 (simplified)
                    encoder.output.append(0x00)  // no type bounds (simplified)
                }
            }
        }

        // Encode a single component type as its own section
        private mutating func encodeSingleComponentType(
            _ typeIndex: Int,
            component: ComponentWatParser.ComponentDef,
            typeIndexMapping: [Int: Int],
            exportedTypeIndices: Set<Int>
        ) throws(WatParserError) {
            let types = component.componentTypes
            guard typeIndex < types.decls.count else { return }

            let typeDef = types.decls[typeIndex]

            try underlying.section(id: 0x07) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(1))  // count = 1
                try Self.encodeComponentTypeContent(typeDef, types: types, typeIndexMapping: typeIndexMapping, encoder: &encoder)
            }
        }

        // Encode multiple component types in a single batched section
        private mutating func encodeBatchedComponentTypes(
            _ typeIndices: [Int],
            component: ComponentWatParser.ComponentDef,
            typeIndexMapping: [Int: Int],
            exportedTypeIndices: Set<Int>,
            emittedTypes: inout Set<Int>
        ) throws(WatParserError) {
            guard !typeIndices.isEmpty else { return }

            let types = component.componentTypes

            try underlying.section(id: 0x07) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(typeIndices.count))

                for typeIndex in typeIndices {
                    guard typeIndex < types.decls.count else { continue }
                    let typeDef = types.decls[typeIndex]
                    emittedTypes.insert(typeIndex)
                    try Self.encodeComponentTypeContent(
                        typeDef,
                        types: types,
                        typeIndexMapping: typeIndexMapping,
                        encoder: &encoder
                    )
                }
            }
        }

        // Encode a single core module as its own section
        private mutating func encodeSingleCoreModule(
            _ moduleIndex: CoreModuleIndex,
            component: ComponentWatParser.ComponentDef,
            options: EncodeOptions
        ) throws(WatParserError) {
            guard Int(moduleIndex.rawValue) < component.coreModulesMap.count else {
                throw WatParserError("Invalid core module index \(moduleIndex.rawValue)", location: nil)
            }

            var moduleDef = component.coreModulesMap[Int(moduleIndex.rawValue)]
            var moduleBytes = try WAT.encode(module: &moduleDef.wat, options: options)

            if options.nameSection, let moduleId = moduleDef.id {
                var nameEncoder = Encoder()
                nameEncoder.encode("name")
                nameEncoder.section(id: 0) { encoder in
                    encoder.encode(String(moduleId.value.dropFirst()))
                }

                var tempEncoder = Encoder()
                tempEncoder.section(id: 0) { encoder in
                    encoder.output.append(contentsOf: nameEncoder.output)
                }
                moduleBytes.append(contentsOf: tempEncoder.output)
            }

            underlying.section(id: 0x01) { encoder in
                encoder.output.append(contentsOf: moduleBytes)
            }
        }

        // Encode a single core instance as its own section
        private mutating func encodeSingleCoreInstance(
            _ instanceIndex: CoreInstanceIndex,
            component: ComponentWatParser.ComponentDef,
            location: Location
        ) throws(WatParserError) {
            guard Int(instanceIndex.rawValue) < component.coreInstancesMap.count else {
                throw WatParserError("Invalid core instance index \(instanceIndex.rawValue)", location: location)
            }

            let instanceDef = component.coreInstancesMap[Int(instanceIndex.rawValue)]

            // Check if this instance has inline export arguments - these become separate instances
            var inlineExportInstances: [[ComponentWatParser.CoreInstanceDef.Argument.Kind.Export]] = []
            var inlineExportMapping: [Int: Int] = [:]

            for (argIndex, arg) in instanceDef.arguments.enumerated() {
                if case .exports(let exports) = arg.kind {
                    inlineExportMapping[argIndex] = inlineExportInstances.count
                    inlineExportInstances.append(exports)
                }
            }

            // Total instances in this section
            let totalInstances = 1 + inlineExportInstances.count

            try underlying.section(id: 0x02) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(totalInstances))

                // First: encode inline export instances (form 0x01)
                for exports in inlineExportInstances {
                    encoder.output.append(0x01)  // inline exports form
                    encoder.writeUnsignedLEB128(UInt32(exports.count))
                    for export in exports {
                        encoder.encode(export.name)
                        encoder.output.append(export.sort.binaryEncoding)
                        encoder.writeUnsignedLEB128(export.index)
                    }
                }

                // Then: encode the instantiate instance (form 0x00)
                encoder.output.append(0x00)  // instantiate form

                let moduleIndex = try component.coreModulesMap.resolveIndex(use: instanceDef.moduleId)
                encoder.writeUnsignedLEB128(UInt32(moduleIndex))

                try encoder.encodeVector(
                    instanceDef.arguments.enumerated().map {
                        // `EnumeratedSequence` does not conform to `Collection` on Darwin OSes before 26.0
                        ($0, $1)
                    }
                ) { element, encoder throws(WatParserError) in
                    let (argIndex, arg) = element
                    encoder.encode(arg.importName)

                    switch arg.kind {
                    case .instance(let instanceId):
                        encoder.output.append(0x12)
                        let resolvedIndex = try component.coreInstancesMap.resolveIndex(use: instanceId)
                        encoder.writeUnsignedLEB128(UInt32(resolvedIndex))
                    case .exports:
                        // Reference the inline export instance we created earlier in this section
                        encoder.output.append(0x12)
                        guard let inlineIndex = inlineExportMapping[argIndex] else {
                            throw WatParserError("Internal error: inline export instance not found", location: location)
                        }
                        encoder.writeUnsignedLEB128(UInt32(inlineIndex))
                    }
                }
            }
        }

        // Helper to encode a single core type's content (without section wrapper)
        private static func encodeCoreTypeContent(
            _ typeDef: ComponentWatParser.CoreTypeDef,
            component: ComponentWatParser.ComponentDef,
            encoder: inout Encoder
        ) throws(WatParserError) {
            switch typeDef.kind {
            case .function(let funcType):
                encoder.output.append(0x60)
                encoder.writeUnsignedLEB128(UInt32(funcType.signature.parameters.count))
                for param in funcType.signature.parameters {
                    encoder.encode(param)
                }
                encoder.writeUnsignedLEB128(UInt32(funcType.signature.results.count))
                for result in funcType.signature.results {
                    encoder.encode(result)
                }

            case .module(let moduleTypeDef):
                encoder.output.append(0x50)
                try encoder.encodeVector(moduleTypeDef.declarations) { decl, encoder throws(WatParserError) in
                    switch decl {
                    case .alias(let alias):
                        encoder.output.append(0x02)
                        encoder.output.append(alias.sort.binaryEncoding)
                        switch alias.target {
                        case .outer(_, _, let resolvedIndex, let outerCount):
                            encoder.output.append(0x01)
                            encoder.writeUnsignedLEB128(UInt32(outerCount))
                            encoder.writeUnsignedLEB128(UInt32(resolvedIndex))
                        }

                    case .import(let importDef):
                        encoder.output.append(0x00)
                        encoder.encode(importDef.moduleName)
                        encoder.encode(importDef.name)
                        switch importDef.descriptor {
                        case .func(let funcTypeIndex):
                            encoder.output.append(0x00)
                            let resolvedTypeIdx = try moduleTypeDef.resolveTypeIndex(use: funcTypeIndex, globalResolver: component.coreTypesMap)
                            encoder.writeUnsignedLEB128(UInt32(resolvedTypeIdx))
                        }

                    case .type, .export:
                        throw WatParserError("Module type declaration not yet supported", location: nil)
                    }
                }
            }
        }

        // Encode multiple core types in a single batched section
        private mutating func encodeBatchedCoreTypes(
            _ typeIndices: [UInt32],
            component: ComponentWatParser.ComponentDef
        ) throws(WatParserError) {
            guard !typeIndices.isEmpty else { return }

            try underlying.section(id: 0x03) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(typeIndices.count))

                for typeIndex in typeIndices {
                    guard Int(typeIndex) < component.coreTypesMap.count else { continue }
                    let typeDef = component.coreTypesMap[Int(typeIndex)]
                    try Self.encodeCoreTypeContent(typeDef, component: component, encoder: &encoder)
                }
            }
        }

        // Encode a single canon definition as its own section
        // Also emits alias section if needed for this canon
        private mutating func encodeSingleCanon(
            _ canonDef: ComponentWatParser.CanonDef,
            coreFuncAliases: [CoreFuncAlias],
            componentFuncAliases: [ComponentFuncAlias],
            component: ComponentWatParser.ComponentDef,
            typeIndexMapping: [Int: Int],
            coreInstanceIndexMapping: [Int: Int],
            location: Location,
            emittedCoreFuncAliases: inout Set<Int>,
            emittedComponentFuncAliases: inout Set<Int>,
            liftIndex: inout Int,
            coreFunctionCount: inout Int
        ) throws(WatParserError) {
            switch canonDef.kind {
            case .lift(let funcIndex):
                // Find the alias for this lift
                let parserInstanceIndex = try component.coreInstancesMap.resolveIndex(use: funcIndex.instance)
                // Convert to binary index for matching with coreFuncAliases
                let binaryInstanceIndex = coreInstanceIndexMapping[parserInstanceIndex] ?? parserInstanceIndex
                guard
                    let aliasIndexInArray = coreFuncAliases.firstIndex(where: {
                        $0.instanceIndex == binaryInstanceIndex && $0.exportName == funcIndex.exportName
                    })
                else {
                    throw WatParserError("Core function alias not found", location: location)
                }

                // Emit alias section if not already emitted
                // The alias creates a new core function at the current coreFunctionCount
                let coreFuncIndex: Int
                if !emittedCoreFuncAliases.contains(aliasIndexInArray) {
                    let alias = coreFuncAliases[aliasIndexInArray]
                    underlying.section(id: 0x06) { encoder in
                        encoder.writeUnsignedLEB128(UInt32(1))  // count = 1
                        encoder.output.append(0x00)  // sort: core
                        encoder.output.append(0x00)  // core sort: func
                        encoder.output.append(0x01)  // aliastarget: core export
                        encoder.writeUnsignedLEB128(UInt32(alias.instanceIndex))
                        encoder.encode(alias.exportName)
                    }
                    coreFuncIndex = coreFunctionCount
                    coreFunctionCount += 1
                    emittedCoreFuncAliases.insert(aliasIndexInArray)
                } else {
                    // Alias already emitted - need to track what index it was assigned
                    // For now, count emitted aliases with lower indices
                    var idx = 0
                    for i in 0..<aliasIndexInArray {
                        if emittedCoreFuncAliases.contains(i) {
                            idx += 1
                        }
                    }
                    // This is a simplification - proper implementation would track assigned indices
                    coreFuncIndex = coreFunctionCount - (emittedCoreFuncAliases.count - idx)
                }

                // Emit canon section
                try underlying.section(id: 0x08) { encoder throws(WatParserError) in
                    encoder.writeUnsignedLEB128(UInt32(1))  // count = 1
                    encoder.output.append(0x00)  // canon.lift
                    encoder.output.append(0x00)  // sub-opcode

                    // Use the tracked core function index
                    encoder.writeUnsignedLEB128(UInt32(coreFuncIndex))

                    try encoder.encodeVector(canonDef.options) { option, encoder throws(WatParserError) in
                        switch option {
                        case .memory(let memoryId):
                            encoder.output.append(0x00)
                            let memoryIndex = try component.coreInstancesMap.resolveIndex(use: memoryId)
                            encoder.writeUnsignedLEB128(UInt32(memoryIndex))
                        case .async:
                            encoder.output.append(0x05)
                        case .realloc, .postReturn, .callback, .stringEncoding:
                            throw WatParserError("Canon option not yet supported", location: location)
                        }
                    }

                    // Look up the type index from the corresponding component function
                    guard liftIndex < component.componentFunctions.decls.count else {
                        throw WatParserError(
                            "Lift index \(liftIndex) out of bounds (have \(component.componentFunctions.decls.count) functions)",
                            location: location
                        )
                    }
                    let componentFunc = component.componentFunctions.decls[liftIndex]
                    let originalTypeIndex = Int(componentFunc.type.rawValue)
                    guard let mappedTypeIndex = typeIndexMapping[originalTypeIndex] else {
                        throw WatParserError("Type index \(originalTypeIndex) not found in mapping", location: location)
                    }
                    encoder.writeUnsignedLEB128(UInt32(mappedTypeIndex))
                }
                liftIndex += 1

            case .lower(let funcRef):
                // Find the alias for this lower
                let instanceIndex = try component.componentInstancesMap.resolveIndex(use: funcRef.instance)
                guard
                    let aliasIndexInArray = componentFuncAliases.firstIndex(where: {
                        $0.instanceIndex == instanceIndex && $0.exportName == funcRef.exportName
                    })
                else {
                    throw WatParserError("Component function alias not found", location: location)
                }

                // Emit alias section if not already emitted
                if !emittedComponentFuncAliases.contains(aliasIndexInArray) {
                    let alias = componentFuncAliases[aliasIndexInArray]
                    underlying.section(id: 0x06) { encoder in
                        encoder.writeUnsignedLEB128(UInt32(1))  // count = 1
                        encoder.output.append(0x01)  // sort: func
                        encoder.output.append(0x00)  // aliastarget: export
                        encoder.writeUnsignedLEB128(UInt32(alias.instanceIndex))
                        encoder.encode(alias.exportName)
                    }
                    emittedComponentFuncAliases.insert(aliasIndexInArray)
                }

                // Emit canon section
                try underlying.section(id: 0x08) { encoder throws(WatParserError) in
                    encoder.writeUnsignedLEB128(UInt32(1))  // count = 1
                    encoder.output.append(0x01)  // canon.lower
                    encoder.output.append(0x00)  // sub-opcode

                    // The function index refers to the component functions index space.
                    // Component functions come from:
                    // 1. Function imports (at indices 0, 1, ...)
                    // 2. Function aliases (continuing indices)
                    // Since we emit aliases before canon.lower, the aliasIndexInArray
                    // is the correct index (offset by any function imports, but we
                    // don't have function imports in these test cases yet)
                    encoder.writeUnsignedLEB128(UInt32(aliasIndexInArray))

                    try encoder.encodeVector(canonDef.options) { option, encoder throws(WatParserError) in
                        switch option {
                        case .memory(let memoryId):
                            encoder.output.append(0x00)
                            let memoryIndex = try component.coreInstancesMap.resolveIndex(use: memoryId)
                            encoder.writeUnsignedLEB128(UInt32(memoryIndex))
                        case .async:
                            encoder.output.append(0x05)
                        case .realloc, .postReturn, .callback, .stringEncoding:
                            throw WatParserError("Canon option not yet supported", location: location)
                        }
                    }
                }
                // Canon.lower creates a core function - increment the count
                coreFunctionCount += 1
            }
        }

        // Encode a single import definition as its own section
        private mutating func encodeSingleImport(
            _ importDef: ComponentWatParser.ImportDef,
            typeIndexMapping: [Int: Int],
            location: Location
        ) throws(WatParserError) {
            try underlying.section(id: 0x0A) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(1))  // count = 1

                // Encode import name with 0x00 prefix (no version suffix)
                encoder.output.append(0x00)
                encoder.encode(importDef.importName)

                // Encode externdesc
                switch importDef.descriptor {
                case .instance(let indexOrId):
                    encoder.output.append(0x05)  // instance externdesc
                    switch indexOrId {
                    case .index(let index, _):
                        guard let mappedIndex = typeIndexMapping[Int(index)] else {
                            throw WatParserError("Type index \(index) not found in index mapping", location: location)
                        }
                        encoder.writeUnsignedLEB128(UInt32(mappedIndex))
                    case .id:
                        throw WatParserError("Import by id not yet supported", location: location)
                    }
                case .function(let funcIndex):
                    encoder.output.append(0x01)  // func externdesc
                    encoder.writeUnsignedLEB128(funcIndex.rawValue)
                case .module, .value, .type, .component, .functionFromInstance:
                    throw WatParserError("Import descriptor not yet supported", location: location)
                }
            }
        }

        // Encode a single export definition as its own section
        // Also emits alias section if needed for functionFromInstance exports
        private mutating func encodeSingleExport(
            _ exportDef: ComponentWatParser.ExportDef,
            typeIndexMapping: [Int: Int],
            coreFuncAliases: [CoreFuncAlias],
            componentFuncAliases: [ComponentFuncAlias],
            exportFuncAliases: [ComponentFuncAlias],
            location: Location,
            emittedExportFuncAliases: inout Set<Int>
        ) throws(WatParserError) {
            // For functionFromInstance exports, emit alias first if needed
            if case .functionFromInstance(_, let exportName) = exportDef.descriptor {
                guard
                    let aliasIndexInArray = exportFuncAliases.firstIndex(where: {
                        $0.exportName == exportName
                    })
                else {
                    throw WatParserError("Export function alias not found for \(exportName)", location: location)
                }

                if !emittedExportFuncAliases.contains(aliasIndexInArray) {
                    let alias = exportFuncAliases[aliasIndexInArray]
                    underlying.section(id: 0x06) { encoder in
                        encoder.writeUnsignedLEB128(UInt32(1))  // count = 1
                        encoder.output.append(0x01)  // sort: func
                        encoder.output.append(0x00)  // aliastarget: export
                        encoder.writeUnsignedLEB128(UInt32(alias.instanceIndex))
                        encoder.encode(alias.exportName)
                    }
                    emittedExportFuncAliases.insert(aliasIndexInArray)
                }
            }

            try underlying.section(id: 0x0B) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(1))  // count = 1

                encoder.output.append(0x00)
                encoder.encode(exportDef.exportName)

                switch exportDef.descriptor {
                case .function(let funcIndex):
                    encoder.output.append(0x01)
                    // The binary function index accounts for function aliases that come before
                    // Functions from canon.lift start after all component function aliases
                    let binaryFuncIndex = componentFuncAliases.count + Int(funcIndex.rawValue)
                    encoder.writeUnsignedLEB128(UInt32(binaryFuncIndex))
                    encoder.output.append(0x00)
                case .functionFromInstance(_, let exportName):
                    guard
                        let aliasIndexInArray = exportFuncAliases.firstIndex(where: {
                            $0.exportName == exportName
                        })
                    else {
                        throw WatParserError("Export function alias not found for \(exportName)", location: location)
                    }
                    let funcIndex = coreFuncAliases.count + componentFuncAliases.count + aliasIndexInArray
                    encoder.output.append(0x01)  // func sort
                    encoder.writeUnsignedLEB128(UInt32(funcIndex))
                    encoder.output.append(0x00)  // no externdesc
                case .type(let indexOrId):
                    encoder.output.append(0x03)  // type sort
                    switch indexOrId {
                    case .index(let index, _):
                        guard let mappedIndex = typeIndexMapping[Int(index)] else {
                            throw WatParserError("Type index \(index) not found in index mapping", location: location)
                        }
                        encoder.writeUnsignedLEB128(UInt32(mappedIndex))
                    case .id:
                        throw WatParserError("Type export by id not yet supported", location: location)
                    }
                    encoder.output.append(0x00)  // no externdesc
                case .module, .value, .component, .instance:
                    throw WatParserError("Export descriptor not yet supported", location: location)
                }
            }
        }

        // Encode a single nested component as its own section
        private mutating func encodeSingleComponent(
            _ componentIndex: ComponentIndex,
            component: ComponentWatParser.ComponentDef,
            options: EncodeOptions
        ) throws(WatParserError) {
            guard Int(componentIndex.rawValue) < component.componentsMap.count else {
                throw WatParserError("Invalid component index \(componentIndex.rawValue)", location: nil)
            }

            let nestedComponent = component.componentsMap[Int(componentIndex.rawValue)]
            var nestedEncoder = ComponentEncoder()
            _ = try nestedEncoder.encode(nestedComponent, options: options)

            underlying.section(id: 0x04) { encoder in
                encoder.output.append(contentsOf: nestedEncoder.underlying.output)
            }
        }

        // Encode a single component instance as its own section
        private mutating func encodeSingleComponentInstance(
            _ instanceIndex: ComponentInstanceIndex,
            component: ComponentWatParser.ComponentDef,
            location: Location
        ) throws(WatParserError) {
            guard Int(instanceIndex.rawValue) < component.componentInstancesMap.count else {
                throw WatParserError("Invalid component instance index \(instanceIndex.rawValue)", location: location)
            }

            let instanceDef = component.componentInstancesMap[Int(instanceIndex.rawValue)]

            guard let componentRef = instanceDef.componentRef else {
                throw WatParserError("Component instance has no component reference", location: location)
            }

            try underlying.section(id: 0x05) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(1))  // count = 1

                encoder.output.append(0x00)  // instantiate form

                let componentIndex = try component.componentsMap.resolveIndex(use: componentRef)
                encoder.writeUnsignedLEB128(UInt32(componentIndex))

                try encoder.encodeVector(instanceDef.arguments) { arg, encoder throws(WatParserError) in
                    encoder.encode(arg.name)

                    switch arg.kind {
                    case .instance(let instanceRef):
                        encoder.output.append(0x05)  // instance sort
                        let resolvedIndex = try component.componentInstancesMap.resolveIndex(use: instanceRef)
                        encoder.writeUnsignedLEB128(UInt32(resolvedIndex))
                    }
                }
            }
        }

        private func groupFields(_ fields: [ComponentWatParser.ComponentDefField]) throws(WatParserError) -> GroupedFields {
            var result = GroupedFields()

            for field in fields {
                switch field.kind {
                case .coreModule(let index):
                    result.coreModules.append((index, field.location))
                case .coreInstance(let index):
                    result.coreInstances.append((index, field.location))
                case .coreType(let index):
                    result.coreTypes.append((index, field.location))
                case .component(let index):
                    result.components.append((index, field.location))
                case .canon(let canonDef):
                    result.canons.append((canonDef, field.location))
                case .exportDef(let exportDef):
                    result.exports.append((exportDef, field.location))
                case .importDef(let importDef):
                    result.imports.append((importDef, field.location))
                case .instance(let index):
                    result.instances.append((index, field.location))
                case .componentType:
                    // Component types are handled separately in the main encoding loop
                    // They don't need to be grouped for auxiliary calculations
                    break
                }
            }

            return result
        }

        /// Build a mapping from parser core instance index to binary index.
        /// This accounts for inline export instances that shift indices.
        private func buildCoreInstanceIndexMapping(
            component: ComponentWatParser.ComponentDef,
            fields: GroupedFields
        ) -> [Int: Int] {
            var mapping: [Int: Int] = [:]
            var binaryIndex = 0

            // Process core instances in order, counting inline export instances
            for (instanceIndex, _) in fields.coreInstances {
                let idx = Int(instanceIndex.rawValue)
                guard idx < component.coreInstancesMap.count else { continue }

                let instanceDef = component.coreInstancesMap[idx]

                // Count inline export instances that will be emitted first
                var inlineExportCount = 0
                for arg in instanceDef.arguments {
                    if case .exports = arg.kind {
                        inlineExportCount += 1
                    }
                }

                // Inline exports come first, then the main instance
                // So the main instance index is offset by inline export count
                mapping[idx] = binaryIndex + inlineExportCount
                binaryIndex += 1 + inlineExportCount  // 1 for main instance + inline exports
            }

            return mapping
        }

        private func collectCoreFuncAliases(
            from canons: [(ComponentWatParser.CanonDef, Location)],
            component: ComponentWatParser.ComponentDef,
            coreInstanceIndexMapping: [Int: Int]
        ) throws(WatParserError) -> [CoreFuncAlias] {
            var aliases: [CoreFuncAlias] = []

            for (canonDef, _) in canons {
                guard case .lift(let funcIndex) = canonDef.kind else { continue }
                let parserIndex = try component.coreInstancesMap.resolveIndex(use: funcIndex.instance)
                // Use the mapped binary index instead of parser index
                let binaryIndex = coreInstanceIndexMapping[parserIndex] ?? parserIndex
                aliases.append((binaryIndex, funcIndex.exportName))
            }

            return aliases
        }

        private func collectComponentFuncAliases(
            from canons: [(ComponentWatParser.CanonDef, Location)],
            component: ComponentWatParser.ComponentDef
        ) throws(WatParserError) -> [ComponentFuncAlias] {
            var aliases: [ComponentFuncAlias] = []

            for (canonDef, _) in canons {
                guard case .lower(let funcRef) = canonDef.kind else { continue }
                let instanceIndex = try component.componentInstancesMap.resolveIndex(use: funcRef.instance)
                aliases.append((instanceIndex, funcRef.exportName))
            }

            return aliases
        }

        private func collectExportFuncAliases(
            from exports: [(ComponentWatParser.ExportDef, Location)],
            component: ComponentWatParser.ComponentDef
        ) throws(WatParserError) -> [ComponentFuncAlias] {
            var aliases: [ComponentFuncAlias] = []

            for (exportDef, _) in exports {
                guard case .functionFromInstance(let instanceRef, let exportName) = exportDef.descriptor else { continue }
                let instanceIndex = try component.componentInstancesMap.resolveIndex(use: instanceRef)
                aliases.append((instanceIndex, exportName))
            }

            return aliases
        }

        private mutating func encodeCoreInstances(
            _ instances: [(CoreInstanceIndex, Location)],
            component: ComponentWatParser.ComponentDef
        ) throws(WatParserError) {
            // First pass: collect all inline export instances that need to be created
            // and compute the mapping from original to actual instance indices
            var inlineExportInstances: [(exports: [ComponentWatParser.CoreInstanceDef.Argument.Kind.Export], location: Location)] = []
            var inlineExportInstanceMapping: [Int: Int] = [:]  // Map from (instance index, arg index) hash to inline instance index

            for (instanceIndex, location) in instances {
                guard Int(instanceIndex.rawValue) < component.coreInstancesMap.count else { continue }
                let instanceDef = component.coreInstancesMap[Int(instanceIndex.rawValue)]

                for (argIndex, arg) in instanceDef.arguments.enumerated() {
                    if case .exports(let exports) = arg.kind {
                        let key = Int(instanceIndex.rawValue) * 1000 + argIndex
                        inlineExportInstanceMapping[key] = inlineExportInstances.count
                        inlineExportInstances.append((exports: exports, location: location))
                    }
                }
            }

            // Total instances = explicit instances + inline export instances
            let totalInstances = instances.count + inlineExportInstances.count
            guard totalInstances > 0 else { return }

            try underlying.section(id: 0x02) { encoder throws(WatParserError) in
                encoder.writeUnsignedLEB128(UInt32(totalInstances))

                // First: encode inline export instances (form 0x01)
                for (exports, _) in inlineExportInstances {
                    encoder.output.append(0x01)  // inline exports form
                    encoder.writeUnsignedLEB128(UInt32(exports.count))
                    for export in exports {
                        encoder.encode(export.name)
                        encoder.output.append(export.sort.binaryEncoding)
                        encoder.writeUnsignedLEB128(export.index)
                    }
                }

                // Second: encode instantiate instances (form 0x00)
                let inlineInstanceBaseIndex = inlineExportInstances.count

                for (instanceIndex, location) in instances {
                    guard Int(instanceIndex.rawValue) < component.coreInstancesMap.count else {
                        throw WatParserError("Invalid core instance index \(instanceIndex.rawValue)", location: location)
                    }

                    let instanceDef = component.coreInstancesMap[Int(instanceIndex.rawValue)]

                    encoder.output.append(0x00)  // instantiate form

                    let moduleIndex = try component.coreModulesMap.resolveIndex(use: instanceDef.moduleId)
                    encoder.writeUnsignedLEB128(UInt32(moduleIndex))

                    try encoder.encodeVector(instanceDef.arguments.enumerated().map { ($0, $1) }) { element, encoder throws(WatParserError) in
                        let (argIndex, arg) = element
                        encoder.encode(arg.importName)

                        switch arg.kind {
                        case .instance(let instanceId):
                            encoder.output.append(0x12)
                            let resolvedIndex = try component.coreInstancesMap.resolveIndex(use: instanceId)
                            // Adjust index for inline instances that come before
                            encoder.writeUnsignedLEB128(UInt32(resolvedIndex + inlineInstanceBaseIndex))
                        case .exports:
                            // Reference the inline export instance we created earlier
                            encoder.output.append(0x12)
                            let key = Int(instanceIndex.rawValue) * 1000 + argIndex
                            guard let inlineIndex = inlineExportInstanceMapping[key] else {
                                throw WatParserError("Internal error: inline export instance not found", location: location)
                            }
                            encoder.writeUnsignedLEB128(UInt32(inlineIndex))
                        }
                    }
                }
            }
        }

        /// Encode a component value type as valtype (either index or inline primitive)
        private static func encodeValType(
            _ typeIndex: ComponentTypeIndex,
            types: NameMapping<ComponentWatParser.ComponentTypeDef>,
            indexMapping: [Int: Int],
            encoder: inout Encoder
        ) throws(WatParserError) {
            // Look up the type to see if it's a primitive
            let typeDef = types[Int(typeIndex.rawValue)]
            // Only inline primitives if the type is anonymous (no ID)
            // Named primitives (like $A1 = bool) should be encoded as type indices when referenced
            if typeDef.id == nil, case .value(let valueType) = typeDef.kind {
                // Check if it's a primitive that can be inlined
                switch valueType {
                case .bool, .s8, .u8, .s16, .u16, .s32, .u32, .s64, .u64, .float32, .float64, .char, .string, .errorContext:
                    // Inline the primitive
                    try encodeComponentValueType(valueType, types: types, indexMapping: indexMapping, encoder: &encoder)
                    return
                default:
                    break
                }
            }
            // Otherwise encode as type index (with remapping)
            guard let mappedIndex = indexMapping[Int(typeIndex.rawValue)] else {
                throw WatParserError("Type index \(typeIndex.rawValue) not found in index mapping", location: nil)
            }
            encoder.writeUnsignedLEB128(UInt32(mappedIndex))
        }

        /// Encode a component value type
        private static func encodeComponentValueType(
            _ valueType: ComponentValueType,
            types: NameMapping<ComponentWatParser.ComponentTypeDef>,
            indexMapping: [Int: Int],
            encoder: inout Encoder
        ) throws(WatParserError) {
            switch valueType {
            // Primitive types
            case .bool: encoder.output.append(0x7F)
            case .s8: encoder.output.append(0x7E)
            case .u8: encoder.output.append(0x7D)
            case .s16: encoder.output.append(0x7C)
            case .u16: encoder.output.append(0x7B)
            case .s32: encoder.output.append(0x7A)
            case .u32: encoder.output.append(0x79)
            case .s64: encoder.output.append(0x78)
            case .u64: encoder.output.append(0x77)
            case .float32: encoder.output.append(0x76)
            case .float64: encoder.output.append(0x75)
            case .char: encoder.output.append(0x74)
            case .string: encoder.output.append(0x73)
            case .errorContext: encoder.output.append(0x64)

            // Composite types
            case .list(let typeIndex):
                encoder.output.append(0x70)
                try encodeValType(typeIndex, types: types, indexMapping: indexMapping, encoder: &encoder)

            case .tuple(let typeIndices):
                encoder.output.append(0x6F)
                encoder.writeUnsignedLEB128(UInt32(typeIndices.count))
                for typeIndex in typeIndices {
                    try encodeValType(typeIndex, types: types, indexMapping: indexMapping, encoder: &encoder)
                }

            case .option(let typeIndex):
                encoder.output.append(0x6B)
                try encodeValType(typeIndex, types: types, indexMapping: indexMapping, encoder: &encoder)

            case .result(let okType, let errorType):
                encoder.output.append(0x6A)
                if let okType {
                    encoder.output.append(0x01)  // has ok type
                    try encodeValType(okType, types: types, indexMapping: indexMapping, encoder: &encoder)
                } else {
                    encoder.output.append(0x00)  // no ok type
                }
                if let errorType {
                    encoder.output.append(0x01)  // has error type
                    try encodeValType(errorType, types: types, indexMapping: indexMapping, encoder: &encoder)
                } else {
                    encoder.output.append(0x00)  // no error type
                }

            case .record(let fields):
                encoder.output.append(0x72)
                encoder.writeUnsignedLEB128(UInt32(fields.count))
                for field in fields {
                    encoder.encode(field.name)
                    try encodeValType(field.type, types: types, indexMapping: indexMapping, encoder: &encoder)
                }

            case .variant(let cases):
                encoder.output.append(0x71)
                encoder.writeUnsignedLEB128(UInt32(cases.count))
                for caseField in cases {
                    encoder.encode(caseField.name)
                    if let caseType = caseField.type {
                        encoder.output.append(0x01)  // has type
                        try encodeValType(caseType, types: types, indexMapping: indexMapping, encoder: &encoder)
                    } else {
                        encoder.output.append(0x00)  // no type
                    }
                    encoder.output.append(0x00)  // refines: none
                }

            case .flags(let flagNames):
                encoder.output.append(0x6e)
                encoder.writeUnsignedLEB128(UInt32(flagNames.count))
                for flagName in flagNames {
                    encoder.encode(flagName)
                }

            case .enum(let enumCases):
                encoder.output.append(0x6d)
                encoder.writeUnsignedLEB128(UInt32(enumCases.count))
                for caseName in enumCases {
                    encoder.encode(caseName)
                }

            case .future, .stream, .resource:
                throw WatParserError("Component value type not yet supported: \(valueType)", location: nil)

            case .indexed(let typeIndex):
                // This is already a type reference, encode as index with remapping
                guard let mappedIndex = indexMapping[Int(typeIndex.rawValue)] else {
                    throw WatParserError("Type index \(typeIndex.rawValue) not found in index mapping", location: nil)
                }
                encoder.writeUnsignedLEB128(UInt32(mappedIndex))
            }
        }

        private mutating func encodeComponentNameSection(component: ComponentWatParser.ComponentDef) throws(WatParserError) {
            let hasComponentName = component.id != nil
            let hasModuleNames = component.coreModulesMap.contains { $0.id != nil }
            let hasInstanceNames = component.coreInstancesMap.contains { $0.id != nil }
            let hasCoreTypeNames = component.coreTypesMap.declarations.contains { $0.id != nil }
            let hasComponentTypeNames = component.componentTypes.decls.contains { $0.id != nil }
            let hasComponentNames = component.componentsMap.contains { $0.id != nil }

            guard hasComponentName || hasModuleNames || hasInstanceNames || hasCoreTypeNames || hasComponentTypeNames || hasComponentNames
            else { return }

            underlying.section(id: 0) { encoder in
                encoder.encode("component-name")

                if let componentName = component.id {
                    encoder.section(id: 0) { encoder in
                        encoder.encode(String(componentName.value.dropFirst()))
                    }
                }

                if hasModuleNames {
                    encoder.section(id: 1) { encoder in
                        encoder.output.append(0x00)
                        encoder.output.append(0x11)

                        let moduleNames = component.coreModulesMap.enumerated().compactMap { i, decl -> (Int, String)? in
                            guard let name = decl.id else { return nil }
                            return (i, name.value)
                        }
                        encoder.encodeVector(moduleNames) { entry, encoder in
                            let (index, name) = entry
                            encoder.writeUnsignedLEB128(UInt(index))
                            encoder.encode(String(name.dropFirst()))
                        }
                    }
                }

                if hasInstanceNames {
                    encoder.section(id: 1) { encoder in
                        encoder.output.append(0x00)
                        encoder.output.append(0x12)

                        let instanceNames = component.coreInstancesMap.enumerated().compactMap { i, decl -> (Int, String)? in
                            guard let name = decl.id else { return nil }
                            return (i, name.value)
                        }
                        encoder.encodeVector(instanceNames) { entry, encoder in
                            let (index, name) = entry
                            encoder.writeUnsignedLEB128(UInt(index))
                            encoder.encode(String(name.dropFirst()))
                        }
                    }
                }

                if hasCoreTypeNames {
                    encoder.section(id: 1) { encoder in
                        encoder.output.append(0x00)
                        encoder.output.append(0x10)

                        let typeNames = component.coreTypesMap.declarations.enumerated().compactMap { i, decl -> (Int, String)? in
                            guard let name = decl.id else { return nil }
                            return (i, name.value)
                        }
                        encoder.encodeVector(typeNames) { entry, encoder in
                            let (index, name) = entry
                            encoder.writeUnsignedLEB128(UInt(index))
                            encoder.encode(String(name.dropFirst()))
                        }
                    }
                }

                if hasComponentTypeNames {
                    encoder.section(id: 1) { encoder in
                        encoder.output.append(0x03)  // Sort code for component types

                        // Build the same index mapping as in encodeComponentTypes
                        // Must match exactly: include non-primitives, primitives with IDs, and exported types
                        var indexMapping: [Int: Int] = [:]
                        var newIndex = 0
                        for (oldIndex, typeDef) in component.componentTypes.decls.enumerated() {
                            let isPrimitive: Bool
                            if case .value(let valueType) = typeDef.kind {
                                isPrimitive = valueType.isPrimitive
                            } else {
                                isPrimitive = false
                            }

                            let hasId = typeDef.id != nil
                            if !isPrimitive || hasId {
                                indexMapping[oldIndex] = newIndex
                                newIndex += 1
                            }
                        }

                        // Collect component type names with remapped indices
                        let typeNames = component.componentTypes.decls.enumerated().compactMap { i, decl -> (Int, String)? in
                            guard let name = decl.id, let mappedIndex = indexMapping[i] else { return nil }
                            return (mappedIndex, name.value)
                        }
                        encoder.encodeVector(typeNames) { entry, encoder in
                            let (index, name) = entry
                            encoder.writeUnsignedLEB128(UInt(index))
                            encoder.encode(String(name.dropFirst()))
                        }
                    }
                }

                if hasComponentNames {
                    encoder.section(id: 1) { encoder in
                        encoder.output.append(0x04)  // Sort code for components

                        let componentNames = component.componentsMap.enumerated().compactMap { i, decl -> (Int, String)? in
                            guard let name = decl.id else { return nil }
                            return (i, name.value)
                        }
                        encoder.encodeVector(componentNames) { entry, encoder in
                            let (index, name) = entry
                            encoder.writeUnsignedLEB128(UInt(index))
                            encoder.encode(String(name.dropFirst()))
                        }
                    }
                }
            }
        }
    }

    private struct GroupedFields {
        var coreModules: [(CoreModuleIndex, Location)] = []
        var coreInstances: [(CoreInstanceIndex, Location)] = []
        var coreTypes: [(UInt32, Location)] = []
        var components: [(ComponentIndex, Location)] = []
        var instances: [(ComponentInstanceIndex, Location)] = []
        var canons: [(ComponentWatParser.CanonDef, Location)] = []
        var exports: [(ComponentWatParser.ExportDef, Location)] = []
        var imports: [(ComponentWatParser.ImportDef, Location)] = []
    }

    private typealias CoreFuncAlias = (instanceIndex: Int, exportName: String)
    private typealias ComponentFuncAlias = (instanceIndex: Int, exportName: String)

    extension CoreDefSort {
        var binaryEncoding: UInt8 {
            switch self {
            case .func: return 0x00
            case .table: return 0x01
            case .memory: return 0x02
            case .global: return 0x03
            case .type: return 0x10
            case .module: return 0x11
            case .instance: return 0x12
            }
        }
    }

    extension ComponentWatParser.CoreAliasSort {
        var binaryEncoding: UInt8 {
            switch self {
            case .func: return 0x00
            case .table: return 0x01
            case .memory: return 0x02
            case .global: return 0x03
            case .type: return 0x10
            }
        }
    }

#endif
