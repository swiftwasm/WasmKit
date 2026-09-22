import Foundation

/// A utility to generate internal VM instruction related code.
enum VMGen {

    static func camelCase(pascalCase: String) -> String {
        let first = pascalCase.first!.lowercased()
        return first + pascalCase.dropFirst()
    }

    static func pascalCase(camelCase: String) -> String {
        let first = camelCase.first!.uppercased()
        return first + camelCase.dropFirst()
    }

    static func snakeCase(pascalCase: String) -> String {
        var result = ""
        for (i, c) in pascalCase.enumerated() {
            if i > 0, c.isUppercase {
                result += "_"
            }
            result.append(c.lowercased())
        }
        return result
    }

    static func alignUp(_ size: Int, to alignment: Int) -> Int {
        (size + alignment - 1) / alignment * alignment
    }

    /// Maps every instruction name to the instruction that owns the handler body it runs.
    ///
    /// Instructions that declare the same `handlerIdentity` compile to bit-identical
    /// handler bodies; the first one in instruction order becomes the canonical owner
    /// and the rest are aliases of it. Instructions without an identity, and the
    /// canonical member of each group, map to themselves.
    ///
    /// Both threading models must agree on this mapping: the direct-threaded handler
    /// table and the token-threaded dispatcher are generated from it, so an alias can
    /// never end up running a different body depending on the threading model.
    static func canonicalHandlerOwners(instructions: [Instruction]) -> [String: Instruction] {
        var canonicalOfIdentity: [String: Instruction] = [:]
        var owners: [String: Instruction] = [:]
        for inst in instructions {
            guard let identity = inst.handlerIdentity else {
                owners[inst.name] = inst
                continue
            }
            precondition(
                !inst.isControl,
                "\(inst.name): control instructions must not share a handler; the debugger maps head slots back to opcode IDs"
            )
            guard let canonical = canonicalOfIdentity[identity] else {
                canonicalOfIdentity[identity] = inst
                owners[inst.name] = inst
                continue
            }
            precondition(
                canonical.mayThrow == inst.mayThrow && canonical.mayUpdatePc == inst.mayUpdatePc
                    && canonical.mayUpdateFrame == inst.mayUpdateFrame
                    && canonical.mayDispatchToTrap == inst.mayDispatchToTrap
                    && canonical.immediate?.type == inst.immediate?.type,
                "\(inst.name) and \(canonical.name) claim the same handler identity '\(identity)' but have different handler shapes"
            )
            owners[inst.name] = canonical
        }
        return owners
    }

    /// The execution parameters the `execute_*` wrapper of `inst` takes. The
    /// accumulator is passed only to a handler that uses it; otherwise the
    /// trampoline would have to materialize it to take its address.
    static func wrapperParameters(of inst: Instruction) -> [ExecutionParameter] {
        var params: [ExecutionParameter] = [.sp, .pc, .md, .ms]
        if inst.useIreg != .none { params.append(.ireg) }
        if inst.useFreg != .none { params.append(.freg) }
        return params
    }

    static func generateDispatcher(instructions: [Instruction]) -> String {
        let owners = canonicalHandlerOwners(instructions: instructions)
        // The translator emits accumulator forms only under direct threading,
        // so the token-threaded dispatcher has neither the accumulator nor cases
        // for them.
        let doExecuteParams: [Instruction.Parameter] =
            [("opcode", "OpcodeID", false)]
            + [ExecutionParameter.sp, .pc, .md, .ms].map { ($0.label, $0.type, true) }
        var output = """
            extension Execution {

                /// Execute an instruction identified by the opcode.
                /// Note: This function is only used when using token threading model.
                @inline(__always)
                mutating func doExecute(_ \(doExecuteParams.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", "))) throws -> CodeSlot {
                    switch opcode {
            """

        for (opcode, inst) in instructions.enumerated() where !inst.isDirectThreadedOnly {
            let owner = owners[inst.name]!
            let tryPrefix = inst.mayThrow || inst.mayDispatchToTrap ? "try " : ""
            let prefix = inst.mayDispatchToTrap ? "executeToken_" : "execute_"
            let args = wrapperParameters(of: owner).map { "\($0.label): &\($0.label)" }
            if owner.name != inst.name {
                output += """

                            // \(inst.name) shares \(owner.name)'s handler body; see Instruction.handlerIdentity
                    """
            }
            output += """

                        case \(opcode): return \(tryPrefix)self.\(prefix)\(owner.name)(\(args.joined(separator: ", ")))
                """
        }
        output += """

                    default: preconditionFailure("Unknown instruction!?")

                    }
                }
            }
            """
        return output
    }

