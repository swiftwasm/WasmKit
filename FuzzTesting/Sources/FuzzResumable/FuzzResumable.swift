import ResumableFuzzing

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzCheck(_ start: UnsafePointer<UInt8>, _ count: Int) -> CInt {
    let bytes = Array(UnsafeBufferPointer(start: start, count: count))
    do {
        try ResumableOracle.run(bytes: bytes)
    } catch let finding as Finding {
        fatalError(finding.description)
    } catch {
        // The module could not be instantiated, e.g. its start-up code trapped.
    }
    return 0
}
