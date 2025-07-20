import Foundation
import SystemPackage
import WasmKit
import WasmKitWASI
import XCTest

final class IntegrationTests: XCTestCase {
    func testRunAll() throws {
        #if os(Android)
            throw XCTSkip("unable to run spectest on Android due to missing files on emulator")
        #endif
        let testDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Vendor/wasi-testsuite")
        var failedTests = [FailedTest]()
        for testSuitePath in ["tests/assemblyscript/testsuite", "tests/c/testsuite", "tests/rust/testsuite"] {
            let suitePath = testDir.appendingPathComponent(testSuitePath)
            failedTests.append(contentsOf: try runTestSuite(path: suitePath))
        }

        if !failedTests.isEmpty {
            XCTFail("Failed tests: \(failedTests.map { "\($0.suite)/\($0.name)" }.joined(separator: ", "))")

            if ProcessInfo.processInfo.environment["WASMKIT_WASI_DUMP_SKIPS"] != nil {
                var itemsToSkip = [String: [String: String]]()
                for test in failedTests {
                    itemsToSkip[test.suite, default: [:]][test.name] = "Not implemented"
                }
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                print(String(data: try encoder.encode(itemsToSkip), encoding: .utf8)!)
            }
        }
    }

    struct FailedTest {
        let suite: String
        let name: String
        let path: URL
        let reason: String
    }
    struct SuiteManifest: Codable {
        let name: String
    }

    static var skipTests: [String: [String: String]] {
        #if os(Windows)
            return [
                "WASI Assemblyscript tests": [:],
                "WASI C tests": [
                    "fdopendir-with-access": "Not implemented",
                    "fopen-with-access": "Not implemented",
                    "lseek": "Not implemented",
                    "pread-with-access": "Not implemented",
                    "pwrite-with-access": "Not implemented",
                    "stat-dev-ino": "Not implemented",
                ],
                "WASI Rust tests": [
                    "close_preopen": "Not implemented",
                    "dangling_fd": "Not implemented",
                    "dangling_symlink": "Not implemented",
                    "directory_seek": "Not implemented",
                    "fd_advise": "Not implemented",
                    "fd_filestat_set": "Not implemented",
                    "fd_flags_set": "Not implemented",
                    "fd_readdir": "Not implemented",
                    "interesting_paths": "Not implemented",
                ],
            ]
        #else
            return [
                "WASI Rust tests" : [
                  "path_link" : "Not implemented",
                  "dir_fd_op_failures" : "Not implemented",
                  "path_rename_dir_trailing_slashes" : "Not implemented",
                  "path_rename" : "Not implemented",
                  "poll_oneoff_stdio" : "Not implemented",
                  "overwrite_preopen" : "Not implemented",
                  "path_filestat" : "Not implemented",
                  "renumber" : "Not implemented",
                  "symlink_filestat" : "Not implemented",
                  "path_open_read_write" : "Not implemented",
                  "path_open_preopen" : "Not implemented",
                  "fd_fdstat_set_rights" : "Not implemented",
                  "file_allocate" : "Not implemented",
                  "stdio" : "Not implemented",
                  "remove_directory_trailing_slashes" : "Not implemented",
                  "symlink_create" : "Not implemented",
                  "readlink" : "Not implemented",
                  "sched_yield" : "Not implemented"
                ],
                "WASI C tests": [
                    "sock_shutdown-invalid_fd" : "Not implemented",
                    "sock_shutdown-not_sock": "Not implemented",
                ]
            ]
        #endif
    }

    func runTestSuite(path: URL) throws -> [FailedTest] {
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

        print("Running test suite: \(manifest.name)")
        let tests = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])

        let skipTests = Self.skipTests[manifest.name] ?? [:]

        var failedTests = [FailedTest]()
        for test in tests {
            guard test.pathExtension == "wasm" else { continue }
            let testName = test.deletingPathExtension().lastPathComponent
            if let reason = skipTests[testName] {
                print("Skipping test \(testName): \(reason)")
                continue
            }
            do {
                try runTest(path: test)
            } catch {
                failedTests.append(FailedTest(suite: manifest.name, name: testName, path: test, reason: String(describing: error)))
            }
        }
        return failedTests
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

        print("Testing \(path.path)")

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
        XCTAssertEqual(exitCode, manifest.exitCode ?? 0, path.path)
    }
}
