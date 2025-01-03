import XCTest

@testable import WASI

final class WASITests: XCTestCase {
    func testPathOpen() throws {
        #if os(Windows)
            try XCTSkipIf(true)
        #endif
        let t = try TestSupport.TemporaryDirectory()

        try t.createDir(at: "External")
        try t.createDir(at: "External/secret-dir-b")
        try t.createFile(at: "External/secret-a.txt", contents: "Secret A")
        try t.createFile(at: "External/secret-dir-b/secret-c.txt", contents: "Secret C")
        try t.createDir(at: "Sandbox")
        try t.createFile(at: "Sandbox/hello.txt", contents: "Hello")
        try t.createSymlink(at: "Sandbox/link-hello.txt", to: "hello.txt")
        try t.createDir(at: "Sandbox/world.dir")
        try t.createSymlink(at: "Sandbox/link-world.dir", to: "world.dir")
        try t.createSymlink(at: "Sandbox/link-external-secret-a.txt", to: "../External/secret-a.txt")
        try t.createSymlink(at: "Sandbox/link-secret-dir-b", to: "../External/secret-dir-b")
        try t.createSymlink(at: "Sandbox/link-updown-hello.txt", to: "../Sandbox/link-updown-hello.txt")
        try t.createSymlink(at: "Sandbox/link-external-non-existent.txt", to: "../External/non-existent.txt")
        try t.createSymlink(at: "Sandbox/link-root", to: "/")
        try t.createSymlink(at: "Sandbox/link-loop.txt", to: "link-loop.txt")

        let wasi = try WASIBridgeToHost(
            preopens: ["/Sandbox": t.url.appendingPathComponent("Sandbox").path]
        )
        let mntFd: WASIAbi.Fd = 3

        func assertResolve(_ path: String, followSymlink: Bool, directory: Bool = false) throws {
            let fd = try wasi.path_open(
                dirFd: mntFd,
                dirFlags: followSymlink ? [.SYMLINK_FOLLOW] : [],
                path: path,
                oflags: directory ? [.DIRECTORY] : [],
                fsRightsBase: .DIRECTORY_BASE_RIGHTS,
                fsRightsInheriting: .DIRECTORY_INHERITING_RIGHTS,
                fdflags: []
            )
            try wasi.fd_close(fd: fd)
        }

        func assertNotResolve(
            _ path: String,
            followSymlink: Bool,
            directory: Bool = false,
            file: StaticString = #file,
            line: UInt = #line,
            _ checkError: ((WASIAbi.Errno) throws -> Void)?
        ) throws {
            do {
                _ = try wasi.path_open(
                    dirFd: mntFd,
                    dirFlags: followSymlink ? [.SYMLINK_FOLLOW] : [],
                    path: path,
                    oflags: directory ? [.DIRECTORY] : [],
                    fsRightsBase: .DIRECTORY_BASE_RIGHTS,
                    fsRightsInheriting: .DIRECTORY_INHERITING_RIGHTS,
                    fdflags: []
                )
                XCTFail("Expected not to be able to open \(path)", file: file, line: line)
            } catch {
                guard let error = error as? WASIAbi.Errno else {
                    XCTFail("Expected WASIAbi.Errno error but got \(error)", file: file, line: line)
                    return
                }
                try checkError?(error)
            }
        }

        try assertNotResolve("non-existent.txt", followSymlink: false) { error in
            XCTAssertEqual(error, .ENOENT)
        }

        try assertResolve("link-hello.txt", followSymlink: true)
        try assertNotResolve("link-hello.txt", followSymlink: false) { error in
            XCTAssertEqual(error, .ELOOP)
        }
        try assertNotResolve("link-hello.txt", followSymlink: true, directory: true) { error in
            XCTAssertEqual(error, .ENOTDIR)
        }

        try assertNotResolve("link-hello.txt/", followSymlink: true) { error in
            XCTAssertEqual(error, .ENOTDIR)
        }

        try assertResolve("link-world.dir", followSymlink: true)
        try assertNotResolve("link-world.dir", followSymlink: false) { error in
            XCTAssertEqual(error, .ELOOP)
        }

        try assertNotResolve("link-external-secret-a.txt", followSymlink: true) { error in
            XCTAssertEqual(error, .EPERM)
        }
        try assertNotResolve("link-external-secret-a.txt", followSymlink: false) { error in
            XCTAssertEqual(error, .ELOOP)
        }

        try assertNotResolve("link-external-non-existent.txt", followSymlink: true) { error in
            XCTAssertEqual(error, .EPERM)
        }
        try assertNotResolve("link-external-non-existent.txt", followSymlink: false) { error in
            XCTAssertEqual(error, .ELOOP)
        }

        try assertNotResolve("link-updown-hello.txt", followSymlink: true) { error in
            XCTAssertEqual(error, .EPERM)
        }
        try assertNotResolve("link-updown-hello.txt", followSymlink: false) { error in
            XCTAssertEqual(error, .ELOOP)
        }

        try assertNotResolve("link-secret-dir-b/secret-c.txt", followSymlink: true) { error in
            XCTAssertEqual(error, .EPERM)
        }
        try assertNotResolve("link-secret-dir-b/secret-c.txt", followSymlink: false) { error in
            XCTAssertEqual(error, .ENOTDIR)
        }

        try assertNotResolve("link-root", followSymlink: true) { error in
            XCTAssertEqual(error, .EPERM)
        }
        try assertNotResolve("link-root", followSymlink: false) { error in
            XCTAssertEqual(error, .ELOOP)
        }

        try assertNotResolve("link-loop.txt", followSymlink: false) { error in
            XCTAssertEqual(error, .ELOOP)
        }
        try assertNotResolve("link-loop.txt", followSymlink: true) { error in
            XCTAssertEqual(error, .ELOOP)
        }
    }
}
