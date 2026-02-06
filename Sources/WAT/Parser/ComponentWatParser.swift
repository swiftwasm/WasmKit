#if ComponentModel

    import ComponentModel
    import WasmParser
    import WasmTypes

    public struct ComponentWatParser: ~Copyable {
        let features: WasmFeatureSet

        /// Stack of components currently being parsed (supports nested components)
        private var componentStack: [ComponentDef] = []

        struct Field {
            enum Kind {
                case component(Int)
            }
        }

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
            return componentStack.removeLast()
        }

        /// Parses a component body when `(component $id?` has already been consumed.
        /// Expects the parser to be positioned at the first field or closing `)`.
        /// Consumes the closing `)` and returns the parsed ComponentDef.
        consuming func parseComponentBody(_ parser: inout Parser, id: Name?) throws(WatParserError) -> ComponentDef {
            componentStack.append(ComponentDef(id: id))
            try parseComponentFields(&parser)
            try parser.expect(.rightParen)
            return componentStack.removeLast()
        }

        /// Parses component fields until a closing `)` is encountered.
        /// Assumes the parser is positioned after `(component $id?`.
        private mutating func parseComponentFields(_ parser: inout Parser) throws(WatParserError) {
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
                    componentStack.append(ComponentDef(id: nestedId))
                    try parseComponentFields(&parser)  // Recursive call for nested components
                    let nested = componentStack.removeLast()
                    let idx = try currentComponent.componentsMap.add(nested)
                    currentComponent.fields.append(.init(location: location, kind: .component(.init(idx))))
                case "import":
                    try parseComponentImport(&parser, location: location)
                case "export":
                    try parseComponentExport(&parser, location: location)
                case "instance":
                    try parseComponentInstance(&parser, location: location)
                case "alias":
                    #warning("Stub: skip unsupported component fields for now")
                    try parser.skipParenBlock()
                    continue  // skipParenBlock consumes the closing ), so skip expect below
                default:
                    throw WatParserError(
                        "Unknown component definition keyword \(keyword)",
                        location: location
                    )
                }
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
                let index = try self.currentComponent.coreModulesMap.add(moduleDef)
                self.currentComponent.fields.append(
                    .init(location: location, kind: .coreModule(.init(index)))
                )

            case "instance":
                let instanceDef = try self.parseCoreInstanceDef(&parser)
                let index = try self.currentComponent.coreInstancesMap.add(instanceDef)
                self.currentComponent.fields.append(
                    .init(location: location, kind: .coreInstance(.init(index)))
                )

            case "type":
                let coreTypeDef = try self.parseCoreTypeDef(&parser)
                let resolvedId = try self.currentComponent.coreTypesMap.add(coreTypeDef)
                self.currentComponent.fields.append(
                    .init(location: location, kind: .coreType(TypeIndex(resolvedId)))
                )

            case "func":
                // (core func $id (canon lower (func $instance "export")))
                let coreFuncId = try parser.takeId()
                try parser.expect(.leftParen)
                try parser.expectKeyword("canon")
                try parser.expectKeyword("lower")

                // Parse component function reference: (func $instance "export") or (func $index)
                let componentFuncRef = try parseComponentFunctionIndex(&parser)

                // Parse canon options
                var options = [CanonDef.Option]()
                while try parser.take(.leftParen) {
                    options.append(try parseCanonOpt(&parser))
                    try parser.expect(.rightParen)
                }

                try parser.expect(.rightParen)  // Close the (canon lower ...) block

                // Track core function in the core functions index space
                let coreFuncIndex = try self.currentComponent.coreFunctionsMap.add(
                    CoreFuncDef(id: coreFuncId)
                )

                self.currentComponent.fields.append(
                    .init(
                        location: location,
                        kind: .canon(
                            .init(
                                kind: .lower(componentFuncRef),
                                functionIndex: FuncIndex(instance: .index(0, location), exportName: ""),  // Placeholder for lower
                                options: options
                            ))
                    )
                )
                _ = coreFuncIndex  // Will be used for resolving references

            default:
                throw WatParserError(
                    "Unknown core definition keyword \(coreKeyword)",
                    location: location
                )
            }
        }

        /// Parse a component import definition
        /// Syntax: (import "name" (instance $id? (export "name" (func ...))...))
        private mutating func parseComponentImport(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let importName = try parser.expectString()
            try parser.expect(.leftParen)
            let descKeyword = try parser.expectKeyword()

            switch descKeyword {
            case "instance":
                let instanceId = try parser.takeId()

                // Parse the instance type constraint
                let instanceTypeDef = try parseInstanceTypeDeclarations(&parser)
                try parser.expect(.rightParen)

                // Add the instance type to componentTypes
                let typeDef = ComponentTypeDef(id: nil, kind: .instance(instanceTypeDef))
                let typeIndex = try currentComponent.componentTypes.add(typeDef)

                // Add the instance to componentInstancesMap
                let instanceIndex = try currentComponent.componentInstancesMap.add(
                    ComponentInstanceDef(id: instanceId, componentRef: nil, arguments: [])
                )

                // Add import field with reference to the type
                currentComponent.fields.append(
                    .init(
                        location: location,
                        kind: .importDef(
                            ImportDef(
                                importModuleName: "",  // Not used for component imports
                                importName: importName,
                                descriptor: .instance(.index(UInt32(typeIndex), location))
                            ))
                    )
                )
                _ = instanceIndex  // silence unused warning

            case "func":
                // Handle function imports
                let funcId = try parser.takeId()
                #warning("Skipping the type constraint as unimplemented")
                var depth = 1
                while depth > 0 {
                    if try parser.take(.leftParen) {
                        depth += 1
                    } else if try parser.take(.rightParen) {
                        depth -= 1
                    } else {
                        try parser.consume()
                    }
                }

                // Add function to componentFunctions
                let funcIndex = try currentComponent.componentFunctions.add(
                    ComponentFuncDef(id: funcId, paramNames: [], type: ComponentTypeIndex(rawValue: 0))
                )

                currentComponent.fields.append(
                    .init(
                        location: location,
                        kind: .importDef(
                            ImportDef(
                                importModuleName: "",
                                importName: importName,
                                descriptor: .function(ComponentFuncIndex(funcIndex))
                            ))
                    )
                )

            default:
                throw WatParserError("Unsupported import descriptor '\(descKeyword)'", location: parser.lexer.location())
            }
        }

        /// Parse a component export definition
        /// Syntax: (export "name" (func $ref)) or (export "name" (func $instance "exportname"))
        private mutating func parseComponentExport(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let exportName = try parser.expectString()
            try parser.expect(.leftParen)
            let descKeyword = try parser.expectKeyword()

            let descriptor: ExternDesc
            switch descKeyword {
            case "func":
                // Check if it's (func $idx) or (func $instance "name")
                let firstArg = try parser.expectIndexOrId()
                if let exportedName = try parser.takeString() {
                    // It's (func $instance "name") - function from an instance export
                    descriptor = .functionFromInstance(firstArg, exportedName)
                } else {
                    // It's (func $idx) - direct function index
                    let funcIndex = try currentComponent.componentFunctions.resolveIndex(use: firstArg)
                    descriptor = .function(ComponentFuncIndex(funcIndex))
                }
                try parser.expect(.rightParen)

            case "instance":
                // (instance $ref)
                let instanceRef = try parser.expectIndexOrId()
                descriptor = .instance(instanceRef)
                try parser.expect(.rightParen)

            case "type":
                // (type $ref)
                let typeRef = try parser.expectIndexOrId()
                descriptor = .type(typeRef)
                try parser.expect(.rightParen)

            default:
                throw WatParserError("Unsupported export descriptor '\(descKeyword)'", location: parser.lexer.location())
            }

            currentComponent.fields.append(
                .init(
                    location: location,
                    kind: .exportDef(
                        ExportDef(
                            exportName: exportName,
                            descriptor: descriptor
                        ))
                )
            )
        }

        /// Parse a component instance definition
        /// Syntax: (instance $id (instantiate $component (with "name" (instance $ref))...))
        private mutating func parseComponentInstance(_ parser: inout Parser, location: Location) throws(WatParserError) {
            let instanceId = try parser.takeId()
            try parser.expect(.leftParen)
            try parser.expectKeyword("instantiate")

            let componentRef = try parser.expectIndexOrId()
            var arguments = [ComponentInstanceArgument]()

            while try parser.takeParenBlockStart("with") {
                let argName = try parser.expectString()
                try parser.expect(.leftParen)
                let argKind = try parser.expectKeyword()

                let argValue: ComponentInstanceArgument.Kind
                switch argKind {
                case "instance":
                    let instanceRef = try parser.expectIndexOrId()
                    argValue = .instance(instanceRef)
                default:
                    throw WatParserError("Unsupported component instance argument kind '\(argKind)'", location: parser.lexer.location())
                }

                try parser.expect(.rightParen)  // Close (instance ...)
                try parser.expect(.rightParen)  // Close (with ...)
                arguments.append(ComponentInstanceArgument(name: argName, kind: argValue))
            }

            try parser.expect(.rightParen)  // Close (instantiate ...)

            let instanceDef = ComponentInstanceDef(id: instanceId, componentRef: componentRef, arguments: arguments)
            let index = try currentComponent.componentInstancesMap.add(instanceDef)
            currentComponent.fields.append(
                .init(location: location, kind: .instance(.init(index)))
            )
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
            if try parser.take(.leftParen) {
                // Parenthesized type constructor
                let typeKeyword = try parser.expectKeyword()

                switch typeKeyword {
                case "func":
                    let params = try parseFuncParams(&parser)
                    var resultType: ComponentValueType?
                    if try parser.takeParenBlockStart("result") {
                        resultType = try parseComponentValueType(&parser)
                        try parser.expect(.rightParen)
                    }
                    kind = .function(ComponentFuncType(params: params, result: resultType))
                    try parser.expect(.rightParen)

                case "instance":
                    let instanceTypeDef = try parseInstanceTypeDeclarations(&parser)
                    kind = .instance(instanceTypeDef)
                    try parser.expect(.rightParen)

                case "component":
                    let componentTypeDef = try parseComponentTypeDeclarations(&parser)
                    kind = .component(componentTypeDef)
                    try parser.expect(.rightParen)

                case "record":
                    var fields: [ComponentRecordField] = []
                    while try parser.takeParenBlockStart("field") {
                        let fieldName = try parser.expectString()
                        let fieldType = try parseComponentValueType(&parser)
                        let fieldTypeIndex: ComponentTypeIndex
                        if case .indexed(let idx) = fieldType {
                            fieldTypeIndex = idx
                        } else {
                            let idx = try addAnonymousComponentType(fieldType)
                            fieldTypeIndex = ComponentTypeIndex(rawValue: idx)
                        }
                        fields.append(ComponentRecordField(name: fieldName, type: fieldTypeIndex))
                        try parser.expect(.rightParen)
                    }
                    let recordType = ComponentValueType.record(fields)
                    kind = .value(recordType)
                    try parser.expect(.rightParen)

                case "variant":
                    var cases: [ComponentCaseField] = []
                    while try parser.takeParenBlockStart("case") {
                        _ = try parser.takeId()  // optional case id like $x
                        let caseName = try parser.expectString()
                        var caseType: ComponentTypeIndex? = nil
                        if try !parser.take(.rightParen) {
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                caseType = idx
                            } else {
                                let idx = try addAnonymousComponentType(valueType)
                                caseType = ComponentTypeIndex(rawValue: idx)
                            }
                            try parser.expect(.rightParen)
                        }
                        cases.append(ComponentCaseField(name: caseName, type: caseType))
                    }
                    let variantType = ComponentValueType.variant(cases)
                    kind = .value(variantType)
                    try parser.expect(.rightParen)

                case "flags":
                    var flagNames: [String] = []
                    while let flagName = try parser.takeString() {
                        flagNames.append(flagName)
                    }
                    let flagsType = ComponentValueType.flags(flagNames)
                    kind = .value(flagsType)
                    try parser.expect(.rightParen)

                case "enum":
                    var enumCases: [String] = []
                    while let caseName = try parser.takeString() {
                        enumCases.append(caseName)
                    }
                    let enumType = ComponentValueType.enum(enumCases)
                    kind = .value(enumType)
                    try parser.expect(.rightParen)

                case "list":
                    let elementType = try parseComponentValueType(&parser)
                    let elementIndex: ComponentTypeIndex
                    if case .indexed(let idx) = elementType {
                        elementIndex = idx
                    } else {
                        let elemIdx = try addAnonymousComponentType(elementType)
                        elementIndex = ComponentTypeIndex(rawValue: elemIdx)
                    }
                    let listType = ComponentValueType.list(elementIndex)
                    kind = .value(listType)
                    try parser.expect(.rightParen)

                case "tuple":
                    var typeIndices: [ComponentTypeIndex] = []
                    while try !parser.take(.rightParen) {
                        let valueType = try parseComponentValueType(&parser)
                        if case .indexed(let idx) = valueType {
                            typeIndices.append(idx)
                        } else {
                            let elemIdx = try addAnonymousComponentType(valueType)
                            typeIndices.append(ComponentTypeIndex(rawValue: elemIdx))
                        }
                    }
                    let tupleType = ComponentValueType.tuple(typeIndices)
                    kind = .value(tupleType)

                case "option":
                    let someType = try parseComponentValueType(&parser)
                    let elementIndex: ComponentTypeIndex
                    if case .indexed(let idx) = someType {
                        elementIndex = idx
                    } else {
                        let elemIdx = try addAnonymousComponentType(someType)
                        elementIndex = ComponentTypeIndex(rawValue: elemIdx)
                    }
                    let optionType = ComponentValueType.option(elementIndex)
                    kind = .value(optionType)
                    try parser.expect(.rightParen)

                case "result":
                    var okType: ComponentTypeIndex?
                    var errorType: ComponentTypeIndex?
                    // Result can be: (result), (result TYPE), (result (ok TYPE)), (result (error TYPE)),
                    // (result TYPE (error TYPE)), (result (ok TYPE) (error TYPE))
                    if try !parser.take(.rightParen) {
                        // Check for (error ...) first (error-only result)
                        if try parser.takeParenBlockStart("error") {
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                errorType = idx
                            } else {
                                errorType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(valueType))
                            }
                            try parser.expect(.rightParen)
                            try parser.expect(.rightParen)
                        } else if try parser.takeParenBlockStart("ok") {
                            // Explicit (ok TYPE)
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                okType = idx
                            } else {
                                okType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(valueType))
                            }
                            try parser.expect(.rightParen)
                            // Check for optional (error TYPE)
                            if try parser.takeParenBlockStart("error") {
                                let errType = try parseComponentValueType(&parser)
                                if case .indexed(let idx) = errType {
                                    errorType = idx
                                } else {
                                    errorType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(errType))
                                }
                                try parser.expect(.rightParen)
                            }
                            try parser.expect(.rightParen)
                        } else {
                            // Shorthand: TYPE is the ok type
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                okType = idx
                            } else {
                                okType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(valueType))
                            }
                            // Check for optional (error TYPE)
                            if try parser.takeParenBlockStart("error") {
                                let errType = try parseComponentValueType(&parser)
                                if case .indexed(let idx) = errType {
                                    errorType = idx
                                } else {
                                    errorType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(errType))
                                }
                                try parser.expect(.rightParen)
                            }
                            try parser.expect(.rightParen)
                        }
                    }
                    let resultType = ComponentValueType.result(ok: okType, error: errorType)
                    kind = .value(resultType)

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
            let typeIndex = try self.currentComponent.componentTypes.add(typeDef)
            self.currentComponent.typesMap[kind] = typeIndex

            // Add the type definition to fields
            self.currentComponent.fields.append(
                .init(
                    location: typeLocation,
                    kind: .componentType(ComponentTypeIndex(rawValue: typeIndex))
                )
            )

            // Generate exports for inline export annotations (after the type)
            for inlineExport in inlineExports {
                self.currentComponent.fields.append(
                    .init(
                        location: inlineExport.location,
                        kind: .exportDef(
                            ExportDef(
                                exportName: inlineExport.name,
                                descriptor: .type(.index(UInt32(typeIndex), typeLocation))
                            ))
                    )
                )
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
                    var exports: [CoreInstanceDef.Argument.Kind.Export] = []
                    while try parser.takeParenBlockStart("export") {
                        let exportName = try parser.expectString()
                        try parser.expect(.leftParen)
                        let sort = try parseCoreDefSort(&parser)
                        let indexOrId = try parser.expectIndexOrId()

                        // Resolve the index from the appropriate index space
                        let resolvedIndex: UInt32
                        switch sort {
                        case .func:
                            resolvedIndex = try UInt32(self.currentComponent.coreFunctionsMap.resolveIndex(use: indexOrId))
                        case .memory:
                            // For memory, we'd need to resolve through core memory index space
                            throw WatParserError("Inline export of memory not yet supported", location: parser.lexer.location())
                        default:
                            throw WatParserError("Inline export of \(sort) not yet supported", location: parser.lexer.location())
                        }

                        try parser.expect(.rightParen)  // Close (func/memory/etc.)
                        try parser.expect(.rightParen)  // Close (export ...)

                        exports.append(.init(name: exportName, sort: sort, index: resolvedIndex))
                    }
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

        private mutating func parseCoreDefSort(_ parser: inout Parser) throws(WatParserError) -> CoreDefSort {
            let rawKeyword = try parser.expectKeyword()
            guard let keyword = CoreDefSort(rawValue: rawKeyword) else {
                throw WatParserError(
                    "Unexpected core declaration sort `\(rawKeyword)",
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
                    "Unexpected component declaration sort `\(rawKeyword)",
                    location: parser.lexer.location()
                )
            }
        }

        private mutating func parseCoreInstanceDef(_ parser: inout Parser) throws(WatParserError) -> CoreInstanceDef {
            let instanceId = try parser.takeId()
            try parser.expect(.leftParen)

            try parser.expectKeyword("instantiate")
            let instantiatedModuleId = try parser.expectIndexOrId()
            var instantiateArguments = [CoreInstanceDef.Argument]()

            while try parser.take(.leftParen) {
                instantiateArguments.append(try self.parseModuleInstanceArguments(&parser))
                try parser.expect(.rightParen)
            }

            try parser.expect(.rightParen)

            return CoreInstanceDef(
                id: instanceId,
                moduleId: instantiatedModuleId,
                arguments: instantiateArguments
            )
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
                var declarations: [CoreModuleDecl] = []

                while try parser.take(.leftParen) {
                    let declKeyword = try parser.expectKeyword()
                    switch declKeyword {
                    case "alias":
                        try parser.expectKeyword("outer")
                        let componentIndex = try parser.expectIndexOrId()
                        let typeIndex = try parser.expectIndexOrId()
                        try parser.expect(.leftParen)
                        let sortKeyword = try parser.expectKeyword()
                        let bindingId = try parser.takeId()
                        try parser.expect(.rightParen)

                        guard let aliasSort = CoreAliasSort(rawValue: sortKeyword) else {
                            throw WatParserError("Unknown alias sort '\(sortKeyword)'", location: parser.lexer.location())
                        }

                        // Resolve outer alias immediately using component stack
                        let (resolvedIndex, outerCount) = try resolveOuterReference(componentId: componentIndex, typeIndex: typeIndex, sort: aliasSort)

                        declarations.append(
                            .alias(
                                CoreModuleAlias(
                                    sort: aliasSort,
                                    target: .outer(componentId: componentIndex, index: typeIndex, resolvedIndex: resolvedIndex, outerCount: outerCount),
                                    bindingId: bindingId
                                )))

                    case "import":
                        let moduleName = try parser.expectString()
                        let importName = try parser.expectString()
                        try parser.expect(.leftParen)
                        let descKeyword = try parser.expectKeyword()

                        let descriptor: CoreImportDesc
                        switch descKeyword {
                        case "func":
                            try parser.expect(.leftParen)
                            try parser.expectKeyword("type")
                            let typeIndex = try parser.expectIndexOrId()
                            try parser.expect(.rightParen)
                            descriptor = .func(typeIndex: typeIndex)
                        default:
                            throw WatParserError("Unsupported import descriptor '\(descKeyword)'", location: parser.lexer.location())
                        }

                        try parser.expect(.rightParen)

                        declarations.append(
                            .import(
                                CoreModuleImport(
                                    moduleName: moduleName,
                                    name: importName,
                                    descriptor: descriptor
                                )))

                    default:
                        throw WatParserError("Unknown module declaration '\(declKeyword)'", location: parser.lexer.location())
                    }
                    try parser.expect(.rightParen)
                }

                var moduleTypeDef = CoreModuleTypeDef(declarations: declarations)

                // Build local type bindings from aliases
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

                kind = .module(moduleTypeDef)

            default:
                throw WatParserError("Unknown core type keyword \(keyword)", location: parser.lexer.location())
            }

            try parser.expect(.rightParen)
            return CoreTypeDef(id: typeId, kind: kind)
        }

        private static func parseCoreValueType(_ parser: inout Parser) throws(WatParserError) -> WasmTypes.ValueType {
            var tempParser = WatParser(parser: parser)
            let unresolvedType = try tempParser.valueType()
            parser = tempParser.parser

            // Core types must be simple value types (i32, i64, f32, f64), not type references.
            // Resolve immediately using a dummy resolver since these types don't reference other definitions.
            struct DummyResolver: NameToIndexResolver {
                func resolveIndex(use: Parser.IndexOrId) throws(WatParserError) -> Int {
                    throw WatParserError("Core value types cannot reference other types", location: use.location)
                }
            }

            return try unresolvedType.resolve(DummyResolver())
        }

        /// Resolve an outer alias reference to a component's type
        /// Returns a tuple of (resolvedTypeIndex, outerCount) where outerCount is the distance to the target component
        private mutating func resolveOuterReference(componentId: Parser.IndexOrId, typeIndex: Parser.IndexOrId, sort: CoreAliasSort) throws(WatParserError) -> (resolvedIndex: Int, outerCount: Int) {
            // Find the target component in the component stack
            // For now, we assume componentId refers to a parent component by name
            // TODO: Support numeric outer counts (e.g., outer 0, outer 1)

            guard case .id(let targetName, _) = componentId else {
                throw WatParserError("Numeric outer counts not yet supported", location: componentId.location)
            }

            // Search component stack from top down (most recent first)
            // Include the current component (it can reference itself from within a module type)
            let currentDepth = componentStack.count - 1
            for i in (0...currentDepth).reversed() {
                let component = componentStack[i]
                if let compId = component.id, compId.value == targetName.value {
                    // Found the target component - resolve the type in its namespace
                    // Outer count is from the module type's perspective:
                    // - 1 level to get from module type to containing component
                    // - (currentDepth - i) levels from containing component to target
                    let outerCount = (currentDepth - i) + 1
                    switch sort {
                    case .type:
                        let resolvedIndex = try component.coreTypesMap.resolveIndex(use: typeIndex)
                        return (resolvedIndex, outerCount)
                    case .func, .table, .memory, .global:
                        throw WatParserError("Outer alias sort '\(sort.rawValue)' not yet supported", location: componentId.location)
                    }
                }
            }

            throw WatParserError("Component '\(targetName.value)' not found in outer scope", location: componentId.location)
        }

        /// Parse instance type declarations (type decls and exports)
        private mutating func parseInstanceTypeDeclarations(_ parser: inout Parser) throws(WatParserError) -> InstanceTypeDef {
            var typeDecls: [InstanceTypeDef.TypeDecl] = []
            var exports: [InstanceTypeDef.ExportDecl] = []

            while try parser.take(.leftParen) {
                let declKeyword = try parser.expectKeyword()
                switch declKeyword {
                case "type":
                    let typeId = try parser.takeId()
                    let valueType = try parseComponentValueType(&parser)
                    typeDecls.append(InstanceTypeDef.TypeDecl(id: typeId, valueType: valueType))
                case "export":
                    let exportName = try parser.expectString()
                    #warning("Skipping the type constraint as unimplemented")
                    var depth = 1
                    while depth > 0 {
                        if try parser.take(.leftParen) {
                            depth += 1
                        } else if try parser.take(.rightParen) {
                            depth -= 1
                        } else {
                            try parser.consume()
                        }
                    }
                    exports.append(InstanceTypeDef.ExportDecl(name: exportName))
                    continue  // Skip the outer expect(.rightParen) since we already consumed it
                default:
                    throw WatParserError("Unknown instance type declaration '\(declKeyword)'", location: parser.lexer.location())
                }
                try parser.expect(.rightParen)
            }

            return InstanceTypeDef(typeDecls: typeDecls, exports: exports)
        }

        /// Parse component type declarations (type decls, imports, and exports)
        private mutating func parseComponentTypeDeclarations(_ parser: inout Parser) throws(WatParserError) -> ComponentInnerTypeDef {
            var typeDecls: [ComponentInnerTypeDef.TypeDecl] = []
            var imports: [ComponentInnerTypeDef.ImportDecl] = []
            var exports: [ComponentInnerTypeDef.ExportDecl] = []

            while try parser.take(.leftParen) {
                let declKeyword = try parser.expectKeyword()
                switch declKeyword {
                case "type":
                    let typeId = try parser.takeId()
                    let valueType = try parseComponentValueType(&parser)
                    typeDecls.append(ComponentInnerTypeDef.TypeDecl(id: typeId, valueType: valueType))
                case "import":
                    let importName = try parser.expectString()
                    #warning("Skipping the type constraint as unimplemented")
                    var depth = 1
                    while depth > 0 {
                        if try parser.take(.leftParen) {
                            depth += 1
                        } else if try parser.take(.rightParen) {
                            depth -= 1
                        } else {
                            try parser.consume()
                        }
                    }
                    imports.append(ComponentInnerTypeDef.ImportDecl(name: importName))
                    continue
                case "export":
                    let exportName = try parser.expectString()

                    #warning("Skipping the type constraint as unimplemented")
                    var depth = 1
                    while depth > 0 {
                        if try parser.take(.leftParen) {
                            depth += 1
                        } else if try parser.take(.rightParen) {
                            depth -= 1
                        } else {
                            try parser.consume()
                        }
                    }
                    exports.append(ComponentInnerTypeDef.ExportDecl(name: exportName))
                    continue
                default:
                    throw WatParserError("Unknown component type declaration '\(declKeyword)'", location: parser.lexer.location())
                }
                try parser.expect(.rightParen)
            }

            return ComponentInnerTypeDef(typeDecls: typeDecls, imports: imports, exports: exports)
        }

        private mutating func parseComponentValueType(_ parser: inout Parser) throws(WatParserError) -> ComponentValueType {
            // First check for type reference (identifier like $A1)
            if let typeRef = try parser.takeId() {
                // Resolve the type reference to an index
                let typeIndex = try currentComponent.componentTypes.resolveIndex(
                    use: .id(typeRef, typeRef.location)
                )
                return .indexed(ComponentTypeIndex(rawValue: typeIndex))
            }

            let primitiveTypeKeyword = try parser.peekKeyword()

            if let primitiveTypeKeyword {
                let primitiveType: ComponentValueType
                switch primitiveTypeKeyword {
                case "bool": primitiveType = .bool
                case "u8": primitiveType = .u8
                case "u16": primitiveType = .u16
                case "u32": primitiveType = .u32
                case "u64": primitiveType = .u64
                case "s8": primitiveType = .s8
                case "s16": primitiveType = .s16
                case "s32": primitiveType = .s32
                case "s64": primitiveType = .s64
                case "float32", "f32": primitiveType = .float32
                case "float64", "f64": primitiveType = .float64
                case "char": primitiveType = .char
                case "string": primitiveType = .string
                case "error-context": primitiveType = .errorContext
                default:
                    throw WatParserError(
                        "Unexpected primitive component type keyword `\(primitiveTypeKeyword)`",
                        location: parser.lexer.location()
                    )
                }
                try parser.consume()
                return primitiveType
            } else {
                try parser.expect(.leftParen)
                let compositeTypeKeyword = try parser.expectKeyword()
                switch compositeTypeKeyword {
                case "list":
                    let elementType = try parseComponentValueType(&parser)
                    try parser.expect(.rightParen)
                    // Get or create type index for element
                    let elementIndex: ComponentTypeIndex
                    if case .indexed(let idx) = elementType {
                        elementIndex = idx
                    } else {
                        // Primitive - create a "pseudo-type" entry that encoder will inline
                        let elemIdx = try addAnonymousComponentType(elementType)
                        elementIndex = ComponentTypeIndex(rawValue: elemIdx)
                    }
                    let listValueType: ComponentValueType = .list(elementIndex)
                    let typeIndex = try addAnonymousComponentType(listValueType)
                    return .indexed(ComponentTypeIndex(rawValue: typeIndex))

                case "tuple":
                    var typeIndices: [ComponentTypeIndex] = []
                    while try !parser.take(.rightParen) {
                        let valueType = try parseComponentValueType(&parser)
                        if case .indexed(let idx) = valueType {
                            typeIndices.append(idx)
                        } else {
                            // Primitive - create pseudo-type entry
                            let elemIdx = try addAnonymousComponentType(valueType)
                            typeIndices.append(ComponentTypeIndex(rawValue: elemIdx))
                        }
                    }
                    let tupleValueType: ComponentValueType = .tuple(typeIndices)
                    let typeIndex = try addAnonymousComponentType(tupleValueType)
                    return .indexed(ComponentTypeIndex(rawValue: typeIndex))

                case "option":
                    let someType = try parseComponentValueType(&parser)
                    try parser.expect(.rightParen)
                    let elementIndex: ComponentTypeIndex
                    if case .indexed(let idx) = someType {
                        elementIndex = idx
                    } else {
                        let elemIdx = try addAnonymousComponentType(someType)
                        elementIndex = ComponentTypeIndex(rawValue: elemIdx)
                    }
                    let optionValueType: ComponentValueType = .option(elementIndex)
                    let typeIndex = try addAnonymousComponentType(optionValueType)
                    return .indexed(ComponentTypeIndex(rawValue: typeIndex))

                case "result":
                    var okType: ComponentTypeIndex?
                    var errorType: ComponentTypeIndex?
                    // Result can be: (result), (result TYPE), (result (ok TYPE)), (result (error TYPE)),
                    // (result TYPE (error TYPE)), (result (ok TYPE) (error TYPE))
                    if try !parser.take(.rightParen) {
                        // Check for (error ...) first (error-only result)
                        if try parser.takeParenBlockStart("error") {
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                errorType = idx
                            } else {
                                errorType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(valueType))
                            }
                            try parser.expect(.rightParen)
                            try parser.expect(.rightParen)
                        } else if try parser.takeParenBlockStart("ok") {
                            // Explicit (ok TYPE)
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                okType = idx
                            } else {
                                okType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(valueType))
                            }
                            try parser.expect(.rightParen)
                            // Check for optional (error TYPE)
                            if try parser.takeParenBlockStart("error") {
                                let errType = try parseComponentValueType(&parser)
                                if case .indexed(let idx) = errType {
                                    errorType = idx
                                } else {
                                    errorType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(errType))
                                }
                                try parser.expect(.rightParen)
                            }
                            try parser.expect(.rightParen)
                        } else {
                            // Shorthand: TYPE is the ok type
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                okType = idx
                            } else {
                                okType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(valueType))
                            }
                            // Check for optional (error TYPE)
                            if try parser.takeParenBlockStart("error") {
                                let errType = try parseComponentValueType(&parser)
                                if case .indexed(let idx) = errType {
                                    errorType = idx
                                } else {
                                    errorType = ComponentTypeIndex(rawValue: try addAnonymousComponentType(errType))
                                }
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
                        let fieldType = try parseComponentValueType(&parser)
                        let fieldTypeIndex: ComponentTypeIndex
                        if case .indexed(let idx) = fieldType {
                            fieldTypeIndex = idx
                        } else {
                            let idx = try addAnonymousComponentType(fieldType)
                            fieldTypeIndex = ComponentTypeIndex(rawValue: idx)
                        }
                        fields.append(ComponentRecordField(name: fieldName, type: fieldTypeIndex))
                        try parser.expect(.rightParen)
                    }
                    let recordValueType: ComponentValueType = .record(fields)
                    let typeIndex = try addAnonymousComponentType(recordValueType)
                    return .indexed(ComponentTypeIndex(rawValue: typeIndex))

                case "variant":
                    var cases: [ComponentCaseField] = []
                    while try parser.takeParenBlockStart("case") {
                        let caseName = try parser.expectString()
                        var caseType: ComponentTypeIndex? = nil
                        // Check if there's a type after the case name
                        if try !parser.take(.rightParen) {
                            let valueType = try parseComponentValueType(&parser)
                            if case .indexed(let idx) = valueType {
                                caseType = idx
                            } else {
                                let idx = try addAnonymousComponentType(valueType)
                                caseType = ComponentTypeIndex(rawValue: idx)
                            }
                            try parser.expect(.rightParen)
                        }
                        cases.append(ComponentCaseField(name: caseName, type: caseType))
                    }
                    let variantValueType: ComponentValueType = .variant(cases)
                    let typeIndex = try addAnonymousComponentType(variantValueType)
                    return .indexed(ComponentTypeIndex(rawValue: typeIndex))

                case "flags":
                    var flagNames: [String] = []
                    while let flagName = try parser.takeString() {
                        flagNames.append(flagName)
                    }
                    let flagsValueType: ComponentValueType = .flags(flagNames)
                    let typeIndex = try addAnonymousComponentType(flagsValueType)
                    return .indexed(ComponentTypeIndex(rawValue: typeIndex))

                case "enum":
                    var enumCases: [String] = []
                    while let caseName = try parser.takeString() {
                        enumCases.append(caseName)
                    }
                    let enumValueType: ComponentValueType = .enum(enumCases)
                    let typeIndex = try addAnonymousComponentType(enumValueType)
                    return .indexed(ComponentTypeIndex(rawValue: typeIndex))

                case "func", "component", "instance":
                    throw WatParserError(
                        "Not supported yet: `\(compositeTypeKeyword)`",
                        location: parser.lexer.location()
                    )
                default:
                    throw WatParserError(
                        "Unexpected composite component type keyword `\(compositeTypeKeyword)`",
                        location: parser.lexer.location()
                    )
                }
            }
        }

        /// Add an anonymous component type for inline type references
        private mutating func addAnonymousComponentType(_ valueType: ComponentValueType) throws(WatParserError) -> Int {
            let typeDef = ComponentTypeDef(id: nil, kind: .value(valueType))

            // Check if this type already exists as an anonymous type (deduplication)
            // Don't reuse named types - they should be referenced by index when used explicitly
            if let existingIndex = currentComponent.typesMap[.value(valueType)] {
                let existingTypeDef = currentComponent.componentTypes[existingIndex]
                if existingTypeDef.id == nil {
                    // Only reuse if it's truly anonymous
                    return existingIndex
                }
            }

            let index = try currentComponent.componentTypes.add(typeDef)
            // Store in typesMap for future anonymous deduplication
            // Note: If a named type with same kind exists, we still create a new anonymous one
            currentComponent.typesMap[.value(valueType)] = index
            return index
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

        private mutating func parseComponentFunc(_ parser: inout Parser) throws(WatParserError) {
            _ = parser.lexer.location()
            _ = try parser.takeId()
            var parameters = [ComponentFuncType.Param]()
            var resultType: ComponentValueType?
            var exportDef: (location: Location, exportName: String)?
            var importDef: (location: Location, importModule: String, importName: String)?

            /// Component functions are not tracked as separate entities in the final binary, i.e. there's no dedicated
            /// component functions section in the binary format. They're always encoded as a part of following
            /// sections: imports, exports, types, or canonical definitions.
            /// What looks like a function definition in component WAT `(func ...)` always desugars into one or
            /// more definitions in those sections.
            while try parser.take(.leftParen) {
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
                    let importModuleName = try parser.expectString()
                    let importName = try parser.expectString()
                    importDef = (parser.lexer.location(), importModuleName, importName)

                case "canon":
                    let location = parser.lexer.location()
                    try parser.expectKeyword("lift")
                    let coreFunctionIndex = try parseCoreFunctionIndex(&parser)
                    var options = [CanonDef.Option]()
                    while try parser.take(.leftParen) {
                        options.append(try parseCanonOpt(&parser))
                        try parser.expect(.rightParen)
                    }
                    self.currentComponent.fields.append(
                        .init(
                            location: location,
                            kind: .canon(
                                .init(
                                    kind: .lift(coreFunctionIndex),
                                    functionIndex: coreFunctionIndex,
                                    options: options
                                ))
                        )
                    )

                default:
                    throw WatParserError(
                        "Unknown component function keyword \(keyword)",
                        location: parser.lexer.location()
                    )
                }

                try parser.expect(.rightParen)
            }

            let concreteType: ComponentTypeDef.Kind
            if parameters.count > 0 || resultType != nil {
                concreteType = .function(.init(params: parameters, result: resultType))
            } else {
                concreteType = .function(.init(params: [], result: nil))
            }

            let typeIndex: Int
            if let existingTypeIndex = self.currentComponent.typesMap[concreteType] {
                typeIndex = existingTypeIndex
            } else {
                typeIndex = try self.currentComponent.componentTypes.add(.init(kind: concreteType))
                self.currentComponent.typesMap[concreteType] = typeIndex
            }

            let funcIndex = try self.currentComponent.componentFunctions.add(
                ComponentFuncDef(paramNames: parameters.map(\.name), type: .init(rawValue: typeIndex))
            )

            if let exportDef {
                self.currentComponent.fields.append(
                    .init(
                        location: exportDef.location,
                        kind: .exportDef(ExportDef(exportName: exportDef.exportName, descriptor: .function(.init(funcIndex))))
                    )
                )
            }

            if let importDef {
                self.currentComponent.fields.append(
                    .init(
                        location: importDef.location,
                        kind: .importDef(
                            .init(
                                importModuleName: importDef.importModule,
                                importName: importDef.importName,
                                descriptor: .function(.init(funcIndex))
                            )
                        )
                    )
                )
            }
        }

        private mutating func parseCanonOpt(_ parser: inout Parser) throws(WatParserError) -> CanonDef.Option {
            let keyword = try parser.expectKeyword()
            switch keyword {
            case "memory":
                return .memory(try parser.expectIndexOrId())
            case "realloc":
                return .realloc(try parseCoreFunctionIndex(&parser))
            case "post-return":
                return .postReturn(try parseCoreFunctionIndex(&parser))
            case "async":
                return .async
            case "callback":
                return .callback(try parseCoreFunctionIndex(&parser))
            default:
                throw WatParserError(
                    "Unknown canon options keyword \(keyword)",
                    location: parser.lexer.location()
                )
            }
        }

        private mutating func parseCoreFunctionIndex(_ parser: inout Parser) throws(WatParserError) -> FuncIndex {
            try parser.expect(.leftParen)
            try parser.expectKeyword("core")
            try parser.expectKeyword("func")
            let instanceId = try parser.expectIndexOrId()
            let exportName = try parser.expectString()
            try parser.expect(.rightParen)

            return .init(instance: instanceId, exportName: exportName)
        }

        /// Parse a component function reference: (func $instance "export")
        /// Used in canon lower syntax.
        private mutating func parseComponentFunctionIndex(_ parser: inout Parser) throws(WatParserError) -> ComponentFuncRef {
            try parser.expect(.leftParen)
            try parser.expectKeyword("func")
            let instanceId = try parser.expectIndexOrId()
            let exportName = try parser.expectString()
            try parser.expect(.rightParen)

            return .init(instance: instanceId, exportName: exportName)
        }
    }

    extension ComponentWatParser {
        struct ComponentDefField {
            enum Kind {
                case coreModule(CoreModuleIndex)
                case coreInstance(CoreInstanceIndex)
                case coreType(TypeIndex)
                case component(ComponentIndex)
                case instance(ComponentInstanceIndex)
                case componentType(ComponentTypeIndex)
                case canon(CanonDef)
                case exportDef(ExportDef)
                case importDef(ImportDef)
            }

            let location: Location
            let kind: Kind
        }

        struct ValueDef: NamedFieldDecl {
            var id: Name?
        }

        struct ComponentInstanceDef: NamedFieldDecl {
            var id: Name?
            var componentRef: Parser.IndexOrId?
            var arguments: [ComponentInstanceArgument]
        }

        struct ComponentInstanceArgument {
            enum Kind {
                case instance(Parser.IndexOrId)
            }
            let name: String
            let kind: Kind
        }

        /// A core function definition created via canon lower.
        struct CoreFuncDef: NamedFieldDecl {
            var id: Name?
        }

        /// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
        public struct ComponentDef: NamedFieldDecl {
            var id: Name?

            // Listed in the order of section indices in binary encoding.
            var coreModulesMap: NameMapping<ModuleDef> = .init()
            var coreInstancesMap: NameMapping<CoreInstanceDef> = .init()
            var coreTypesMap: CoreTypesMap = .init()
            var coreFunctionsMap: NameMapping<CoreFuncDef> = .init()  // Core functions created by canon lower

            var componentFunctions: NameMapping<ComponentFuncDef> = .init()
            var valuesMap: NameMapping<ValueDef> = .init()
            var componentTypes: NameMapping<ComponentTypeDef> = .init()
            var componentInstancesMap: NameMapping<ComponentInstanceDef> = .init()
            var componentsMap: NameMapping<ComponentDef> = .init()

            /// As sections in CM binaries can stay disjoint and unmerged,
            /// we should preserve disjoint sections together with their ordering.
            var fields = [ComponentDefField]()

            /// Mapping from a component type to its unique ID in `componentTypes` name mapping storage.
            var typesMap = [ComponentTypeDef.Kind: Int]()
        }

        struct ModuleDef: NamedFieldDecl {
            var id: Name?
            var wat: Wat
        }

        struct CoreInstanceDef: NamedFieldDecl {
            struct Argument {
                enum Kind {
                    struct Export {
                        let name: String
                        let sort: CoreDefSort
                        let index: UInt32
                    }
                    case instance(Parser.IndexOrId)
                    case exports([Export])
                }

                let importName: String
                let kind: Kind
            }

            var id: Name?
            var moduleId: Parser.IndexOrId
            var arguments: [Argument]
        }

        struct CoreTypeDef: NamedFieldDecl {
            enum Kind {
                case function(WatParser.FunctionType)
                case module(CoreModuleTypeDef)
            }
            var id: Name?
            let kind: Kind
        }

        struct CoreModuleTypeDef {
            var declarations: [CoreModuleDecl]
            var localTypeBindings: [String: Int] = [:]

            func resolveTypeIndex(use: Parser.IndexOrId, globalResolver: CoreTypesMap) throws(WatParserError) -> Int {
                switch use {
                case .id(let id, _):
                    if let localDeclIndex = localTypeBindings[id.value] {
                        return localDeclIndex
                    }
                    return try globalResolver.resolveIndex(use: use)
                case .index:
                    return try globalResolver.resolveIndex(use: use)
                }
            }
        }

        enum CoreModuleDecl {
            case alias(CoreModuleAlias)
            case type(TypeIndex)
            case `import`(CoreModuleImport)
            case export(CoreModuleExport)
        }

        struct CoreModuleAlias {
            let sort: CoreAliasSort
            let target: CoreModuleAliasTarget
            let bindingId: Name?
        }

        enum CoreModuleAliasTarget {
            case outer(componentId: Parser.IndexOrId, index: Parser.IndexOrId, resolvedIndex: Int, outerCount: Int)
        }

        enum CoreAliasSort: String {
            case `func`
            case table
            case memory
            case global
            case type
        }

        struct CoreModuleImport {
            let moduleName: String
            let name: String
            let descriptor: CoreImportDesc
        }

        enum CoreImportDesc {
            case `func`(typeIndex: Parser.IndexOrId)
        }

        struct CoreModuleExport {
            let name: String
            let descriptor: CoreImportDesc
        }

        struct FuncIndex {
            var instance: Parser.IndexOrId
            var exportName: String
        }

        /// Reference to a component function via instance export.
        /// Used in canon lower: (func $instance "export")
        struct ComponentFuncRef {
            var instance: Parser.IndexOrId
            var exportName: String
        }

        struct CanonDef {
            enum Option {
                case stringEncoding(ComponentStringEncoding)
                case memory(Parser.IndexOrId)
                case realloc(FuncIndex)
                case postReturn(FuncIndex)
                case `async`
                case callback(FuncIndex)
            }

            enum Kind {
                case lower(ComponentFuncRef)
                case lift(FuncIndex)
            }
            let kind: Kind
            let functionIndex: FuncIndex
            let options: [Option]
        }

        enum ExternDesc {
            case module(Parser.IndexOrId)
            case function(ComponentFuncIndex)
            case functionFromInstance(Parser.IndexOrId, String)  // (instance, exportName)
            case value(Parser.IndexOrId)
            case type(Parser.IndexOrId)
            case component(Parser.IndexOrId)
            case instance(Parser.IndexOrId)
        }

        struct ExportDef {
            let exportName: String
            let descriptor: ExternDesc
        }

        struct ImportDef {
            let importModuleName: String
            let importName: String
            let descriptor: ExternDesc
        }

        struct ComponentFuncDef: NamedFieldDecl {
            var id: Name?
            let paramNames: [String]
            let type: ComponentTypeIndex
        }

        struct ComponentTypeDef: NamedFieldDecl {
            enum Kind: Hashable {
                case function(ComponentFuncType)
                case value(ComponentValueType)
                case instance(InstanceTypeDef)
                case component(ComponentInnerTypeDef)
            }
            var id: Name?
            let kind: Kind
        }

        struct InstanceTypeDef: Hashable {
            struct TypeDecl: Hashable {
                let id: Name?
                let valueType: ComponentValueType
            }
            struct ExportDecl: Hashable {
                let name: String
                // Simplified - full implementation would handle type equality constraints
            }
            let typeDecls: [TypeDecl]
            let exports: [ExportDecl]
        }

        struct ComponentInnerTypeDef: Hashable {
            struct TypeDecl: Hashable {
                let id: Name?
                let valueType: ComponentValueType
            }
            struct ImportDecl: Hashable {
                let name: String
            }
            struct ExportDecl: Hashable {
                let name: String
            }
            let typeDecls: [TypeDecl]
            let imports: [ImportDecl]
            let exports: [ExportDecl]
        }
    }

#endif
