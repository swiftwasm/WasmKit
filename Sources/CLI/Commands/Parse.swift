import SystemPackage
import WAT
import WasmKit

/// Parses a `.wasm` or `.wat` module.
func parseWasm(filePath: FilePath) throws -> Module {
    if filePath.extension == "wat", #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, visionOS 1.0, watchOS 7.0, *) {
        let fileHandle = try FileDescriptor.open(filePath, .readOnly)
        defer { try? fileHandle.close() }

        let size = try fileHandle.seek(offset: 0, from: .end)

        let wat = try String(unsafeUninitializedCapacity: Int(size)) {
            try fileHandle.read(fromAbsoluteOffset: 0, into: .init($0))
        }
        return try WasmKit.parseWasm(bytes: wat2wasm(wat))
    } else {
        return try WasmKit.parseWasm(filePath: filePath)
    }
}
