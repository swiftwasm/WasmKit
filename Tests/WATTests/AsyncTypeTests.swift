#if ComponentModel
    import Testing
    import WAT
    import WasmKit
    import WasmParser

    @Suite struct AsyncTypeTests {
        private static let asyncFeatures: WasmFeatureSet = .all.union([.componentModelAsync])

        @Test func streamCharRejected() throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm("(component (type (stream char)))", features: Self.asyncFeatures)
            }
            #expect(error?.description.contains("stream char") == true)
        }

        @Test func streamTypeRequiresFlag() throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm("(component (type (stream u8)))", features: .default)
            }
            #expect(error?.description.contains("Unsupported type definition keyword stream") == true)
        }

        @Test func syncComponentEncodingUnchangedAcrossFlag() throws {
            let wat = "(component (type (func (result u32))))"
            let off = try wat2wasm(wat, features: .default)
            let on = try wat2wasm(wat, features: Self.asyncFeatures)
            #expect(off == on)
        }

        @Test func asyncCanonOpRequiresFlag() throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm(
                    "(component (canon task.return (result u32) (core func $tr)))", features: .default)
            }
            #expect(error?.message == "Unknown canon operation 'task.return'")
        }

        @Test func contextValueTypeErrorPointsAtValueType() throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm(
                    "(component (canon context.get\n  f32 0 (core func $cg)))", features: Self.asyncFeatures)
            }
            #expect(error?.message == "context.get/set value type must be i32 or i64, got 'f32'")
            let position = error?.location?.computeLineAndColumn()
            #expect(position?.line == 2)
            #expect(position?.column == 3)
        }

        @Test(arguments: [
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (type $t (func)) (func $g async (type $t) (canon lift (core func $i "f"))))"#,
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (type $t (func)) (func $g (type $t) async (canon lift (core func $i "f"))))"#,
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (type $t (func)) (canon lift (core func $i "f") (func $g async (type $t))))"#,
            #"(component (type (instance (type $t (func)) (export "f" (func async (type $t))))))"#,
            #"(component (type $t (func (result u32))) (import "f" (func async (type $t))))"#,
        ])
        func asyncWithTypeReferenceRejected(wat: String) throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm(wat, features: Self.asyncFeatures)
            }
            #expect(error?.message == "async cannot be combined with a type reference")
        }

        @Test func asyncAliasFunctionRejected() throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm(
                    #"(component (import "i" (instance $j (export "f" (func)))) (func $g async (alias export $j "f")))"#,
                    features: Self.asyncFeatures)
            }
            #expect(error?.message == "async cannot be combined with an alias")
        }

        @Test(arguments: [
            #"(component (type $t (func)) (import "f" (func (type $t) async)))"#,
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (type $t (func)) (canon lift (core func $i "f") (func $g (type $t) async)))"#,
            #"(component (type (instance (type $t (func)) (export "f" (func (type $t) async)))))"#,
            #"(component (import "i" (instance $j (export "f" (func)))) (func $g (alias export $j "f") async))"#,
            #"(component (import "f" (func (param "x" u32) async)))"#,
            #"(component (import "f" (func (result u32) async)))"#,
            #"(component (core module $m (func (export "f") (param i32))) (core instance $i (instantiate $m)) (func $g (param "x" u32) (canon lift (core func $i "f"))) (export "g" (func $g) (func (param "x" u32) async)))"#,
            #"(component (core module $m (func (export "f") (result i32) i32.const 0)) (core instance $i (instantiate $m)) (func $g (result u32) (canon lift (core func $i "f"))) (export "g" (func $g) (func (result u32) async)))"#,
            #"(component (core module $m (func (export "f") (param i32))) (core instance $i (instantiate $m)) (canon lift (core func $i "f") (func $g (param "x" u32) async)))"#,
            #"(component (core module $m (func (export "f") (result i32) i32.const 0)) (core instance $i (instantiate $m)) (canon lift (core func $i "f") (func $g (result u32) async)))"#,
            #"(component (type (func (param "x" u32) async)))"#,
            #"(component (type (func (result u32) async)))"#,
            #"(component (type (instance (type (func (param "x" u32) async)))))"#,
            #"(component (type (instance (type (func (result u32) async)))))"#,
            #"(component (type (instance (export "f" (func (param "x" u32) async)))))"#,
            #"(component (type (instance (export "f" (func (result u32) async)))))"#,
        ])
        func trailingAsyncInFunctionRejected(wat: String) throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm(wat, features: Self.asyncFeatures)
            }
            #expect(error?.message == "expected rightParen")
        }

        @Test(arguments: [
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (func $g (param "x" u32) async (canon lift (core func $i "f"))))"#,
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (func $g (result u32) async (canon lift (core func $i "f"))))"#,
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (func $g (canon lift (core func $i "f")) async))"#,
            #"(component (core module $m (func (export "f"))) (core instance $i (instantiate $m)) (func $g async async (canon lift (core func $i "f"))))"#,
        ])
        func misplacedOrRepeatedAsyncInComponentFunctionRejected(wat: String) throws {
            let error = #expect(throws: WatParserError.self) {
                _ = try wat2wasm(wat, features: Self.asyncFeatures)
            }
            #expect(error?.message == "async must appear once, before the function's params, result and canon lift")
        }

        @Test func streamBinaryDecodeRequiresFlag() throws {
            let bytes = try wat2wasm("(component (type (stream u8)))", features: Self.asyncFeatures)
            _ = try parseComponent(bytes: bytes, features: Self.asyncFeatures)
            let error = #expect(throws: WasmParserError.self) {
                _ = try parseComponent(bytes: bytes, features: .default)
            }
            #expect(error?.description.contains("malformed value type: 102") == true)
        }
    }
#endif
