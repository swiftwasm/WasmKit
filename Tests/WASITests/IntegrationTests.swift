import Foundation
import Testing
import WasmKit
import WasmKitWASI

#if os(Windows)
    import ucrt
#elseif canImport(Android)
    import Android
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

@Suite
struct IntegrationTests {

    #if !os(Android)
        // One at a time, as under the upstream runner: several cases create
        // the same names, such as `file.cleanup`, in the shared root.
        @Test(
            .serialized,
            arguments: try IntegrationTests.discoverAllTests()
        )
        func run(test: URL) throws {
            try runTest(path: test)
        }
    #endif

    struct FailedTest {
        let suite: String
        let name: String
        let path: URL
        let reason: String
    }
    struct SuiteManifest: Codable {
        let name: String
    }

    static var skipTests: [String: Set<String>] {
        #if os(Windows)
            return [
                "WASI Assemblyscript tests": [],
                "WASI C tests": [
                    "fdopendir-with-access",
                    "fopen-with-access",
                    "lseek",
                    "pread-with-access",
                    "pwrite-with-access",
                    "pwrite-with-append",
                    "sock_shutdown-invalid_fd",
                    "sock_shutdown-not_sock",
                    "stat-dev-ino",
                ],
                "WASI Rust tests": [
                    "close_preopen",
                    "dangling_fd",
                    "dangling_symlink",
                    "dir_fd_op_failures",
                    "directory_seek",
                    "fd_advise",
                    "fd_fdstat_set_rights",
                    "fd_filestat_set",
                    "fd_flags_set",
                    "fd_readdir",
                    "file_allocate",
                    "file_pread_pwrite",
                    "file_seek_tell",
                    "file_truncation",
                    "file_unbuffered_write",
                    "fstflags_validate",
                    "interesting_paths",
                    "isatty",
                    "nofollow_errors",
                    "overwrite_preopen",
                    "path_exists",
                    "path_filestat",
                    "path_link",
                    "path_open_create_existing",
                    "path_open_dirfd_not_dir",
                    "path_open_missing",
                    "path_open_nonblock",
                    "path_open_preopen",
                    "path_open_read_write",
                    "path_rename",
                    "path_rename_dir_trailing_slashes",
                    "path_symlink_trailing_slashes",
                    "poll_oneoff_stdio",
                    "readlink",
                    "remove_directory_trailing_slashes",
                    "remove_nonempty_directory",
                    "renumber",
                    "sched_yield",
                    "stdio",
                    "symlink_create",
                    "symlink_filestat",
                    "symlink_loop",
                    "truncation_rights",
                    "unlink_file_trailing_slashes",
                ],
            ]
        #else
            return [:]
        #endif
    }

    /// The WASI version whose prebuilt tests we run. The suites also ship
    /// `wasm32-wasip3` components, which need the component model.
    static let wasiVersion = "wasm32-wasip1"

    static func discoverAllTests() throws -> [URL] {
        let testDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Vendor/wasi-testsuite")
        var tests = [URL]()
        for language in ["assemblyscript", "c", "rust"] {
            let suitePath = testDir.appendingPathComponent("tests/\(language)/testsuite/\(wasiVersion)")
            tests.append(contentsOf: try discoverTestsFromSuite(path: suitePath))
        }
        return tests
    }

