import Foundation
import SystemPackage
import Testing
import WasmKit
import WasmKitWASI

@Suite
struct IntegrationTests {

    #if !os(Android)
        @Test(
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
            var tests: [String: Set<String>] = [
                "WASI Rust tests": [
                    "path_link",
                    "dir_fd_op_failures",
                    "pwrite-with-append",
                    "poll_oneoff_stdio",
                    "overwrite_preopen",
                    "path_filestat",
                    "renumber",
                    "symlink_filestat",
                    "path_open_read_write",
                    "path_open_preopen",
                    "fd_fdstat_set_rights",
                    "file_allocate",
                    "stdio",
                    "remove_directory_trailing_slashes",
                    "symlink_create",
                    "sched_yield",
                ],
                "WASI C tests": [
                    "sock_shutdown-invalid_fd",
                    "sock_shutdown-not_sock",
                ],
            ]
            #if os(Linux)
                tests["WASI C tests"]?.insert("pwrite-with-append")
            #endif
            return tests
        #endif
    }

    static func discoverAllTests() throws -> [URL] {
        let testDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Vendor/wasi-testsuite")
        var tests = [URL]()
        for testSuitePath in ["tests/assemblyscript/testsuite", "tests/c/testsuite", "tests/rust/testsuite"] {
            let suitePath = testDir.appendingPathComponent(testSuitePath)
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

        let skipTests = Self.skipTests[manifest.name] ?? []

        var testCases = [URL]()
        for test in tests {
            guard test.pathExtension == "wasm" else { continue }
            let testName = test.deletingPathExtension().lastPathComponent
            if skipTests.contains(testName) {
                continue
            }
            testCases.append(test)
        }
        return testCases
    }

    struct CaseManifest: Codable {
        var dirs: [String]?
        var args: [String]?
        var env: [String: String]?
        var exitCode: UInt32?

        static var empty: CaseManifest {
            CaseManifest(dirs: nil, args: nil, env: nil, exitCode: nil)
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

        // HACK: WasmKit intentionally does not support fd_allocate
        if path.lastPathComponent == "fd_advise.wasm" {
            manifest.env = (manifest.env ?? [:]).merging(["NO_FD_ALLOCATE": "1"]) { _, new in new }
        }

        let suitePath = path.deletingLastPathComponent()

        let wasi = try WASIBridgeToHost(
            args: [path.path] + (manifest.args ?? []),
            environment: manifest.env ?? [:],
            preopens: (manifest.dirs ?? []).reduce(into: [String: String]()) {
                $0[$1] = suitePath.appendingPathComponent($1).path
            }
        )
        let engine = Engine()
        let store = Store(engine: engine)
        var imports = Imports()
        wasi.link(to: &imports, store: store)
        let module = try parseWasm(filePath: FilePath(path.path))
        let instance = try module.instantiate(store: store, imports: imports)
        let exitCode = try wasi.start(instance)
        #expect(exitCode == manifest.exitCode ?? 0, "\(path.path)")
    }
}
