#if ComponentModel
    import Testing
    import WAT
    import ComponentModel
    import WasmParser

    @testable import WasmKit

    @Suite
    struct ComponentLoaderTests {
        // MARK: - ComponentImports Tests

        @Test
        func emptyComponentImports() {
            let imports = ComponentImports()
            #expect(imports.lookup(name: "nonexistent") == nil)
        }

        @Test
        func componentImportsLookup() throws {
            let engine = Engine()
            let store = Store(engine: engine)

            // Create a simple module instance to use as an import
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (func (export "test") (result i32)
                            i32.const 42
                        )
                    )
                    """
                )
            )
            let instance = try module.instantiate(store: store)

            var imports = ComponentImports()
            imports.define(name: "my-module", coreInstance: instance)

            let looked = imports.lookup(name: "my-module")
            #expect(looked != nil)
            #expect(imports.lookup(name: "other") == nil)
        }

        // MARK: - Error Cases

        @Test
        func invalidCoreInstanceIndex() throws {
            let engine = Engine()
            let store = Store(engine: engine)
            let linker = ComponentLoader(store: store)

            var component = ParsedComponent()
            // Try to export a core instance that doesn't exist
            component.exports.append(
                ParsedComponentExport(
                    name: "invalid",
                    kind: .coreInstance(instanceIndex: 99)
                ))

            do {
                _ = try linker.instantiate(component: component)
                Issue.record("Expected ComponentLoaderError.invalidCoreInstanceIndex to be thrown")
            } catch let error as ComponentLoaderError {
                guard case .invalidCoreInstanceIndex(let index) = error else {
                    Issue.record("Expected invalidCoreInstanceIndex, got \(error)")
                    return
                }
                #expect(index == 99)
            } catch {
                Issue.record("Expected ComponentLoaderError, got \(type(of: error))")
            }
        }

        @Test
        func coreExportNotFound() throws {
            let engine = Engine()
            let store = Store(engine: engine)
            let linker = ComponentLoader(store: store)

            // Create a core module without the expected export
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (func (export "other_func") (result i32)
                            i32.const 1
                        )
                    )
                    """
                )
            )

            var component = ParsedComponent()
            component.coreModules.append(ParsedCoreModule(module: module))
            // Add core instance definition to instantiate the module
            component.coreInstanceDefs.append(.instantiate(moduleIndex: 0, args: []))

            // Try to lift a function that doesn't exist
            let funcType = ComponentFuncType(params: [], result: .s32)
            component.canonicalDefinitions.append(
                ParsedCanonicalDefinition(
                    kind: .lift(coreInstanceIndex: 0, functionName: "nonexistent", type: funcType)
                ))

            do {
                _ = try linker.instantiate(component: component)
                Issue.record("Expected ComponentLoaderError.coreExportNotFound to be thrown")
            } catch let error as ComponentLoaderError {
                guard case .coreExportNotFound(let instanceIndex, let name) = error else {
                    Issue.record("Expected coreExportNotFound, got \(error)")
                    return
                }
                #expect(instanceIndex == 0)
                #expect(name == "nonexistent")
            } catch {
                Issue.record("Expected ComponentLoaderError, got \(type(of: error))")
            }
        }

        // MARK: - Import Validation Tests

        @Test
        func missingImportValidation() throws {
            let engine = Engine()
            let store = Store(engine: engine)
            let linker = ComponentLoader(store: store)

            // Create a component that requires an import
            var component = ParsedComponent()
            component.imports.append(
                ParsedComponentImport(
                    name: "required-module",
                    kind: .module
                ))

            // Try to instantiate without providing the import
            do {
                _ = try linker.instantiate(component: component)
                Issue.record("Expected ComponentLoaderError.missingImport to be thrown")
            } catch let error as ComponentLoaderError {
                guard case .missingImport(let name) = error else {
                    Issue.record("Expected missingImport, got \(error)")
                    return
                }
                #expect(name == "required-module")
            } catch {
                Issue.record("Expected ComponentLoaderError, got \(type(of: error))")
            }
        }

        @Test
        func incompatibleImportValidation() throws {
            let engine = Engine()
            let store = Store(engine: engine)
            let linker = ComponentLoader(store: store)

            // Create a core module instance
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (func (export "test") (result i32)
                            i32.const 42
                        )
                    )
                    """
                )
            )
            let instance = try module.instantiate(store: store)

            // Create a component that requires a function import
            var component = ParsedComponent()
            component.imports.append(
                ParsedComponentImport(
                    name: "my-import",
                    kind: .function(ComponentFuncType(params: [], result: .s32))
                ))

            // Provide a coreInstance instead of a function
            var imports = ComponentImports()
            imports.define(name: "my-import", coreInstance: instance)

            do {
                _ = try linker.instantiate(component: component, imports: imports)
                Issue.record("Expected ComponentLoaderError.incompatibleImport to be thrown")
            } catch let error as ComponentLoaderError {
                guard case .incompatibleImport(let name, let expected, let got) = error else {
                    Issue.record("Expected incompatibleImport, got \(error)")
                    return
                }
                #expect(name == "my-import")
                #expect(expected == "function")
                #expect(got == "coreInstance")
            } catch {
                Issue.record("Expected ComponentLoaderError, got \(type(of: error))")
            }
        }

        @Test
        func validModuleImport() throws {
            let engine = Engine()
            let store = Store(engine: engine)
            let linker = ComponentLoader(store: store)

            // Create a core module
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (func (export "test") (result i32)
                            i32.const 42
                        )
                    )
                    """
                )
            )

            // Create a component that requires a module import
            var component = ParsedComponent()
            component.imports.append(
                ParsedComponentImport(
                    name: "my-module",
                    kind: .module
                ))

            // Provide the module
            var imports = ComponentImports()
            imports.define(name: "my-module", coreModule: module)

            // Should succeed without throwing
            let instance = try linker.instantiate(component: component, imports: imports)
            #expect(instance.export("anything") == nil)  // Empty exports
        }

        // MARK: - Full CM WAT Tests

        /// Helper to parse, encode, and instantiate a component from WAT
        private func instantiateComponentWAT(_ wat: String) throws -> ComponentInstance {
            let engine = Engine()
            let store = Store(engine: engine)
            let linker = ComponentLoader(store: store)

            var wast = try parseComponentWAST(wat)
            guard let (directive, _) = try wast.nextDirective(),
                case .component(let comp) = directive,
                case .text(let componentDef) = comp.source
            else {
                throw ComponentLoaderError.missingImport(name: "Failed to parse component WAT")
            }

            var encoder = ComponentEncoder()
            let bytes = try encoder.encode(componentDef, options: .init())
            let parsed = try parseComponent(bytes: bytes)
            return try linker.instantiate(component: parsed)
        }

        @Test
        func liftCoreFunctionFromWAT() throws {
            let instance = try instantiateComponentWAT(
                """
                (component
                    (core module $m
                        (func (export "double") (param i32) (result i32)
                            local.get 0
                            local.get 0
                            i32.add
                        )
                        (memory (export "memory") 1)
                    )
                    (core instance $i (instantiate $m))
                    (func (export "double") (param "value" s32) (result s32)
                        (canon lift (core func $i "double")
                            (memory $i "memory")
                        )
                    )
                )
                """)

            guard case .function(let doubleFunc) = instance.export("double") else {
                Issue.record("Expected double function export")
                return
            }

            #expect(doubleFunc.type.params.count == 1)
            #expect(doubleFunc.type.params[0].name == "value")
            #expect(doubleFunc.type.result == .s32)

            // Test invocation
            let results = try doubleFunc.invoke([.s32(21)])
            if case .s32(let v) = results[0] {
                #expect(v == 42)
            } else {
                Issue.record("Expected s32 result")
            }
        }

        @Test
        func primitiveLiftingFromWAT() throws {
            let instance = try instantiateComponentWAT(
                """
                (component
                    (core module $m
                        (func (export "identity") (param i32) (result i32)
                            local.get 0
                        )
                    )
                    (core instance $i (instantiate $m))
                    (func (export "i-to-b") (param "a" u32) (result bool)
                        (canon lift (core func $i "identity"))
                    )
                    (func (export "i-to-u8") (param "a" u32) (result u8)
                        (canon lift (core func $i "identity"))
                    )
                    (func (export "i-to-s8") (param "a" u32) (result s8)
                        (canon lift (core func $i "identity"))
                    )
                )
                """)

            // Test i-to-b (u32 -> bool)
            guard case .function(let iToBFunc) = instance.export("i-to-b") else {
                Issue.record("Expected i-to-b function")
                return
            }

            var results = try iToBFunc.invoke([.u32(0)])
            if case .bool(let b) = results[0] {
                #expect(b == false)
            } else {
                Issue.record("Expected bool result")
            }

            results = try iToBFunc.invoke([.u32(1)])
            if case .bool(let b) = results[0] {
                #expect(b == true)
            } else {
                Issue.record("Expected bool result")
            }

            // Test i-to-u8 (u32 -> u8 with truncation)
            guard case .function(let iToU8Func) = instance.export("i-to-u8") else {
                Issue.record("Expected i-to-u8 function")
                return
            }

            results = try iToU8Func.invoke([.u32(0xf01)])
            if case .u8(let v) = results[0] {
                #expect(v == 1, "Expected truncation to 1")
            } else {
                Issue.record("Expected u8 result")
            }

            // Test i-to-s8 (u32 -> s8 with sign extension)
            guard case .function(let iToS8Func) = instance.export("i-to-s8") else {
                Issue.record("Expected i-to-s8 function")
                return
            }

            results = try iToS8Func.invoke([.u32(0xffff_ffff)])
            if case .s8(let v) = results[0] {
                #expect(v == -1)
            } else {
                Issue.record("Expected s8 result")
            }
        }

        @Test
        func stringLengthFromWAT() throws {
            // Test string parameter with realloc using full Component Model WAT
            let instance = try instantiateComponentWAT(
                """
                (component
                    (core module $m
                        (memory (export "memory") 1)
                        (func (export "realloc") (param i32 i32 i32 i32) (result i32)
                            i32.const 1024
                        )
                        (func (export "strlen") (param i32 i32) (result i32)
                            local.get 1
                        )
                    )
                    (core instance $i (instantiate $m))
                    (func (export "strlen") (param "s" string) (result u32)
                        (canon lift (core func $i "strlen")
                            (memory $i "memory")
                            (realloc (func $i "realloc"))
                        )
                    )
                )
                """)

            guard case .function(let strlenFunc) = instance.export("strlen") else {
                Issue.record("Expected strlen function export")
                return
            }

            // Test with empty string
            var results = try strlenFunc.invoke([.string("")])
            if case .u32(let len) = results[0] {
                #expect(len == 0)
            } else {
                Issue.record("Expected u32 result for empty string")
            }

            // Test with "hello" (5 bytes UTF-8)
            results = try strlenFunc.invoke([.string("hello")])
            if case .u32(let len) = results[0] {
                #expect(len == 5)
            } else {
                Issue.record("Expected u32 result for 'hello'")
            }

            // Test with unicode string "🍰" (4 bytes UTF-8)
            results = try strlenFunc.invoke([.string("🍰")])
            if case .u32(let len) = results[0] {
                #expect(len == 4, "Expected 4 UTF-8 bytes for cake emoji, got \(len)")
            } else {
                Issue.record("Expected u32 result for unicode string")
            }
        }

        @Test
        func stringRepeatFromWAT() throws {
            // Test string return using full Component Model WAT
            // Note: String results require indirect return (result flattens to 2 values > MAX_FLAT_RESULTS=1)
            // The core function must return a single i32 pointer to the result tuple in memory
            let instance = try instantiateComponentWAT(
                """
                (component
                    (core module $m
                        (memory (export "memory") 1)
                        ;; Start at offset 256 to ensure alignment
                        (global $next_ptr (mut i32) (i32.const 256))

                        ;; Helper to align pointer to 4 bytes
                        (func $align4 (param $ptr i32) (result i32)
                            (i32.and
                                (i32.add (local.get $ptr) (i32.const 3))
                                (i32.const -4)
                            )
                        )

                        ;; repeat_char: (length: i32, char: i32) -> i32 (pointer to result tuple)
                        ;; For indirect return: write (ptr, len) tuple to memory and return pointer to it
                        (func (export "repeat_char") (param $length i32) (param $char i32) (result i32)
                            (local $str_ptr i32)
                            (local $result_ptr i32)
                            (local $i i32)

                            ;; Allocate space for the string content (aligned to 4)
                            (local.set $str_ptr (call $align4 (global.get $next_ptr)))
                            (global.set $next_ptr (i32.add (local.get $str_ptr) (local.get $length)))

                            ;; Fill string with repeated char
                            (local.set $i (i32.const 0))
                            (block $done
                                (loop $loop
                                    (br_if $done (i32.ge_u (local.get $i) (local.get $length)))
                                    (i32.store8
                                        (i32.add (local.get $str_ptr) (local.get $i))
                                        (local.get $char)
                                    )
                                    (local.set $i (i32.add (local.get $i) (i32.const 1)))
                                    (br $loop)
                                )
                            )

                            ;; Allocate space for result tuple (ptr: i32, len: i32) = 8 bytes, aligned to 4
                            (local.set $result_ptr (call $align4 (global.get $next_ptr)))
                            (global.set $next_ptr (i32.add (local.get $result_ptr) (i32.const 8)))

                            ;; Store (ptr, len) tuple at result_ptr
                            (i32.store (local.get $result_ptr) (local.get $str_ptr))
                            (i32.store (i32.add (local.get $result_ptr) (i32.const 4)) (local.get $length))

                            ;; Return pointer to result tuple
                            (local.get $result_ptr)
                        )
                    )
                    (core instance $i (instantiate $m))
                    (func (export "repeat") (param "length" u32) (param "char" u32) (result string)
                        (canon lift (core func $i "repeat_char")
                            (memory $i "memory")
                        )
                    )
                )
                """)

            guard case .function(let repeatFunc) = instance.export("repeat") else {
                Issue.record("Expected repeat function export")
                return
            }

            // Test: repeat 'A' (65) 5 times -> "AAAAA"
            var results = try repeatFunc.invoke([.u32(5), .u32(65)])
            if case .string(let s) = results[0] {
                #expect(s == "AAAAA", "Expected 'AAAAA', got '\(s)'")
            } else {
                Issue.record("Expected string result, got \(results[0])")
            }

            // Test: repeat 'x' (120) 3 times -> "xxx"
            results = try repeatFunc.invoke([.u32(3), .u32(120)])
            if case .string(let s) = results[0] {
                #expect(s == "xxx", "Expected 'xxx', got '\(s)'")
            } else {
                Issue.record("Expected string result")
            }

            // Test: repeat with length 0 -> ""
            results = try repeatFunc.invoke([.u32(0), .u32(65)])
            if case .string(let s) = results[0] {
                #expect(s == "", "Expected empty string, got '\(s)'")
            } else {
                Issue.record("Expected string result")
            }
        }

        @Test
        func digitsToStringFromWAT() throws {
            // Test enum list to string conversion using Component Model WAT
            // This tests: enum lowering, list lowering, string lifting, memory management
            let instance = try instantiateComponentWAT(
                """
                (component
                    ;; Define digit variant (equivalent to enum) with all 10 digits
                    (type $digit (variant
                        (case "zero") (case "one") (case "two")
                        (case "three") (case "four") (case "five")
                        (case "six") (case "seven") (case "eight") (case "nine")
                    ))

                    (core module $m
                        (memory (export "memory") 1)
                        (global $heap_ptr (mut i32) (i32.const 1024))

                        ;; Alignment-aware realloc for list allocation
                        (func (export "realloc") (param $old_ptr i32) (param $old_size i32)
                                                  (param $align i32) (param $new_size i32) (result i32)
                            (local $ptr i32)
                            (local.set $ptr (i32.and
                                (i32.add (global.get $heap_ptr) (i32.sub (local.get $align) (i32.const 1)))
                                (i32.sub (i32.const 0) (local.get $align))
                            ))
                            (global.set $heap_ptr (i32.add (local.get $ptr) (local.get $new_size)))
                            (local.get $ptr)
                        )

                        ;; Core function: (list_ptr, list_len) -> result_ptr
                        ;; Converts list of discriminants to string with digit names
                        (func (export "digits_to_string") (param $list_ptr i32) (param $list_len i32) (result i32)
                            (local $i i32)
                            (local $disc i32)
                            (local $out_ptr i32)
                            (local $out_len i32)
                            (local $result_ptr i32)

                            ;; Allocate result tuple space (4-byte aligned)
                            (local.set $result_ptr (i32.and
                                (i32.add (global.get $heap_ptr) (i32.const 3))
                                (i32.const -4)
                            ))
                            (global.set $heap_ptr (i32.add (local.get $result_ptr) (i32.const 8)))

                            ;; Allocate output buffer (max 5 chars per digit: "Three", "Seven", "Eight")
                            (local.set $out_ptr (global.get $heap_ptr))
                            (global.set $heap_ptr (i32.add (local.get $out_ptr) (i32.mul (local.get $list_len) (i32.const 5))))

                            ;; Process each digit
                            (local.set $out_len (i32.const 0))
                            (loop $loop
                                (if (i32.lt_u (local.get $i) (local.get $list_len))
                                    (then
                                        ;; Read discriminant (for 10-case variant, discriminants are u8, 1 byte each)
                                        (local.set $disc (i32.load8_u (i32.add (local.get $list_ptr) (local.get $i))))

                                        ;; Write digit name based on discriminant
                                        (if (i32.eq (local.get $disc) (i32.const 0))
                                            (then
                                                ;; "Zero"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 90))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 101))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 114))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 3)) (i32.const 111))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 4)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 1))
                                            (then
                                                ;; "One"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 79))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 110))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 101))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 3)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 2))
                                            (then
                                                ;; "Two"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 84))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 119))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 111))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 3)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 3))
                                            (then
                                                ;; "Three"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 84))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 104))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 114))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 3)) (i32.const 101))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 4)) (i32.const 101))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 5)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 4))
                                            (then
                                                ;; "Four"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 70))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 111))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 117))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 3)) (i32.const 114))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 4)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 5))
                                            (then
                                                ;; "Five"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 70))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 105))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 118))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 3)) (i32.const 101))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 4)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 6))
                                            (then
                                                ;; "Six"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 83))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 105))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 120))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 3)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 7))
                                            (then
                                                ;; "Seven"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 83))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 101))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 118))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 3)) (i32.const 101))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 4)) (i32.const 110))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 5)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 8))
                                            (then
                                                ;; "Eight"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 69))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 105))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 103))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 3)) (i32.const 104))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 4)) (i32.const 116))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 5)))
                                            )
                                        )
                                        (if (i32.eq (local.get $disc) (i32.const 9))
                                            (then
                                                ;; "Nine"
                                                (i32.store8 (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 78))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 1)) (i32.const 105))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 2)) (i32.const 110))
                                                (i32.store8 (i32.add (i32.add (local.get $out_ptr) (local.get $out_len)) (i32.const 3)) (i32.const 101))
                                                (local.set $out_len (i32.add (local.get $out_len) (i32.const 4)))
                                            )
                                        )

                                        (local.set $i (i32.add (local.get $i) (i32.const 1)))
                                        (br $loop)
                                    )
                                )
                            )

                            ;; Write result tuple
                            (i32.store (local.get $result_ptr) (local.get $out_ptr))
                            (i32.store offset=4 (local.get $result_ptr) (local.get $out_len))
                            (local.get $result_ptr)
                        )
                    )
                    (core instance $i (instantiate $m))

                    (func (export "digits-to-string") (param "digits" (list $digit)) (result string)
                        (canon lift (core func $i "digits_to_string")
                            (memory $i "memory")
                            (realloc (func $i "realloc"))
                        )
                    )
                )
                """)

            guard case .function(let digitsFunc) = instance.export("digits-to-string") else {
                Issue.record("Expected digits-to-string function export")
                return
            }

            // Test: [one, two] -> "OneTwo"
            var results = try digitsFunc.invoke([
                .list([
                    .variant(caseName: "one", payload: nil),
                    .variant(caseName: "two", payload: nil),
                ])
            ])
            if case .string(let s) = results[0] {
                #expect(s == "OneTwo", "Expected 'OneTwo', got '\(s)'")
            } else {
                Issue.record("Expected string result, got \(results[0])")
            }

            // Test: [zero, one, two] -> "ZeroOneTwo"
            results = try digitsFunc.invoke([
                .list([
                    .variant(caseName: "zero", payload: nil),
                    .variant(caseName: "one", payload: nil),
                    .variant(caseName: "two", payload: nil),
                ])
            ])
            if case .string(let s) = results[0] {
                #expect(s == "ZeroOneTwo", "Expected 'ZeroOneTwo', got '\(s)'")
            } else {
                Issue.record("Expected string result")
            }

            // Test: all 10 digits
            results = try digitsFunc.invoke([
                .list([
                    .variant(caseName: "zero", payload: nil),
                    .variant(caseName: "one", payload: nil),
                    .variant(caseName: "two", payload: nil),
                    .variant(caseName: "three", payload: nil),
                    .variant(caseName: "four", payload: nil),
                    .variant(caseName: "five", payload: nil),
                    .variant(caseName: "six", payload: nil),
                    .variant(caseName: "seven", payload: nil),
                    .variant(caseName: "eight", payload: nil),
                    .variant(caseName: "nine", payload: nil),
                ])
            ])
            if case .string(let s) = results[0] {
                #expect(
                    s == "ZeroOneTwoThreeFourFiveSixSevenEightNine",
                    "Expected 'ZeroOneTwoThreeFourFiveSixSevenEightNine', got '\(s)'")
            } else {
                Issue.record("Expected string result")
            }

            // Test: [three, seven, nine] -> "ThreeSevenNine"
            results = try digitsFunc.invoke([
                .list([
                    .variant(caseName: "three", payload: nil),
                    .variant(caseName: "seven", payload: nil),
                    .variant(caseName: "nine", payload: nil),
                ])
            ])
            if case .string(let s) = results[0] {
                #expect(s == "ThreeSevenNine", "Expected 'ThreeSevenNine', got '\(s)'")
            } else {
                Issue.record("Expected string result")
            }

            // Test: empty list -> ""
            results = try digitsFunc.invoke([.list([])])
            if case .string(let s) = results[0] {
                #expect(s == "", "Expected empty string, got '\(s)'")
            } else {
                Issue.record("Expected string result")
            }
        }
    }

#endif
