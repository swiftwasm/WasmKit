import Foundation
import SystemPackage
import WasmKit
import WasmKitWASI
import XCTest

final class IntegrationTests: XCTestCase {
    func testRunAll() throws {
        let testDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Vendor/wasi-testsuite")
        for testSuitePath in ["tests/assemblyscript/testsuite", "tests/c/testsuite", "tests/rust/testsuite"] {
            let suitePath = testDir.appendingPathComponent(testSuitePath)
            try runTestSuite(path: suitePath)
        }
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
            return [:]
        #endif
    }

    func runTestSuite(path: URL) throws {
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

        for test in tests {
            guard test.pathExtension == "wasm" else { continue }
            let testName = test.deletingPathExtension().lastPathComponent
            if let reason = skipTests[testName] {
                print("Skipping test \(testName): \(reason)")
                continue
            }
            try runTest(path: test)
        }
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
        let runtime = Runtime(hostModules: wasi.hostModules)
        let module = try parseWasm(filePath: FilePath(path.path))
        let instance = try runtime.instantiate(module: module)
        let exitCode = try wasi.start(instance, runtime: runtime)
        XCTAssertEqual(exitCode, manifest.exitCode ?? 0, path.path)
    }
}
