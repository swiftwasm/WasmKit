import WAT

/// Fuzzes the WAST script entry point (`wasmkit wast` / `parseWAST`), which
/// accepts fully untrusted text and drives the same lexer/parser as `wat2wasm`
/// plus the `assert_*` / `invoke` / `register` / `(module binary|quote ...)`
/// directive grammar.
@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzCheck(_ start: UnsafePointer<UInt8>, _ count: Int) -> CInt {
    let text = String(decoding: UnsafeBufferPointer(start: start, count: count), as: UTF8.self)
    guard var wast = try? parseWAST(text) else { return 0 }
    while let (directive, _) = try? wast.nextDirective() {
        // Text modules are parsed lazily: encode them so the fuzzer reaches the
        // same code the WAST runner does.
        switch directive {
        case .module(let module), .assertInvalid(let module, _), .assertMalformed(let module, _):
            if case .text(let wat) = module.source {
                _ = try? wat.encode()
            }
        case .assertUnlinkable(let wat, _):
            _ = try? wat.encode()
        default:
            break
        }
    }
    return 0
}
