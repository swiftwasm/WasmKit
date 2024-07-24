import WasmKit

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzCheck(_ start: UnsafePointer<UInt8>, _ count: Int) -> CInt {
    let bytes = Array(UnsafeBufferPointer(start: start, count: count))
    do {
        var module = try WasmKit.parseWasm(bytes: bytes)
        try module.materializeAll()
    } catch {
        // Ignore errors
    }
    return 0
}
