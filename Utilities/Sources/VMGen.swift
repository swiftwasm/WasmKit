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

    static func generateDispatcher(instructions: [Instruction]) -> String {
        let doExecuteParams: [Instruction.Parameter] =
            [("opcode", "OpcodeID", false)]
            + ExecutionParameter.allCases.map { ($0.label, $0.type, true) }
        var output = """
            extension Execution {

                /// Execute an instruction identified by the opcode.
                /// Note: This function is only used when using token threading model.
                @inline(__always)
                mutating func doExecute(_ \(doExecuteParams.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", "))) throws -> CodeSlot {
                    switch opcode {
            """

        for (opcode, inst) in instructions.enumerated() {
            let tryPrefix = inst.mayThrow ? "try " : ""
            let args = ExecutionParameter.allCases.map { "\($0.label): &\($0.label)" }
            output += """

                        case \(opcode): return \(tryPrefix)self.execute_\(inst.name)(\(args.joined(separator: ", ")))
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
            sp.pointee[\(op.resultType): immediate.result] = \(op.mayThrow ? "try " : "")sp.pointee[\(op.lhsType): immediate.lhs].\(camelCase(pascalCase: op.op))(sp.pointee[\(op.rhsType): immediate.rhs])
            """
        }
        for op in intUnaryInsts + floatUnaryOps {
            inlineImpls[op.instruction.name] = """
            sp.pointee[\(op.resultType): immediate.result] = \(op.mayThrow ? "try " : "")sp.pointee[\(op.inputType): immediate.input].\(camelCase(pascalCase: op.op))
            """
        }

        for op in memoryLoadOps {
            inlineImpls[op.instruction.name] = """
            try memoryLoad(sp: sp.pointee, md: md.pointee, ms: ms.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) })
            """
        }
        for op in memoryStoreOps {
            inlineImpls[op.instruction.name] = """
            try memoryStore(sp: sp.pointee, md: md.pointee, ms: ms.pointee, storeOperand: immediate, castFromValue: { \(op.castFromValue) })
            """
        }

        for op in memoryAtomicLoadOps {
            inlineImpls[op.atomicInstruction.name] = """
            try memoryLoad(sp: sp.pointee, md: md.pointee, ms: ms.pointee, loadOperand: immediate, loadAs: \(op.loadAs).self, castToValue: { \(op.castToValue) })
            """
        }
        for op in memoryAtomicStoreOps {
            inlineImpls[op.atomicInstruction.name] = """
            try memoryStore(sp: sp.pointee, md: md.pointee, ms: ms.pointee, storeOperand: immediate, castFromValue: { \(op.castFromValue) })
            """
        }

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
        for inst in instructions {
            try replaceInstMethodSignature(inst, sourceRoot: sourceRoot)
        }
    }

    static func generateEnumDefinition(instructions: [Instruction]) -> String {
        var output = """
        /// An internal VM instruction.
        ///
        /// NOTE: This enum representation is just for modeling purposes. The actual
        /// runtime representation can be different.
        enum Instruction: Equatable {

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
            output += "        case .\(inst.name): return \(i)\n"
        }
        output += """
                }
            }
        }

        """

        output += """
        extension Instruction {
            /// Load an instruction from the given program counter.
            /// - Parameter pc: The program counter to read from.
            /// - Returns: The instruction read from the program counter.
            /// - Precondition: The instruction sequence must be compiled with token threading model.
            static func load(from pc: inout Pc) -> Instruction {
                let opcode = pc.read(UInt64.self)
                switch opcode {

        """
        for (i, inst) in instructions.enumerated() {
            if let immediate = inst.immediate {
                let maybeLabel = immediate.name.map { "\($0): " } ?? ""
                output += "        case \(i): return .\(inst.name)(\(maybeLabel)\(immediate.type).load(from: &pc))\n"
            } else {
                output += "        case \(i): return .\(inst.name)\n"
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

    static func generateImmediateDefinitions(instructions: [Instruction]) -> String {
        var output = ""

        output += """

        extension Instruction {
            // MARK: - Instruction Immediates

        """

        var emittedImmediateTypes = Set<String>()
        for inst in instructions {
            guard let layout = inst.immediateLayout else { continue }
            guard emittedImmediateTypes.insert(layout.name).inserted else { continue }

            let definition = layout.buildDeclaration()
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
                mutating func execute_\(inst.name)(\(ExecutionParameter.allCases.map { "\($0.label): UnsafeMutablePointer<\($0.type)>" }.joined(separator: ", ")))\(throwsKwd) -> CodeSlot {

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

    static func generateDirectThreadedCodeOfCPart(instructions: [Instruction]) -> String {
        var output = ""

        func handlerName(_ inst: Instruction) -> String {
            "wasmkit_tc_\(inst.name)"
        }

        for inst in instructions {
            let params = ExecutionParameter.allCases
            output += """
            SWIFT_CC(swiftasync) static inline void \(handlerName(inst))(\(params.map { "\($0.type) \($0.label)" }.joined(separator: ", ")), SWIFT_CONTEXT void *state) {
                SWIFT_CC(swift) uint64_t wasmkit_execute_\(inst.name)(\(params.map { "\($0.type) *\($0.label)" }.joined(separator: ", ")), SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
                void * _Nullable error = NULL; uint64_t next;
                INLINE_CALL next = wasmkit_execute_\(inst.name)(\(params.map { "&\($0.label)" }.joined(separator: ", ")), state, &error);\n
            """
            if inst.mayThrow {
                output += "    if (error) return wasmkit_execution_state_set_error(error, sp, state);\n"
            }
            output += """
                return ((wasmkit_tc_exec)next)(sp, pc, md, ms, state);
            }

            """
        }

        output += """
        static const uintptr_t wasmkit_tc_exec_handlers[] = {

        """
        for inst in instructions {
            output += "    (uintptr_t)((wasmkit_tc_exec)&\(handlerName(inst))),\n"
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


                // MARK: - Direct Threaded Code

                """
                + generateDirectThreadedCode(instructions: instructions, inlineImpls: inlineImpls)
                + """

                extension Instruction {
                    /// The tail-calling execution handler for the instruction.
                    var handler: UInt {
                        #if os(WASI)
                        fatalError("Direct threading is not supported on WASI")
                        #else
                        return withUnsafePointer(to: wasmkit_tc_exec_handlers) {
                            let count = MemoryLayout.size(ofValue: wasmkit_tc_exec_handlers) / MemoryLayout<wasmkit_tc_exec>.size
                            return $0.withMemoryRebound(to: UInt.self, capacity: count) {
                                $0[Int(self.opcodeID)]
                            }
                        }
                        #endif
                    }
                }

                """
            ),
            GeneratedFile(
                projectSources + ["_CWasmKit", "include", "DirectThreadedCode.inc"],
                header + generateDirectThreadedCodeOfCPart(instructions: instructions)
            ),
            GeneratedFile(
                projectSources + ["WasmKit", "Execution", "Instructions", "Instruction.swift"],
                header + generateEnumDefinition(instructions: instructions)
            ),
        ]

        for file in generatedFiles {
            try file.writeIfChanged(sourceRoot: sourceRoot)
        }

        try replaceMethodSignature(instructions: instructions, sourceRoot: sourceRoot)
    }
}
