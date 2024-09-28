import _CWasmKit

/// Standard error output stream.
struct _Stderr: TextOutputStream {

    func write(_ string: String) {
        if string.isEmpty { return }
        var string = string
        string.withUTF8 {
            wasmkit_fwrite_stderr($0.baseAddress!, $0.count)
        }
    }
}
