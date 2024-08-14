import Foundation
import WIT
import WasmKit
import WasmKitWASI
import XCTest

@testable import WITOverlayGenerator

/// This harness expects the following directory structure:
///
/// ```
/// |- Fixtures
/// |  |- ${TEST_CASE}
/// |     |- ${TEST_CASE}.swift
/// |     |- wit
/// |        |- ${WORLD}.wit
/// ```
struct RuntimeTestHarness {
    struct Configuration: Codable {
        let swiftExecutablePath: URL
        let wasiSwiftSDKPath: URL

        var swiftCompilerExecutablePath: URL {
            swiftExecutablePath.deletingLastPathComponent().appendingPathComponent("swiftc")
        }

        static let `default`: Configuration? = {
            let decoder = JSONDecoder()
            let defaultsPath = RuntimeTestHarness.testsDirectory
                .deletingLastPathComponent()
                .appendingPathComponent("default.json")
            guard let bytes = try? Data(contentsOf: defaultsPath) else { return nil }
            return try? decoder.decode(Configuration.self, from: bytes)
        }()
    }

    struct Error: Swift.Error, CustomStringConvertible {
        let description: String
    }

    let fixturePath: URL
    var fixtureName: String { fixturePath.lastPathComponent }
    let configuration: Configuration
    let fileManager: FileManager
    var temporaryFiles: [String] = []

    init(
        fixture: String,
        configuration: Configuration? = .default,
        fileManager: FileManager = .default
    ) throws {
        self.fixturePath = RuntimeTestHarness.testsDirectory
            .appendingPathComponent("Fixtures").appendingPathComponent(fixture)
        guard let configuration else {
            throw XCTSkip(
                """
                Please create 'Tests/default.json' with this or similar contents:
                {
                    "swiftExecutablePath": "$HOME/Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2024-07-08-a.xctoolchain/usr/bin/swift",
                    "wasiSwiftSDKPath": "$HOME/Library/org.swift.swiftpm/swift-sdks/swift-wasm-DEVELOPMENT-SNAPSHOT-2024-07-09-a-wasm32-unknown-wasi.artifactbundle/DEVELOPMENT-SNAPSHOT-2024-07-09-a-wasm32-unknown-wasi/wasm32-unknown-wasi"
                }


                or specify `configuration` parameter in your test code.
                """)
        }
        self.configuration = configuration
        self.fileManager = fileManager
    }

    static let testsDirectory: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Runtime
        .deletingLastPathComponent()  // WITOverlayGeneratorTests

    static let sourcesDirectory: URL =
        testsDirectory
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // Package root
        .appendingPathComponent("Sources")

    static func createTemporaryFile(suffix: String = "") -> String {
        let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
        let templatePath = tempdir.appendingPathComponent("WasmKit.XXXXXX\(suffix)")
        var template = [UInt8](templatePath.path.utf8).map { Int8($0) } + [Int8(0)]
        let fd = mkstemps(&template, Int32(suffix.utf8.count))
        if fd == -1 {
            fatalError("Failed to create temp directory")
        }
        return String(cString: template)
    }

    private mutating func createTemporaryFile(suffix: String = "") -> String {
        let created = Self.createTemporaryFile(suffix: suffix)
        self.temporaryFiles.append(created)
        return created
    }

    private mutating func cleanupTemporaryFiles() {
        temporaryFiles.forEach {
            try! fileManager.removeItem(atPath: $0)
        }
        temporaryFiles = []
    }

