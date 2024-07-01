// Compile: swiftc ./hello.swift -o hello.wasm -target wasm32-unknown-none-wasm -enable-experimental-feature Extern -enable-experimental-feature Embedded -wmo -Xcc -fdeclspec -Xclang-linker -nostdlib -Xfrontend -disable-stack-protector -Osize
// Swift version: DEVELOPMENT-SNAPSHOT-2024-06-13-a

// This is a simple WASI program written in Embedded Swift.

@_extern(wasm, module: "wasi_snapshot_preview1", name: "fd_write")
@_extern(c)
func fd_write(fd: Int32, iovs: UnsafeRawPointer, iovs_len: Int32, nwritten: UnsafeMutablePointer<Int32>) -> Int32

func _print(_ string: StaticString) {
    string.withUTF8Buffer { string in
        withUnsafeTemporaryAllocation(byteCount: 8, alignment: 4) { iov in
            let iov = iov.baseAddress!
            iov.advanced(by: 0).storeBytes(of: string.baseAddress!, as: UnsafeRawPointer.self)
            iov.advanced(by: 4).storeBytes(of: Int32(string.count), as: Int32.self)
            var nwritten: Int32 = 0
            _ = fd_write(fd: 1, iovs: iov, iovs_len: 1, nwritten: &nwritten)
        }
    }
}

// The entry point of this WASI program.
@_expose(wasm, "_start")
@_cdecl("_start")
func _start() {
    _print("Hello, World!\n")
}
