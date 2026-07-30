// swift-tools-version:6.3

import PackageDescription

import class Foundation.ProcessInfo

let DarwinPlatforms: [Platform] = [.macOS, .iOS, .watchOS, .tvOS, .visionOS]

let swiftSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error, .when(platforms: DarwinPlatforms + [.linux, .wasi, .android, .openbsd]))
]

let cliCommandsTarget = Target.target(
    name: "CLICommands",
    dependencies: [
        "WAT",
        "WasmKit",
        "WasmKitWASI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    exclude: ["CMakeLists.txt"],
    swiftSettings: swiftSettings
)

let cliCommandsTestTarget = Target.testTarget(
    name: "CLICommandsTests",
    dependencies: [
        "CLICommands",
        "WasmTypes",
        "WAT",
        "WASI",
        "WasmKit",
        "WasmKitWASI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    exclude: ["Fixtures"]
)

let package = Package(
    name: "WasmKit",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .executable(name: "wasmkit-cli", targets: ["CLI"]),
        .library(name: "WasmKit", targets: ["WasmKit"]),
        .library(name: "WasmKitWASI", targets: ["WasmKitWASI"]),
        .library(name: "WASI", targets: ["WASI"]),
        .library(name: "WasmParser", targets: ["WasmParser"]),
        .library(name: "WAT", targets: ["WAT"]),
        .library(name: "WIT", targets: ["WIT"]),
        .library(name: "WITMarker", targets: ["WITMarker"]),
        .library(name: "_CabiShims", targets: ["_CabiShims"]),
    ],
    traits: [
        .default(enabledTraits: ["FileSystem", "MultiThread", "Disassembler"]),
        "FileSystem",
        "ComponentModel",
        "WasmDebuggingSupport",
        // Collects instruction-trigram statistics during execution and dumps
        // them to stderr on exit. Development-only diagnostics.
        "EngineStats",
        // Serializes shared engine state with real locks. Disable only for
        // single-threaded environments (e.g. bare-metal Embedded Swift) where
        // the Synchronization module provides no Mutex.
        "MultiThread",
        // Textual instruction dumping (`wasmkit explore`).
        "Disassembler",
    ],
    targets: [
        cliCommandsTarget,
        cliCommandsTestTarget,
        .executableTarget(
            name: "CLI",
            dependencies: ["CLICommands"],
            exclude: ["CMakeLists.txt"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WasmKit",
            dependencies: [
                "_CWasmKit",
                "WasmParser",
                "WasmTypes",
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                ),
                .target(
                    name: "WAVE",
                    condition: .when(traits: ["ComponentModel"])
                ),
            ],
            exclude: ["CMakeLists.txt"],
            swiftSettings: swiftSettings
        ),
        .target(name: "_CWasmKit"),
        .target(
            name: "WasmKitFuzzing",
            dependencies: ["WasmKit"],
            path: "FuzzTesting/Sources/WasmKitFuzzing",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WasmKitTests",
            dependencies: ["WasmKit", "WAT", "WasmKitFuzzing"],
            exclude: ["ExtraSuite", "CMakeLists.txt"],
            swiftSettings: swiftSettings
        ),

        .target(
            name: "WAT",
            dependencies: [
                "WasmParser",
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                ),
            ],
            exclude: ["CMakeLists.txt"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WATTests",
            dependencies: [
                .target(
                    name: "WasmTools",
                    condition: .when(traits: ["ComponentModel"])
                ),
                "WAT",
            ],
            swiftSettings: swiftSettings
        ),

        .target(
            name: "WasmParser",
            dependencies: [
                "WasmTypes",
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                ),
            ],
            exclude: ["CMakeLists.txt"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WasmParserTests",
            dependencies: [
                "WasmParser",
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                ),
            ],
            swiftSettings: swiftSettings
        ),

        .target(name: "WasmTypes", exclude: ["CMakeLists.txt"], swiftSettings: swiftSettings),
        .testTarget(name: "WasmTypesTests", dependencies: ["WasmTypes"], swiftSettings: swiftSettings),

        .target(
            name: "WasmKitWASI",
            dependencies: ["WasmKit", "WASI"],
            exclude: ["CMakeLists.txt"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WASI",
            dependencies: [
                "WasmTypes",
                .target(name: "CWASIPlatform", condition: .when(platforms: [.wasi])),
            ],
            exclude: ["CMakeLists.txt"],
            swiftSettings: swiftSettings
        ),
        .target(name: "CWASIPlatform"),
        .testTarget(name: "WASITests", dependencies: ["WASI", "WasmKitWASI"], swiftSettings: swiftSettings),

        // Component Model (CM)

        /// `wasm-tools.wasm` wrapper used when comparing CM test suite against existing baseline implementation
        .target(
            name: "WasmTools",
            dependencies: [
                "WasmKit",
                "WasmKitWASI",
            ],
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ComponentModel",
            dependencies: [
                "WasmTypes"
            ],
            swiftSettings: swiftSettings
        ),

        .executableTarget(
            name: "WITTool",
            dependencies: [
                "WIT",
                "WITOverlayGenerator",
                "WITExtractor",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: swiftSettings
        ),

        .target(
            name: "WIT",
            dependencies: [
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                )
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(name: "WITTests", dependencies: ["WIT"], swiftSettings: swiftSettings),

        .target(
            name: "WAVE",
            dependencies: [
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                )
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WAVETests",
            dependencies: [
                "WAVE",
                "WIT",
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                ),
            ],
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ComponentLinker",
            dependencies: [
                "WAT",
                "WIT",
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                ),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ComponentLinkerTests",
            dependencies: [
                "ComponentLinker",
                "WasmParser",
                "WIT",
                .target(
                    name: "ComponentModel",
                    condition: .when(traits: ["ComponentModel"])
                ),
            ],
            swiftSettings: swiftSettings
        ),

        .target(name: "WITOverlayGenerator", dependencies: ["WIT"], swiftSettings: swiftSettings),
        .target(name: "_CabiShims"),

        .target(
            name: "WITExtractor",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(name: "WITMarker", swiftSettings: swiftSettings),
        .testTarget(name: "WITExtractorTests", dependencies: ["WITExtractor", "WIT"], swiftSettings: swiftSettings),

        .target(
            name: "GDBRemoteProtocol",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
            ],
            exclude: ["LICENSE.txt"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "GDBRemoteProtocolTests",
            dependencies: ["GDBRemoteProtocol"],
            exclude: ["LICENSE.txt"],
            swiftSettings: swiftSettings
        ),
    ]
)

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.1"),
        .package(url: "https://github.com/apple/swift-system", from: "1.7.2"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.90.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.7.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"604.0.0"),
    ]
} else {
    package.dependencies += [
        .package(path: "../swift-argument-parser"),
        .package(path: "../swift-system"),
        .package(path: "../swift-nio"),
        .package(path: "../swift-log"),
        .package(path: "../swift-syntax"),
    ]
}

#if !os(Windows)
    // Add build tool plugins only for non-Windows platforms
    package.products.append(contentsOf: [
        .plugin(name: "WITOverlayPlugin", targets: ["WITOverlayPlugin"]),
        .plugin(name: "WITExtractorPlugin", targets: ["WITExtractorPlugin"]),
    ])

    package.targets.append(contentsOf: [
        .plugin(name: "WITOverlayPlugin", capability: .buildTool(), dependencies: ["WITTool"]),
        .plugin(name: "GenerateOverlayForTesting", capability: .buildTool(), dependencies: ["WITTool"]),
        .testTarget(
            name: "WITOverlayGeneratorTests",
            dependencies: ["WITOverlayGenerator", "WasmKit", "WasmKitWASI"],
            exclude: ["Fixtures", "Compiled", "Generated", "EmbeddedSupport"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "GenerateOverlayForTesting")]
        ),
        .plugin(
            name: "WITExtractorPlugin",
            capability: .command(
                intent: .custom(verb: "extract-wit", description: "Extract WIT definition from Swift module"),
                permissions: []
            ),
            dependencies: ["WITTool"]
        ),
        .testTarget(
            name: "WITExtractorPluginTests",
            exclude: ["Fixtures"],
            swiftSettings: swiftSettings
        ),

        .target(
            name: "WasmKitGDBHandler",
            dependencies: [
                .product(name: "_NIOFileSystem", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "SystemPackage", package: "swift-system"),
                "WasmKit",
                "WasmKitWASI",
                "GDBRemoteProtocol",
            ],
            exclude: ["LICENSE.txt"],
            swiftSettings: swiftSettings
        ),
    ])

    cliCommandsTarget.dependencies.append(contentsOf: [
        .product(name: "Logging", package: "swift-log", condition: .when(traits: ["WasmDebuggingSupport"])),
        .product(name: "NIOCore", package: "swift-nio", condition: .when(traits: ["WasmDebuggingSupport"])),
        .product(name: "NIOPosix", package: "swift-nio", condition: .when(traits: ["WasmDebuggingSupport"])),
        .target(name: "GDBRemoteProtocol", condition: .when(traits: ["WasmDebuggingSupport"])),
        .target(name: "WasmKitGDBHandler", condition: .when(traits: ["WasmDebuggingSupport"])),
    ])

    cliCommandsTestTarget.dependencies.append(contentsOf: [
        .product(name: "SystemPackage", package: "swift-system", condition: .when(traits: ["WasmDebuggingSupport"])),
        .product(name: "Logging", package: "swift-log", condition: .when(traits: ["WasmDebuggingSupport"])),
        .product(name: "NIOCore", package: "swift-nio", condition: .when(traits: ["WasmDebuggingSupport"])),
        .target(name: "GDBRemoteProtocol", condition: .when(traits: ["WasmDebuggingSupport"])),
        .target(name: "WasmKitGDBHandler", condition: .when(traits: ["WasmDebuggingSupport"])),
    ])
#endif