    static func discoverTestsFromSuite(path: URL) throws -> [URL] {
        let manifestPath = path.appendingPathComponent("manifest.json")
        let manifest = try JSONDecoder().decode(SuiteManifest.self, from: Data(contentsOf: manifestPath))

        // Clean up **/*.cleanup
        do {
            let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])!
            for case let url as URL in enumerator {
                if url.pathExtension == "cleanup" {
                    try FileManager.default.removeItem(at: url)
                }
            }
        }

        let tests = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])

        // Suite names carry the WASI version, e.g. "WASI C tests [wasm32-wasip1]".
        let suiteName = manifest.name.replacingOccurrences(of: " [\(wasiVersion)]", with: "")
        let skipTests = Self.skipTests[suiteName] ?? []

        var testCases = [URL]()
        for test in tests {
            guard test.pathExtension == "wasm" else { continue }
            let testName = test.deletingPathExtension().lastPathComponent
            if skipTests.contains(testName) {
                continue
            }
            testCases.append(test)
        }
        return testCases.sorted { $0.path < $1.path }
    }

    /// A test specification, as described in `doc/specification.md` of
    /// wasi-testsuite. Only the legacy form is read: no wasip1 test uses
    /// the operation-based form, whose extra steps (sockets, HTTP) need a
    /// subprocess to talk to.
    struct CaseManifest: Codable {
        var args: [String]?
        var env: [String: String]?
        /// A directory, relative to the test, preopened as the guest's `/`.
        var root: String?
        var exitCode: UInt32?
        var stdout: String?
        var stderr: String?
        var operations: [Operation]?

        struct Operation: Codable {
            var type: String
        }

        static var empty: CaseManifest {
            CaseManifest()
        }
    }

    func runTest(path: URL) throws {
        let manifestPath = path.deletingPathExtension().appendingPathExtension("json")
        var manifest: CaseManifest
        if FileManager.default.fileExists(atPath: manifestPath.path) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            manifest = try decoder.decode(CaseManifest.self, from: Data(contentsOf: manifestPath))
        } else {
            manifest = .empty
        }
        guard manifest.operations == nil else {
            Issue.record("\(path.lastPathComponent): operation-based test specifications are not supported")
            return
        }

        let suitePath = path.deletingLastPathComponent()
        let preopens =
            manifest.root.map {
                [WASIBridgeToHost.Preopen(guestPath: "/", hostPath: suitePath.appendingPathComponent($0).path)]
            } ?? []

        // Give the guest files rather than our own terminal, so its output
        // can be checked and, like under the upstream runner, no stdio is a tty.
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("wasi-testsuite-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outputDir) }
        let stdoutPath = outputDir.appendingPathComponent("stdout")
        let stderrPath = outputDir.appendingPathComponent("stderr")
        #if os(Windows)
            let nullDevice = "NUL"
        #else
            let nullDevice = "/dev/null"
        #endif
        let stdin = try Self.openStdioFile(nullDevice, write: false)
        defer { Self.closeStdioFile(stdin) }
        let stdout = try Self.openStdioFile(stdoutPath.path, write: true)
        defer { Self.closeStdioFile(stdout) }
        let stderr = try Self.openStdioFile(stderrPath.path, write: true)
        defer { Self.closeStdioFile(stderr) }

        let wasi = try WASIBridgeToHost(
            args: [path.path] + (manifest.args ?? []),
            environment: manifest.env ?? [:],
            fileSystem: .host()
                .withStdio(
                    stdin: stdin,
                    stdout: stdout,
                    stderr: stderr
                )
                .withPreopens(preopens)
        )
        let result = Result {
            try wasi.runAndClose { wasi in
                let engine = Engine()
                let store = Store(engine: engine)
                var imports = Imports()
                wasi.link(to: &imports, store: store)
                let module = try parseWasm(filePath: path.path)
                let instance = try module.instantiate(store: store, imports: imports)
                return try wasi.start(instance)
            }
        }
        // Decode leniently, so that output in another encoding is reported
        // as a mismatch rather than thrown.
        let actualStdout = String(decoding: try Data(contentsOf: stdoutPath), as: UTF8.self)
        let actualStderr = String(decoding: try Data(contentsOf: stderrPath), as: UTF8.self)
        let output = "stdout: \(actualStdout)\nstderr: \(actualStderr)"
        let exitCode: UInt32
        switch result {
        case .success(let code): exitCode = code
        case .failure(let error):
            // A trap usually follows a panic message on stderr.
            Issue.record(error, "\(path.path)\n\(output)")
            return
        }
        #expect(exitCode == manifest.exitCode ?? 0, "\(path.path)\n\(output)")
        // The upstream runner reads as many bytes as it expects and compares those.
        if let expected = manifest.stdout {
            #expect(actualStdout.hasPrefix(expected), "\(path.path)\n\(output)")
        }
        if let expected = manifest.stderr {
            #expect(actualStderr.hasPrefix(expected), "\(path.path)\n\(output)")
        }
    }

    /// Opens a file as a platform descriptor for the guest's stdio.
    /// `FileHandle.fileDescriptor` is unavailable on Windows, so this goes
    /// through the C runtime directly.
    static func openStdioFile(_ path: String, write: Bool) throws -> CInt {
        #if os(Windows)
            var fd: CInt = -1
            let flags = (write ? _O_WRONLY | _O_CREAT | _O_TRUNC : _O_RDONLY) | _O_BINARY
            _ = path.withCString(encodedAs: UTF16.self) { widePath in
                _wsopen_s(&fd, widePath, flags, _SH_DENYNO, _S_IREAD | _S_IWRITE)
            }
        #else
            let fd = open(path, write ? O_WRONLY | O_CREAT | O_TRUNC : O_RDONLY, 0o644)
        #endif
        guard fd >= 0 else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: path])
        }
        return fd
    }

    static func closeStdioFile(_ fd: CInt) {
        #if os(Windows)
            _ = _close(fd)
        #else
            _ = close(fd)
        #endif
    }
}