    static func generateBasicInstImplementations() -> [String: String] {
        var inlineImpls: [String: String] = [:]
        for op in intBinOps + floatBinOps {
            inlineImpls[op.instruction.name] = """
            sp.pointee[\(op.resultSlot): immediate.result] = \(op.mayThrow ? "try " : "")sp.pointee[\(op.lhsSlot): immediate.lhs].\(camelCase(pascalCase: op.op))(sp.pointee[\(op.rhsSlot): immediate.rhs])
            """
        }
        for op in floatBinBinOps {
            // The intermediate is bound to a `let` and both operations use the
            // ordinary `+`/`-`/`*`, so LLVM rounds each one separately: Wasm
            // forbids contracting this into a fused multiply-add (on arm64 the
            // handlers are `fmul` + `fadd`, never `fmadd`).
            inlineImpls[op.instruction.name] = """
                let intermediate = sp.pointee[\(op.slot): immediate.x].\(camelCase(pascalCase: op.op1))(sp.pointee[\(op.slot): immediate.y])
                        sp.pointee[\(op.slot): immediate.result] = intermediate.\(camelCase(pascalCase: op.op2))(sp.pointee[\(op.slot): immediate.z])
                """
        }
        for op in intBinBinOps {
            let second =
                op.reversed
                ? "sp.pointee[\(op.type): immediate.z].\(camelCase(pascalCase: op.op2))(intermediate)"
                : "intermediate.\(camelCase(pascalCase: op.op2))(sp.pointee[\(op.type): immediate.z])"
            inlineImpls[op.instruction.name] = """
                let intermediate = sp.pointee[\(op.type): immediate.x].\(camelCase(pascalCase: op.op1))(sp.pointee[\(op.type): immediate.y])
                        sp.pointee[\(op.type): immediate.result] = \(second)
                """
        }
        for op in intAccBinOps {
            let load = op.type == "i32" ? "UInt32(truncatingIfNeeded: ireg.pointee)" : "ireg.pointee"
            func store(_ expression: String) -> String {
                op.type == "i32" ? "UInt64(\(expression))" : expression
            }
            let method = camelCase(pascalCase: op.op)
            inlineImpls[op.toAccName] = """
                ireg.pointee = \(store("sp.pointee[\(op.type): immediate.lhs].\(method)(sp.pointee[\(op.type): immediate.rhs])"))
                """
            inlineImpls[op.fromAccName] = """
                sp.pointee[\(op.type): immediate.result] = \(load).\(method)(sp.pointee[\(op.type): immediate.operand])
                """
            inlineImpls[op.inAccName] = """
                ireg.pointee = \(store("\(load).\(method)(sp.pointee[\(op.type): immediate.operand])"))
                """
            inlineImpls[op.toAccAndSlot.name] = """
                let value = sp.pointee[\(op.type): immediate.lhs].\(method)(sp.pointee[\(op.type): immediate.rhs])
                        sp.pointee[\(op.type): immediate.result] = value
                        ireg.pointee = \(store("value"))
                """
        }
        inlineImpls["consumeFuel"] = """
            if let trap = consumeFuel(immediate: immediate) { %TRAP% }
            """
        inlineImpls["selectAcc"] = """
            let onTrue = sp.pointee[immediate.onTrue]
                    let onFalse = sp.pointee[immediate.onFalse]
                    sp.pointee[immediate.result] = UInt32(truncatingIfNeeded: ireg.pointee) != 0 ? onTrue : onFalse
            """
        for type in intValueTypes {
            for op in selectCmpOps {
                inlineImpls["select\(type.uppercased())\(op)"] = """
                    let onTrue = sp.pointee[immediate.onTrue]
                            let onFalse = sp.pointee[immediate.onFalse]
                            sp.pointee[immediate.result] = sp.pointee[\(type): immediate.lhs].\(camelCase(pascalCase: op))(sp.pointee[\(type): immediate.rhs]) != 0 ? onTrue : onFalse
                    """
            }
            for op in selectCmpImmOps {
                inlineImpls["select\(type.uppercased())\(op)Imm"] = """
                    let onTrue = sp.pointee[immediate.onTrue]
                            let onFalse = sp.pointee[immediate.onFalse]
                            sp.pointee[immediate.result] = sp.pointee[\(type): immediate.lhs].\(camelCase(pascalCase: op))(immediate.\(type)) != 0 ? onTrue : onFalse
                    """
            }
        }
        inlineImpls["copyStackAccToSlot"] = """
            sp.pointee[immediate.dest] = sp.pointee[immediate.source]
                    sp.pointee[immediate.result] = UntypedValue(storage: ireg.pointee)
            """
        inlineImpls["globalGetToAcc"] = """
            ireg.pointee = immediate.global.withValue { $0.rawStorage.lo }
            """
        for op in intBinImmInsts + intCmpImmInsts {
            inlineImpls[op.instruction.name] = """
            sp.pointee[\(op.resultType): immediate.result] = sp.pointee[\(op.type): immediate.lhs].\(camelCase(pascalCase: op.op))(immediate.\(op.type))
            """
        }
        for op in intBinImmInsts {
            let value = "sp.pointee[\(op.type): immediate.lhs].\(camelCase(pascalCase: op.op))(immediate.\(op.type))"
            inlineImpls[op.toAcc.name] = """
            ireg.pointee = \(op.type == "i32" ? "UInt64(\(value))" : value)
            """
            inlineImpls[op.toAccAndSlot.name] = """
            let value = \(value)
                    sp.pointee[\(op.type): immediate.result] = value
                    ireg.pointee = \(op.type == "i32" ? "UInt64(value)" : "value")
            """
        }
        for op in floatAccBinOps {
            let method = camelCase(pascalCase: op.op)
            inlineImpls["f64\(op.op)ToAcc"] = """
                freg.pointee = sp.pointee[f64: immediate.lhs].\(method)(sp.pointee[f64: immediate.rhs])
                """
            inlineImpls["f64\(op.op)FromAcc"] = """
                sp.pointee[f64: immediate.result] = freg.pointee.\(method)(sp.pointee[f64: immediate.operand])
                """
            inlineImpls["f64\(op.op)InAcc"] = """
                freg.pointee = freg.pointee.\(method)(sp.pointee[f64: immediate.operand])
                """
            inlineImpls["f64\(op.op)FromAccRev"] = """
                sp.pointee[f64: immediate.result] = sp.pointee[f64: immediate.operand].\(method)(freg.pointee)
                """
            inlineImpls["f64\(op.op)InAccRev"] = """
                freg.pointee = sp.pointee[f64: immediate.operand].\(method)(freg.pointee)
                """
        }
        for op in floatBinBinOps where op.type == "f64" {
            inlineImpls["\(op.name)ToAcc"] = """
                let intermediate = sp.pointee[f64: immediate.x].\(camelCase(pascalCase: op.op1))(sp.pointee[f64: immediate.y])
                        freg.pointee = intermediate.\(camelCase(pascalCase: op.op2))(sp.pointee[f64: immediate.z])
                """
        }
        inlineImpls["f64SqrtToAcc"] = """
            freg.pointee = sp.pointee[f64: immediate.operand].sqrt
            """
        inlineImpls["f64LoadToFAcc"] = """
            if let trap = memoryLoadToFAcc(sp: sp.pointee, md: md.pointee, ms: ms.pointee, freg: &freg.pointee, loadOperand: immediate) { %TRAP% }
            """
        inlineImpls["f64LoadFromAccToFAcc"] = """
            if let trap = memoryLoadFromAccToFAcc(md: md.pointee, ms: ms.pointee, ireg: ireg.pointee, freg: &freg.pointee, loadOperand: immediate) { %TRAP% }
            """
        inlineImpls["f64StoreFromFAcc"] = """
            if let trap = memoryStoreFromFAcc(sp: sp.pointee, md: md.pointee, ms: ms.pointee, freg: freg.pointee, storeOperand: immediate) { %TRAP% }
            """
        for op in intUnaryInsts + floatUnaryOps {
            inlineImpls[op.instruction.name] = """
            sp.pointee[\(op.resultSlot): immediate.result] = \(op.mayThrow ? "try " : "")sp.pointee[\(op.inputSlot): immediate.input].\(camelCase(pascalCase: op.op))
            """
        }

        for op in memoryLoadOps {
            inlineImpls[op.instruction.name] = """
            if let trap = memoryLoad(sp: sp.pointee, md: md.pointee, ms: ms.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
        }
        for op in memoryStoreOps {
            inlineImpls[op.instruction.name] = """
            if let trap = memoryStore(sp: sp.pointee, md: md.pointee, ms: ms.pointee, storeOperand: immediate, castFromValue: { \(op.castFromValue) }) { %TRAP% }
            """
        }
        for op in memoryLoadOps {
            inlineImpls[op.toAccInstruction.name] = """
            if let trap = memoryLoadToAcc(sp: sp.pointee, md: md.pointee, ms: ms.pointee, ireg: &ireg.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
            inlineImpls[op.withCopyInstruction.name] = """
            if let trap = memoryLoadWithCopy(sp: sp.pointee, md: md.pointee, ms: ms.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
            inlineImpls[op.toAccAndSlotInstruction.name] = """
            if let trap = memoryLoadToAccAndSlot(sp: sp.pointee, md: md.pointee, ms: ms.pointee, ireg: &ireg.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
            inlineImpls[op.fromAccInstruction.name] = """
            if let trap = memoryLoadFromAcc(sp: sp.pointee, md: md.pointee, ms: ms.pointee, ireg: ireg.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
            inlineImpls[op.inAccInstruction.name] = """
            if let trap = memoryLoadInAcc(md: md.pointee, ms: ms.pointee, ireg: &ireg.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
        }
        for op in memoryStoreOps {
            inlineImpls[op.fromAccInstruction.name] = """
            if let trap = memoryStoreFromAcc(sp: sp.pointee, md: md.pointee, ms: ms.pointee, ireg: ireg.pointee, storeOperand: immediate, castFromValue: { \(op.castFromValue) }) { %TRAP% }
            """
            inlineImpls[op.addrFromAccInstruction.name] = """
            if let trap = memoryStoreAddrFromAcc(sp: sp.pointee, md: md.pointee, ms: ms.pointee, ireg: ireg.pointee, storeOperand: immediate, castFromValue: { \(op.castFromValue) }) { %TRAP% }
            """
        }

        for op in memoryAtomicLoadOps {
            inlineImpls[op.atomicInstruction.name] = """
            if let trap = atomicLoad(sp: sp.pointee, md: md.pointee, ms: ms.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
        }
        for op in memoryAtomicStoreOps {
            inlineImpls[op.atomicInstruction.name] = """
            if let trap = atomicStore(sp: sp.pointee, md: md.pointee, ms: ms.pointee, storeOperand: immediate, castFromValue: { \(op.castFromValue) }) { %TRAP% }
            """
        }

        for op in atomicRmwOps {
            let opLower = op.op.lowercased()
            let width = op.type == "i32" ? "32" : "64"
            let loadAs = op.type == "i32" ? "UInt32" : "UInt64"
            let cFunc = "wasmkit_atomic_rmw_\(opLower)_\(width)"
            inlineImpls[op.instruction.name] = """
            if let trap = atomicRmw(sp: sp.pointee, md: md.pointee, ms: ms.pointee, rmwOperand: immediate, loadAs: \(loadAs).self, atomicOp: { \(cFunc)($0, $1) }, castFromValue: { \(op.castFromValue) }, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
        }

        for op in atomicRmw8Ops {
            let opLower = op.op.lowercased()
            let cFunc = "wasmkit_atomic_rmw_\(opLower)_8"
            inlineImpls[op.instruction.name] = """
            if let trap = atomicRmw(sp: sp.pointee, md: md.pointee, ms: ms.pointee, rmwOperand: immediate, loadAs: UInt8.self, atomicOp: { \(cFunc)($0, $1) }, castFromValue: { \(op.castFromValue) }, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
        }

        for op in atomicRmw16Ops {
            let opLower = op.op.lowercased()
            let cFunc = "wasmkit_atomic_rmw_\(opLower)_16"
            inlineImpls[op.instruction.name] = """
            if let trap = atomicRmw(sp: sp.pointee, md: md.pointee, ms: ms.pointee, rmwOperand: immediate, loadAs: UInt16.self, atomicOp: { \(cFunc)($0, $1) }, castFromValue: { \(op.castFromValue) }, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
        }

        for op in atomicRmw32Ops {
            let opLower = op.op.lowercased()
            let cFunc = "wasmkit_atomic_rmw_\(opLower)_32"
            inlineImpls[op.instruction.name] = """
            if let trap = atomicRmw(sp: sp.pointee, md: md.pointee, ms: ms.pointee, rmwOperand: immediate, loadAs: UInt32.self, atomicOp: { \(cFunc)($0, $1) }, castFromValue: { \(op.castFromValue) }, castToValue: { \(op.castToValue) }) { %TRAP% }
            """
        }

        inlineImpls["i32AtomicRmwCmpxchg"] = """
        if let trap = atomicCmpxchg(sp: sp.pointee, md: md.pointee, ms: ms.pointee, cmpxchgOperand: immediate, loadAs: UInt32.self, atomicCmpxchg: { ptr, expected, desired in var exp = expected; _ = wasmkit_atomic_cmpxchg_32(ptr, &exp, desired); return exp }, castFromValue: { $0.i32 }, castToValue: { .i32($0) }) { %TRAP% }
        """
        inlineImpls["i64AtomicRmwCmpxchg"] = """
        if let trap = atomicCmpxchg(sp: sp.pointee, md: md.pointee, ms: ms.pointee, cmpxchgOperand: immediate, loadAs: UInt64.self, atomicCmpxchg: { ptr, expected, desired in var exp = expected; _ = wasmkit_atomic_cmpxchg_64(ptr, &exp, desired); return exp }, castFromValue: { $0.i64 }, castToValue: { .i64($0) }) { %TRAP% }
        """
        inlineImpls["i32AtomicRmw8CmpxchgU"] = """
        if let trap = atomicCmpxchg(sp: sp.pointee, md: md.pointee, ms: ms.pointee, cmpxchgOperand: immediate, loadAs: UInt8.self, atomicCmpxchg: { ptr, expected, desired in var exp = expected; _ = wasmkit_atomic_cmpxchg_8(ptr, &exp, desired); return exp }, castFromValue: { UInt8(truncatingIfNeeded: $0.i32) }, castToValue: { .i32(UInt32($0)) }) { %TRAP% }
        """
        inlineImpls["i32AtomicRmw16CmpxchgU"] = """
        if let trap = atomicCmpxchg(sp: sp.pointee, md: md.pointee, ms: ms.pointee, cmpxchgOperand: immediate, loadAs: UInt16.self, atomicCmpxchg: { ptr, expected, desired in var exp = expected; _ = wasmkit_atomic_cmpxchg_16(ptr, &exp, desired); return exp }, castFromValue: { UInt16(truncatingIfNeeded: $0.i32) }, castToValue: { .i32(UInt32($0)) }) { %TRAP% }
        """
        inlineImpls["i64AtomicRmw8CmpxchgU"] = """
        if let trap = atomicCmpxchg(sp: sp.pointee, md: md.pointee, ms: ms.pointee, cmpxchgOperand: immediate, loadAs: UInt8.self, atomicCmpxchg: { ptr, expected, desired in var exp = expected; _ = wasmkit_atomic_cmpxchg_8(ptr, &exp, desired); return exp }, castFromValue: { UInt8(truncatingIfNeeded: $0.i64) }, castToValue: { .i64(UInt64($0)) }) { %TRAP% }
        """
        inlineImpls["i64AtomicRmw16CmpxchgU"] = """
        if let trap = atomicCmpxchg(sp: sp.pointee, md: md.pointee, ms: ms.pointee, cmpxchgOperand: immediate, loadAs: UInt16.self, atomicCmpxchg: { ptr, expected, desired in var exp = expected; _ = wasmkit_atomic_cmpxchg_16(ptr, &exp, desired); return exp }, castFromValue: { UInt16(truncatingIfNeeded: $0.i64) }, castToValue: { .i64(UInt64($0)) }) { %TRAP% }
        """
        inlineImpls["i64AtomicRmw32CmpxchgU"] = """
        if let trap = atomicCmpxchg(sp: sp.pointee, md: md.pointee, ms: ms.pointee, cmpxchgOperand: immediate, loadAs: UInt32.self, atomicCmpxchg: { ptr, expected, desired in var exp = expected; _ = wasmkit_atomic_cmpxchg_32(ptr, &exp, desired); return exp }, castFromValue: { UInt32(truncatingIfNeeded: $0.i64) }, castToValue: { .i64(UInt64($0)) }) { %TRAP% }
        """
        inlineImpls["memoryAtomicWait32"] = """
        try atomicWait32(sp: sp.pointee, md: md.pointee, ms: ms.pointee, waitOperand: immediate)
        """
        inlineImpls["memoryAtomicWait64"] = """
        try atomicWait64(sp: sp.pointee, md: md.pointee, ms: ms.pointee, waitOperand: immediate)
        """
        inlineImpls["memoryAtomicNotify"] = """
        try atomicNotify(sp: sp.pointee, md: md.pointee, ms: ms.pointee, notifyOperand: immediate)
        """
        inlineImpls["atomicFence"] = """
        atomicFence(sp: sp.pointee)
        """

        return inlineImpls
    }

    static func instMethodDecl(_ inst: Instruction) -> String {
        let throwsKwd = inst.mayThrow ? " throws" : ""
        let returnClause = inst.mayUpdatePc ? " -> (Pc, CodeSlot)" : ""
        let args = inst.parameters
        return "func \(inst.name)(\(args.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", ")))\(throwsKwd)\(returnClause)"
    }

    static func generatePrototype(instructions: [Instruction]) -> String {
        var output = """

            extension Execution {
            """
        for inst in instructions {
            output += """

                    mutating \(instMethodDecl(inst)) {
                        fatalError("Unimplemented instruction: \(inst.name)")
                    }
                """
        }
        output += """

            }

            """
        return output
    }

    static func replaceInstMethodSignature(_ inst: Instruction, sourceRoot: URL) throws {
        func tryReplace(file: URL) throws -> Bool {
            let originalContent = try String(contentsOf: file)
            var contents = originalContent
            guard contents.contains("func \(inst.name)(") else {
                return false
            }
            // Replace the found line with the new signature
            var lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
            for (i, line) in lines.enumerated() {
                if let range = line.range(of: "func \(inst.name)(") {
                    lines[i] = lines[i][..<range.lowerBound] + instMethodDecl(inst) + " {"
                    break
                }
            }
            contents = lines.joined(separator: "\n")
            if contents == originalContent {
                return true
            }
            try contents.write(to: file, atomically: true, encoding: .utf8)
            print("Replaced \(inst.name) in \(file.lastPathComponent)")
            return true
        }

        let files = try FileManager.default.contentsOfDirectory(at: sourceRoot.appendingPathComponent("Sources/WasmKit/Execution/Instructions"), includingPropertiesForKeys: nil)
        for file in files {
            guard file.lastPathComponent != "InstructionSupport.swift" else {
                continue
            }
            if try tryReplace(file: file) {
                return
            }
        }
    }
    static func replaceMethodSignature(instructions: [Instruction], sourceRoot: URL) throws {
        let inlineImpls = generateBasicInstImplementations()
        for inst in instructions {
            // An instruction whose body is generated inline has no wrapper handler for this pass
            // to fix up: what it has is an ordinary function that the generated body calls, whose
            // signature is chosen by that call site rather than by `instMethodDecl`. Rewriting it
            // to the wrapper shape breaks it, so leave these alone. The cost is that such a
            // function's signature is maintained by hand; a spec change that outgrows it shows up
            // as a build error rather than an automatic rewrite.
            if inlineImpls[inst.name] != nil {
                continue
            }
            try replaceInstMethodSignature(inst, sourceRoot: sourceRoot)
        }
    }

    static func generateEnumDefinition(instructions: [Instruction]) -> String {
        var output = """
        /// An internal VM instruction.
        ///
        /// NOTE: This enum representation is just for modeling purposes. The actual
        /// runtime representation can be different.
        enum Instruction {

        """
        for inst in instructions {
            if let documentation = inst.documentation {
                for line in documentation.split(separator: "\n", omittingEmptySubsequences: false) {
                    output += "    /// \(line)\n"
                }
            }
            output += "    case \(inst.name)"
            if let immediate = inst.immediate {
                output += "("
                if let name = immediate.name {
                    output += name + ": " + immediate.type
                } else {
                    output += immediate.type
                }
                output += ")"
            } else {
                output += "(NoOperand)"
            }
            output += "\n"
        }
        output += "}\n"

        output += generateImmediateDefinitions(instructions: instructions)
        output += "\n"

        output += """
        extension Instruction {
            var rawImmediate: (any InstructionImmediate)? {
                switch self {

        """
        for inst in instructions {
            guard let immediate = inst.immediate else { continue }
            output += "        case .\(inst.name)(let \(immediate.label)): return \(immediate.label)\n"
        }
        output += """
                default: return nil
                }
            }

            /// Emits the immediate operand of this instruction, if any.
            /// Dispatches without existentials so that Embedded Swift, which cannot
            /// call default protocol methods on existentials, can use it.
            func emitImmediate(to emit: @escaping (CodeSlot) -> Void) {
                switch self {

        """
        for inst in instructions {
            guard let immediate = inst.immediate else { continue }
            output += "        case .\(inst.name)(let \(immediate.label)): \(immediate.label).emit(to: emit)\n"
        }
        output += """
                default: return
                }
            }
        }

        """

        output += "\n\n"
        output += """
        extension Instruction {
            /// The opcode ID of the instruction.
            var opcodeID: OpcodeID {
                switch self {

        """
        for (i, inst) in instructions.enumerated() {
            // The last case is spelled `default` because the type checker gives up
            // proving a switch over this many cases exhaustive.
            if i == instructions.count - 1 {
                output += "        default: return \(i)  // .\(inst.name)\n"
            } else {
                output += "        case .\(inst.name): return \(i)\n"
            }
        }
        output += """
                }
            }
        }

        """

        let directThreadedOnlyOpcodes = instructions.indices.filter { instructions[$0].isDirectThreadedOnly }
        output += """
        extension Instruction {
            /// The number of opcodes, trap pseudo-instructions included.
            static let opcodeCount = \(instructions.count)

            /// Whether only the direct-threaded dispatcher implements this instruction;
            /// `Execution.doExecute` has no case for it.
            var isDirectThreadedOnly: Bool {
                switch opcodeID {
                case \(directThreadedOnlyOpcodes.map(String.init).joined(separator: ", ")): return true
                default: return false
                }
            }
        }

        """

        output += """
        extension Instruction {
            /// Load an instruction from the given program counter.
            /// - Parameters:
            ///   - pc: The program counter to read from.
            ///   - threadingModel: The threading model the instruction sequence was compiled with.
            /// - Returns: The instruction read from the program counter.
            ///
            /// Compiled for size: one arm per opcode, used only for disassembly.
            @_optimize(size)
            static func load(from pc: inout Pc, threadingModel: EngineConfiguration.ThreadingModel) -> Instruction {
                let opcode = Instruction.opcode(ofHeadSlot: pc.read(CodeSlot.self), threadingModel: threadingModel)
                switch opcode {

        """
        for (i, inst) in instructions.enumerated() {
            if let immediate = inst.immediate {
                let maybeLabel = immediate.name.map { "\($0): " } ?? ""
                output += "        case \(i): return .\(inst.name)(\(maybeLabel)\(immediate.type).load(from: &pc))\n"
            } else {
                output += "        case \(i): return .\(inst.name)(NoOperand())\n"
            }
        }
        output += """
                default: fatalError("Unknown instruction opcode: \\(opcode)")
                }
            }
        }

        """
        output += """

        #if EngineStats
        extension Instruction {
            /// The name of the instruction.
            /// - Parameter opcode: The opcode ID of the instruction.
            /// - Returns: The name of the instruction.
            ///
            /// NOTE: This function is used for debugging purposes.
            static func name(opcode: OpcodeID) -> String {
                switch opcode {
        """
        for (i, inst) in instructions.enumerated() {
            output += """

                        case \(i): return "\(inst.name)"
                """
        }
        output += """

                default: fatalError("Unknown instruction index: \\(opcode)")
                }
            }
        }
        #endif // EngineStats

        """
        return output
    }

    static func generateNextInstructionPredictor(instructions: [Instruction]) -> String {
        let controlInstructions = instructions.enumerated().filter { $0.element.isControl }

        var output = """

        #if WasmDebuggingSupport

        /// A protocol for predicting the next instruction(s) that will execute after a control-flow instruction.
        ///
        /// Each `isControl` instruction in VMSpec gets a dedicated method in this protocol.
        /// Adding a new control instruction automatically adds a new protocol requirement,
        /// so any conforming type will fail to compile until it implements the new prediction.
        protocol NextInstructionPredictor: ~Copyable {

        """
        for (_, inst) in controlInstructions {
            output += "    mutating func predictNext_\(inst.name)(operandPc: Pc, sp: Sp) -> [Pc]\n"
        }
        output += """
        }

        extension Instruction {
            /// Dispatches to the appropriate `NextInstructionPredictor` method based on the opcode ID.
            /// - Returns: The predicted next Pc(s), or `nil` if the opcode is not a control instruction.
            static func predictNextPcs(
                opcodeID: OpcodeID, operandPc: Pc, sp: Sp,
                predictor: inout some NextInstructionPredictor & ~Copyable
            ) -> [Pc]? {
                switch opcodeID {

        """
        for (opcode, inst) in controlInstructions {
            output += "        case \(opcode): return predictor.predictNext_\(inst.name)(operandPc: operandPc, sp: sp)\n"
        }
        output += """
                default: return nil
                }
            }

            /// Builds a map from head code slot to opcode ID for all control-flow instructions.
            ///
            /// This is generated so that adding a new `isControl` instruction automatically
            /// includes it in the map without manual updates.
            static func buildControlHeadSlotMap(
                threadingModel: EngineConfiguration.ThreadingModel
            ) -> [CodeSlot: OpcodeID] {
                var map = [CodeSlot: OpcodeID]()

        """
        for (_, inst) in controlInstructions {
            let dummyExpr: String
            if let layout = inst.immediateLayout {
                let fields = layout.fields.map { field in
                    "\(field.name): \(field.type.zeroLiteral)"
                }.joined(separator: ", ")
                dummyExpr = ".\(inst.name)(.init(\(fields)))"
            } else if let immediate = inst.immediate {
                // Simple immediate type (e.g. BrOperand = Int32)
                dummyExpr = ".\(inst.name)(\(immediate.type)(0))"
            } else {
                dummyExpr = ".\(inst.name)(Instruction.NoOperand())"
            }
            output += """
                        do {
                            let inst = Instruction\(dummyExpr)
                            map[inst.headSlot(threadingModel: threadingModel)] = inst.opcodeID
                        }

            """
        }
        output += """
                    return map
                }
            }

            #endif // WasmDebuggingSupport

            """
        return output
    }

    static func generateImmediateDefinitions(instructions: [Instruction]) -> String {
        var output = ""

        output += """

        extension Instruction {
            // MARK: - Instruction Immediates

            /// The payload of instructions without an immediate. It is never
            /// emitted; a payload on every case keeps the enum tag equal to the
            /// opcode ID, so `opcodeID` needs no table.
            struct NoOperand {
                init() {}
                private var reserved: UInt8 = 0
            }

        """

        let wordDecodedLayouts = Set(
            instructions.filter(\.readsNextHandlerUpFront).compactMap { $0.immediateLayout?.name }
        )
        var emittedImmediateTypes = Set<String>()
        for inst in instructions {
            guard let layout = inst.immediateLayout else { continue }
            guard emittedImmediateTypes.insert(layout.name).inserted else { continue }

            let definition = layout.buildDeclaration(decodesAsWords: wordDecodedLayouts.contains(layout.name))
            output += "\n"
            for line in definition.split(separator: "\n") {
                output += "    " + line + "\n"
            }
        }

        output += "}\n"

        return output
    }

    static func generateDirectThreadedCode(instructions: [Instruction], inlineImpls: [String: String]) -> String {
        var output = """
            extension Execution {
            """
        for inst in instructions {
            let args = inst.parameters.map { label, _, isInout in
                let isExecParam = ExecutionParameter.allCases.contains { $0.label == label }
                if isExecParam {
                    return "\(label): \(isInout ? "&" : "")\(label).pointee"
                } else {
                    return "\(label): \(isInout ? "&" : "")\(label)"
                }
            }.joined(separator: ", ")
            let throwsKwd = inst.mayThrow ? " throws" : ""
            let tryKwd = inst.mayThrow ? "try " : ""
            output += """

                @_silgen_name("wasmkit_execute_\(inst.name)") @inline(__always)
                mutating func execute_\(inst.name)(\(wrapperParameters(of: inst).map { "\($0.label): UnsafeMutablePointer<\($0.type)>" }.joined(separator: ", ")))\(throwsKwd) -> CodeSlot {

            """
            if let immediate = inst.immediate {
                output += """
                        let \(immediate.label) = \(immediate.type).load(from: &pc.pointee)

                """
            }
            let call = "\(tryKwd)self.\(inst.name)(\(args))"
            if inst.mayUpdatePc {
                output += """
                        let next: CodeSlot
                        (pc.pointee, next) = \(call)

                """
            } else if inst.mayDispatchToTrap {
                // Read the next head slot and bump `pc` up front: the body has a second
                // exit (a trap pseudo-instruction's head slot) and tail-merging the two
                // exits would cost the fast path an extra address computation plus a
                // branch to reach the shared load. See `Instruction.mayDispatchToTrap`.
                let impl = (inlineImpls[inst.name] ?? call)
                    .replacingOccurrences(of: "%TRAP%", with: "return trap.directThreadedHeadSlot")
                output += """
                        let next = pc.pointee.pointee
                        pc.pointee = pc.pointee.advanced(by: 1)
                        \(impl)

                """
            } else if inst.readsNextHandlerUpFront {
                // Read the next head slot right after the immediate, so the two loads
                // from `pc` are adjacent and can be combined.
                output += """
                        let next = pc.pointee.pointee
                        pc.pointee = pc.pointee.advanced(by: 1)
                        \(inlineImpls[inst.name] ?? call)

                """
            } else {
                output += """
                        \(inlineImpls[inst.name] ?? call)
                        let next = pc.pointee.pointee
                        pc.pointee = pc.pointee.advanced(by: 1)

                """
            }
            output += """
                    return next
                }
            """
        }
        output += """

            }

            """
        return output
    }

    /// Emits the token-threaded wrapper of every handler that can dispatch to a trap
    /// pseudo-instruction.
    ///
    /// The direct-threaded wrapper returns the trap handler's address so that the C
    /// trampoline tail-calls it; token threading has no handler addresses, so it raises
    /// the trap from the dispatcher instead. The handler body itself is written once and
    /// inlined into both.
    static func generateTokenThreadedTrapWrappers(instructions: [Instruction], inlineImpls: [String: String]) -> String {
        let wrapped = instructions.filter { $0.mayDispatchToTrap && !$0.isDirectThreadedOnly }
        guard !wrapped.isEmpty else { return "" }
        var output = """
            extension Execution {
            """
        for inst in wrapped {
            let args = inst.parameters.map { label, _, isInout in
                let isExecParam = ExecutionParameter.allCases.contains { $0.label == label }
                if isExecParam {
                    return "\(label): \(isInout ? "&" : "")\(label).pointee"
                } else {
                    return "\(label): \(isInout ? "&" : "")\(label)"
                }
            }.joined(separator: ", ")
            let call = "self.\(inst.name)(\(args))"
            let impl = (inlineImpls[inst.name] ?? call)
                .replacingOccurrences(of: "%TRAP%", with: "try trap.raise()")
            output += """

                @inline(__always)
                mutating func executeToken_\(inst.name)(\(wrapperParameters(of: inst).map { "\($0.label): UnsafeMutablePointer<\($0.type)>" }.joined(separator: ", "))) throws -> CodeSlot {

            """
            if let immediate = inst.immediate {
                output += """
                        let \(immediate.label) = \(immediate.type).load(from: &pc.pointee)

                """
            }
            output += """
                    \(impl)
                    let next = pc.pointee.pointee
                    pc.pointee = pc.pointee.advanced(by: 1)
                    return next
                }
            """
        }
        output += """

            }

            """
        return output
    }

    /// Emits a constant-foldable head-slot accessor for each trap pseudo-instruction.
    static func generateTrapPseudoInstructionSlots(instructions: [Instruction]) -> String {
        var output = """

            extension Instruction {

            """
        for (opcode, inst) in instructions.enumerated() where inst.isTrapPseudoInstruction {
            output += """
                    /// The direct-threaded head slot of the `\(inst.name)` pseudo-instruction.
                    ///
                    /// Reads one element of the handler table directly: going through
                    /// `handler` would copy the whole table into a stack temporary and
                    /// leave the reading handler with a stack-protector prologue.
                    @inline(__always)
                    static var \(inst.name)HeadSlot: CodeSlot {
                        #if !(arch(i386) || arch(x86_64) || arch(arm) || arch(arm64) || arch(arm64_32))
                        fatalError("Direct threading is not supported on this platform")
                        #else
                        return CodeSlot(wasmkit_tc_exec_handlers.\(opcode))
                        #endif
                    }

            """
        }
        output += """
            }

            """
        return output
    }

    static func generateDirectThreadedCodeOfCPart(instructions: [Instruction]) -> String {
        var output = ""

        func handlerName(_ inst: Instruction) -> String {
            "wasmkit_tc_\(inst.name)"
        }

        // Instructions that declare the same `handlerIdentity` compile to bit-identical
        // handler bodies, so emit the trampoline once and let every opcode in the group
        // point its handler-table entry at it. Leaving the duplicates in makes the
        // compiler's function merging pass fold them and replace each duplicate with a
        // `b <canonical>` thunk, which the table then points at: one extra taken branch
        // on every dispatch to that opcode. The token-threaded dispatcher is generated
        // from the same mapping, so both models run the same body for an alias.
        let owners = canonicalHandlerOwners(instructions: instructions)
        let emittedHandlers = instructions.filter { owners[$0.name]!.name == $0.name }

        for inst in emittedHandlers {
            let params = ExecutionParameter.allCases
            let bodyParams = wrapperParameters(of: inst)
            output += """
            WASMKIT_TC_CC static inline void \(handlerName(inst))(\(params.map { "\($0.cType) \($0.label)" }.joined(separator: ", ")), WASMKIT_TC_CONTEXT void *state) {
                SWIFT_CC(swift) uint64_t wasmkit_execute_\(inst.name)(\(bodyParams.map { "\($0.cType) *\($0.label)" }.joined(separator: ", ")), SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
                void * _Nullable error = NULL; uint64_t next;
                INLINE_CALL next = wasmkit_execute_\(inst.name)(\(bodyParams.map { "&\($0.label)" }.joined(separator: ", ")), state, &error);\n
            """
            if inst.mayThrow {
                output += "    if (error) return wasmkit_execution_state_set_error(error, sp, state);\n"
            }
            // An accumulator is only live between a producer and the handler
            // right after it, so a handler that does not use one passes on an
            // indeterminate value instead of preserving it across calls.
            var accArgs: [String] = []
            for (use, cType, label) in [(inst.useIreg, "uint64_t", "ireg"), (inst.useFreg, "double", "freg")] {
                if use != .none {
                    accArgs.append(label)
                } else {
                    accArgs.append("dead_\(label)")
                    output += "    WASMKIT_DEAD_ACCUMULATOR(\(cType), dead_\(label));\n"
                }
            }
            output += """
                WASMKIT_TC_MUSTTAIL return ((wasmkit_tc_exec)next)(sp, pc, md, ms, \(accArgs.joined(separator: ", ")), state);
            }

            """
        }

        output += """
        // Indexed by opcode ID. Opcodes whose handlers are bit-identical (see
        // `Instruction.handlerIdentity` in VMSpec) share a single entry point here,
        // so that dispatch never goes through a compiler-generated merge thunk.
        static const uintptr_t wasmkit_tc_exec_handlers[] = {

        """
        for inst in instructions {
            output += "    (uintptr_t)((wasmkit_tc_exec)&\(handlerName(owners[inst.name]!))),\n"
        }
        output += """
        };

        """

        return output
    }

    static func main(arguments: [String]) throws {
        let sourceRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

        if arguments.count > 1 {
            switch arguments[1] {
            case "prototype":
                print(generatePrototype(instructions: instructions))
                return
            case "replace":
                try replaceMethodSignature(instructions: instructions, sourceRoot: sourceRoot)
            default: break
            }
        }

        let header = """
            // swift-format-ignore-file
            //// Automatically generated by Utilities/Sources/VMGen.swift
            //// DO NOT EDIT DIRECTLY


            """

        let projectSources = ["Sources"]

        let inlineImpls = generateBasicInstImplementations()

        let generatedFiles = [
            GeneratedFile(
                projectSources + ["WasmKit", "Execution", "DispatchInstruction.swift"],
                header
                + """
                // Include the C inline code to codegen together with the Swift code.
                import _CWasmKit.InlineCode

                // MARK: - Token Threaded Code

                """
                + generateDispatcher(instructions: instructions)
                + """


                """
                + generateTokenThreadedTrapWrappers(instructions: instructions, inlineImpls: inlineImpls)
                + """

                // MARK: - Direct Threaded Code

                """
                + generateDirectThreadedCode(instructions: instructions, inlineImpls: inlineImpls)
                + """

                // The handler table exists only where Clang offers one of Swift's
                // calling conventions; this list is the Swift-side spelling of
                // WASMKIT_USE_DIRECT_THREADED_CODE in Platform.h.
                #if arch(i386) || arch(x86_64) || arch(arm) || arch(arm64) || arch(arm64_32)
                /// A copy of the direct-threading handler table, made once per process.
                ///
                /// Swift imports the C array as a tuple value, so taking its address
                /// materializes the whole table on the stack. Doing that for every
                /// emitted instruction dominated translation. Reading the table through
                /// a C accessor instead would keep the handler bodies from inlining into
                /// their trampolines.
                nonisolated(unsafe) private let wasmkitExecHandlerTable: UnsafePointer<UInt> = {
                    let count = MemoryLayout.size(ofValue: wasmkit_tc_exec_handlers) / MemoryLayout<wasmkit_tc_exec>.size
                    let table = UnsafeMutablePointer<UInt>.allocate(capacity: count)
                    withUnsafePointer(to: wasmkit_tc_exec_handlers) {
                        $0.withMemoryRebound(to: UInt.self, capacity: count) {
                            table.update(from: $0, count: count)
                        }
                    }
                    return UnsafePointer(table)
                }()
                #endif

                extension Instruction {
                    /// The tail-calling execution handler for the instruction.
                    var handler: UInt {
                        Instruction.handler(opcodeID: self.opcodeID)
                    }

                    /// The tail-calling execution handler for an opcode.
                    @inline(__always)
                    static func handler(opcodeID: OpcodeID) -> UInt {
                        #if !(arch(i386) || arch(x86_64) || arch(arm) || arch(arm64) || arch(arm64_32))
                        fatalError("Direct threading is not supported on this platform")
                        #else
                        return wasmkitExecHandlerTable[Int(opcodeID)]
                        #endif
                    }
                }

                """
                + generateTrapPseudoInstructionSlots(instructions: instructions)
            ),
            GeneratedFile(
                projectSources + ["_CWasmKit", "include", "DirectThreadedCode.inc"],
                header + generateDirectThreadedCodeOfCPart(instructions: instructions)
            ),
            GeneratedFile(
                projectSources + ["WasmKit", "Execution", "Instructions", "Instruction.swift"],
                header + generateEnumDefinition(instructions: instructions)
                + generateNextInstructionPredictor(instructions: instructions)
            ),
        ]

        for file in generatedFiles {
            try file.writeIfChanged(sourceRoot: sourceRoot)
        }

        try replaceMethodSignature(instructions: instructions, sourceRoot: sourceRoot)
    }
}
