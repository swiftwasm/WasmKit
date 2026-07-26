import WAT

#if canImport(WASILibc)
import WASILibc
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// Embedded Swift's stdlib omits the locale-aware number-parsing shims that
// `Double`/`Float` string initializers call. wasi-libc is single-locale (C),
// so back them with plain `strtod`/`strtof`. Per RuntimeShims.h the ABI writes
// the parsed value through `outResult` and returns the end pointer.
#if $Embedded
@_cdecl("_swift_stdlib_strtod_clocale")
func _swift_stdlib_strtod_clocale(
    _ nptr: UnsafePointer<CChar>?, _ outResult: UnsafeMutablePointer<Double>?
) -> UnsafePointer<CChar>? {
    var endPtr: UnsafeMutablePointer<CChar>?
    outResult?.pointee = strtod(nptr, &endPtr)
    return endPtr.map { UnsafePointer($0) }
}

@_cdecl("_swift_stdlib_strtof_clocale")
func _swift_stdlib_strtof_clocale(
    _ nptr: UnsafePointer<CChar>?, _ outResult: UnsafeMutablePointer<Float>?
) -> UnsafePointer<CChar>? {
    var endPtr: UnsafeMutablePointer<CChar>?
    outResult?.pointee = strtof(nptr, &endPtr)
    return endPtr.map { UnsafePointer($0) }
}
#endif

@main
struct Entrypoint {
    static func main() {
        // Read all of stdin via libc `read(2)` instead of `readLine()`, whose
        // stdlib backing (`swift_stdlib_readLine_stdin`) is unavailable in
        // Embedded Swift.
        var input = [UInt8]()
        var chunk = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = chunk.withUnsafeMutableBytes { buffer in
                read(0, buffer.baseAddress, buffer.count)
            }
            if count <= 0 { break }
            input.append(contentsOf: chunk[0..<Int(count)])
        }
        guard !input.isEmpty else { return }
        let watString = String(decoding: input, as: UTF8.self)

        do throws(WatParserError) {
            let bytes = try wat2wasm(watString)
            for byte in bytes {
                print("0x" + String(byte, radix: 16))
            }
        } catch {
            print(error)
        }
    }
}
