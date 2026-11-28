#if ComponentModel
    import ComponentModel
    import Testing
    import WAT
    import WasmParser

    /// Checks that the decoder maps each async canon built-in to its opcode and
    /// immediate shape. `ComponentTests` compares only encoder output with `wasm-tools`.
    @Suite struct AsyncCanonOpTests {
        private static let asyncFeatures: WasmFeatureSet = .all.union([.componentModelAsync])

        // MARK: - Decode helpers

        /// Encodes `wat` with the async feature on and returns every canonical
        /// definition in the binary. Uses `WasmParser.ComponentParser` directly
        /// because `parseComponent` throws for async canon built-ins.
        private func decodeCanonicalDefinitions(_ wat: String) throws -> [CanonicalDefinition] {
            let bytes = try WAT.wat2wasm(wat, features: Self.asyncFeatures)
            var parser = WasmParser.ComponentParser(bytes: bytes, features: Self.asyncFeatures)
            var defs: [CanonicalDefinition] = []
            while let payload = try parser.parseNext() {
                if case .canonSection(let canons) = payload {
                    defs.append(contentsOf: canons)
                }
            }
            return defs
        }

        private func singleAsyncBuiltin(_ wat: String) throws -> AsyncCanonicalBuiltin {
            let builtins = try decodeCanonicalDefinitions(wat).compactMap {
                (def: CanonicalDefinition) -> AsyncCanonicalBuiltin? in
                if case .asyncBuiltin(let builtin) = def { return builtin }
                return nil
            }
            #expect(builtins.count == 1)
            return try #require(builtins.first)
        }

        private func optionsContainAsync(_ options: [CanonicalOption]) -> Bool {
            options.contains { if case .async = $0 { return true } else { return false } }
        }

        @Test func decodesNoneShape() throws {
            let builtin = try singleAsyncBuiltin("(component (canon waitable.join (core func $wj)))")
            #expect(builtin.opcode == .waitableJoin)
            guard case .none = builtin.immediates else {
                Issue.record("expected .none, got \(builtin.immediates)")
                return
            }

            let index = try singleAsyncBuiltin("(component (canon thread.index (core func $ti)))")
            #expect(index.opcode == .threadIndex)
            guard case .none = index.immediates else {
                Issue.record("expected .none for thread.index, got \(index.immediates)")
                return
            }
        }

        @Test func decodesBackpressureIncDecAsNoneShape() throws {
            let inc = try singleAsyncBuiltin("(component (canon backpressure.inc (core func $bi)))")
            #expect(inc.opcode == .backpressureInc)
            guard case .none = inc.immediates else {
                Issue.record("expected .none for backpressure.inc, got \(inc.immediates)")
                return
            }

            let dec = try singleAsyncBuiltin("(component (canon backpressure.dec (core func $bd)))")
            #expect(dec.opcode == .backpressureDec)
            guard case .none = dec.immediates else {
                Issue.record("expected .none for backpressure.dec, got \(dec.immediates)")
                return
            }
        }

        @Test func decodesTypeShape() throws {
            let builtin = try singleAsyncBuiltin(
                "(component (type (func)) (type $ST (stream u8)) (canon stream.new $ST (core func $sn)))")
            #expect(builtin.opcode == .streamNew)
            guard case .type(let typeIndex) = builtin.immediates else {
                Issue.record("expected .type, got \(builtin.immediates)")
                return
            }
            #expect(typeIndex == 1)
        }

        @Test func decodesTypeWithOptionsShape() throws {
            let builtin = try singleAsyncBuiltin(
                "(component (type (func)) (type $ST (stream u8)) (canon stream.read $ST async (core func $sr)))")
            #expect(builtin.opcode == .streamRead)
            guard case .typeWithOptions(let typeIndex, let options) = builtin.immediates else {
                Issue.record("expected .typeWithOptions, got \(builtin.immediates)")
                return
            }
            #expect(typeIndex == 1)
            #expect(options.count == 1)
            #expect(optionsContainAsync(options))
        }

        @Test func decodesTypeWithAsyncFlagShape() throws {
            let plain = try singleAsyncBuiltin(
                "(component (type (func)) (type $ST (stream u8)) (canon stream.cancel-read $ST (core func $scr)))")
            #expect(plain.opcode == .streamCancelRead)
            guard case .typeWithAsyncFlag(let plainTypeIndex, let plainAsync) = plain.immediates else {
                Issue.record("expected .typeWithAsyncFlag, got \(plain.immediates)")
                return
            }
            #expect(plainTypeIndex == 1)
            #expect(plainAsync == false)

            let flagged = try singleAsyncBuiltin(
                "(component (type (func)) (type $ST (stream u8)) (canon stream.cancel-read $ST async (core func $scr)))")
            guard case .typeWithAsyncFlag(let flaggedTypeIndex, let flaggedAsync) = flagged.immediates else {
                Issue.record("expected .typeWithAsyncFlag, got \(flagged.immediates)")
                return
            }
            #expect(flaggedTypeIndex == 1)
            #expect(flaggedAsync == true)
        }

        @Test func decodesAsyncFlagShape() throws {
            let plain = try singleAsyncBuiltin("(component (canon subtask.cancel (core func $sc)))")
            #expect(plain.opcode == .subtaskCancel)
            guard case .asyncFlag(let plainFlag) = plain.immediates else {
                Issue.record("expected .asyncFlag, got \(plain.immediates)")
                return
            }
            #expect(plainFlag == false)

            let flagged = try singleAsyncBuiltin("(component (canon subtask.cancel async (core func $sc)))")
            guard case .asyncFlag(let flag) = flagged.immediates else {
                Issue.record("expected .asyncFlag, got \(flagged.immediates)")
                return
            }
            #expect(flag == true)
        }

        @Test func decodesCancellableFlagShape() throws {
            let plain = try singleAsyncBuiltin("(component (canon thread.yield (core func $ty)))")
            #expect(plain.opcode == .threadYield)
            guard case .cancellableFlag(let plainFlag) = plain.immediates else {
                Issue.record("expected .cancellableFlag, got \(plain.immediates)")
                return
            }
            #expect(plainFlag == false)

            let flagged = try singleAsyncBuiltin("(component (canon thread.yield cancellable (core func $ty)))")
            guard case .cancellableFlag(let flag) = flagged.immediates else {
                Issue.record("expected .cancellableFlag, got \(flagged.immediates)")
                return
            }
            #expect(flag == true)

            let suspend = try singleAsyncBuiltin("(component (canon thread.suspend (core func $ts)))")
            #expect(suspend.opcode == .threadSuspend)
            guard case .cancellableFlag(let suspendFlag) = suspend.immediates else {
                Issue.record("expected .cancellableFlag for thread.suspend, got \(suspend.immediates)")
                return
            }
            #expect(suspendFlag == false)

            let cancellableSuspend = try singleAsyncBuiltin(
                "(component (canon thread.suspend cancellable (core func $ts)))")
            #expect(cancellableSuspend.opcode == .threadSuspend)
            guard case .cancellableFlag(let cancellableSuspendFlag) = cancellableSuspend.immediates else {
                Issue.record("expected .cancellableFlag for thread.suspend, got \(cancellableSuspend.immediates)")
                return
            }
            #expect(cancellableSuspendFlag == true)
        }

        @Test func decodesResultListWithOptionsShape() throws {
            let withResult = try singleAsyncBuiltin(
                "(component (canon task.return (result u32) (core func $tr)))")
            #expect(withResult.opcode == .taskReturn)
            guard case .resultListWithOptions(let result, let options) = withResult.immediates else {
                Issue.record("expected .resultListWithOptions, got \(withResult.immediates)")
                return
            }
            #expect(result == .inlined(.primitive(.u32)))
            #expect(options.isEmpty)

            let noResult = try singleAsyncBuiltin("(component (canon task.return (core func $tr)))")
            guard case .resultListWithOptions(let emptyResult, let emptyOptions) = noResult.immediates else {
                Issue.record("expected .resultListWithOptions, got \(noResult.immediates)")
                return
            }
            #expect(emptyResult == nil)
            #expect(emptyOptions.isEmpty)
        }

        @Test func decodesContextShape() throws {
            let get = try singleAsyncBuiltin("(component (canon context.get i32 0 (core func $cg)))")
            #expect(get.opcode == .contextGetI32)
            guard case .context(let getType, let getSlot) = get.immediates else {
                Issue.record("expected .context, got \(get.immediates)")
                return
            }
            #expect(getType == .i32)
            #expect(getSlot == 0)

            let set = try singleAsyncBuiltin("(component (canon context.set i64 3 (core func $cs)))")
            #expect(set.opcode == .contextSetI32)
            guard case .context(let setType, let setSlot) = set.immediates else {
                Issue.record("expected .context, got \(set.immediates)")
                return
            }
            #expect(setType == .i64)
            #expect(setSlot == 3)
        }

        @Test func decodesCancellableWithMemoryShape() throws {
            let wait = try singleAsyncBuiltin(
                """
                (component
                  (core module $Memory (memory (export "mem") 1))
                  (core instance $memory (instantiate $Memory))
                  (alias core export $memory "mem" (core memory $first))
                  (canon waitable-set.wait (memory $memory "mem") (core func $w)))
                """)
            #expect(wait.opcode == .waitableSetWait)
            guard case .cancellableWithMemory(let waitCancellable, let waitMemoryIndex) = wait.immediates else {
                Issue.record("expected .cancellableWithMemory, got \(wait.immediates)")
                return
            }
            #expect(waitCancellable == false)
            #expect(waitMemoryIndex == 1)

            let poll = try singleAsyncBuiltin(
                """
                (component
                  (core module $Memory (memory (export "mem") 1))
                  (core instance $memory (instantiate $Memory))
                  (canon waitable-set.poll cancellable (memory $memory "mem") (core func $p)))
                """)
            #expect(poll.opcode == .waitableSetPoll)
            guard case .cancellableWithMemory(let pollCancellable, let pollMemoryIndex) = poll.immediates else {
                Issue.record("expected .cancellableWithMemory, got \(poll.immediates)")
                return
            }
            #expect(pollCancellable == true)
            #expect(pollMemoryIndex == 0)
        }

        @Test func decodesTypeWithTableShape() throws {
            let builtin = try singleAsyncBuiltin(
                """
                (component
                  (type (func))
                  (core module $Table (table (export "__indirect_function_table") 2 funcref))
                  (core instance $table (instantiate $Table))
                  (core type (func))
                  (core type (func))
                  (core type $start-func-ty (func (param i32)))
                  (alias core export $table "__indirect_function_table" (core table))
                  (alias core export $table "__indirect_function_table" (core table $ift))
                  (core func $tni (canon thread.new-indirect $start-func-ty (table $ift))))
                """)
            #expect(builtin.opcode == .threadNewIndirect)
            guard case .typeWithTable(let typeIndex, let tableIndex) = builtin.immediates else {
                Issue.record("expected .typeWithTable, got \(builtin.immediates)")
                return
            }
            #expect(typeIndex == 2)
            #expect(tableIndex == 1)
        }

        // MARK: - `func async` parse positions

        @Test func decodesAsyncFuncInImportPosition() throws {
            let wat = #"(component (import "f" (func $f async (result u32))))"#
            let bytes = try WAT.wat2wasm(wat, features: Self.asyncFeatures)

            var parser = WasmParser.ComponentParser(bytes: bytes, features: Self.asyncFeatures)
            var sawAsyncFunc = false
            while let payload = try parser.parseNext() {
                if case .typeSection(let types) = payload {
                    for type in types {
                        if case .function(let funcType) = type, funcType.isAsync {
                            sawAsyncFunc = true
                        }
                    }
                }
            }
            #expect(sawAsyncFunc)
        }

        @Test func decodesAsyncFuncInInstanceTypeExportPosition() throws {
            let wat = #"(component (type (instance (export "write4" (func async)))))"#
            let bytes = try WAT.wat2wasm(wat, features: Self.asyncFeatures)

            var parser = WasmParser.ComponentParser(bytes: bytes, features: Self.asyncFeatures)
            var sawAsyncFunc = false
            while let payload = try parser.parseNext() {
                if case .typeSection(let types) = payload {
                    for case .instance(let instanceType) in types {
                        for case .type(.function(let funcType)) in instanceType.declarations where funcType.isAsync {
                            sawAsyncFunc = true
                        }
                    }
                }
            }
            #expect(sawAsyncFunc)
        }

        @Test func asyncFuncPositionsRejectedWithFlagOff() throws {
            #expect(throws: WatParserError.self) {
                _ = try WAT.wat2wasm(
                    #"(component (import "f" (func $f async (result u32))))"#, features: .default)
            }
            #expect(throws: WatParserError.self) {
                _ = try WAT.wat2wasm(
                    #"(component (type (instance (export "write4" (func async)))))"#, features: .default)
            }
        }
    }
#endif
