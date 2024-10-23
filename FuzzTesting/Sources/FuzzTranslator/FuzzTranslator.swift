import WasmKit
import WasmKitFuzzing

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzCheck(_ start: UnsafePointer<UInt8>, _ count: Int) -> CInt {
    let bytes = Array(UnsafeBufferPointer(start: start, count: count))
    do {
        try fuzzInstantiation(bytes: bytes)
    } catch {
        // Ignore errors
    }
    return 0
}