    private mutating func collectGuestInputFiles() throws -> [String] {
        let implFile = fixturePath.appendingPathComponent(fixtureName + ".swift")

        let (mainPackage, packageResolver) = try PackageResolver.parse(
            directory: fixturePath.appendingPathComponent("wit").path,
            loader: LocalFileLoader()
        )
        let context = SemanticsContext(rootPackage: mainPackage, packageResolver: packageResolver)
        let guestContent = try WITOverlayGenerator.generateGuest(context: context)
        let generatedFile = Self.testsDirectory.appendingPathComponent("Generated")
            .appendingPathComponent(fixtureName + "GeneratedTargetOverlay.swift")
        try FileManager.default.createDirectory(
            at: generatedFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try guestContent.write(to: generatedFile, atomically: true, encoding: .utf8)
        return [implFile.path, generatedFile.path]
    }

    /// Build up WebAssembly module from the fixture and instantiate WasmKit runtime with the module.
    mutating func build(
        link: (inout [String: HostModule]) -> Void,
        run: (Runtime, Instance) throws -> Void
    ) throws {
        for compile in [compileForEmbedded, compileForWASI] {
            defer { cleanupTemporaryFiles() }
            let compiled = try compile(collectGuestInputFiles())

            let wasi = try WASIBridgeToHost(args: [compiled.path])
            var hostModules: [String: HostModule] = wasi.hostModules
            link(&hostModules)

            let module = try parseWasm(filePath: .init(compiled.path))
            let runtime = Runtime(hostModules: hostModules)
            let instance = try runtime.instantiate(module: module)
            try run(runtime, instance)
        }
    }

    func compileForEmbedded(inputFiles: [String]) throws -> URL {
        let embeddedSupport = Self.testsDirectory.appendingPathComponent("EmbeddedSupport")

        let libc = embeddedSupport.appendingPathComponent("MinLibc.c")
        let libcObjFile = Self.testsDirectory
            .appendingPathComponent("Compiled")
            .appendingPathComponent("MinLibc.o")
        FileManager.default.createFile(atPath: libcObjFile.deletingLastPathComponent().path, contents: nil, attributes: nil)
        try compileToObj(
            cInputFiles: [libc.path],
            arguments: [
                "-target", "wasm32-unknown-none-wasm",
                // Enable bulk memory operations for `realloc`
                "-mbulk-memory",
            ], outputPath: libcObjFile)

        return try compile(
            inputFiles: inputFiles + [libcObjFile.path],
            arguments: [
                "-target", "wasm32-unknown-none-wasm",
                "-enable-experimental-feature", "Embedded",
                "-wmo", "-Xcc", "-fdeclspec",
                "-Xfrontend", "-disable-stack-protector",
                "-Xlinker", "--no-entry", "-Xclang-linker", "-nostdlib",
            ])
    }

    func compileForWASI(inputFiles: [String]) throws -> URL {
        return try compile(
            inputFiles: inputFiles,
            arguments: [
                "-target", "wasm32-unknown-wasi",
                "-static-stdlib",
                "-Xclang-linker", "-mexec-model=reactor",
                "-resource-dir", configuration.wasiSwiftSDKPath.appendingPathComponent("/swift.xctoolchain/usr/lib/swift_static").path,
                "-sdk", configuration.wasiSwiftSDKPath.appendingPathComponent("WASI.sdk").path,
                "-Xclang-linker", "-resource-dir",
                "-Xclang-linker", configuration.wasiSwiftSDKPath.appendingPathComponent("swift.xctoolchain/usr/lib/swift_static/clang").path,
            ])
    }

    /// Compile the given input Swift source files into core Wasm module
    func compile(inputFiles: [String], arguments: [String]) throws -> URL {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            throw XCTSkip("WITOverlayGenerator test requires Foundation.Process")
        #else
            let outputPath = Self.testsDirectory
                .appendingPathComponent("Compiled")
                .appendingPathComponent("\(fixtureName).core.wasm")
            try fileManager.createDirectory(at: outputPath.deletingLastPathComponent(), withIntermediateDirectories: true)
            let process = Process()
            process.launchPath = configuration.swiftCompilerExecutablePath.path
            process.arguments =
                inputFiles + arguments + [
                    "-I\(Self.sourcesDirectory.appendingPathComponent("_CabiShims").appendingPathComponent("include").path)",
                    // TODO: Remove `--export-all` linker option by replacing `@_cdecl` with `@_expose(wasm)`
                    "-Xlinker", "--export-all",
                    "-o", outputPath.path,
                ]
            // NOTE: Clear environment variables to avoid inheriting from the current process.
            //       A test process launched by SwiftPM includes SDKROOT environment variable
            //       and it makes Swift Driver wrongly pick the SDK root from the environment
            //       variable (typically host SDK root) instead of wasi-sysroot.
            process.environment = [:]
            process.launch()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                let fileContents = inputFiles.map {
                    """
                    // MARK: - \($0)
                    \((try? String(contentsOfFile: $0)) ?? "Failed to read \($0)")
                    """
                }.joined(separator: "\n====================\n")
                let message = """
                    Failed to execute \(
                        ([configuration.swiftCompilerExecutablePath.path] + (process.arguments ?? [])).joined(separator: " ")
                    )
                    Exit status: \(process.terminationStatus)
                    Input files:
                    \(fileContents)
                    """
                throw Error(description: message)
            }
            return outputPath
        #endif
    }

    /// Compile the given input Swift source files into an object file
    func compileToObj(cInputFiles: [String], arguments: [String], outputPath: URL) throws {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            throw XCTSkip("WITOverlayGenerator test requires Foundation.Process")
        #else
            let process = Process()
            // Assume that clang is placed alongside swiftc
            process.launchPath =
                configuration.swiftCompilerExecutablePath
                .deletingLastPathComponent().appendingPathComponent("clang").path
            process.arguments =
                cInputFiles + arguments + [
                    "-c",
                    "-o", outputPath.path,
                ]
            process.environment = [:]
            process.launch()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                let message = """
                    Failed to execute \(
                        ([configuration.swiftCompilerExecutablePath.path] + (process.arguments ?? [])).joined(separator: " ")
                    )
                    Exit status: \(process.terminationStatus)
                    """
                throw Error(description: message)
            }
        #endif
    }
}
