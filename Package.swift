// swift-tools-version:6.1

import PackageDescription

import class Foundation.ProcessInfo

let DarwinPlatforms: [Platform] = [.macOS, .iOS, .watchOS, .tvOS, .visionOS]

let cliCommandsTarget = Target.target(
    name: "CLICommands",
    dependencies: [
        "WAT",
        "WasmKit",
        "WasmKitWASI",
    ],
    exclude: ["CMakeLists.txt"]
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
        .library(name: "_CabiShims", targets: ["_CabiShims"]),
    ],
    traits: [
        .default(enabledTraits: []),
        "WasmDebuggingSupport",
    ],
    targets: [
        cliCommandsTarget,
        .executableTarget(
            name: "CLI",
            dependencies: ["CLICommands"],
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "WasmKit",
            dependencies: [
                "_CWasmKit",
                "WasmParser",
                "WasmTypes"
            ],
            exclude: ["CMakeLists.txt"]
        ),
        .target(name: "_CWasmKit"),
        .target(
            name: "WasmKitFuzzing",
            dependencies: ["WasmKit"],
            path: "FuzzTesting/Sources/WasmKitFuzzing"
        ),
        .testTarget(
            name: "WasmKitTests",
            dependencies: ["WasmKit", "WAT", "WasmKitFuzzing"],
            exclude: ["ExtraSuite", "CMakeLists.txt"]
        ),

        .target(
            name: "WAT",
            dependencies: ["WasmParser"],
            exclude: ["CMakeLists.txt"]
        ),
        .testTarget(name: "WATTests", dependencies: ["WAT"]),

        .target(
            name: "WasmParser",
            dependencies: [
                "WasmTypes",
            ],
            exclude: ["CMakeLists.txt"]
        ),
        .testTarget(name: "WasmParserTests", dependencies: ["WasmParser"]),

        .target(name: "WasmTypes", exclude: ["CMakeLists.txt"]),

        .target(
            name: "WasmKitWASI",
            dependencies: ["WasmKit", "WASI"],
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "WASI",
            dependencies: ["WasmTypes"],
            exclude: ["CMakeLists.txt"]
        ),
        .testTarget(name: "WASITests", dependencies: ["WASI", "WasmKitWASI"]),

        .executableTarget(
            name: "WITTool",
            dependencies: [
                "WIT",
                "WITOverlayGenerator",
                "WITExtractor",
            ]
        ),

        .target(name: "WIT"),
        .testTarget(name: "WITTests", dependencies: ["WIT"]),

        .target(name: "WITOverlayGenerator", dependencies: ["WIT"]),
        .target(name: "_CabiShims"),

        .target(name: "WITExtractor"),
        .testTarget(name: "WITExtractorTests", dependencies: ["WITExtractor", "WIT"]),

        .target(
            name: "GDBRemoteProtocol",
            dependencies: [
            ],
            exclude: ["LICENSE.txt"]
        ),
        .testTarget(
            name: "GDBRemoteProtocolTests",
            dependencies: ["GDBRemoteProtocol"],
            exclude: ["LICENSE.txt"]
        ),
    ]
)

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
    ]
} else {
    package.dependencies += [
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
            exclude: ["Fixtures"]
        ),

        .target(
            name: "WasmKitGDBHandler",
            dependencies: [
                "WasmKit",
                "WasmKitWASI",
                "GDBRemoteProtocol",
            ],
            exclude: ["LICENSE.txt"]
        ),
    ])

    cliCommandsTarget.dependencies.append(contentsOf: [
        .target(name: "GDBRemoteProtocol", condition: .when(traits: ["WasmDebuggingSupport"])),
        .target(name: "WasmKitGDBHandler", condition: .when(traits: ["WasmDebuggingSupport"])),
    ])
#endif
