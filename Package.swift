// swift-tools-version:6.0

import PackageDescription

import class Foundation.ProcessInfo

let DarwinPlatforms: [Platform] = [.macOS, .iOS, .watchOS, .tvOS, .visionOS]

let package = Package(
    name: "WasmKit",
    platforms: [.macOS(.v10_13), .iOS(.v12)],
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
    targets: [
        .executableTarget(
            name: "CLI",
            dependencies: [
                "WAT",
                "WasmKit",
                "WasmKitWASI",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SystemPackage", package: "swift-system"),
            ],
            exclude: ["CMakeLists.txt"]
        ),

        .target(
            name: "WasmKit",
            dependencies: [
                "_CWasmKit",
                "WasmParser",
                "WasmTypes",
                "SystemExtras",
                .product(name: "SystemPackage", package: "swift-system"),
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
            exclude: ["ExtraSuite"]
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
                .product(name: "SystemPackage", package: "swift-system"),
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
            dependencies: ["WasmTypes", "SystemExtras"],
            exclude: ["CMakeLists.txt"]
        ),
        .testTarget(name: "WASITests", dependencies: ["WASI", "WasmKitWASI"]),

        .target(
            name: "SystemExtras",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
                .target(name: "CSystemExtras", condition: .when(platforms: [.wasi])),
            ],
            exclude: ["CMakeLists.txt"],
            swiftSettings: [
                .define("SYSTEM_PACKAGE_DARWIN", .when(platforms: DarwinPlatforms))
            ]
        ),

        .target(name: "CSystemExtras"),

        .executableTarget(
            name: "WITTool",
            dependencies: [
                "WIT",
                "WITOverlayGenerator",
                "WITExtractor",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        .target(name: "WIT"),
        .testTarget(name: "WITTests", dependencies: ["WIT"]),

        .target(name: "WITOverlayGenerator", dependencies: ["WIT"]),
        .target(name: "_CabiShims"),

        .target(name: "WITExtractor"),
        .testTarget(name: "WITExtractorTests", dependencies: ["WITExtractor", "WIT"]),
    ]
)

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "release/1.6.2"),
        .package(url: "https://github.com/apple/swift-system", from: "1.5.0"),
    ]
} else {
    package.dependencies += [
        .package(path: "../swift-argument-parser"),
        .package(path: "../swift-system"),
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
    ])
#endif
