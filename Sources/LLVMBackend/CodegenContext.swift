import BasicContainers
import LLVMInterop
import LLVM_Analysis
import LLVM_Utils
import SystemPackage
import WAT
import WasmParser
import WasmTypes

package struct CodegenContext: ~Copyable {
    enum Error: Swift.Error {
        case objectFileEmissionFailed
        case multiValueResultsNotSupportedYet(functionName: String)
        case unsupportedImport(Import)
    }

    private(set) var ir: IRContext

    private let isVerbose: Bool

    package init(isVerbose: Bool) {
        self.ir = IRContext()
        self.isVerbose = isVerbose
    }

    mutating func codegen(wasmStream: some ByteStream) throws {
        var parser = Parser(stream: wasmStream)

        var types = [FunctionType]()
        var functionTypes = [TypeIndex]()
        var functionVisitors = RigidArray<IRFunctionVisitor>()
        var importedFunctions = [IRValue]()
        var functionNames = [String]()
        var memories = [Memory]()

        while let payload = try parser.parseNext() {
            switch payload {
            case .typeSection(let t): types = t
            case .functionSection(let f): functionTypes.append(contentsOf: f)
            case .memorySection(let m):
                memories = m

            case .importSection(let imports):
                for i in imports {
                    switch i.descriptor {
                    case .function(let typeIndex):
                        let type = types[Int(typeIndex)]

                        guard type.results.count <= 1 else {
                            throw Error.multiValueResultsNotSupportedYet(functionName: "\(i.module).\(i.name)")
                        }

                        let irType = self.ir.__pointerTypeUnsafe()

                        // Mangle the name with character counts to avoid naming collisions.
                        // Without this mangling we can't distinguish between a function
                        // ".print" from module "foo" and function "print" from module "foo.",
                        // as without character counts they both would be mangled as `foo.print`.
                        // Another alternative could be to introduce a separator that's not allowed
                        // in Wasm function and module names (which one?), but character counts
                        // seem more reliable and predictable at the moment of writing.
                        let name = "\(i.module.count)_\(i.name.count)_\(i.module).\(i.name)"
                        name.withStringRef {
                            importedFunctions.append(self.ir.__createImportedFunctionUnsafe($0, irType))
                        }
                        functionNames.append(name)
                        functionTypes.append(typeIndex)

                    case .global, .table, .memory:
                        throw Error.unsupportedImport(i)
                    }
                }

            case .codeSection(let functions):
                functionVisitors = RigidArray(capacity: functions.count)
                for (i, f) in functions.enumerated() {
                    let type = types[Int(functionTypes[importedFunctions.count + i])]
                    // Create visitors first before actually visiting instructions.
                    // This will forward-declare all `llvm::Function` instances so that `call`
                    // LLVM IR instructions have these instances to refer to and are valid.
                    let name = "\(i)"
                    try functionVisitors.append(
                        .init(
                            name: name,
                            type: type,
                            locals: type.parameters + f.locals,
                            code: f,
                            ir: self.ir,
                        ))

                    functionNames.append(name)
                }
            default: continue
            }
        }

        for i in 0..<functionVisitors.count {
            try functionVisitors[i].visit(
                types, functionTypes, memories,
                importedFunctions: importedFunctions, functionNames: functionNames
            )
        }

        if self.isVerbose {
            print(String(self.ir.printModule()))
        }
    }

    package mutating func emitObjectFile(wasmPath: FilePath) throws -> FilePath {
        let fd = try FileDescriptor.open(wasmPath, .readOnly)
        try self.codegen(wasmStream: FileHandleStream(fileHandle: fd))
        var objectFilePath = wasmPath
        objectFilePath.extension = "o"
        guard objectFilePath.string.withStringRef({ self.ir.emitObjectFile($0) }) else {
            throw Error.objectFileEmissionFailed
        }

        return objectFilePath
    }
}

extension IRContext {
    func function(type: IRFunctionType, name: String) -> IRFunction? {
        let f = name.withStringRef {
            self.__functionUnsafe(type, $0)
        }

        return if f._isValid { f } else { nil }
    }
}
