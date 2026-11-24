#if ComponentModel
    import ComponentModel
    import Testing
    import WasmParser

    @Suite
    struct ComponentParserTests {
        static func component(section id: UInt8, _ contents: [UInt8]) -> [UInt8] {
            [0x00, 0x61, 0x73, 0x6d, 0x0d, 0x00, 0x01, 0x00, id] + TestSupport.unsignedLEB128(contents.count) + contents
        }

        static func payloads(_ bytes: [UInt8]) throws(WasmParserError) -> [ComponentParsingPayload] {
            var parser = ComponentParser(bytes: bytes)
            var payloads: [ComponentParsingPayload] = []
            while let payload = try parser.parseNext() {
                payloads.append(payload)
            }
            return payloads
        }

        static func typeDefinitions(_ typeSection: [UInt8]) throws(WasmParserError) -> [ComponentTypeDef] {
            try payloads(component(section: 0x07, typeSection)).flatMap { payload -> [ComponentTypeDef] in
                guard case .typeSection(let types) = payload else { return [] }
                return types
            }
        }

        enum OperandType: CaseIterable {
            case record, variant, list, tuple, option, result

            var typeSection: [UInt8] {
                switch self {
                case .record: return [0x01, 0x72, 0x01, 0x01, 0x61, 0x79]  // (record (field "a" u32))
                case .variant: return [0x01, 0x71, 0x01, 0x01, 0x61, 0x01, 0x79, 0x00]  // (variant (case "a" u32))
                case .list: return [0x01, 0x70, 0x79]  // (list u32)
                case .tuple: return [0x01, 0x6f, 0x02, 0x79, 0x7d]  // (tuple u32 u8)
                case .option: return [0x01, 0x6b, 0x79]  // (option u32)
                case .result: return [0x01, 0x6a, 0x01, 0x79, 0x01, 0x7d]  // (result u32 (error u8))
                }
            }

            var expected: ComponentDefValType {
                switch self {
                case .record: return .record([ComponentRecordField(name: "a", type: .primitive(.u32))])
                case .variant: return .variant([ComponentCaseField(name: "a", type: .primitive(.u32))])
                case .list: return .list(.primitive(.u32))
                case .tuple: return .tuple([.primitive(.u32), .primitive(.u8)])
                case .option: return .option(.primitive(.u32))
                case .result: return .result(ok: .primitive(.u32), error: .primitive(.u8))
                }
            }
        }

        @Test(arguments: OperandType.allCases)
        func primitiveOperandsParseAsPrimitives(type: OperandType) throws {
            let types = try Self.typeDefinitions(type.typeSection)
            guard types.count == 1, case .definedValue(let parsed) = types[0] else {
                Issue.record("Expected one defined value type, got \(types)")
                return
            }
            #expect(parsed == type.expected)
        }

        @Test
        func typeIndicesInFunctionType() throws {
            // (func (param "p" 63) (param "q" 64) (result 129))
            let types = try Self.typeDefinitions([
                0x01, 0x40, 0x02, 0x01, 0x70, 0x3f, 0x01, 0x71, 0xc0, 0x00, 0x00, 0x81, 0x01,
            ])
            guard types.count == 1, case .function(let function) = types[0] else {
                Issue.record("Expected one function type, got \(types)")
                return
            }
            let index63 = ComponentDefValType.indexed(ComponentTypeIndex(rawValue: 63))
            let index64 = ComponentDefValType.indexed(ComponentTypeIndex(rawValue: 64))
            let index129 = ComponentDefValType.indexed(ComponentTypeIndex(rawValue: 129))
            #expect(function == ComponentFuncType(params: [.init(name: "p", type: index63), .init(name: "q", type: index64)], result: index129))
        }

        @Test
        func resourceTypesParse() throws {
            // (resource (rep i32)), (resource (rep i32) (dtor 0))
            let types = try Self.typeDefinitions([0x02, 0x3f, 0x7f, 0x00, 0x3f, 0x7f, 0x01, 0x00])
            guard types.count == 2, case .resource(let first) = types[0], case .resource(let second) = types[1] else {
                Issue.record("Expected two resource types, got \(types)")
                return
            }
            #expect(first == nil)
            #expect(second == 0)
        }

        @Test
        func handleTypesParse() throws {
            // (resource (rep i32)), (own 0), (borrow 0)
            let types = try Self.typeDefinitions([0x03, 0x3f, 0x7f, 0x00, 0x69, 0x00, 0x68, 0x00])
            guard types.count == 3, case .definedValue(let owned) = types[1], case .definedValue(let borrowed) = types[2] else {
                Issue.record("Expected a resource and two handle types, got \(types)")
                return
            }
            #expect(owned == .own(ResourceTypeIndex(rawValue: 0)))
            #expect(borrowed == .borrow(ResourceTypeIndex(rawValue: 0)))
        }

        @Test
        func coreTagSortParses() throws {
            // (core instance (export "t" (tag 0)))
            let instanceBytes = Self.component(section: 0x02, [0x01, 0x01, 0x01, 0x01, 0x74, 0x04, 0x00])
            guard case .coreInstanceSection(let instances) = try Self.payloads(instanceBytes).last,
                instances.count == 1, case .exports(let exports) = instances[0], exports.count == 1
            else {
                Issue.record("Expected one core instance with one export")
                return
            }
            #expect(exports[0].sort == .tag)

            // (alias core export 0 "t" (core tag))
            let aliasBytes = Self.component(section: 0x06, [0x01, 0x00, 0x04, 0x01, 0x00, 0x01, 0x74])
            guard case .aliasSection(let aliases) = try Self.payloads(aliasBytes).last, aliases.count == 1 else {
                Issue.record("Expected one alias")
                return
            }
            guard case .core(.tag) = aliases[0].sort else {
                Issue.record("Expected a core tag alias, got \(aliases[0].sort)")
                return
            }
        }

        @Test
        func exportWithTypeAscription() throws {
            // (export "g" (func 0) (func (type 1)))
            let bytes = Self.component(section: 0x0b, [0x01, 0x00, 0x01, 0x67, 0x01, 0x00, 0x01, 0x01, 0x01])
            guard case .exportSection(let exports) = try Self.payloads(bytes).last, exports.count == 1 else {
                Issue.record("Expected one export")
                return
            }
            #expect(exports[0].name == "g")
            #expect(exports[0].index == 0)
            guard case .function(typeIndex: 1)? = exports[0].externDesc else {
                Issue.record("Expected a function type ascription, got \(String(describing: exports[0].externDesc))")
                return
            }
        }

        @Test
        func importNameWithPrefixOneHasNoVersionSuffix() throws {
            // Name prefix 0x01, name "a", (func (type 0))
            let bytes = Self.component(section: 0x0a, [0x01, 0x01, 0x01, 0x61, 0x01, 0x00])
            guard case .importSection(let imports) = try Self.payloads(bytes).last, imports.count == 1 else {
                Issue.record("Expected one import")
                return
            }
            #expect(imports[0].name == "a")
            guard case .function(typeIndex: 0) = imports[0].externDesc else {
                Issue.record("Expected a function import, got \(imports[0].externDesc)")
                return
            }
        }

        @Test
        func coreModuleTypeTagDescriptorsParse() throws {
            // (core type (module (import "a" "b" (tag (param i32))) (export "c" (tag (param i32)))))
            let bytes = Self.component(
                section: 0x03,
                [
                    0x01, 0x50, 0x04,
                    0x01, 0x60, 0x01, 0x7f, 0x00,
                    0x00, 0x01, 0x61, 0x01, 0x62, 0x04, 0x00, 0x00,
                    0x01, 0x60, 0x01, 0x7f, 0x00,
                    0x03, 0x01, 0x63, 0x04, 0x00, 0x01,
                ])
            guard case .coreTypeSection(let types) = try Self.payloads(bytes).last, types.count == 1,
                case .module(let module) = types[0], module.declarations.count == 4,
                case .import(let imported) = module.declarations[1],
                case .exportDecl(let exportName, let exported) = module.declarations[3]
            else {
                Issue.record("Expected one core module type with an import and an export")
                return
            }
            #expect(imported.descriptor == .tag(0))
            #expect(exportName == "c")
            #expect(exported == .tag(1))
        }

        enum MalformedComponent: CaseIterable {
            case version, layer, namedResults, resultLeadingByte, namePrefix, exportTypePresenceByte, stream, future, funcAsync, asyncCanonBuiltin
            case variantCaseTerminator, resultCompositeType, tagAttribute

            var bytes: [UInt8] {
                switch self {
                case .version:  // header version 0x0e
                    return [0x00, 0x61, 0x73, 0x6d, 0x0e, 0x00, 0x01, 0x00]
                case .layer:  // header layer 0x02
                    return [0x00, 0x61, 0x73, 0x6d, 0x0d, 0x00, 0x02, 0x00]
                case .namedResults:  // (func) with one named result and no result entry
                    return ComponentParserTests.component(section: 0x07, [0x01, 0x40, 0x00, 0x01, 0x01])
                case .resultLeadingByte:  // (func) with result list byte 0x02
                    return ComponentParserTests.component(section: 0x07, [0x01, 0x40, 0x00, 0x02, 0x00])
                case .namePrefix:  // import name prefix 0x02
                    return ComponentParserTests.component(section: 0x0a, [0x01, 0x02, 0x01, 0x61, 0x01, 0x00])
                case .exportTypePresenceByte:  // export "g" (func 0) with type presence byte 0x02
                    return ComponentParserTests.component(section: 0x0b, [0x01, 0x00, 0x01, 0x67, 0x01, 0x00, 0x02])
                case .stream:  // (stream u8)
                    return ComponentParserTests.component(section: 0x07, [0x01, 0x66, 0x01, 0x7d])
                case .future:  // (future u8)
                    return ComponentParserTests.component(section: 0x07, [0x01, 0x65, 0x01, 0x7d])
                case .funcAsync:  // (func async)
                    return ComponentParserTests.component(section: 0x07, [0x01, 0x43, 0x00, 0x01, 0x00])
                case .asyncCanonBuiltin:  // (canon waitable-set.new)
                    return ComponentParserTests.component(section: 0x08, [0x01, 0x1f])
                case .variantCaseTerminator:  // (variant (case "a")) with terminator byte 0x01
                    return ComponentParserTests.component(section: 0x07, [0x01, 0x71, 0x01, 0x01, 0x61, 0x00, 0x01])
                case .resultCompositeType:  // (func (result (list u32))) with the list written inline
                    return ComponentParserTests.component(section: 0x07, [0x01, 0x40, 0x00, 0x00, 0x70, 0x79])
                case .tagAttribute:  // (core type (module (import "a" "b" (tag ...)))) with tag attribute byte 0x01
                    return ComponentParserTests.component(
                        section: 0x03, [0x01, 0x50, 0x01, 0x00, 0x01, 0x61, 0x01, 0x62, 0x04, 0x01, 0x00])
                }
            }

            var message: String {
                switch self {
                case .version: return "unknown binary version: [14, 0]"
                case .layer: return "unknown binary version: [13, 0, 2, 0]"
                case .namedResults: return "named results must be empty, got count 1"
                case .resultLeadingByte: return "invalid leading byte (0x2) for component function results"
                case .namePrefix: return "invalid import/export name prefix: 0x2"
                case .exportTypePresenceByte: return "invalid leading byte (0x2) for export type ascription"
                case .stream: return "malformed value type: 102"
                case .future: return "malformed value type: 101"
                case .funcAsync: return "invalid leading byte (0x43) for component type"
                case .asyncCanonBuiltin: return "invalid leading byte (0x1f) for canon definition"
                case .variantCaseTerminator: return "invalid leading byte (0x1) for variant case terminator"
                case .resultCompositeType: return "malformed value type: 112"
                case .tagAttribute: return "Invalid tag attribute: 1 (expected 0)"
                }
            }
        }

        @Test(arguments: MalformedComponent.allCases)
        func malformedComponentIsRejected(component: MalformedComponent) {
            let error = #expect(throws: WasmParserError.self) {
                _ = try Self.payloads(component.bytes)
            }
            guard let error else { return }
            guard case .message(let message) = error.kind else {
                Issue.record("Expected a message error, got \(error)")
                return
            }
            #expect(message.text == component.message)
        }
    }
#endif
