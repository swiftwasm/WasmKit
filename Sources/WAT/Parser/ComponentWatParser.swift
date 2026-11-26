#if ComponentModel

    import ComponentModel
    import WasmParser
    import WasmTypes

    package struct ComponentWatParser: ~Copyable {
        let features: WasmFeatureSet

        /// Stack of components currently being parsed (supports nested components)
        private var componentStack: [ComponentDef] = []

        /// Stack of type definition contexts for nested instance/component types.
        /// Used for resolving outer alias references with named type references.
        private var typeContextStack: [LocalTypeContext] = []

        /// Map of type names to their local type bindings (for completed type definitions).
        /// Used for resolving outer alias references that refer to types defined earlier in the same component.
        private var completedTypeContexts: [String: [String: UInt32]] = [:]

        /// Number of composite value types and instance or component type bodies currently being parsed.
        private var typeNestingDepth = 0

        init(features: WasmFeatureSet) {
            self.features = features
            // Initialize stack with empty root component
            self.componentStack.append(ComponentDef())
        }

        private var currentComponent: ComponentDef {
            _read {
                yield self.componentStack[componentStack.count - 1]
            }
            _modify {
                yield &self.componentStack[componentStack.count - 1]
            }
        }

        /// Returns the parsed root component after all fields have been processed
        consuming func parse(_ parser: inout Parser) throws(WatParserError) -> ComponentDef {
            try parser.expect(.leftParen)
            try parser.expectKeyword("component")
            let id = try parser.takeId()
            componentStack.append(ComponentDef(id: id))
            try parseComponentFields(&parser)
            try parser.expect(.rightParen)
            var component = componentStack.removeLast()
            component.normalizeDefinitions()
            return component
        }

        /// Parses a component body when `(component $id?` has already been consumed.
        /// Expects the parser to be positioned at the first field or closing `)`.
        /// Consumes the closing `)` and returns the parsed ComponentDef.
        consuming func parseComponentBody(_ parser: inout Parser, id: Name?) throws(WatParserError) -> ComponentDef {
            componentStack.append(ComponentDef(id: id))
            try parseComponentFields(&parser)
            try parser.expect(.rightParen)
            var component = componentStack.removeLast()
            component.normalizeDefinitions()
            return component
        }

        /// Emit inline export definitions for a set of parsed inline exports.
        private mutating func emitInlineExports(
            _ exports: [(location: Location, name: String)],
            descriptor: (Location) -> ExternDesc
        ) {
            for inlineExport in exports {
                let exportDef = ExportDef(
                    exportName: .plain(inlineExport.name),
                    descriptor: descriptor(inlineExport.location),
                    isInline: true
                )
                currentComponent.definitions.append(.componentExport(exportDef))
            }
        }

        private static let maxComponentNestingDepth = 100
        /// A debug build with AddressSanitizer uses up to 33 KB of stack per level, and a Swift task thread has 512 KB.
        private static let maxTypeNestingDepth = 10

        /// Enters one level of type nesting. The caller decrements `typeNestingDepth` when it leaves the level.
        private mutating func enterTypeNesting(_ parser: inout Parser) throws(WatParserError) {
            guard typeNestingDepth < Self.maxTypeNestingDepth else {
                throw WatParserError("nesting too deep", location: parser.lexer.location())
            }
            typeNestingDepth += 1
        }

        /// Parses component fields until a closing `)` is encountered.
        /// Assumes the parser is positioned after `(component $id?`.
        ///
        /// Uses an iterative approach with an explicit stack to avoid
        /// stack overflow on deeply nested components.
        private mutating func parseComponentFields(_ parser: inout Parser) throws(WatParserError) {
            let outerDepth = componentStack.count

            parsing: while true {
                while try parser.take(.leftParen) {
                    let keyword = try parser.expectKeyword()
                    let location = parser.lexer.location()
                    switch keyword {
                    case "core":
                        try parseCoreDef(&parser)
                    case "type":
                        try parseComponentTypeDef(&parser)
                    case "func":
                        try parseComponentFunc(&parser)
                    case "component":
                        let nestedId = try parser.takeId()
                        guard componentStack.count <= Self.maxComponentNestingDepth else {
                            throw WatParserError(
                                "nesting too deep",
                                location: location
                            )
                        }
                        componentStack.append(ComponentDef(id: nestedId))
                        continue parsing
                    case "import":
                        try parseComponentImport(&parser, location: location)
                    case "export":
                        try parseComponentExport(&parser, location: location)
                    case "instance":
                        try parseComponentInstance(&parser, location: location)
                    case "alias":
                        try parseComponentAlias(&parser, location: location)
                    case "canon":
                        try parseTopLevelCanon(&parser, location: location)
                    case "start":
                        try parseComponentStart(&parser, location: location)
                    default:
                        throw WatParserError(
                            "Unknown component definition keyword \(keyword)",
                            location: location
                        )
                    }
                    try parser.expect(.rightParen)
                }

                // Inner while exited: no more fields in current component.
                guard componentStack.count > outerDepth else {
                    break parsing
                }
                var nested = componentStack.removeLast()
                nested.normalizeDefinitions()
                _ = try currentComponent.componentsMap.add(nested)
                currentComponent.definitions.append(.nestedComponent(nested))
                try parser.expect(.rightParen)
            }
        }

        /// Parse a core definition (module, instance, type, or func via canon lower) and add it to the current component
        private mutating func parseCoreDef(_ parser: inout Parser) throws(WatParserError) {
            let coreKeyword = try parser.expectKeyword()
            let location = parser.lexer.location()
            switch coreKeyword {
            case "module":
                let moduleDef = try self.parseModuleDef(&parser)
                _ = try self.currentComponent.coreModulesMap.add(moduleDef)
                self.currentComponent.definitions.append(.coreModule(moduleDef))

            case "instance":
                var instanceDef = try self.parseCoreInstanceDef(&parser)

                // Desugar inline exports: each inline export argument becomes a separate
                // export-only core instance that is emitted BEFORE the main instance
                if case .instantiate(let moduleId, let arguments) = instanceDef.form {
                    var syntheticInstanceIndices: [Int: Int] = [:]  // argIndex -> syntheticInstanceIndex

                    for (argIndex, arg) in arguments.enumerated() {
                        if case .exports(let exports) = arg.kind {
                            // Create synthetic export-only core instance
                            let syntheticInstance = CoreInstanceDef(
                                id: nil,
                                form: .exports(exports)
                            )
                            let syntheticIndex = try self.currentComponent.coreInstancesMap.add(syntheticInstance)
                            syntheticInstanceIndices[argIndex] = syntheticIndex

                            // Add synthetic instance to both fields and definitions FIRST
                            self.currentComponent.definitions.append(.coreInstance(syntheticInstance))
                        }
                    }

                    // Replace inline export arguments with instance references
                    if !syntheticInstanceIndices.isEmpty {
                        var newArguments = arguments
                        for (argIndex, syntheticIndex) in syntheticInstanceIndices {
                            let oldArg = arguments[argIndex]
                            newArguments[argIndex] = CoreInstanceDef.Argument(
                                importName: oldArg.importName,
                                kind: .instance(.index(UInt32(syntheticIndex), location))
                            )
                        }
                        instanceDef = CoreInstanceDef(
                            id: instanceDef.id,
                            form: .instantiate(moduleId: moduleId, arguments: newArguments)
                        )
                    }
                }

                _ = try self.currentComponent.coreInstancesMap.add(instanceDef)
                self.currentComponent.definitions.append(.coreInstance(instanceDef))

            case "type":
                let coreTypeDef = try self.parseCoreTypeDef(&parser)
                _ = try self.currentComponent.coreTypesMap.add(coreTypeDef)
                self.currentComponent.definitions.append(.coreType(coreTypeDef))

            case "func":
                // (core func $id? (canon lower (func $instance "export")))
                // (core func $id? (canon resource.new $t))
                // (core func $id? (canon resource.drop $t))
                // (core func $id? (canon resource.rep $t))
                let coreFuncId = try parser.takeId()
                try parser.expect(.leftParen)
                let coreFuncKind = try parser.expectKeyword()

                switch coreFuncKind {
                case "canon":
                    let operation = try parser.expectKeyword()
                    try parseCoreFuncCanon(&parser, operation: operation, form: .nested(id: coreFuncId), location: location)

                default:
                    throw WatParserError(
                        "expected 'canon' in core func definition, got '\(coreFuncKind)'",
                        location: parser.lexer.location()
                    )
                }

            default:
                throw WatParserError(
                    "Unknown core definition keyword \(coreKeyword)",
                    location: location
                )
            }
        }

        /// Register an inline instance type definition and return its type index.
        private mutating func registerInlineInstanceTypeDef(id: Name?, _ decls: [ComponentDecl]) throws(WatParserError) -> Int {
            let typeDef = ComponentTypeDef(id: nil, kind: .instance(decls))
            return try registerInlineComponentTypeDef(typeDef)
        }

        /// Register an inline component type definition and return its type index.
        /// Adds to typeIndexSpace and appends to definitions.
        private mutating func registerInlineComponentTypeDef(_ typeDef: ComponentTypeDef) throws(WatParserError) -> Int {
            let typeIndex = try currentComponent.typeIndexSpace.addDefinition(typeDef)
            currentComponent.definitions.append(.componentType(typeDef, typeIndex: typeIndex))
            return typeIndex
        }

        /// Parse a component extern name: either a plain string or `(interface "name")`.
        private func parseComponentExternName(_ parser: inout Parser) throws(WatParserError) -> ComponentExternName {
            if let name = try parser.takeString() {
                return .plain(name)
            }
            // Must be (interface "name")
            try parser.expect(.leftParen)
            try parser.expectKeyword("interface")
            let name = try parser.expectString()
            try parser.expect(.rightParen)
            return .interface(name)
        }

        private mutating func parseComponentImport(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let importName = try parseComponentExternName(&parser)
            try parser.expect(.leftParen)
            let descKeyword = try parser.expectKeyword()

            switch descKeyword {
            case "type":
                // Handle type imports: (type $id? (sub resource)) or (type $id? (eq $ref))
                let typeId = try parser.takeId()
                var emptyCtx = LocalTypeContext()
                let bound = try parseTypeBound(&parser, localCtx: &emptyCtx)
                try parser.expect(.rightParen)

                // Add the type to component types with a placeholder value type
                // The actual resource type will be provided at instantiation time
                let resourceValueType: ComponentDefValType
                switch bound {
                case .subResource:
                    // Imported resource type - represented as a resource with no destructor
                    resourceValueType = .resource(destructor: nil)
                case .eq(let typeIndex):
                    // Type equality - reference the existing type
                    resourceValueType = .indexed(ComponentTypeIndex(rawValue: Int(typeIndex)))
                }

                let typeDef = ComponentTypeDef(id: typeId, kind: .value(resourceValueType))
                let typeIndex = try currentComponent.typeIndexSpace.addImport(name: typeId, typeDef: typeDef)

                let importDef = ImportDef(
                    importName: importName,
                    descriptor: .type(.index(UInt32(typeIndex), location), bound)
                )
                // Type imports create type indices through the import section, not the type section.
                currentComponent.definitions.append(.componentImport(importDef))

            case "instance":
                let instanceId = try parser.takeId()

                // Disambiguate (type $ref) shorthand vs inline instance type
                let typeIndex: Int
                let savedLexer = parser.lexer
                if try parser.takeParenBlockStart("type") {
                    let typeRef = try parser.expectIndexOrId()
                    if try parser.take(.rightParen) {
                        // (type $ref): type reference shorthand
                        typeIndex = try currentComponent.resolveIndex(use: typeRef, in: .componentType)
                    } else {
                        // Not (type $ref), restore and parse as inline instance type
                        parser.lexer = savedLexer
                        let decls = try parseInstanceTypeDeclarations(&parser)
                        typeIndex = try registerInlineInstanceTypeDef(id: instanceId, decls)
                    }
                } else {
                    // Inline instance type (no (type ...) wrapper)
                    let decls = try parseInstanceTypeDeclarations(&parser)
                    typeIndex = try registerInlineInstanceTypeDef(id: instanceId, decls)
                }
                try parser.expect(.rightParen)

                _ = try currentComponent.componentInstancesMap.add(
                    ComponentInstanceDef(id: instanceId, componentRef: nil, arguments: [])
                )
                let importDef = ImportDef(
                    importName: importName,
                    descriptor: .instance(.index(UInt32(typeIndex), location))
                )
                currentComponent.definitions.append(.componentImport(importDef))

            case "func":
                // Handle function imports with inline type or type reference
                let funcId = try parser.takeId()

                // Check for (type $ref) shorthand first
                if try parser.takeParenBlockStart("type") {
                    let typeRef = try parser.expectIndexOrId()
                    try parser.expect(.rightParen)  // Close (type ...)
                    try parser.expect(.rightParen)  // Close (func ...)

                    let funcTypeIndex = try currentComponent.resolveIndex(use: typeRef, in: .componentType)

                    let funcIndex = try currentComponent.componentFunctions.add(
                        ComponentFuncDef(id: funcId, paramNames: [], type: ComponentTypeIndex(rawValue: funcTypeIndex))
                    )

                    let importDef = ImportDef(
                        importName: importName,
                        descriptor: .function(ComponentFuncIndex(funcIndex))
                    )
                    currentComponent.definitions.append(.componentImport(importDef))
                    break
                }

                // Parse function signature (params and result)
                var params: [ComponentFuncType.Param] = []
                var resultType: ComponentDefValType?

                while try parser.takeParenBlockStart("param") {
                    let paramName = try parser.expectString()
                    let paramType = try parseComponentValueType(&parser)
                    params.append(ComponentFuncType.Param(name: paramName, type: paramType))
                    try parser.expect(.rightParen)
                }

                if try parser.takeParenBlockStart("result") {
                    resultType = try parseComponentValueType(&parser)
                    try parser.expect(.rightParen)
                }

                try parser.expect(.rightParen)

                // Create function type
                // Always create a fresh type for each import's inline function type.
                // wasm-tools does not deduplicate inline types created by import desugaring.
                let funcType = ComponentFuncType(params: params, result: resultType)
                let funcTypeDef = ComponentTypeDef(id: nil, kind: .function(funcType))

                let funcTypeIndex = try currentComponent.typeIndexSpace.addDefinition(funcTypeDef)
                currentComponent.definitions.append(.componentType(funcTypeDef, typeIndex: funcTypeIndex))

                // Add function to componentFunctions
                let funcIndex = try currentComponent.componentFunctions.add(
                    ComponentFuncDef(id: funcId, paramNames: params.map(\.name), type: ComponentTypeIndex(rawValue: funcTypeIndex))
                )

                let importDef = ImportDef(
                    importName: importName,
                    descriptor: .function(ComponentFuncIndex(funcIndex))
                )
                currentComponent.definitions.append(.componentImport(importDef))

            case "component":
                // Handle component imports
                let compId = try parser.takeId()

                // Register the imported component in componentsMap so it can be referenced by instantiate
                // The component is a placeholder - the actual component comes from the import
                let compDef = ComponentDef(id: compId)
                _ = try currentComponent.componentsMap.add(compDef)

                // Parse optional type reference or inline component type
                // Disambiguate between:
                //   (type $ref): type reference shorthand
                //   (type $id <body>) or (type ...): inline type declarations
                let typeIndex: Int
                let savedLexer = parser.lexer
                if try parser.takeParenBlockStart("type") {
                    let typeRef = try parser.expectIndexOrId()
                    if try parser.take(.rightParen) {
                        // (type $ref): type reference shorthand
                        typeIndex = try currentComponent.resolveIndex(use: typeRef, in: .componentType)
                    } else {
                        // Not (type $ref), restore and parse as inline component type
                        parser.lexer = savedLexer
                        let componentTypeDef = try parseComponentTypeDeclarations(&parser)
                        let typeDef = ComponentTypeDef(id: nil, kind: .component(componentTypeDef))
                        typeIndex = try registerInlineComponentTypeDef(typeDef)
                    }
                } else {
                    // Inline component type: (component $C1 (import ...) (export ...))
                    let componentTypeDef = try parseComponentTypeDeclarations(&parser)
                    let typeDef = ComponentTypeDef(id: nil, kind: .component(componentTypeDef))
                    typeIndex = try registerInlineComponentTypeDef(typeDef)
                }
                try parser.expect(.rightParen)  // Close (component ...)

                // Add the component import with the type index
                let importDef = ImportDef(
                    importName: importName,
                    descriptor: .component(.index(UInt32(typeIndex), location))
                )
                currentComponent.definitions.append(.componentImport(importDef))

            case "core":
                // (core module $id? (type $ref)?) or (core module $id? (import ...) (export ...) ...)
                try parser.expectKeyword("module")
                let moduleId = try parser.takeId()
                if try parser.takeParenBlockStart("type") {
                    // (core module (type $ref))
                    let typeRef = try parser.expectIndexOrId()
                    try parser.expect(.rightParen)  // Close (type ...)
                    try parser.expect(.rightParen)  // Close (core module ...)

                    let coreTypeIndex = try currentComponent.resolveIndex(use: typeRef, in: .coreType)

                    // Add a placeholder ModuleDef
                    let placeholder = ModuleDef(id: moduleId, wat: nil)
                    _ = try currentComponent.coreModulesMap.add(placeholder)

                    let importDef = ImportDef(
                        importName: importName,
                        descriptor: .coreModule(.index(UInt32(coreTypeIndex), location))
                    )
                    currentComponent.definitions.append(.componentImport(importDef))
                } else {
                    // Inline core module type: parse module body declarations
                    let moduleTypeDef = try parseCoreModuleTypeBody(&parser)
                    try parser.expect(.rightParen)  // Close (core module ...)

                    let coreTypeDef = CoreTypeDef(id: nil, kind: .module(moduleTypeDef))
                    let coreTypeIndex = try currentComponent.coreTypesMap.add(coreTypeDef)
                    currentComponent.definitions.append(.coreType(coreTypeDef))

                    let placeholder = ModuleDef(id: moduleId, wat: nil)
                    _ = try currentComponent.coreModulesMap.add(placeholder)

                    let importDef = ImportDef(
                        importName: importName,
                        descriptor: .coreModule(.index(UInt32(coreTypeIndex), location))
                    )
                    currentComponent.definitions.append(.componentImport(importDef))
                }

            case "value":
                // (import "name" (value $id? <valtype>)) (🪙 gated)
                let valueId = try parser.takeId()
                let valType = try parseComponentValueType(&parser)
                try parser.expect(.rightParen)
                let importDef = ImportDef(
                    importName: importName,
                    descriptor: .valueType(valType)
                )
                currentComponent.definitions.append(.componentImport(importDef))
                // Track value in the value index space
                try currentComponent.valuesMap.add(ValueDef(id: valueId))

            default:
                throw WatParserError("Unsupported import descriptor '\(descKeyword)'", location: parser.lexer.location())
            }
        }
        /// Syntax: (export "name" (func $ref)) or (export "name" (func $instance "exportname"))
        private mutating func parseComponentExport(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let exportName = try parseComponentExternName(&parser)
            try parser.expect(.leftParen)
            let descKeyword = try parser.expectKeyword()

            let descriptor: ExternDesc
            switch descKeyword {
            case "func":
                // Check if it's (func $idx) or (func $instance "name")
                let firstArg = try parser.expectIndexOrId()
                if let exportedName = try parser.takeString() {
                    let funcIndex = try desugarFuncProjection(&parser, instanceRef: firstArg, exportName: exportedName)
                    descriptor = .function(ComponentFuncIndex(Int(funcIndex)))
                } else {
                    // It's (func $idx) - direct function index
                    let funcIndex = try currentComponent.componentFunctions.resolveIndex(use: firstArg)
                    descriptor = .function(ComponentFuncIndex(funcIndex))
                }
                try parser.expect(.rightParen)

            case "instance":
                descriptor = .instance(try parser.expectIndexOrId())
                try parser.expect(.rightParen)

            case "type":
                descriptor = .type(try parser.expectIndexOrId(), nil)  // exports don't have bounds
                try parser.expect(.rightParen)

            case "component":
                let componentRef = try parser.expectIndexOrId()
                let resolvedIndex = try currentComponent.resolveIndex(use: componentRef, in: .component)
                descriptor = .component(.index(UInt32(resolvedIndex), parser.lexer.location()))
                try parser.expect(.rightParen)

            case "value":
                let valueRef = try parser.expectIndexOrId()
                descriptor = .value(valueRef)
                try parser.expect(.rightParen)

            case "core":
                try parser.expectKeyword("module")
                let moduleRef = try parser.expectIndexOrId()
                let resolvedIndex = try currentComponent.resolveIndex(use: moduleRef, in: .coreModule)
                descriptor = .module(.index(UInt32(resolvedIndex), parser.lexer.location()))
                try parser.expect(.rightParen)
            default:
                throw WatParserError("Unsupported export descriptor '\(descKeyword)'", location: parser.lexer.location())
            }

            // Every export creates a new index in its sort's index space
            // (Component Model binary spec: exports produce new indices)
            switch descriptor {
            case .type:
                _ = currentComponent.typeIndexSpace.addExport()
            case .instance:
                let instanceDef = ComponentInstanceDef(id: nil, componentRef: nil, arguments: [])
                _ = try currentComponent.componentInstancesMap.add(instanceDef)
            case .function:
                let funcDef = ComponentFuncDef(
                    id: nil,
                    paramNames: [],
                    type: nil
                )
                _ = try currentComponent.componentFunctions.add(funcDef)
            case .component:
                let componentDef = ComponentDef(id: nil, definitions: [])
                _ = try currentComponent.componentsMap.add(componentDef)
            case .module, .coreModule:
                let moduleDef = ModuleDef(id: nil, wat: nil)
                _ = try currentComponent.coreModulesMap.add(moduleDef)
            default:
                break
            }

            // Parse optional type annotation: (func ...) or (type ...) etc. after the main descriptor
            var typeAnnotation: ExportTypeAnnotation? = nil
            // Deferred annotation type definition: must be appended after the export since
            // annotation types can reference the alias created by the export (e.g., $t' in
            // `(export $t' "t" (type $t)) ... (func (param "x" $t'))`)
            var deferredAnnotationTypeDef: (ComponentTypeDef, Int)? = nil
            if try parser.peek(.leftParen) != nil {
                // There's a type annotation. Parse it as an inline function/instance/component type
                try parser.expect(.leftParen)
                let annotKeyword = try parser.expectKeyword()
                switch annotKeyword {
                case "func":
                    // Parse inline function type annotation
                    var params: [ComponentFuncType.Param] = []
                    var resultType: ComponentDefValType?
                    while try parser.takeParenBlockStart("param") {
                        let paramName = try parser.expectString()
                        let paramType = try parseComponentValueType(&parser)
                        params.append(ComponentFuncType.Param(name: paramName, type: paramType))
                        try parser.expect(.rightParen)
                    }
                    if try parser.takeParenBlockStart("result") {
                        resultType = try parseComponentValueType(&parser)
                        try parser.expect(.rightParen)
                    }
                    try parser.expect(.rightParen)
                    // Extract composite value types (own, borrow, etc.) from the
                    // annotation function type into separate type definitions
                    let rawFuncType = ComponentFuncType(params: params, result: resultType)
                    let funcType = try extractAnnotationFuncTypeComposites(rawFuncType)
                    let typeDef = ComponentTypeDef(id: nil, kind: .function(funcType))
                    let typeIndex = try currentComponent.typeIndexSpace.addDefinition(typeDef)
                    deferredAnnotationTypeDef = (typeDef, typeIndex)
                    typeAnnotation = ExportTypeAnnotation(typeIndex: typeIndex, kind: .function)
                case "instance":
                    // Parse inline instance type annotation
                    let decls = try parseInstanceTypeDeclarations(&parser)
                    try parser.expect(.rightParen)
                    let typeDef = ComponentTypeDef(id: nil, kind: .instance(decls))
                    let typeIndex = try registerInlineComponentTypeDef(typeDef)
                    typeAnnotation = ExportTypeAnnotation(typeIndex: typeIndex, kind: .instance)
                case "component":
                    // Parse inline component type annotation
                    let decls = try parseComponentTypeDeclarations(&parser)
                    try parser.expect(.rightParen)
                    let typeDef = ComponentTypeDef(id: nil, kind: .component(decls))
                    let typeIndex = try registerInlineComponentTypeDef(typeDef)
                    typeAnnotation = ExportTypeAnnotation(typeIndex: typeIndex, kind: .component)
                default:
                    throw WatParserError("Unsupported export type annotation '\(annotKeyword)'", location: parser.lexer.location())
                }
            }

            // Append annotation type def before the export that references it
            if let (typeDef, typeIndex) = deferredAnnotationTypeDef {
                currentComponent.definitions.append(.componentType(typeDef, typeIndex: typeIndex))
            }
            let exportDef = ExportDef(
                exportName: exportName,
                descriptor: descriptor,
                typeAnnotation: typeAnnotation
            )
            currentComponent.definitions.append(.componentExport(exportDef))
        }

        /// Parse a start definition: (start $func (value $v)* (result (value $r?))*)
        private mutating func parseComponentStart(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let funcRef = try parser.expectIndexOrId()

            var args: [Parser.IndexOrId] = []
            while try parser.takeParenBlockStart("value") {
                let valueRef = try parser.expectIndexOrId()
                try parser.expect(.rightParen)
                args.append(valueRef)
            }

            var resultCount = 0
            while try parser.takeParenBlockStart("result") {
                try parser.expect(.leftParen)
                try parser.expectKeyword("value")
                let resultId = try parser.takeId()  // optional result binding id
                // Track result value in the value index space
                try currentComponent.valuesMap.add(ValueDef(id: resultId))
                try parser.expect(.rightParen)
                try parser.expect(.rightParen)
                resultCount += 1
            }

            let startDef = StartDef(funcRef: funcRef, args: args, resultCount: resultCount)
            currentComponent.definitions.append(.componentStart(startDef))
        }

        /// Parses a top-level canon definition: `(canon lift ... (func $id? <type>?))`, or a
        /// definition that produces a core function, `(canon <op> ... (core func $id?))`.
        private mutating func parseTopLevelCanon(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let operation = try parser.expectKeyword()
            if operation == "lift" {
                try parseTopLevelCanonLift(&parser)
            } else {
                try parseCoreFuncCanon(&parser, operation: operation, form: .trailing, location: location)
            }
        }

        /// Where a canon definition that produces a core function binds that function's `$id`.
        private enum CoreFuncCanonForm {
            /// `(core func $id? (canon <op> ...))`; the parse closes `(canon ...)`.
            case nested(id: Name?)
            /// `(canon <op> ... (core func $id?))`; the parse consumes the trailing block.
            case trailing
        }

        /// Parses the rest of a canon definition that produces a core function, after its operation
        /// keyword (`lower`, `resource.new`, `resource.drop` or `resource.rep`),
        /// then registers the core function and appends the canon definition.
        private mutating func parseCoreFuncCanon(
            _ parser: inout Parser,
            operation: String,
            form: CoreFuncCanonForm,
            location: Location
        ) throws(WatParserError) {
            let kind: CanonDef.Kind
            var options: [CanonDef.Option] = []
            switch operation {
            case "lower":
                kind = .lower(try parseCanonLowerFuncRef(&parser))
                let stopBefore: String?
                switch form {
                case .nested: stopBefore = nil
                case .trailing: stopBefore = "core"
                }
                options = try desugarCanonOptions(try parseCanonOptionList(&parser, stopBefore: stopBefore), location: location)
            case "resource.new":
                kind = .resourceNew(try parser.expectIndexOrId())
            case "resource.drop":
                kind = .resourceDrop(try parser.expectIndexOrId())
            case "resource.rep":
                kind = .resourceRep(try parser.expectIndexOrId())
            default:
                throw WatParserError("Unknown canon operation '\(operation)'", location: parser.lexer.location())
            }

            let coreFuncId: Name?
            switch form {
            case .nested(let id):
                coreFuncId = id
                try parser.expect(.rightParen)
            case .trailing:
                try parser.expectParenBlockStart("core")
                try parser.expectKeyword("func")
                coreFuncId = try parser.takeId()
                try parser.expect(.rightParen)
            }

            try currentComponent.coreFunctionsMap.add(CoreAliasDef(id: coreFuncId))
            currentComponent.definitions.append(.canon(CanonDef(kind: kind, options: options, liftTypeIndex: nil)))
        }

        /// A `(canon lift (core func ...) <options>*)` whose function type is not parsed yet.
        private struct CanonLift {
            let coreFunction: FuncIndex
            let options: [CanonDef.Option]
            let location: Location
        }

        /// Parses `(core func ...) <options>*` after `canon lift`, stopping before
        /// `(stopBefore ...)`, or before the closing `)` when `stopBefore` is nil.
        private mutating func parseCanonLift(_ parser: inout Parser, stopBefore: String?) throws(WatParserError) -> CanonLift {
            let location = parser.lexer.location()
            let coreFunction = try parseCoreFunctionIndex(&parser)
            let options = try parseCanonOptionList(&parser, stopBefore: stopBefore)
            return CanonLift(coreFunction: coreFunction, options: options, location: location)
        }

        /// Appends what a `canon lift` desugars into after its function type at `typeIndex`: an
        /// alias for a `(core func $instance "name")` reference, the aliases its options need,
        /// and the canon definition.
        private mutating func emitCanonLift(_ lift: CanonLift, typeIndex: Int) throws(WatParserError) {
            var coreFunction = lift.coreFunction
            if case .export(let instance, let exportName) = coreFunction {
                let index = try emitCoreExportAlias(sort: .func, coreInstanceIndex: instance, exportName: exportName)
                coreFunction = .direct(.index(UInt32(index), lift.location))
            }
            let options = try desugarCanonOptions(lift.options, location: lift.location)
            currentComponent.definitions.append(
                .canon(CanonDef(kind: .lift(coreFunction), options: options, liftTypeIndex: typeIndex)))
        }

        /// Returns `existing`, or appends a definition of `funcType` and returns its type index.
        /// Inline function types are not deduplicated, matching `wasm-tools`.
        private mutating func functionTypeIndex(existing: Int?, _ funcType: ComponentFuncType) throws(WatParserError) -> Int {
            if let existing {
                return existing
            }
            return try registerInlineComponentTypeDef(ComponentTypeDef(kind: .function(funcType)))
        }

        /// Parses `(core func ...) <options>* (func $id? <type>?)` after a top-level `canon lift`.
        private mutating func parseTopLevelCanonLift(_ parser: inout Parser) throws(WatParserError) {
            let lift = try parseCanonLift(&parser, stopBefore: "func")

            try parser.expect(.leftParen)
            try parser.expectKeyword("func")
            let funcId = try parser.takeId()
            var parameters = [ComponentFuncType.Param]()
            var resultType: ComponentDefValType?
            var existingTypeRef: Int?
            while try parser.take(.leftParen) {
                let keyword = try parser.expectKeyword()
                switch keyword {
                case "param":
                    parameters.append(try self.parseComponentFuncParam(&parser))
                case "result":
                    resultType = try parseComponentValueType(&parser)
                case "type":
                    let typeRef = try parser.expectIndexOrId()
                    existingTypeRef = try currentComponent.resolveTypeIndex(use: typeRef)
                default:
                    throw WatParserError(
                        "Unknown component function keyword \(keyword) in canon lift",
                        location: parser.lexer.location()
                    )
                }
                try parser.expect(.rightParen)
            }
            try parser.expect(.rightParen)

            let typeIndex = try functionTypeIndex(existing: existingTypeRef, ComponentFuncType(params: parameters, result: resultType))
            try emitCanonLift(lift, typeIndex: typeIndex)
            _ = try currentComponent.componentFunctions.add(
                ComponentFuncDef(id: funcId, paramNames: parameters.map(\.name), type: ComponentTypeIndex(rawValue: typeIndex))
            )
        }

        /// Parse a component-level alias definition
        /// Syntax: (alias core export $instance "name" (core <sort> $bindingId))
        ///         (alias export $instance "name" (<sort> $bindingId))
        private mutating func parseComponentAlias(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let aliasKeyword = try parser.expectKeyword()

            switch aliasKeyword {
            case "core":
                // Core alias: (alias core export $instance "name" (core <sort> $bindingId))
                try parser.expectKeyword("export")
                let instanceIndex = try parser.expectIndexOrId()
                let exportName = try parser.expectString()

                // Parse: (core <sort> $bindingId)
                try parser.expect(.leftParen)
                try parser.expectKeyword("core")
                let coreSort = try parseCoreDefSort(&parser)
                let bindingId = try parser.takeId()
                try parser.expect(.rightParen)  // Close (core <sort> ...)

                try emitCoreExportAlias(
                    sort: coreSort,
                    coreInstanceIndex: instanceIndex,
                    exportName: exportName,
                    bindingId: bindingId
                )

            case "export":
                // Component alias from instance export: (alias export $instance "name" (<sort> $bindingId))
                let instanceIndex = try parser.expectIndexOrId()
                let exportName = try parser.expectString()

                // Parse: (<sort> $bindingId)
                try parser.expect(.leftParen)
                let sort = try parseComponentDefSort(&parser)
                let bindingId = try parser.takeId()
                try parser.expect(.rightParen)  // Close (<sort> ...)

                try emitComponentExportAlias(
                    sort: sort,
                    instanceIndex: instanceIndex,
                    exportName: exportName,
                    bindingId: bindingId
                )

            case "outer":
                // (alias outer <$ComponentName|count> <$typeId|idx> (<sort> $bindingId?))
                let ctRef = try parser.expectIndexOrId()

                // outerCount is the de Bruijn distance: 0 = current, 1 = immediate parent, etc.
                let outerCount: UInt32
                switch ctRef {
                case .index(let idx, _):
                    outerCount = idx
                case .id(let name, let location):
                    guard let depth = componentStack.lastIndex(where: { $0.id?.value == name.value }) else {
                        throw WatParserError("Component '\(name.value)' not found in outer scope", location: location)
                    }
                    outerCount = UInt32(componentStack.count - 1 - depth)
                }

                let targetRef = try parser.expectIndexOrId()

                // Parse sort: (type $id?) | (core type $id?) | (core module $id?) | (component $id?)
                try parser.expect(.leftParen)
                let sort: OuterAliasKey.Sort
                let sortKw = try parser.expectKeyword()
                switch sortKw {
                case "type":
                    sort = .componentType
                case "component":
                    sort = .component
                case "core":
                    let coreKw = try parser.expectKeyword()
                    switch coreKw {
                    case "type": sort = .coreType
                    case "module": sort = .coreModule
                    default: throw WatParserError("Unknown outer alias core sort '\(coreKw)'", location: parser.lexer.location())
                    }
                default:
                    throw WatParserError("Unknown outer alias sort '\(sortKw)'", location: parser.lexer.location())
                }
                let bindingId = try parser.takeId()
                try parser.expect(.rightParen)

                let targetIndex: UInt32
                switch targetRef {
                case .index(let idx, _):
                    targetIndex = idx
                case .id(let name, let location):
                    guard let distance = Int(exactly: outerCount), distance < componentStack.count else {
                        throw WatParserError("Cannot resolve outer alias target outside component stack", location: location)
                    }
                    let target = componentStack[componentStack.count - 1 - distance]
                    guard let index = target.index(of: name.value, in: sort) else {
                        throw WatParserError("Cannot resolve outer alias target '\(name.value)'", location: location)
                    }
                    targetIndex = UInt32(index)
                }

                let index = try currentComponent.addOuterAliasEntry(sort, id: bindingId)
                currentComponent.definitions.append(
                    .alias(
                        ComponentAlias(
                            sort: sort.aliasSort,
                            target: .outer(outerCount: outerCount, targetIndex: targetIndex),
                            bindingId: bindingId,
                            typeIndex: sort == .componentType ? index : nil
                        )))

            default:
                throw WatParserError("Unsupported alias keyword '\(aliasKeyword)'", location: parser.lexer.location())
            }
        }

        /// Parse a component instance definition
        /// Syntax: (instance $id (instantiate $component (with "name" (instance $ref))...))
        /// Parse instance exports: (export "name" (<sort> $ref)) ...
        /// Handles the function projection `(func $inst "name")`.
        private mutating func parseInstanceExports(_ parser: inout Parser) throws(WatParserError) -> [ComponentInstanceExport] {
            var exports = [ComponentInstanceExport]()
            while try parser.takeParenBlockStart("export") {
                let exportName = try parseComponentExternName(&parser)
                try parser.expect(.leftParen)
                let sort = try parseComponentDefSort(&parser)
                let ref: Parser.IndexOrId
                switch sort {
                case .func:
                    let funcRef = try parser.expectIndexOrId()
                    if let exportedName = try parser.takeString() {
                        let funcIndex = try desugarFuncProjection(&parser, instanceRef: funcRef, exportName: exportedName)
                        ref = .index(funcIndex, parser.lexer.location())
                    } else {
                        ref = funcRef
                    }
                case .type, .instance, .component, .core(.module):
                    ref = try parser.expectIndexOrId()
                case .core(let coreSort):
                    throw WatParserError("Unsupported core export sort '\(coreSort.keyword)'", location: parser.lexer.location())
                case .value:
                    throw WatParserError("Unsupported export sort 'value'", location: parser.lexer.location())
                }
                try parser.expect(.rightParen)
                try parser.expect(.rightParen)
                exports.append(ComponentInstanceExport(name: exportName, sort: sort, ref: ref))
            }
            return exports
        }

        private mutating func parseComponentInstance(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let instanceId = try parser.takeId()

            // Empty instance body: no (export ...) or (instantiate ...) inside.
            if try parser.peek(.rightParen) != nil {
                let instanceDef = ComponentInstanceDef(id: instanceId, componentRef: nil, arguments: [], exports: [])
                _ = try currentComponent.componentInstancesMap.add(instanceDef)
                currentComponent.definitions.append(.componentInstance(instanceDef))
                return
            }
            // Check if this is a value-based instance (export ...) or instantiate
            guard let nextKeyword = try parser.peekKeywordAfterLeftParen() else {
                throw WatParserError("Expected (instantiate ...) or (export ...)", location: parser.lexer.location())
            }

            if nextKeyword == "export" {
                // Value-based instance: (instance $id (export "name" (<sort> $ref)) ...)
                let exports = try parseInstanceExports(&parser)

                let instanceDef = ComponentInstanceDef(id: instanceId, componentRef: nil, arguments: [], exports: exports)
                _ = try currentComponent.componentInstancesMap.add(instanceDef)
                currentComponent.definitions.append(.componentInstance(instanceDef))
                return
            }

            try parser.expect(.leftParen)
            try parser.expectKeyword("instantiate")

            // Component reference: either a direct index/id or a projection (component $inst "name")
            let componentRef: Parser.IndexOrId
            if let directRef = try parser.takeIndexOrId() {
                let resolvedIndex = try currentComponent.resolveIndex(use: directRef, in: .component)
                componentRef = .index(UInt32(resolvedIndex), parser.lexer.location())
            } else {
                // Must be (component $inst "name") projection
                try parser.expect(.leftParen)
                try parser.expectKeyword("component")
                let instRef = try parser.expectIndexOrId()
                let exportedName = try parser.expectString()
                try parser.expect(.rightParen)

                let idx = try emitComponentExportAlias(
                    sort: .component,
                    instanceIndex: instRef,
                    exportName: exportedName
                )
                componentRef = .index(UInt32(idx), parser.lexer.location())
            }
            var arguments = [ComponentInstanceArgument]()

            while try parser.takeParenBlockStart("with") {
                let argName = try parser.expectString()
                try parser.expect(.leftParen)
                let sort = try parseComponentDefSort(&parser)
                let ref: Parser.IndexOrId
                switch sort {
                case .instance:
                    // (instance $ref) or (instance (export "name" (<sort> $ref)) ...)
                    if let instanceRef = try parser.takeIndexOrId() {
                        ref = instanceRef
                    } else {
                        // Inline anonymous value-based instance
                        let exports = try parseInstanceExports(&parser)
                        let instanceDef = ComponentInstanceDef(id: nil, componentRef: nil, arguments: [], exports: exports)
                        let idx = try currentComponent.componentInstancesMap.add(instanceDef)
                        currentComponent.definitions.append(.componentInstance(instanceDef))
                        ref = .index(UInt32(idx), location)
                    }
                case .type, .core(.module):
                    ref = try parser.expectIndexOrId()
                case .component:
                    let componentRef = try parser.expectIndexOrId()
                    let resolvedIndex = try currentComponent.resolveIndex(use: componentRef, in: .component)
                    ref = .index(UInt32(resolvedIndex), parser.lexer.location())
                case .func:
                    // (func $instance "exportName") or (func $ref)
                    let firstRef = try parser.expectIndexOrId()
                    if let exportName = try parser.takeString() {
                        let funcIndex = try desugarFuncProjection(&parser, instanceRef: firstRef, exportName: exportName)
                        ref = .index(funcIndex, location)
                    } else {
                        // (func $ref) - direct function reference
                        let funcIndex = try currentComponent.componentFunctions.resolveIndex(use: firstRef)
                        ref = .index(UInt32(funcIndex), location)
                    }
                case .core(let coreSort):
                    throw WatParserError(
                        "Unsupported core sort '\(coreSort.keyword)' in instantiation argument",
                        location: parser.lexer.location()
                    )
                case .value:
                    throw WatParserError("Unsupported component instance argument kind 'value'", location: parser.lexer.location())
                }

                try parser.expect(.rightParen)  // Close (instance ...)
                try parser.expect(.rightParen)  // Close (with ...)
                arguments.append(ComponentInstanceArgument(name: argName, sort: sort, ref: ref))
            }

            try parser.expect(.rightParen)  // Close (instantiate ...)

            let instanceDef = ComponentInstanceDef(id: instanceId, componentRef: componentRef, arguments: arguments)
            _ = try currentComponent.componentInstancesMap.add(instanceDef)
            currentComponent.definitions.append(.componentInstance(instanceDef))
        }

        /// Parse a component type definition (func, instance, component, or primitive) with optional inline exports
        private mutating func parseComponentTypeDef(_ parser: inout Parser) throws(WatParserError) {
            let typeLocation = parser.lexer.location()
            let typeId = try parser.takeId()

            // Parse inline exports (zero or more)
            var inlineExports: [(location: Location, name: String)] = []
            while try parser.takeParenBlockStart("export") {
                let exportLocation = parser.lexer.location()
                let exportName = try parser.expectString()
                inlineExports.append((location: exportLocation, name: exportName))
                try parser.expect(.rightParen)
            }

            let kind: ComponentTypeDef.Kind
            var pendingDestructorRef: FuncIndex? = nil  // For resource types with destructors
            if try parser.take(.leftParen) {
                // Parenthesized type constructor
                let typeKeyword = try parser.expectKeyword()

                switch typeKeyword {
                case "func":
                    let params = try parseFuncParams(&parser)
                    var resultType: ComponentDefValType?
                    if try parser.takeParenBlockStart("result") {
                        resultType = try parseComponentValueType(&parser)
                        try parser.expect(.rightParen)
                    }
                    kind = .function(ComponentFuncType(params: params, result: resultType))
                    try parser.expect(.rightParen)

                case "instance":
                    let instanceTypeDef = try parseInstanceTypeDeclarations(&parser, typeName: typeId?.value)
                    kind = .instance(instanceTypeDef)
                    try parser.expect(.rightParen)

                case "component":
                    let componentTypeDef = try parseComponentTypeDeclarations(&parser, typeName: typeId?.value)
                    kind = .component(componentTypeDef)
                    try parser.expect(.rightParen)

                case "record", "variant", "flags", "enum", "list", "tuple", "option", "result",
                    "own", "borrow":
                    let valueType = try parseCompositeValueTypeBody(
                        keyword: typeKeyword, &parser,
                        recurse: { (p: inout ComponentWatParser, parser: inout Parser) throws(WatParserError) -> ComponentDefValType in
                            try p.parseComponentValueType(&parser)
                        },
                        resolveTypeRef: { (p: inout ComponentWatParser, ref: Parser.IndexOrId) throws(WatParserError) -> ComponentTypeIndex in
                            let index = try p.currentComponent.resolveIndex(use: ref, in: .componentType)
                            return ComponentTypeIndex(rawValue: index)
                        },
                        toInlined: { (p: inout ComponentWatParser, valueType: ComponentDefValType) throws(WatParserError) -> ComponentValType in
                            try p.toInlinedValueType(valueType)
                        }
                    )
                    kind = .value(valueType)

                case "resource":
                    // Parse: (resource (rep i32) [(dtor (func $instance "export"))])
                    // Check for (rep i32)
                    if try parser.takeParenBlockStart("rep") {
                        let repType = try parser.expectKeyword()
                        guard repType == "i32" else {
                            throw WatParserError(
                                "resources can only be represented by `i32`",
                                location: parser.lexer.location()
                            )
                        }
                        try parser.expect(.rightParen)
                    }

                    // Check for optional destructor (dtor (func $instance "export"))
                    if try parser.takeParenBlockStart("dtor") {
                        // Parse (func $instance "export")
                        try parser.expect(.leftParen)
                        try parser.expectKeyword("func")
                        let instanceRef = try parser.expectIndexOrId()
                        let exportName = try parser.expectString()
                        try parser.expect(.rightParen)
                        try parser.expect(.rightParen)

                        // Store the destructor reference; an alias is created before the type.
                        pendingDestructorRef = .export(instance: instanceRef, exportName: exportName)
                    }

                    try parser.expect(.rightParen)

                    // If there's a destructor, emit an alias for it first
                    // This must happen BEFORE the type definition is added to definitions
                    var destructorCoreFuncIndex: ComponentFuncIndex? = nil
                    if case .export(let instanceRef, let exportName) = pendingDestructorRef {
                        let coreFuncIndex = try emitCoreExportAlias(sort: .func, coreInstanceIndex: instanceRef, exportName: exportName)
                        destructorCoreFuncIndex = ComponentFuncIndex(coreFuncIndex)
                    }

                    // Create resource type with the actual destructor index (not sentinel)
                    let resourceType = ComponentDefValType.resource(destructor: destructorCoreFuncIndex)
                    kind = .value(resourceType)

                default:
                    throw WatParserError(
                        "Unsupported type definition keyword \(typeKeyword)",
                        location: parser.lexer.location()
                    )
                }
            } else {
                // Shorthand: primitive value type keyword directly (e.g., `bool`, `u8`, etc.)
                let primitiveType = try parseComponentValueType(&parser)
                kind = .value(primitiveType)
            }

            let typeDef = ComponentTypeDef(id: typeId, kind: kind)
            let typeIndex = try self.currentComponent.typeIndexSpace.addDefinition(typeDef)

            // Store destructor reference if this is a resource type with a destructor
            if let destructorRef = pendingDestructorRef {
                self.currentComponent.destructorRefs[typeIndex] = destructorRef
            }

            // Add the type definition to fields
            self.currentComponent.definitions.append(.componentType(typeDef, typeIndex: typeIndex))

            // Generate exports for inline export annotations (after the type)
            emitInlineExports(inlineExports) { _ in
                .type(.index(UInt32(typeIndex), typeLocation), nil)
            }
        }

        private mutating func parseModuleDef(_ parser: inout Parser) throws(WatParserError) -> ModuleDef {
            let moduleID = try parser.takeId()
            let wat = try parseWAT(&parser, features: features)
            return .init(id: moduleID, wat: wat)
        }

        private mutating func parseModuleInstanceArguments(_ parser: inout Parser) throws(WatParserError) -> CoreInstanceDef.Argument {
            try parser.expectKeyword("with")
            let importName = try parser.expectString()
            try parser.expect(.leftParen)

            let result: CoreInstanceDef.Argument.Kind
            if try parser.takeKeyword("instance") {
                // Check if it's a reference to an existing instance or inline exports
                if try parser.peek(.leftParen) != nil {
                    // Inline exports: (instance (export "name" (func $ref))...)
                    let exports = try parseCoreExports(&parser)
                    result = .exports(exports)
                } else {
                    // Reference to existing instance: (instance $ref)
                    let instanceID = try parser.expectIndexOrId()
                    result = .instance(instanceID)
                }
            } else {
                throw WatParserError("Expected 'instance' keyword after '('", location: parser.lexer.location())
            }
            try parser.expect(.rightParen)
            return .init(importName: importName, kind: result)
        }

        /// Parse a sequence of (export "name" (<sort> $ref)) entries for core instances.
        private mutating func parseCoreExports(_ parser: inout Parser) throws(WatParserError) -> [CoreInstanceDef.Argument.Kind.Export] {
            var exports: [CoreInstanceDef.Argument.Kind.Export] = []
            while try parser.takeParenBlockStart("export") {
                let exportName = try parser.expectString()
                try parser.expect(.leftParen)
                let sort = try parseCoreDefSort(&parser)
                let indexOrId = try parser.expectIndexOrId()

                let resolvedIndex = try resolveCoreIndex(sort: sort, ref: indexOrId)

                try parser.expect(.rightParen)  // Close (func/memory/etc.)
                try parser.expect(.rightParen)  // Close (export ...)

                exports.append(.init(name: exportName, sort: sort, index: resolvedIndex))
            }
            return exports
        }

        private mutating func parseCoreDefSort(_ parser: inout Parser) throws(WatParserError) -> CoreDefSort {
            let rawKeyword = try parser.expectKeyword()
            guard let keyword = CoreDefSort(keyword: rawKeyword) else {
                throw WatParserError(
                    "Unexpected core declaration sort '\(rawKeyword)'",
                    location: parser.lexer.location()
                )
            }

            return keyword
        }

        private mutating func parseComponentDefSort(_ parser: inout Parser) throws(WatParserError) -> ComponentDefSort {
            let rawKeyword = try parser.expectKeyword()
            switch rawKeyword {
            case "core":
                return .core(try parseCoreDefSort(&parser))

            case "func": return .func
            case "value": return .value
            case "type": return .type
            case "component": return .component
            case "instance": return .instance

            default:
                throw WatParserError(
                    "Unexpected component declaration sort '\(rawKeyword)'",
                    location: parser.lexer.location()
                )
            }
        }

        private mutating func parseCoreInstanceDef(_ parser: inout Parser) throws(WatParserError) -> CoreInstanceDef {
            let instanceId = try parser.takeId()

            // Check if this is an export-form or instantiate-form instance
            guard let nextKeyword = try parser.peekKeywordAfterLeftParen() else {
                throw WatParserError("Expected (instantiate ...) or (export ...)", location: parser.lexer.location())
            }

            if nextKeyword == "export" {
                // Export-form: (core instance $id (export "name" (func $ref)) ...)
                let exports = try parseCoreExports(&parser)
                return CoreInstanceDef(id: instanceId, form: .exports(exports))
            }

            try parser.expect(.leftParen)
            try parser.expectKeyword("instantiate")

            var instantiatedModuleId = try parser.expectIndexOrId()

            if case .id = instantiatedModuleId {
                let resolvedIndex = try currentComponent.resolveIndex(use: instantiatedModuleId, in: .coreModule)
                instantiatedModuleId = .index(UInt32(resolvedIndex), parser.lexer.location())
            }

            var instantiateArguments = [CoreInstanceDef.Argument]()

            while try parser.take(.leftParen) {
                instantiateArguments.append(try self.parseModuleInstanceArguments(&parser))
                try parser.expect(.rightParen)
            }

            try parser.expect(.rightParen)

            return CoreInstanceDef(
                id: instanceId,
                form: .instantiate(moduleId: instantiatedModuleId, arguments: instantiateArguments)
            )
        }

        /// Parse the body of a core module type definition (alias, import, export declarations).
        private mutating func parseCoreModuleTypeBody(_ parser: inout Parser) throws(WatParserError) -> CoreModuleTypeDef {
            var declarations: [CoreModuleDecl] = []
            var nextModuleTypeIndex = 0
            var typeIdBindings: [(id: Name, declIndex: Int)] = []
            // Track explicitly declared function types for typeuse resolution:
            // inline types are deduplicated against explicit (type ...) declarations only
            var explicitFuncTypes: [WasmTypes.FunctionType: Int] = [:]

            /// Helper: resolve an inline function type against explicit declarations.
            /// If a matching explicit type exists, returns its type index.
            /// Otherwise creates a new inline type declaration and returns its index.
            func resolveInlineType(_ funcType: WasmTypes.FunctionType) -> Int {
                if let existing = explicitFuncTypes[funcType] {
                    return existing
                }
                let typeIdx = nextModuleTypeIndex
                declarations.append(.type(funcType))
                nextModuleTypeIndex += 1
                return typeIdx
            }

            while try parser.take(.leftParen) {
                let declKeyword = try parser.expectKeyword()
                switch declKeyword {
                case "type":
                    let typeId = try parser.takeId()
                    try parser.expect(.leftParen)
                    try parser.expectKeyword("func")
                    let (parameters, _) = try parser.parseParamList(mayHaveName: true) { parser throws(WatParserError) in
                        try Self.parseCoreValueType(&parser)
                    }
                    let results = try parser.parseResultList { parser throws(WatParserError) in
                        try Self.parseCoreValueType(&parser)
                    }
                    let funcType = WasmTypes.FunctionType(parameters: parameters, results: results)
                    try parser.expect(.rightParen)
                    if let typeId {
                        typeIdBindings.append((id: typeId, declIndex: declarations.count))
                    }
                    // Register explicit type declarations for typeuse resolution
                    explicitFuncTypes[funcType] = nextModuleTypeIndex
                    declarations.append(.type(funcType))
                    nextModuleTypeIndex += 1

                case "alias":
                    try parser.expectKeyword("outer")
                    let componentIndex = try parser.expectIndexOrId()
                    let typeIndex = try parser.expectIndexOrId()
                    try parser.expect(.leftParen)
                    let aliasSort = try parseCoreDefSort(&parser)
                    let bindingId = try parser.takeId()
                    try parser.expect(.rightParen)

                    let (resolvedIndex, outerCount) = try resolveOuterReference(componentId: componentIndex, typeIndex: typeIndex, sort: aliasSort)

                    declarations.append(
                        .alias(
                            CoreModuleAlias(
                                sort: aliasSort,
                                target: .outer(componentId: componentIndex, index: typeIndex, resolvedIndex: resolvedIndex, outerCount: outerCount),
                                bindingId: bindingId
                            )))
                    if aliasSort == .type {
                        nextModuleTypeIndex += 1
                    }

                case "import":
                    let moduleName = try parser.expectString()
                    let importName = try parser.expectString()
                    var inlineDecls: [CoreModuleDecl]? = []
                    var tempNextTypeIndex = nextModuleTypeIndex
                    var descriptor = try Self.parseCoreImportDesc(&parser, inlineTypeDecls: &inlineDecls, nextTypeIndex: &tempNextTypeIndex)
                    // Deduplicate inline type declarations
                    if let inlineDecls, !inlineDecls.isEmpty {
                        for decl in inlineDecls {
                            if case .type(let funcType) = decl {
                                let idx = resolveInlineType(funcType)
                                descriptor = .func(typeIndex: .index(UInt32(idx), parser.lexer.location()))
                            }
                        }
                    }
                    declarations.append(
                        .import(
                            CoreModuleImport(
                                moduleName: moduleName,
                                name: importName,
                                descriptor: descriptor
                            )))

                case "export":
                    let exportName = try parser.expectString()
                    var exportInlineDecls: [CoreModuleDecl]? = []
                    var tempNextTypeIndex = nextModuleTypeIndex
                    var descriptor = try Self.parseCoreImportDesc(&parser, inlineTypeDecls: &exportInlineDecls, nextTypeIndex: &tempNextTypeIndex)
                    // Deduplicate inline type declarations
                    if let exportInlineDecls, !exportInlineDecls.isEmpty {
                        for decl in exportInlineDecls {
                            if case .type(let funcType) = decl {
                                let idx = resolveInlineType(funcType)
                                descriptor = .func(typeIndex: .index(UInt32(idx), parser.lexer.location()))
                            }
                        }
                    }
                    declarations.append(
                        .export(
                            CoreModuleExport(
                                name: exportName,
                                descriptor: descriptor
                            )))

                default:
                    throw WatParserError("Unknown module declaration '\(declKeyword)'", location: parser.lexer.location())
                }
                try parser.expect(.rightParen)
            }

            var moduleTypeDef = CoreModuleTypeDef(declarations: declarations)

            // Build local type bindings from aliases and type declarations
            for (index, decl) in declarations.enumerated() {
                if case .alias(let alias) = decl,
                    alias.sort == .type,
                    let bindingId = alias.bindingId
                {
                    if moduleTypeDef.localTypeBindings[bindingId.value] != nil {
                        throw WatParserError("Duplicate type binding \(bindingId.value)", location: bindingId.location)
                    }
                    moduleTypeDef.localTypeBindings[bindingId.value] = index
                }
            }
            for binding in typeIdBindings {
                if moduleTypeDef.localTypeBindings[binding.id.value] != nil {
                    throw WatParserError("Duplicate type binding \(binding.id.value)", location: binding.id.location)
                }
                moduleTypeDef.localTypeBindings[binding.id.value] = binding.declIndex
            }

            return moduleTypeDef
        }

        private mutating func parseCoreTypeDef(_ parser: inout Parser) throws(WatParserError) -> CoreTypeDef {
            let typeId = try parser.takeId()
            try parser.expect(.leftParen)
            let keyword = try parser.expectKeyword()

            let kind: CoreTypeDef.Kind
            switch keyword {
            case "func":
                let (parameters, parameterNames) = try parser.parseParamList(mayHaveName: true) { parser throws(WatParserError) in
                    try Self.parseCoreValueType(&parser)
                }

                let results = try parser.parseResultList { parser throws(WatParserError) in
                    try Self.parseCoreValueType(&parser)
                }

                let funcType = WatParser.FunctionType(
                    signature: WasmTypes.FunctionType(parameters: parameters, results: results),
                    parameterNames: parameterNames
                )
                kind = .function(funcType)

            case "module":
                kind = .module(try parseCoreModuleTypeBody(&parser))

            default:
                throw WatParserError("Unknown core type keyword \(keyword)", location: parser.lexer.location())
            }

            try parser.expect(.rightParen)
            return CoreTypeDef(id: typeId, kind: kind)
        }

        /// Resolver that always throws, used for core types that cannot reference other definitions.
        private struct CoreDummyResolver: NameToIndexResolver {
            let message: String
            func resolveIndex(use: Parser.IndexOrId) throws(WatParserError) -> Int {
                throw WatParserError(message, location: use.location)
            }
        }

        private static func parseCoreValueType(_ parser: inout Parser) throws(WatParserError) -> WasmTypes.ValueType {
            var tempParser = WatParser(parser: parser)
            let unresolvedType = try tempParser.valueType()
            parser = tempParser.parser

            // Core types must be simple value types (i32, i64, f32, f64), not type references.
            // Resolve immediately using a dummy resolver since these types don't reference other definitions.
            return try unresolvedType.resolve(CoreDummyResolver(message: "Core value types cannot reference other types"))
        }

        /// Parse a core import/export descriptor: (func (type N)) | (global ...) | (table ...) | (memory ...)
        /// Consumes the outer parentheses.
        private static func parseCoreImportDesc(
            _ parser: inout Parser,
            inlineTypeDecls: inout [CoreModuleDecl]?,
            nextTypeIndex: inout Int
        ) throws(WatParserError) -> CoreImportDesc {
            try parser.expect(.leftParen)
            let descKeyword = try parser.expectKeyword()
            let descriptor: CoreImportDesc
            switch descKeyword {
            case "func":
                // Skip optional export item id (e.g., (func $name))
                _ = try parser.takeId()
                if try parser.takeParenBlockStart("type") {
                    // (func (type N) [(param ...) (result ...)])
                    let typeIndex = try parser.expectIndexOrId()
                    try parser.expect(.rightParen)
                    // Skip any trailing inline param/result annotations (they must
                    // match the referenced type but don't affect the descriptor)
                    _ = try parser.parseParamList(mayHaveName: true) { parser throws(WatParserError) in
                        try parseCoreValueType(&parser)
                    }
                    _ = try parser.parseResultList { parser throws(WatParserError) in
                        try parseCoreValueType(&parser)
                    }
                    descriptor = .func(typeIndex: typeIndex)
                } else {
                    // Inline function type or bare (func): parse params/results
                    let (parameters, _) = try parser.parseParamList(mayHaveName: true) { parser throws(WatParserError) in
                        try parseCoreValueType(&parser)
                    }
                    let results = try parser.parseResultList { parser throws(WatParserError) in
                        try parseCoreValueType(&parser)
                    }
                    let funcType = WasmTypes.FunctionType(parameters: parameters, results: results)
                    let typeIdx = nextTypeIndex
                    nextTypeIndex += 1
                    inlineTypeDecls?.append(.type(funcType))
                    descriptor = .func(typeIndex: .index(UInt32(typeIdx), parser.lexer.location()))
                }
            case "global":
                _ = try parser.takeId()  // skip optional id
                var tempParser = WatParser(parser: parser)
                let unresolvedGlobalType = try tempParser.globalType()
                parser = tempParser.parser
                let globalType = try unresolvedGlobalType.resolve(CoreDummyResolver(message: "Core global types cannot reference other types"))
                descriptor = .global(globalType)
            case "table":
                _ = try parser.takeId()  // skip optional id
                var tempParser = WatParser(parser: parser)
                let unresolvedTableType = try tempParser.tableType()
                parser = tempParser.parser
                let tableType = try unresolvedTableType.resolve(CoreDummyResolver(message: "Core table element types cannot reference other types"))
                descriptor = .table(tableType)
            case "memory":
                _ = try parser.takeId()  // skip optional id
                var tempParser = WatParser(parser: parser)
                let memoryType = try tempParser.memoryType()
                parser = tempParser.parser
                descriptor = .memory(memoryType)
            default:
                throw WatParserError("Unsupported import/export descriptor '\(descKeyword)'", location: parser.lexer.location())
            }
            try parser.expect(.rightParen)
            return descriptor
        }

        /// Resolves an `alias outer` inside a core module type. Returns the target's core type index
        /// and the outer count, counted from the module type, where 1 is the enclosing component.
        private func resolveOuterReference(componentId: Parser.IndexOrId, typeIndex: Parser.IndexOrId, sort: CoreDefSort) throws(WatParserError) -> (resolvedIndex: Int, outerCount: Int) {
            let currentDepth = componentStack.count - 1
            let targetDepth: Int
            switch componentId {
            case .index(let rawCount, let location):
                guard let count = Int(exactly: rawCount), count >= 1, count <= currentDepth else {
                    throw WatParserError("Invalid outer alias count of \(rawCount) in a core module type", location: location)
                }
                targetDepth = currentDepth - (count - 1)
            case .id(let name, let location):
                guard let depth = componentStack.lastIndex(where: { $0.id?.value == name.value }) else {
                    throw WatParserError("Component '\(name.value)' not found in outer scope", location: location)
                }
                targetDepth = depth
            }
            guard sort == .type else {
                throw WatParserError("Outer alias sort '\(sort.keyword)' not yet supported", location: componentId.location)
            }
            let resolvedIndex = try componentStack[targetDepth].coreTypesMap.resolveIndex(use: typeIndex)
            return (resolvedIndex, currentDepth - targetDepth + 1)
        }

        /// Parse alias declaration inside a type definition using local type context.
        /// Syntax: (alias export $instance "name" (type $binding))
        ///         (alias outer $component $typeIndex (type $binding))
        private mutating func parseLocalTypeAlias(
            _ parser: inout Parser,
            context: inout LocalTypeContext
        ) throws(WatParserError) -> TypeAliasDecl {
            let targetKeyword = try parser.expectKeyword()
            let target: TypeAliasDecl.Target

            switch targetKeyword {
            case "export":
                let instanceRef = try parser.expectIndexOrId()
                guard let instanceIndex = context.resolveInstance(instanceRef) else {
                    throw WatParserError(
                        "Cannot resolve instance reference '\(instanceRef)' in local type context",
                        location: parser.lexer.location()
                    )
                }
                let exportName = try parser.expectString()
                target = .export(instanceIndex: instanceIndex, exportName: exportName)

            case "outer":
                let ctRef = try parser.expectIndexOrId()
                let outerCount: UInt32
                // Track which type space to use for resolving the type reference
                var targetTypeBindings: [String: UInt32]? = nil

                switch ctRef {
                case .index(let idx, _):
                    outerCount = idx

                case .id(let name, let location):
                    // Named reference - search typeContextStack, completedTypeContexts, and componentStack
                    var foundCount: UInt32? = nil

                    // First, search the type context stack for matching type definition names (currently being parsed)
                    let typeDepth = typeContextStack.count - 1
                    if typeDepth >= 0 {
                        for i in (0...typeDepth).reversed() {
                            let typeCtx = typeContextStack[i]
                            if let typeName = typeCtx.name, typeName == name.value {
                                // Found a matching type definition
                                foundCount = UInt32(typeDepth - i)
                                targetTypeBindings = typeCtx.typeBindings
                                break
                            }
                        }
                    }

                    // Second, search completed type contexts (types that finished parsing)
                    if foundCount == nil, let bindings = completedTypeContexts[name.value] {
                        foundCount = 1
                        targetTypeBindings = bindings
                    }

                    // Third, search component stack
                    if foundCount == nil {
                        let componentDepth = componentStack.count - 1
                        for i in (0...componentDepth).reversed() {
                            let component = componentStack[i]
                            if let compId = component.id, compId.value == name.value {
                                foundCount = UInt32((componentDepth - i) + 1)
                                targetTypeBindings = nil
                                break
                            }
                        }
                    }

                    guard let count = foundCount else {
                        throw WatParserError(
                            "Component or type '\(name.value)' not found in outer scope",
                            location: location
                        )
                    }
                    outerCount = count
                }

                let idxRef = try parser.expectIndexOrId()
                let typeIndex: UInt32
                switch idxRef {
                case .index(let idx, _):
                    typeIndex = idx
                case .id(let name, _):
                    // Try resolving in target type bindings first, then current component
                    if let bindings = targetTypeBindings, let localIdx = bindings[name.value] {
                        typeIndex = localIdx
                    } else if let resolved = try? currentComponent.resolveTypeIndex(use: idxRef) {
                        typeIndex = UInt32(resolved)
                    } else {
                        throw WatParserError(
                            "Cannot resolve type reference '\(name.value)' in outer alias",
                            location: parser.lexer.location()
                        )
                    }
                }
                target = .outer(outerCount: outerCount, typeIndex: typeIndex)

            default:
                throw WatParserError(
                    "Unknown alias target '\(targetKeyword)'",
                    location: parser.lexer.location()
                )
            }

            // Parse sort: (type $binding) or (instance $binding)
            try parser.expect(.leftParen)
            let sortKeyword = try parser.expectKeyword()
            let sort: ComponentDefSort
            switch sortKeyword {
            case "type":
                sort = .type
            case "instance":
                sort = .instance
            default:
                throw WatParserError(
                    "Unknown alias sort '\(sortKeyword)'",
                    location: parser.lexer.location()
                )
            }

            let bindingId = try parser.takeId()
            try parser.expect(.rightParen)

            return TypeAliasDecl(target: target, sort: sort, bindingId: bindingId)
        }

        /// Parse instance type declarations (type decls and exports, no imports)
        private mutating func parseInstanceTypeDeclarations(_ parser: inout Parser, typeName: String? = nil) throws(WatParserError) -> [ComponentDecl] {
            try parseComponentTypeDeclarations(&parser, typeName: typeName)
        }

        /// Parse component type declarations (type decls, aliases, imports, and exports)
        private mutating func parseComponentTypeDeclarations(_ parser: inout Parser, typeName: String? = nil) throws(WatParserError) -> [ComponentDecl] {
            try enterTypeNesting(&parser)
            defer { typeNestingDepth -= 1 }
            var decls: [ComponentDecl] = []
            var localCtx = LocalTypeContext()
            localCtx.name = typeName

            // Push this context to the stack so it can be found by nested outer aliases
            typeContextStack.append(localCtx)
            let myStackIndex = typeContextStack.count - 1  // Remember our position
            defer {
                // Update the stack with the final context before popping
                typeContextStack[myStackIndex] = localCtx
                // Save to completedTypeContexts if it has a name
                if let name = typeName {
                    completedTypeContexts[name] = localCtx.typeBindings
                }
                typeContextStack.removeLast()
            }

            /// Helper to insert pending outer aliases before a declaration that uses them
            func insertPendingOuterAliases() {
                let pending = localCtx.takePendingOuterAliases()
                for alias in pending {
                    let aliasDecl = TypeAliasDecl(
                        target: .outer(outerCount: alias.outerCount, typeIndex: alias.targetTypeIndex),
                        sort: alias.sort == .coreType ? .core(.type) : .type,
                        bindingId: nil
                    )
                    decls.append(.alias(aliasDecl))
                }
            }

            /// Helper to insert pending inline types before a declaration that uses them
            func insertPendingInlineTypes() {
                let pending = localCtx.takePendingInlineTypes()
                for typeDef in pending {
                    decls.append(.type(typeDef))
                }
                let pendingCore = localCtx.takePendingInlineCoreTypes()
                for coreTypeDef in pendingCore {
                    decls.append(.coreType(coreTypeDef))
                }
            }

            while try parser.take(.leftParen) {
                let declKeyword = try parser.expectKeyword()
                switch declKeyword {
                case "core":
                    // (core type ...) inside a component type definition
                    try parser.expectKeyword("type")
                    let coreTypeDef = try parseCoreTypeDef(&parser)
                    localCtx.nextCoreTypeIndex += 1
                    decls.append(.coreType(coreTypeDef))
                case "type":
                    let typeId = try parser.takeId()
                    let typeKind = try parseInlineTypeKind(&parser, localCtx: &localCtx, typeName: typeId?.value)
                    // Insert any pending inline types created during parseInlineTypeKind
                    // (e.g., tuple types inside a variant) before the type that references them
                    insertPendingInlineTypes()
                    _ = localCtx.registerType(name: typeId?.value)
                    // Update our specific stack position immediately so nested types can see this type
                    typeContextStack[myStackIndex] = localCtx
                    decls.append(.type(ComponentTypeDef(id: typeId, kind: typeKind)))
                case "import":
                    let importName = try parseComponentExternName(&parser)
                    let descriptor = try parseTypeExternDesc(&parser, localCtx: &localCtx)
                    // Insert any pending outer aliases and inline types before this import
                    // Outer aliases must come first since inline types may reference them
                    insertPendingOuterAliases()
                    insertPendingInlineTypes()
                    // Register type if this is a type import
                    if case .type(let typeId, _) = descriptor {
                        _ = localCtx.registerType(name: typeId)
                    }
                    // Register instance if this is an instance import
                    if case .instance(let instanceId, _) = descriptor {
                        _ = localCtx.registerInstance(name: instanceId)
                    }
                    // Always sync the stack: parseTypeExternDesc may have created
                    // outer aliases and registered name bindings in localCtx
                    typeContextStack[myStackIndex] = localCtx
                    decls.append(.import(ExternDecl(name: importName, descriptor: descriptor)))
                case "export":
                    let exportName = try parseComponentExternName(&parser)
                    let descriptor = try parseTypeExternDesc(&parser, localCtx: &localCtx)
                    // Insert any pending outer aliases and inline types before this export
                    // Outer aliases must come first since inline types may reference them
                    insertPendingOuterAliases()
                    insertPendingInlineTypes()
                    // Register type IDs for reference resolution (e.g., (type $T2 ...) creates binding for $T2)
                    if case .type(let id, _) = descriptor {
                        _ = localCtx.registerType(name: id)
                    }
                    // Register instance IDs for alias resolution
                    if case .instance(let id, _) = descriptor {
                        _ = localCtx.registerInstance(name: id)
                    }
                    // Always sync the stack
                    typeContextStack[myStackIndex] = localCtx
                    decls.append(.export(ExternDecl(name: exportName, descriptor: descriptor)))
                case "alias":
                    let aliasDecl = try parseLocalTypeAlias(&parser, context: &localCtx)
                    switch aliasDecl.sort {
                    case .instance:
                        _ = localCtx.registerInstance(name: aliasDecl.bindingId?.value)
                    case .type:
                        _ = localCtx.registerType(name: aliasDecl.bindingId?.value)
                    case .core(.type):
                        localCtx.nextCoreTypeIndex += 1
                    default:
                        throw WatParserError("Unsupported alias sort in a type declaration", location: parser.lexer.location())
                    }
                    typeContextStack[myStackIndex] = localCtx
                    decls.append(.alias(aliasDecl))
                default:
                    throw WatParserError("Unknown component type declaration '\(declKeyword)'", location: parser.lexer.location())
                }
                try parser.expect(.rightParen)
            }

            return decls
        }

        /// Parse the body of a composite value type after the keyword has been consumed.
        /// Returns the raw ComponentDefValType (not indexed/registered).
        private mutating func parseCompositeValueTypeBody(
            keyword: String,
            _ parser: inout Parser,
            recurse: (inout ComponentWatParser, inout Parser) throws(WatParserError) -> ComponentDefValType,
            resolveTypeRef: (inout ComponentWatParser, Parser.IndexOrId) throws(WatParserError) -> ComponentTypeIndex,
            toInlined: (inout ComponentWatParser, ComponentDefValType) throws(WatParserError) -> ComponentValType
        ) throws(WatParserError) -> ComponentDefValType {
            switch keyword {
            case "list":
                let elementType = try recurse(&self, &parser)
                try parser.expect(.rightParen)
                return .list(try toInlined(&self, elementType))

            case "tuple":
                var valTypes: [ComponentValType] = []
                while try !parser.take(.rightParen) {
                    valTypes.append(try toInlined(&self, recurse(&self, &parser)))
                }
                return .tuple(valTypes)

            case "option":
                let someType = try recurse(&self, &parser)
                try parser.expect(.rightParen)
                return .option(try toInlined(&self, someType))

            case "result":
                var okType: ComponentValType?
                var errorType: ComponentValType?
                if try !parser.take(.rightParen) {
                    if try parser.takeParenBlockStart("error") {
                        errorType = try toInlined(&self, recurse(&self, &parser))
                        try parser.expect(.rightParen)
                        try parser.expect(.rightParen)
                    } else if try parser.takeParenBlockStart("ok") {
                        okType = try toInlined(&self, recurse(&self, &parser))
                        try parser.expect(.rightParen)
                        if try parser.takeParenBlockStart("error") {
                            errorType = try toInlined(&self, recurse(&self, &parser))
                            try parser.expect(.rightParen)
                        }
                        try parser.expect(.rightParen)
                    } else {
                        okType = try toInlined(&self, recurse(&self, &parser))
                        if try parser.takeParenBlockStart("error") {
                            errorType = try toInlined(&self, recurse(&self, &parser))
                            try parser.expect(.rightParen)
                        }
                        try parser.expect(.rightParen)
                    }
                }
                return .result(ok: okType, error: errorType)

            case "record":
                var fields: [ComponentRecordField] = []
                while try parser.takeParenBlockStart("field") {
                    let fieldName = try parser.expectString()
                    fields.append(ComponentRecordField(name: fieldName, type: try toInlined(&self, recurse(&self, &parser))))
                    try parser.expect(.rightParen)
                }
                try parser.expect(.rightParen)
                return .record(fields)

            case "variant":
                var cases: [ComponentCaseField] = []
                while try parser.takeParenBlockStart("case") {
                    _ = try parser.takeId()  // optional case binding id (discarded)
                    let caseName = try parser.expectString()
                    let caseType: ComponentValType?
                    if try !parser.take(.rightParen) {
                        caseType = try toInlined(&self, recurse(&self, &parser))
                        try parser.expect(.rightParen)
                    } else {
                        caseType = nil
                    }
                    cases.append(ComponentCaseField(name: caseName, type: caseType))
                }
                try parser.expect(.rightParen)
                return .variant(cases)

            case "flags":
                var flagNames: [String] = []
                while let flagName = try parser.takeString() {
                    flagNames.append(flagName)
                }
                try parser.expect(.rightParen)
                return .flags(flagNames)

            case "enum":
                var enumCases: [String] = []
                while let caseName = try parser.takeString() {
                    enumCases.append(caseName)
                }
                try parser.expect(.rightParen)
                return .enum(enumCases)

            case "own":
                let resourceTypeRef = try parser.expectIndexOrId()
                let resourceTypeIndex = try resolveTypeRef(&self, resourceTypeRef)
                try parser.expect(.rightParen)
                return .own(ResourceTypeIndex(rawValue: Int(resourceTypeIndex.rawValue)))

            case "borrow":
                let resourceTypeRef = try parser.expectIndexOrId()
                let resourceTypeIndex = try resolveTypeRef(&self, resourceTypeRef)
                try parser.expect(.rightParen)
                return .borrow(ResourceTypeIndex(rawValue: Int(resourceTypeIndex.rawValue)))

            default:
                throw WatParserError(
                    "Unexpected composite component type keyword `\(keyword)`",
                    location: parser.lexer.location()
                )
            }
        }

        /// Unified value type parser. The closures abstract the differences between
        /// global (component-level) and local (type-body-level) contexts.
        private mutating func parseComponentValueTypeImpl(
            _ parser: inout Parser,
            resolveTypeRef: (inout ComponentWatParser, Parser.IndexOrId) throws(WatParserError) -> ComponentTypeIndex,
            recurse: (inout ComponentWatParser, inout Parser) throws(WatParserError) -> ComponentDefValType,
            registerType: (inout ComponentWatParser, ComponentDefValType) throws(WatParserError) -> ComponentTypeIndex,
            toInlined: (inout ComponentWatParser, ComponentDefValType) throws(WatParserError) -> ComponentValType
        ) throws(WatParserError) -> ComponentDefValType {
            // Type reference by $id
            if let typeRef = try parser.takeId() {
                let typeIndex = try resolveTypeRef(&self, .id(typeRef, typeRef.location))
                return .indexed(typeIndex)
            }

            // Type reference by numeric index
            if let numericIndex: UInt32 = try parser.takeUnsignedInt() {
                let typeIndex = try resolveTypeRef(&self, .index(numericIndex, parser.lexer.location()))
                return .indexed(typeIndex)
            }

            // Primitive types
            if let keyword = try parser.peekKeyword() {
                if let primitiveType = Self.parsePrimitiveValueType(keyword) {
                    try parser.consume()
                    return .primitive(primitiveType)
                }
            }

            // Composite types
            try enterTypeNesting(&parser)
            defer { typeNestingDepth -= 1 }
            try parser.expect(.leftParen)
            let keyword = try parser.expectKeyword()
            let valueType = try parseCompositeValueTypeBody(
                keyword: keyword, &parser,
                recurse: recurse, resolveTypeRef: resolveTypeRef, toInlined: toInlined
            )
            return .indexed(try registerType(&self, valueType))
        }

        /// Parse a primitive value type keyword, returning nil if not a primitive.
        private static func parsePrimitiveValueType(_ keyword: String) -> ComponentPrimValType? {
            switch keyword {
            case "bool": return .bool
            case "u8": return .u8
            case "u16": return .u16
            case "u32": return .u32
            case "u64": return .u64
            case "s8": return .s8
            case "s16": return .s16
            case "s32": return .s32
            case "s64": return .s64
            case "float32", "f32": return .float32
            case "float64", "f64": return .float64
            case "char": return .char
            case "string": return .string
            case "error-context": return .errorContext
            default: return nil
            }
        }

        private mutating func parseComponentValueType(_ parser: inout Parser) throws(WatParserError) -> ComponentDefValType {
            try parseComponentValueTypeImpl(
                &parser,
                resolveTypeRef: { (p: inout ComponentWatParser, ref: Parser.IndexOrId) throws(WatParserError) -> ComponentTypeIndex in
                    let index = try p.currentComponent.resolveIndex(use: ref, in: .componentType)
                    return ComponentTypeIndex(rawValue: index)
                },
                recurse: { (p: inout ComponentWatParser, parser: inout Parser) throws(WatParserError) -> ComponentDefValType in
                    try p.parseComponentValueType(&parser)
                },
                registerType: { (p: inout ComponentWatParser, valueType: ComponentDefValType) throws(WatParserError) -> ComponentTypeIndex in
                    try p.addAnonymousComponentType(valueType)
                },
                toInlined: { (p: inout ComponentWatParser, valueType: ComponentDefValType) throws(WatParserError) -> ComponentValType in
                    try p.toInlinedValueType(valueType)
                }
            )
        }

        /// Parse a component value type within a local type context.
        /// First checks the local context for type references, then falls back to global resolution
        /// and creates outer aliases as needed.
        private mutating func parseLocalComponentValueType(
            _ parser: inout Parser,
            context: inout LocalTypeContext
        ) throws(WatParserError) -> ComponentDefValType {
            try parseComponentValueTypeImpl(
                &parser,
                resolveTypeRef: { (p: inout ComponentWatParser, ref: Parser.IndexOrId) throws(WatParserError) -> ComponentTypeIndex in
                    if let localIndex = context.resolveType(ref) {
                        return ComponentTypeIndex(rawValue: Int(localIndex))
                    }
                    let outerIndex = UInt32(try p.currentComponent.resolveTypeIndex(use: ref))
                    let localIndex = context.getOrCreateOuterAlias(outerCount: 1, targetTypeIndex: outerIndex)
                    return ComponentTypeIndex(rawValue: Int(localIndex))
                },
                recurse: { (p: inout ComponentWatParser, parser: inout Parser) throws(WatParserError) -> ComponentDefValType in
                    try p.parseLocalComponentValueType(&parser, context: &context)
                },
                registerType: { (_: inout ComponentWatParser, valueType: ComponentDefValType) throws(WatParserError) -> ComponentTypeIndex in
                    let typeDef = ComponentTypeDef(id: nil, kind: .value(valueType))
                    let idx = context.addInlineType(typeDef)
                    return ComponentTypeIndex(rawValue: Int(idx))
                },
                toInlined: { (_: inout ComponentWatParser, valueType: ComponentDefValType) throws(WatParserError) -> ComponentValType in
                    if case .inlined(let inlined) = valueType { return inlined }
                    let typeDef = ComponentTypeDef(id: nil, kind: .value(valueType))
                    let idx = context.addInlineType(typeDef)
                    return .index(ComponentTypeIndex(rawValue: Int(idx)))
                }
            )
        }

        /// Parse a type kind for inline type declarations inside instance/component types.
        /// Handles: (instance ...), (component ...), (func ...), value types, or type reference
        /// This is used for (type ...) declarations inside instance and component type definitions.
        private mutating func parseInlineTypeKind(
            _ parser: inout Parser,
            localCtx: inout LocalTypeContext,
            typeName: String? = nil
        ) throws(WatParserError) -> ComponentTypeDef.Kind {
            // Check for parenthesized type constructor
            if try parser.peek(.leftParen) != nil {
                try parser.expect(.leftParen)
                let keyword = try parser.expectKeyword()

                switch keyword {
                case "instance":
                    // Parse inline instance type: (instance (export "name" ...) ...)
                    let instanceTypeDef = try parseInstanceTypeDeclarations(&parser)
                    try parser.expect(.rightParen)
                    return .instance(instanceTypeDef)

                case "component":
                    // Parse inline component type: (component (import ...) (export ...) ...)
                    let componentTypeDef = try parseComponentTypeDeclarations(&parser, typeName: typeName)
                    try parser.expect(.rightParen)
                    return .component(componentTypeDef)

                case "func":
                    // Parse inline function type: (func (param ...) (result ...))
                    let params = try parseLocalFuncParams(&parser, context: &localCtx)
                    var resultType: ComponentDefValType?
                    if try parser.takeParenBlockStart("result") {
                        resultType = try parseLocalComponentValueType(&parser, context: &localCtx)
                        try parser.expect(.rightParen)
                    }
                    try parser.expect(.rightParen)
                    // Extract composite value types into separate type definitions
                    let funcType = localCtx.extractFuncTypeComposites(
                        ComponentFuncType(params: params, result: resultType))
                    return .function(funcType)

                // Handle composite value types via shared parser
                case "list", "tuple", "option", "result", "record", "variant",
                    "flags", "enum", "own", "borrow":
                    let valueType = try parseCompositeValueTypeBody(
                        keyword: keyword, &parser,
                        recurse: { (p: inout ComponentWatParser, parser: inout Parser) throws(WatParserError) -> ComponentDefValType in
                            try p.parseLocalComponentValueType(&parser, context: &localCtx)
                        },
                        resolveTypeRef: { (p: inout ComponentWatParser, ref: Parser.IndexOrId) throws(WatParserError) -> ComponentTypeIndex in
                            if let localIndex = localCtx.resolveType(ref) {
                                return ComponentTypeIndex(rawValue: Int(localIndex))
                            }
                            let outerIndex = UInt32(try p.currentComponent.resolveTypeIndex(use: ref))
                            let localIndex = localCtx.getOrCreateOuterAlias(outerCount: 1, targetTypeIndex: outerIndex)
                            return ComponentTypeIndex(rawValue: Int(localIndex))
                        },
                        toInlined: { (p: inout ComponentWatParser, valueType: ComponentDefValType) throws(WatParserError) -> ComponentValType in
                            if case .inlined(let inlined) = valueType { return inlined }
                            let typeDef = ComponentTypeDef(id: nil, kind: .value(valueType))
                            let idx = localCtx.addInlineType(typeDef)
                            return .index(ComponentTypeIndex(rawValue: Int(idx)))
                        }
                    )
                    return .value(valueType)

                case "resource":
                    throw WatParserError(
                        "resources can only be defined within a concrete component",
                        location: parser.lexer.location()
                    )

                default:
                    throw WatParserError("Unknown type constructor '\(keyword)' in type declaration", location: parser.lexer.location())
                }
            } else {
                // No parenthesis - parse as primitive value type or type reference
                let valueType = try parseLocalComponentValueType(&parser, context: &localCtx)
                return .value(valueType)
            }
        }

        /// Parse function parameters using local type context
        private mutating func parseLocalFuncParams(
            _ parser: inout Parser,
            context: inout LocalTypeContext
        ) throws(WatParserError) -> [ComponentFuncType.Param] {
            var params: [ComponentFuncType.Param] = []
            while try parser.takeParenBlockStart("param") {
                let name = try parser.expectString()
                let type = try parseLocalComponentValueType(&parser, context: &context)
                params.append(ComponentFuncType.Param(name: name, type: type))
                try parser.expect(.rightParen)
            }
            return params
        }

        /// Add a fresh anonymous component type for an inline type reference.
        ///
        /// wasm-tools never deduplicates anonymous inline value types: each occurrence gets its own
        /// definition even when structurally identical to an earlier one (two `(list string)` params, or
        /// `(list u32)` reused across functions, all become distinct type defs). Emit one fresh def per
        /// occurrence to match the reference encoder byte-for-byte.
        private mutating func addAnonymousComponentType(_ valueType: ComponentDefValType) throws(WatParserError) -> ComponentTypeIndex {
            let typeDef = ComponentTypeDef(id: nil, kind: .value(valueType))
            let typeIndex = try currentComponent.typeIndexSpace.addDefinition(typeDef)
            currentComponent.definitions.append(.componentType(typeDef, typeIndex: typeIndex))
            return ComponentTypeIndex(rawValue: typeIndex)
        }

        /// Convert a ComponentDefValType to an ComponentValType for use in record/variant fields.
        /// Primitives are inlined directly; non-primitives get a type index via addAnonymousComponentType.
        private mutating func toInlinedValueType(_ valueType: ComponentDefValType) throws(WatParserError) -> ComponentValType {
            if case .inlined(let inlined) = valueType {
                return inlined
            }
            let index = try valueType.getOrCreateIndex { () throws(WatParserError) in
                try addAnonymousComponentType(valueType)
            }
            return .index(index)
        }

        private mutating func parseComponentFuncParam(_ parser: inout Parser) throws(WatParserError) -> ComponentFuncType.Param {
            try .init(name: parser.expectString(), type: try parseComponentValueType(&parser))
        }

        /// Parse function parameters for component function types
        private mutating func parseFuncParams(_ parser: inout Parser) throws(WatParserError) -> [ComponentFuncType.Param] {
            var params: [ComponentFuncType.Param] = []
            while try parser.takeParenBlockStart("param") {
                let name = try parser.expectString()
                let type = try parseComponentValueType(&parser)
                params.append(ComponentFuncType.Param(name: name, type: type))
                try parser.expect(.rightParen)
            }
            return params
        }

        /// Parse a type bound: (sub resource) or (eq $typeRef)
        /// Expects the parser to be positioned at the open paren of the bound.
        /// When `localCtx` is provided, type references are resolved against it first.
        private mutating func parseTypeBound(_ parser: inout Parser, localCtx: inout LocalTypeContext) throws(WatParserError) -> TypeBound {
            try parser.expect(.leftParen)
            let keyword = try parser.expectKeyword()
            switch keyword {
            case "sub":
                try parser.expectKeyword("resource")
                try parser.expect(.rightParen)
                return .subResource
            case "eq":
                let typeRef = try parser.expectIndexOrId()
                // Type equality handles both local and global references:
                // - Numeric indices (e.g., (eq 0)) may refer to local types within inline definitions
                // - Identifiers (e.g., (eq $T)) refer to types - check local context first, then outer scopes
                let typeIndex: UInt32
                switch typeRef {
                case .index(let idx, _):
                    // Keep numeric index as-is - it may be a local reference
                    typeIndex = idx
                case .id(let name, _):
                    // Try local context first
                    if let localIdx = localCtx.resolveType(typeRef) {
                        typeIndex = localIdx
                    } else {
                        // Search outer type contexts in the stack
                        var foundInOuter: (outerIndex: UInt32, outerCount: UInt32)? = nil
                        let stackDepth = typeContextStack.count - 1
                        if stackDepth >= 0 {
                            // Search from innermost to outermost (skip the current context at top)
                            for i in (0..<stackDepth).reversed() {
                                let outerCtx = typeContextStack[i]
                                if let outerIdx = outerCtx.typeBindings[name.value] {
                                    // Found in this outer context
                                    // outerCount is distance from current context to the target
                                    let outerCount = UInt32(stackDepth - i)
                                    foundInOuter = (outerIdx, outerCount)
                                    break
                                }
                            }
                        }

                        if let (outerIdx, outerCount) = foundInOuter {
                            // Create an outer alias in the current context
                            let localIdx = localCtx.getOrCreateOuterAlias(outerCount: outerCount, targetTypeIndex: outerIdx)
                            typeIndex = localIdx
                        } else if let resolvedIndex = try? currentComponent.resolveTypeIndex(use: typeRef) {
                            // Found in the enclosing component's type index space.
                            // If we're inside a type definition (typeContextStack is non-empty),
                            // we need an outer alias to bring it into the local scope.
                            // The distance is typeContextStack.count (from the type body to the component).
                            if !typeContextStack.isEmpty {
                                let outerCount = UInt32(typeContextStack.count)
                                let localIdx = localCtx.getOrCreateOuterAlias(outerCount: outerCount, targetTypeIndex: UInt32(resolvedIndex))
                                typeIndex = localIdx
                            } else {
                                typeIndex = UInt32(resolvedIndex)
                            }
                        } else if !typeContextStack.isEmpty {
                            // Inside a type definition, the type may be in an ancestor component.
                            // Search the component stack directly to find it, then create a direct
                            // outer alias from the type context to the target without intermediate
                            // component-level aliases.
                            let resolvedIdx = try resolveTypeInAncestorForTypeBound(typeRef, localCtx: &localCtx)
                            typeIndex = resolvedIdx
                        } else {
                            throw WatParserError("Type '\(name.value)' not found in any scope for eq bound", location: name.location)
                        }
                    }
                }
                try parser.expect(.rightParen)
                return .eq(typeIndex: typeIndex)
            default:
                throw WatParserError(
                    "Unknown type bound '\(keyword)', expected 'sub' or 'eq'",
                    location: parser.lexer.location()
                )
            }
        }

        /// Resolve a type reference in ancestor components for use inside a type definition body.
        /// Creates an outer alias that reaches directly to the ancestor scope.
        private mutating func resolveTypeInAncestorForTypeBound(
            _ typeRef: Parser.IndexOrId,
            localCtx: inout LocalTypeContext
        ) throws(WatParserError) -> UInt32 {
            let currentDepth = componentStack.count - 1
            for i in stride(from: currentDepth - 1, through: 0, by: -1) {
                let parent = componentStack[i]
                let targetIdx: Int?
                if let idx = try? parent.resolveTypeIndex(use: typeRef) {
                    targetIdx = idx
                } else {
                    targetIdx = nil
                }
                if let idx = targetIdx {
                    // outerCount from the type def body to the target:
                    // typeContextStack.count levels from type to current component,
                    // then (currentDepth - i) more to reach the ancestor.
                    let componentDistance = UInt32(currentDepth - i)
                    let typeDistance = UInt32(typeContextStack.count)
                    let totalOuterCount = typeDistance + componentDistance
                    return localCtx.getOrCreateOuterAlias(
                        outerCount: totalOuterCount,
                        targetTypeIndex: UInt32(idx)
                    )
                }
            }
            throw WatParserError(
                "Type '\(typeRef)' not found in any enclosing scope for eq bound",
                location: typeRef.location
            )
        }

        /// Parse an extern descriptor for type imports/exports in component types.
        /// Syntax: (type $id? <typebound>) | (func ...) | (instance ...) | (component ...)
        /// When `localCtx` is provided, type references are resolved against the local context first,
        /// and outer aliases are generated for references to the enclosing component's types.
        private mutating func parseTypeExternDesc(
            _ parser: inout Parser,
            localCtx: inout LocalTypeContext
        ) throws(WatParserError) -> TypeExternDesc {
            try parser.expect(.leftParen)
            let keyword = try parser.expectKeyword()

            switch keyword {
            case "core":
                // (core module $id? (type INDEX)?) or (core module $id? (import ...) (export ...) ...)
                try parser.expectKeyword("module")
                let moduleId = try parser.takeId()
                var coreTypeIndex: UInt32
                // Disambiguate (type INDEX) reference from inline body starting with (type $id (func ...))
                // by peeking: if we see (type followed by an id/index and then ), it's a reference.
                var isTypeRef = false
                if try parser.peekKeywordAfterLeftParen() == "type" {
                    var saved = parser
                    _ = try saved.take(.leftParen)
                    _ = try saved.expectKeyword()  // "type"
                    _ = try saved.takeIndexOrId()
                    if try saved.peek(.rightParen) != nil {
                        isTypeRef = true
                    }
                }
                if isTypeRef {
                    _ = try parser.take(.leftParen)
                    _ = try parser.expectKeyword()  // "type"
                    let typeRef = try parser.expectIndexOrId()
                    coreTypeIndex = try resolveCoreTypeRefInLocalContext(typeRef, localCtx: &localCtx)
                    try parser.expect(.rightParen)
                } else {
                    // No explicit type: parse inline module type body
                    let moduleTypeDef = try parseCoreModuleTypeBody(&parser)
                    let inlineCoreType = CoreTypeDef(id: nil, kind: .module(moduleTypeDef))
                    coreTypeIndex = localCtx.addInlineCoreType(inlineCoreType)
                }
                try parser.expect(.rightParen)
                return .coreModule(id: moduleId?.value, coreTypeIndex: coreTypeIndex)

            case "type":
                let typeId = try parser.takeId()
                let bound = try parseTypeBound(&parser, localCtx: &localCtx)
                try parser.expect(.rightParen)
                return .type(id: typeId?.value, bound: bound)

            case "func":
                let funcId = try parser.takeId()
                // Parse optional type reference or inline function type
                var typeIndex: UInt32? = nil
                if try parser.takeParenBlockStart("type") {
                    // (type INDEX) - explicit type reference
                    let typeRef = try parser.expectIndexOrId()
                    typeIndex = try resolveTypeRefInLocalContext(typeRef, localCtx: &localCtx)
                    try parser.expect(.rightParen)
                } else if try parser.peek(.leftParen) != nil {
                    // Inline function type with (param ...) and/or (result ...)
                    let params = try parseLocalFuncParams(&parser, context: &localCtx)
                    var resultType: ComponentDefValType?
                    if try parser.takeParenBlockStart("result") {
                        resultType = try parseLocalComponentValueType(&parser, context: &localCtx)
                        try parser.expect(.rightParen)
                    }
                    // Extract composite value types (own, borrow, tuple, etc.) into
                    // separate type definitions before the function type
                    let funcType = localCtx.extractFuncTypeComposites(
                        ComponentFuncType(params: params, result: resultType))
                    let funcTypeDef = ComponentTypeDef(id: nil, kind: .function(funcType))
                    let idx = localCtx.addInlineType(funcTypeDef)
                    typeIndex = idx
                }
                // If no explicit type reference and no inline type, create empty function type
                // This handles cases like (export "f" (func)) which need an anonymous (func) type
                if typeIndex == nil {
                    let emptyFuncType = ComponentFuncType(params: [], result: nil)
                    let funcTypeDef = ComponentTypeDef(id: nil, kind: .function(emptyFuncType))
                    let idx = localCtx.addInlineType(funcTypeDef)
                    typeIndex = idx
                }
                try parser.expect(.rightParen)
                return .function(id: funcId?.value, typeIndex: typeIndex)

            case "instance":
                let instanceId = try parser.takeId()
                let typeIndex = try parseInlineOrRefTypeExternDesc(
                    &parser, localCtx: &localCtx,
                    parseDecls: { (s: inout Self, p: inout Parser) throws(WatParserError) in try s.parseInstanceTypeDeclarations(&p) },
                    makeKind: { .instance($0) }
                )
                try parser.expect(.rightParen)
                return .instance(id: instanceId?.value, typeIndex: typeIndex)

            case "component":
                let compId = try parser.takeId()
                let typeIndex = try parseInlineOrRefTypeExternDesc(
                    &parser, localCtx: &localCtx,
                    parseDecls: { (s: inout Self, p: inout Parser) throws(WatParserError) in try s.parseComponentTypeDeclarations(&p) },
                    makeKind: { .component($0) }
                )
                try parser.expect(.rightParen)
                return .component(id: compId?.value, typeIndex: typeIndex)

            default:
                throw WatParserError(
                    "Unknown extern descriptor '\(keyword)'",
                    location: parser.lexer.location()
                )
            }
        }

        /// Disambiguates (type $ref) shorthand vs inline type declarations for instance/component
        /// extern descriptors, returning the resolved type index.
        private mutating func parseInlineOrRefTypeExternDesc(
            _ parser: inout Parser,
            localCtx: inout LocalTypeContext,
            parseDecls: (inout Self, inout Parser) throws(WatParserError) -> [ComponentDecl],
            makeKind: ([ComponentDecl]) -> ComponentTypeDef.Kind
        ) throws(WatParserError) -> UInt32? {
            let savedLexer = parser.lexer
            if try parser.takeParenBlockStart("type") {
                let typeRef = try parser.expectIndexOrId()
                if try parser.take(.rightParen) {
                    return try resolveTypeRefInLocalContext(typeRef, localCtx: &localCtx)
                } else {
                    parser.lexer = savedLexer
                    let decls = try parseDecls(&self, &parser)
                    let typeDef = ComponentTypeDef(id: nil, kind: makeKind(decls))
                    return localCtx.addInlineType(typeDef)
                }
            } else if try parser.peek(.leftParen) != nil {
                let decls = try parseDecls(&self, &parser)
                let typeDef = ComponentTypeDef(id: nil, kind: makeKind(decls))
                return localCtx.addInlineType(typeDef)
            } else if let typeRef = try parser.takeIndexOrId() {
                return try resolveTypeRefInLocalContext(typeRef, localCtx: &localCtx)
            }
            let typeDef = ComponentTypeDef(id: nil, kind: makeKind([]))
            return localCtx.addInlineType(typeDef)
        }

        /// Resolve a type reference in the context of a local type definition.
        /// First checks the immediate local context, then walks up the type context stack
        /// (for nested type definitions), and finally resolves from the outer component.
        /// Generates outer aliases as needed, returning the local alias index.
        private mutating func resolveTypeRefInLocalContext(
            _ typeRef: Parser.IndexOrId,
            localCtx: inout LocalTypeContext
        ) throws(WatParserError) -> UInt32 {
            // First check local context
            if let localIndex = localCtx.resolveType(typeRef) {
                return localIndex
            }

            // Walk up the type context stack for enclosing type definitions
            // (e.g., instance type inside component type)
            // Skip the last entry since it's the current localCtx (already checked above)
            if typeContextStack.count >= 2 {
                let currentIdx = typeContextStack.count - 1
                for i in (0..<currentIdx).reversed() {
                    if let parentIndex = typeContextStack[i].resolveType(typeRef) {
                        // Found in an enclosing type context.
                        // Outer count = distance from current context to the found context
                        let outerCount = UInt32(currentIdx - i)
                        let aliasIndex = localCtx.getOrCreateOuterAlias(outerCount: outerCount, targetTypeIndex: parentIndex)
                        // Register the name binding so nested contexts can find it
                        if case .id(let name, _) = typeRef {
                            localCtx.typeBindings[name.value] = aliasIndex
                        }
                        return aliasIndex
                    }
                }
            }

            // Resolve from outer component and create an outer alias
            let outerIndex = UInt32(try currentComponent.resolveTypeIndex(use: typeRef))
            let aliasIndex = localCtx.getOrCreateOuterAlias(outerCount: 1, targetTypeIndex: outerIndex)
            // Register the name binding so nested contexts can find it
            if case .id(let name, _) = typeRef {
                localCtx.typeBindings[name.value] = aliasIndex
            }
            return aliasIndex
        }

        /// Resolve a core type reference in the context of a local type definition.
        /// Similar to resolveTypeRefInLocalContext but for core types.
        /// Creates outer aliases as needed, returning the local core type alias index.
        private mutating func resolveCoreTypeRefInLocalContext(
            _ typeRef: Parser.IndexOrId,
            localCtx: inout LocalTypeContext
        ) throws(WatParserError) -> UInt32 {
            // For numeric indices, use directly
            if case .index(let idx, _) = typeRef {
                return idx
            }

            // Resolve from outer component's core types map and create an outer alias
            let outerIndex = UInt32(try currentComponent.coreTypesMap.resolveIndex(use: typeRef))
            let aliasIndex = localCtx.getOrCreateOuterCoreAlias(outerCount: 1, targetCoreTypeIndex: outerIndex)
            return aliasIndex
        }

        private mutating func parseComponentFunc(_ parser: inout Parser) throws(WatParserError) {
            let funcId = try parser.takeId()
            var parameters = [ComponentFuncType.Param]()
            var resultType: ComponentDefValType?
            var exportDef: (location: Location, exportName: String)?
            var importDef: (location: Location, importModule: String, importName: String)?
            var canonLift: CanonLift?
            var existingTypeRef: Int?  // When (type $ref) is used instead of inline params/result

            /// Component functions are not tracked as separate entities in the final binary, i.e. there's no dedicated
            /// component functions section in the binary format. They're always encoded as a part of following
            /// sections: imports, exports, types, or canonical definitions.
            /// What looks like a function definition in component WAT `(func ...)` always desugars into one or
            /// more definitions in those sections.
            while true {
                guard try parser.take(.leftParen) else { break }
                let keyword = try parser.expectKeyword()
                switch keyword {
                case "param":
                    guard resultType == nil else {
                        throw WatParserError(
                            "Unknown component function parameter after function result is already declared",
                            location: parser.lexer.location()
                        )
                    }

                    parameters.append(try self.parseComponentFuncParam(&parser))

                case "result":
                    resultType = try parseComponentValueType(&parser)

                case "export":
                    exportDef = (parser.lexer.location(), try parser.expectString())

                case "import":
                    let firstString = try parser.expectString()
                    if let secondString = try parser.takeString() {
                        // Two-string form: (import "module" "name"), for core module imports
                        importDef = (parser.lexer.location(), firstString, secondString)
                    } else {
                        // Single-string form: (import "name"), a component-level inline import
                        importDef = (parser.lexer.location(), "", firstString)
                    }

                case "canon":
                    try parser.expectKeyword("lift")
                    canonLift = try parseCanonLift(&parser, stopBefore: nil)

                case "type":
                    // (type $ref) - reference an existing function type instead of inline params/result
                    let typeRef = try parser.expectIndexOrId()
                    existingTypeRef = try currentComponent.resolveTypeIndex(use: typeRef)

                case "alias":
                    // (alias export $inst "name"): func defined entirely by alias
                    let aliasKeyword = try parser.expectKeyword()
                    guard aliasKeyword == "export" else {
                        throw WatParserError(
                            "Unsupported alias kind '\(aliasKeyword)' in component function",
                            location: parser.lexer.location()
                        )
                    }
                    let instanceRef = try parser.expectIndexOrId()
                    let exportName = try parser.expectString()

                    // Emit alias to create the function (also registers in componentFunctions)
                    let funcIdx = try emitComponentExportAlias(
                        sort: .func,
                        instanceIndex: instanceRef,
                        exportName: exportName,
                        bindingId: funcId
                    )

                    // Emit inline export if present
                    if let exportDef {
                        let exportDefValue = ExportDef(
                            exportName: .plain(exportDef.exportName),
                            descriptor: .function(ComponentFuncIndex(funcIdx)),
                            isInline: true
                        )
                        self.currentComponent.definitions.append(.componentExport(exportDefValue))
                    }

                    try parser.expect(.rightParen)  // close (alias ...)
                    return  // early return: alias-based func is fully handled

                default:
                    throw WatParserError(
                        "Unknown component function keyword \(keyword)",
                        location: parser.lexer.location()
                    )
                }

                try parser.expect(.rightParen)
            }

            // Order: type -> core func alias -> option aliases -> canon -> export
            let typeIndex = try functionTypeIndex(
                existing: existingTypeRef,
                ComponentFuncType(params: parameters, result: resultType)
            )
            if let canonLift {
                try emitCanonLift(canonLift, typeIndex: typeIndex)
            }

            let funcIndex = try self.currentComponent.componentFunctions.add(
                ComponentFuncDef(id: funcId, paramNames: parameters.map(\.name), type: ComponentTypeIndex(rawValue: typeIndex))
            )

            if let exportDef {
                let exportDefValue = ExportDef(exportName: .plain(exportDef.exportName), descriptor: .function(.init(funcIndex)), isInline: true)
                self.currentComponent.definitions.append(.componentExport(exportDefValue))
            }

            if let importDef {
                let importDefValue = ImportDef(
                    importName: .plain(importDef.importName),
                    descriptor: .function(.init(funcIndex))
                )
                self.currentComponent.definitions.append(.componentImport(importDefValue))
            }
        }

        /// Extract composite value types from a function type at top-level component scope.
        /// Creates separate type definitions for own/borrow/tuple/etc. and replaces them
        /// with index references, matching wasm-tools behavior.
        private mutating func extractAnnotationFuncTypeComposites(
            _ funcType: ComponentFuncType
        ) throws(WatParserError) -> ComponentFuncType {
            var params = [ComponentFuncType.Param]()
            for param in funcType.params {
                let extractedType = try extractTopLevelCompositeValueType(param.type)
                params.append(ComponentFuncType.Param(name: param.name, type: extractedType))
            }
            let result: ComponentDefValType?
            if let r = funcType.result {
                result = try extractTopLevelCompositeValueType(r)
            } else {
                result = nil
            }
            return ComponentFuncType(params: params, result: result, isAsync: funcType.isAsync)
        }

        /// Extract a composite value type at top-level component scope into a separate
        /// type definition. Returns an index reference to the new type.
        private mutating func extractTopLevelCompositeValueType(
            _ type: ComponentDefValType
        ) throws(WatParserError) -> ComponentDefValType {
            switch type {
            case .inlined(.primitive), .inlined(.index), .primitive(.errorContext):
                return type
            default:
                // Composite type: create a new type definition
                let typeDef = ComponentTypeDef(id: nil, kind: .value(type))
                let typeIndex = try currentComponent.typeIndexSpace.addDefinition(typeDef)
                currentComponent.definitions.append(.componentType(typeDef, typeIndex: typeIndex))
                return .inlined(.index(ComponentTypeIndex(rawValue: typeIndex)))
            }
        }

        /// Desugars the projection `(func $inst "name")` to `(alias export $inst "name" (func))`
        /// and returns the index of the aliased function.
        private mutating func desugarFuncProjection(
            _ parser: inout Parser,
            instanceRef: Parser.IndexOrId,
            exportName: String
        ) throws(WatParserError) -> UInt32 {
            let location = parser.lexer.location()
            let instanceIndex = Parser.IndexOrId.index(
                UInt32(try currentComponent.componentInstancesMap.resolveIndex(use: instanceRef)),
                location
            )
            let idx = try emitComponentExportAlias(
                sort: .func,
                instanceIndex: instanceIndex,
                exportName: exportName
            )
            return UInt32(idx)
        }

        /// Emit a component-export alias: create the alias, register a placeholder in the
        /// sort's index space, append the alias to definitions, and return the assigned index.
        @discardableResult
        private mutating func emitComponentExportAlias(
            sort: ComponentDefSort,
            instanceIndex: Parser.IndexOrId,
            exportName: String,
            bindingId: Name? = nil
        ) throws(WatParserError) -> Int {
            var aliasTypeIndex: Int? = nil
            let idx: Int
            switch sort {
            case .func:
                let funcDef = ComponentFuncDef(id: bindingId, paramNames: [], type: nil)
                idx = try currentComponent.componentFunctions.add(funcDef)
            case .instance:
                let instanceDef = ComponentInstanceDef(id: bindingId, componentRef: nil, arguments: [])
                idx = try currentComponent.componentInstancesMap.add(instanceDef)
            case .component:
                let componentDef = ComponentDef(id: bindingId)
                idx = try currentComponent.componentsMap.add(componentDef)
            case .core(.module):
                let placeholder = ModuleDef(id: bindingId)
                idx = try currentComponent.coreModulesMap.add(placeholder)
            case .type:
                let typeIndex = try currentComponent.typeIndexSpace.addAlias(name: bindingId)
                aliasTypeIndex = typeIndex
                idx = typeIndex
            case .core(let coreSort):
                guard let coreIndex = try currentComponent.addCoreAliasEntry(coreSort, id: bindingId) else {
                    throw WatParserError("A component instance cannot export a core \(coreSort.keyword)", location: instanceIndex.location)
                }
                idx = coreIndex
            case .value:
                throw WatParserError("Value aliases are not supported", location: instanceIndex.location)
            }

            let alias = ComponentAlias(
                sort: sort,
                target: .componentExport(
                    instanceIndex: instanceIndex,
                    exportName: exportName
                ),
                bindingId: bindingId,
                typeIndex: aliasTypeIndex
            )
            currentComponent.definitions.append(.alias(alias))
            return idx
        }

        /// Resolve a core index from the appropriate index space based on sort.
        private func resolveCoreIndex(sort: CoreDefSort, ref: Parser.IndexOrId) throws(WatParserError) -> UInt32 {
            switch sort {
            case .func:
                return try UInt32(currentComponent.coreFunctionsMap.resolveIndex(use: ref))
            case .memory:
                return try UInt32(currentComponent.coreMemoriesMap.resolveIndex(use: ref))
            case .table:
                return try UInt32(currentComponent.coreTablesMap.resolveIndex(use: ref))
            case .global:
                return try UInt32(currentComponent.coreGlobalsMap.resolveIndex(use: ref))
            case .tag:
                return try UInt32(currentComponent.coreTagsMap.resolveIndex(use: ref))
            case .type, .module, .instance:
                throw WatParserError("Unsupported core sort '\(sort.keyword)' for inline export resolution", location: ref.location)
            }
        }

        /// Emit a core export alias: (alias core export $coreInstance "name" (core <sort>))
        /// Registers the alias in the appropriate core index space and appends to definitions.
        @discardableResult
        private mutating func emitCoreExportAlias(
            sort: CoreDefSort,
            coreInstanceIndex: Parser.IndexOrId,
            exportName: String,
            bindingId: Name? = nil
        ) throws(WatParserError) -> Int {
            guard let idx = try currentComponent.addCoreAliasEntry(sort, id: bindingId) else {
                throw WatParserError("Unsupported core sort '\(sort.keyword)' for core export alias", location: nil)
            }
            let alias = ComponentAlias(
                sort: .core(sort),
                target: .coreExport(
                    instanceIndex: coreInstanceIndex,
                    exportName: exportName
                ),
                bindingId: bindingId,
                typeIndex: nil
            )
            currentComponent.definitions.append(.alias(alias))
            return idx
        }
        /// Desugar canon options that reference memories/functions via instance exports.
        /// Emits alias definitions and replaces export-form references with direct indices.
        private mutating func desugarCanonOptions(
            _ options: [CanonDef.Option],
            location: Location
        ) throws(WatParserError) -> [CanonDef.Option] {
            var result = options
            for (i, option) in options.enumerated() {
                switch option {
                case .memory(let memRef):
                    switch memRef {
                    case .direct(let ref):
                        let memIndex = try currentComponent.coreMemoriesMap.resolveIndex(use: ref)
                        result[i] = .memoryIndex(UInt32(memIndex))
                    case .export(let instance, let exportName):
                        let memIndex = try emitCoreExportAlias(sort: .memory, coreInstanceIndex: instance, exportName: exportName)
                        result[i] = .memoryIndex(UInt32(memIndex))
                    }

                case .realloc(let funcRef), .postReturn(let funcRef), .callback(let funcRef):
                    if case .export(let instance, let exportName) = funcRef {
                        let funcIndex = try emitCoreExportAlias(sort: .func, coreInstanceIndex: instance, exportName: exportName)
                        let directRef = FuncIndex.direct(.index(UInt32(funcIndex), location))
                        switch option {
                        case .realloc: result[i] = .realloc(directRef)
                        case .postReturn: result[i] = .postReturn(directRef)
                        case .callback: result[i] = .callback(directRef)
                        default: break
                        }
                    }

                default:
                    break
                }
            }
            return result
        }

        /// Parses a canon option list of parenthesized options and bare string encodings.
        /// Stops before a trailing `(<stopKeyword> …)` block (`(core func …)` for `lower`,
        /// `(func …)` for `lift`), or before the enclosing `)` when `stopKeyword` is `nil`.
        private mutating func parseCanonOptionList(
            _ parser: inout Parser, stopBefore stopKeyword: String?
        ) throws(WatParserError) -> [CanonDef.Option] {
            var options = [CanonDef.Option]()
            while true {
                if let stopKeyword {
                    if try parser.peekKeywordAfterLeftParen() == stopKeyword {
                        break  // trailing (stopKeyword …) block, not an option
                    }
                }
                if try parser.take(.leftParen) {
                    options.append(try parseCanonOpt(&parser))
                    try parser.expect(.rightParen)
                    continue
                }
                if let encoding = try parseBareStringEncoding(&parser) {
                    options.append(.stringEncoding(encoding))
                    continue
                }
                break
            }
            return options
        }

        private mutating func parseCanonOpt(_ parser: inout Parser) throws(WatParserError) -> CanonDef.Option {
            let keyword = try parser.expectKeyword()
            switch keyword {
            case "memory":
                return .memory(try parseCoreMemoryRef(&parser))
            case "realloc":
                return .realloc(try parseCanonOptFuncRef(&parser))
            case "post-return":
                return .postReturn(try parseCanonOptFuncRef(&parser))
            case "async":
                return .async
            case "callback":
                return .callback(try parseCanonOptFuncRef(&parser))
            case "string-encoding":
                // Parse string encoding: utf8 | utf16 | latin1+utf16
                let encodingKeyword = try parser.expectKeyword()
                let encoding: ComponentStringEncoding
                switch encodingKeyword {
                case "utf8":
                    encoding = .utf8
                case "utf16":
                    encoding = .utf16
                case "latin1+utf16":
                    encoding = .latin1UTF16
                default:
                    throw WatParserError(
                        "Unknown string encoding '\(encodingKeyword)'",
                        location: parser.lexer.location()
                    )
                }
                return .stringEncoding(encoding)
            default:
                throw WatParserError(
                    "Unknown canon options keyword \(keyword)",
                    location: parser.lexer.location()
                )
            }
        }

        /// Parse a bare `string-encoding=<encoding>` keyword outside parentheses.
        /// Returns nil if the next token is not a bare string-encoding keyword.
        private func parseBareStringEncoding(_ parser: inout Parser) throws(WatParserError) -> ComponentStringEncoding? {
            let prefix = "string-encoding="
            guard let keyword = try parser.peekKeyword(), keyword.hasPrefix(prefix) else {
                return nil
            }
            try parser.consume()
            let suffix = String(keyword.dropFirst(prefix.count))
            switch suffix {
            case "utf8":
                return .utf8
            case "utf16":
                return .utf16
            case "latin1+utf16":
                return .latin1UTF16
            default:
                throw WatParserError(
                    "Unknown string encoding '\(suffix)'",
                    location: parser.lexer.location()
                )
            }
        }

        /// Parses `$ref` or `$instance "name"`, building the result with `direct` or `export`.
        private func parseRefOrInstanceExport<Ref>(
            _ parser: inout Parser,
            direct: (Parser.IndexOrId) -> Ref,
            export: (Parser.IndexOrId, String) -> Ref
        ) throws(WatParserError) -> Ref {
            let ref = try parser.expectIndexOrId()
            if let exportName = try parser.takeString() {
                return export(ref, exportName)
            }
            return direct(ref)
        }

        /// Parses a core memory reference: `$ref` or `$instance "name"`.
        private func parseCoreMemoryRef(_ parser: inout Parser) throws(WatParserError) -> MemoryRef {
            try parseRefOrInstanceExport(&parser, direct: MemoryRef.direct, export: MemoryRef.export)
        }

        /// Parses `(core func $ref)` or `(core func $instance "name")`.
        private func parseCoreFunctionIndex(_ parser: inout Parser) throws(WatParserError) -> FuncIndex {
            try parser.expect(.leftParen)
            try parser.expectKeyword("core")
            try parser.expectKeyword("func")
            let ref = try parseRefOrInstanceExport(&parser, direct: FuncIndex.direct, export: FuncIndex.export)
            try parser.expect(.rightParen)
            return ref
        }

        /// Parses a canon option's core function: `$ref` or `$instance "name"`, optionally inside `(func ...)`.
        private func parseCanonOptFuncRef(_ parser: inout Parser) throws(WatParserError) -> FuncIndex {
            guard try parser.take(.leftParen) else {
                return try parseRefOrInstanceExport(&parser, direct: FuncIndex.direct, export: FuncIndex.export)
            }
            try parser.expectKeyword("func")
            let ref = try parseRefOrInstanceExport(&parser, direct: FuncIndex.direct, export: FuncIndex.export)
            try parser.expect(.rightParen)
            return ref
        }

        /// Parse a component function reference: (func $instance "export" ...) or (func $idx)
        /// Used in canon lower syntax. Returns the resolved component function index.
        private mutating func parseCanonLowerFuncRef(
            _ parser: inout Parser
        ) throws(WatParserError) -> ComponentFuncIndex {
            try parser.expect(.leftParen)
            try parser.expectKeyword("func")
            let firstArg = try parser.expectIndexOrId()
            if let exportName = try parser.takeString() {
                // Projection: desugar through an alias
                let funcIndex = try desugarFuncProjection(&parser, instanceRef: firstArg, exportName: exportName)
                try parser.expect(.rightParen)
                return ComponentFuncIndex(Int(funcIndex))
            } else {
                // (func $idx) form - direct function reference
                let funcIndex = try currentComponent.componentFunctions.resolveIndex(use: firstArg)
                try parser.expect(.rightParen)
                return ComponentFuncIndex(funcIndex)
            }
        }
    }

    extension CoreDefSort {
        init?(keyword: String) {
            switch keyword {
            case "func": self = .func
            case "table": self = .table
            case "memory": self = .memory
            case "global": self = .global
            case "tag": self = .tag
            case "type": self = .type
            case "module": self = .module
            case "instance": self = .instance
            default: return nil
            }
        }

        var keyword: String {
            switch self {
            case .func: return "func"
            case .table: return "table"
            case .memory: return "memory"
            case .global: return "global"
            case .tag: return "tag"
            case .type: return "type"
            case .module: return "module"
            case .instance: return "instance"
            }
        }
    }

    extension ComponentDefSort {
        var text: String {
            switch self {
            case .core(let coreSort): return "core \(coreSort.keyword)"
            case .func: return "func"
            case .value: return "value"
            case .type: return "type"
            case .component: return "component"
            case .instance: return "instance"
            }
        }
    }

#endif
