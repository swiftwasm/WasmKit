#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

import SystemPackage

package protocol ImportedFunctionArguments {
    associatedtype ResultType

    func apply(symbol: UnsafeMutableRawPointer) -> ResultType
}

package struct U32Args2Result1: ImportedFunctionArguments {
    typealias CType = @convention(c) (UInt32, UInt32) -> UInt32

    private let args: (UInt32, UInt32)

    package init(_ first: UInt32, _ second: UInt32) {
        self.args = (first, second)
    }

    package func apply(symbol: UnsafeMutableRawPointer) -> UInt32 {
        unsafeBitCast(symbol, to: CType.self)(self.args.0, self.args.1)
    }
}

package struct Loader: ~Copyable {
    enum Error: Swift.Error {
        case symbolNotFound(String)
    }

    package enum ClosureType {
        case u32Args2Result1(UInt32, UInt32)
    }

    let memory: Wasm32Memory?

    package init(memory: consuming Wasm32Memory?) {
        self.memory = memory
    }

    package func load<T: ImportedFunctionArguments>(
        library: FilePath,
        entrypointSymbol: String,
        arguments: T
    ) throws -> T.ResultType {
        let handle = dlopen(library.string, RTLD_LAZY)
        defer { dlclose(handle) }

        guard let symbol = dlsym(handle, entrypointSymbol) else {
            throw Error.symbolNotFound(entrypointSymbol)
        }

        return arguments.apply(symbol: symbol)
    }
}
