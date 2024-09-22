import Foundation

/// A utility to generate internal VM instruction related code.
enum VMGen {

    static func camelCase(pascalCase: String) -> String {
        let first = pascalCase.first!.lowercased()
        return first + pascalCase.dropFirst()
    }

    struct GeneratedFile {
        let pathComponents: [String]
        let content: String

        init(_ pathComponents: [String], _ content: String) {
            self.pathComponents = pathComponents
            self.content = content
        }
    }

    static func generateDispatcher(instructions: [Instruction]) -> String {
        let doExecuteParams: [Instruction.Parameter] =
            [("instruction", "UInt64", false)]
            + ExecutionParameter.allCases.map { ($0.label, $0.type, true) }
        var output = """
            extension Execution {
                @inline(__always)
                mutating func doExecute(_ \(doExecuteParams.map { "\($0.label): \($0.isInout ? "inout " : "")\($0.type)" }.joined(separator: ", "))) throws {
                    switch instruction {
            """

        for (index, inst) in instructions.enumerated() {
            let tryPrefix = inst.mayThrow ? "try " : ""
            let args = ExecutionParameter.allCases.map { "\($0.label): &\($0.label)" }
            output += """

                        case \(index): \(tryPrefix)self.execute_\(inst.name)(\(args.joined(separator: ", ")))
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

    static func generateBasicInstImplementations() -> String {
        var output = """
            extension Execution {
            """

        for op in intBinOps + floatBinOps {
            output += """

                @inline(__always) mutating \(instMethodDecl(op.instruction)) {
                    sp[\(op.resultType): binaryOperand.result] = \(op.mayThrow ? "try " : "")sp[\(op.lhsType): binaryOperand.lhs].\(camelCase(pascalCase: op.op))(sp[\(op.rhsType): binaryOperand.rhs])
                }
            """
        }
        for op in intUnaryInsts + floatUnaryOps {
            output += """

                mutating \(instMethodDecl(op.instruction)) {
                    sp[\(op.resultType): unaryOperand.result] = \(op.mayThrow ? "try " : "")sp[\(op.inputType): unaryOperand.input].\(camelCase(pascalCase: op.op))
                }
            """
        }

        for inst in memoryLoadInsts {
            output += """

                @inline(__always) mutating \(instMethodDecl(inst.base)) {
                    return try memoryLoad(sp: sp, md: md, ms: ms, loadOperand: loadOperand, loadAs: \(inst.loadAs).self, castToValue: { \(inst.castToValue) })
                }
            """
        }
        for inst in memoryStoreInsts {
            output += """

                @inline(__always) mutating \(instMethodDecl(inst.base)) {
                    return try memoryStore(sp: sp, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { \(inst.castFromValue) })
                }
            """
        }

        output += """

            }

            """
        return output
    }

    static func instMethodDecl(_ inst: Instruction) -> String {
        let throwsKwd = inst.mayThrow ? " throws" : ""
        let returnClause = inst.mayUpdatePc ? " -> Pc" : ""
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

    static func generateInstName(instructions: [Instruction]) -> String {
        var output = """
            extension Instruction {
                var name: String {
                    switch self {
            """
        for inst in instructions {
            output += """

                        case .\(inst.name): return "\(inst.name)"
                """
        }
        output += """

                    }
                }
            }

            """
        return output
    }

    static func generateEnumDefinition(instructions: [Instruction]) -> String {
        var output = "enum Instruction: Equatable {\n"
        for inst in instructions {
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
        output += "}\n\n"

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
            var rawIndex: Int {
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
                let rawIndex = pc.read(UInt64.self)
                switch rawIndex {

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
                default: fatalError("Unknown instruction index: \\(rawIndex)")
                }
            }
        }

        """
        return output
    }

    static func generateDirectThreadedCode(instructions: [Instruction]) -> String {
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
            let mayAssignPc = inst.mayUpdatePc ? "pc.pointee = " : ""
            output += """

                @_silgen_name("wasmkit_execute_\(inst.name)") @inline(__always)
                mutating func execute_\(inst.name)(\(ExecutionParameter.allCases.map { "\($0.label): UnsafeMutablePointer<\($0.type)>" }.joined(separator: ", ")))\(throwsKwd) {

            """
            if let immediate = inst.immediate {
                output += """
                        let \(immediate.label) = \(immediate.type).load(from: &pc.pointee)

                """
            }
            output += """
                    \(mayAssignPc)\(tryKwd)self.\(inst.name)(\(args))
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
                SWIFT_CC(swift) void wasmkit_execute_\(inst.name)(\(params.map { "\($0.type) *\($0.label)" }.joined(separator: ", ")), SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
                void * _Nullable error = NULL;
                INLINE_CALL wasmkit_execute_\(inst.name)(\(params.map { "&\($0.label)" }.joined(separator: ", ")), state, &error);\n
            """
            if inst.mayThrow {
                output += "    if (error) return wasmkit_execution_state_set_error(error, state);\n"
            }
            output += """
                wasmkit_tc_exec next = (wasmkit_tc_exec)(*(void **)pc);
                pc += sizeof(uint64_t);
                return next(sp, pc, md, ms, state);
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
            //// Automatically generated by Utilities/Sources/VMGen.swift
            //// DO NOT EDIT DIRECTLY

            """

        let projectSources = ["Sources"]

        let generatedFiles = [
            GeneratedFile(
                projectSources + ["WasmKit", "Execution", "DispatchInstruction.swift"],
                header + generateDispatcher(instructions: instructions)
                + "\n\n"
                + generateInstName(instructions: instructions)
                + "\n\n"
                + generateBasicInstImplementations()
                + "\n\n"
                + generateDirectThreadedCode(instructions: instructions)
                + """


                import _CWasmKit.InlineCode

                extension Instruction {
                    private static let handlers: [UInt64] = withUnsafePointer(to: wasmkit_tc_exec_handlers) {
                        let count = MemoryLayout.size(ofValue: wasmkit_tc_exec_handlers) / MemoryLayout<wasmkit_tc_exec>.size
                        return $0.withMemoryRebound(to: UInt64.self, capacity: count) {
                            Array(UnsafeBufferPointer(start: $0, count: count))
                        }
                    }

                    @inline(never)
                    var handler: UInt64 {
                        return Self.handlers[rawIndex]
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
            let subPath = file.pathComponents.joined(separator: "/")
            let path = sourceRoot.appendingPathComponent(subPath)
            // Write the content only if the file does not exist or the content is different
            let shouldWrite: Bool
            if !FileManager.default.fileExists(atPath: path.path) {
                shouldWrite = true
            } else {
                let existingContent = try String(contentsOf: path)
                shouldWrite = existingContent != file.content
            }

            if shouldWrite {
                try file.content.write(to: path, atomically: true, encoding: .utf8)
                print("\u{001B}[1;33mUpdated\u{001B}[0;0m \(subPath)")
            }
        }

        try replaceMethodSignature(instructions: instructions, sourceRoot: sourceRoot)
    }
}
