import WAT

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzCheck(_ start: UnsafePointer<UInt8>, _ count: Int) -> CInt {
    let text = String(decoding: UnsafeBufferPointer(start: start, count: count), as: UTF8.self)
    _ = try? wat2wasm(text)
    return 0
}
