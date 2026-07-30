import Foundation
import WASI
import WAT
import WasmKit
import WasmTypes

enum PreopenFixture {
    static let fixtureContents = "wasmkit-preopen-fixture"

    static var fixturePath: String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/wasi-preopen-argv0.wat")
            .path
    }

    static func fixtureSource() throws -> String {
        try String(contentsOfFile: fixturePath, encoding: .utf8)
    }

    static func fixtureModule() throws -> Module {
        try WasmKit.parseWasm(bytes: wat2wasm(fixtureSource()))
    }

    static func withProbeDirectory<R>(_ body: (URL) throws -> R) throws -> R {
        let directory = try makeProbeDirectory()
        return try withThrowing {
            try body(directory)
        } defer: {
            try FileManager.default.removeItem(at: directory)
        }
    }

    static func withProbeDirectory<R: Sendable>(
        _ body: @Sendable (URL) async throws -> R
    ) async throws -> R {
        let directory = try makeProbeDirectory()
        return try await withAsyncThrowing {
            try await body(directory)
        } defer: {
            try FileManager.default.removeItem(at: directory)
        }
    }

    private static func makeProbeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("wasmkit-cli-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(fixtureContents.utf8).write(to: directory.appendingPathComponent("probe.txt"))
        return directory
    }
}
