// swift-tools-version:5.8

import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
    name: "WasmKit",
    platforms: [.macOS(.v10_13), .iOS(.v12)],
    products: [
        .library(
            name: "WasmKit",
            targets: ["WasmKit"]
        ),
        .library(
            name: "WasmParser",
            targets: ["WasmParser"]
        ),
        .executable(
            name: "wasmkit-cli",
            targets: ["CLI"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "CLI",
            dependencies: [
                "WasmKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SystemPackage", package: "swift-system"),
            ],
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "WasmTypes",
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "WasmKit",
            dependencies: [
                "WasmParser",
                "WasmTypes",
                .product(name: "SystemPackage", package: "swift-system"),
            ],
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "WasmParser",
            dependencies: [
                "WasmTypes",
                .product(name: "SystemPackage", package: "swift-system"),
            ],
            exclude: ["CMakeLists.txt"]
        ),
        .executableTarget(
            name: "Spectest",
            dependencies: [
                "WasmKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SystemPackage", package: "swift-system"),
            ]
        ),
        .testTarget(
            name: "WasmKitTests",
            dependencies: ["WasmKit"]
        ),
        .testTarget(
            name: "WasmParserTests",
            dependencies: ["WasmParser"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
        .package(url: "https://github.com/apple/swift-system", .upToNextMinor(from: "1.2.1")),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-format.git", from: "510.1.0"),
    ]
} else {
    package.dependencies += [
        .package(path: "../swift-argument-parser"),
        .package(path: "../swift-system"),
    ]
}

#if !os(Windows)
    // Add WASI-related products and targets
    package.products.append(contentsOf: [
        .library(
            name: "WasmKitWASI",
            targets: ["WasmKitWASI"]
        ),
        .library(
            name: "WASI",
            targets: ["WASI"]
        ),
    ])
    package.targets.append(contentsOf: [
        .target(
            name: "WASI",
            dependencies: ["WasmTypes", "SystemExtras"],
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "WasmKitWASI",
            dependencies: ["WasmKit", "WASI"],
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "SystemExtras",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system")
            ],
            exclude: ["CMakeLists.txt"]
        ),
        .testTarget(
            name: "WASITests",
            dependencies: ["WASI"]
        ),
        .testTarget(
            name: "WASITests",
            dependencies: ["WASI"]
        ),
    ])
    let targetDependenciesToAdd = [
        "CLI": ["WasmKitWASI"],
        "WasmKit": ["SystemExtras"],
    ]
    for (targetName, dependencies) in targetDependenciesToAdd {
        if let target = package.targets.first(where: { $0.name == targetName }) {
            target.dependencies += dependencies.map { .target(name: $0) }
        } else {
            fatalError("Target \(targetName) not found!?")
        }
    }

    // Add WIT-related products and targets
    package.products.append(contentsOf: [
        .library(name: "WIT", targets: ["WIT"]),
        .library(name: "_CabiShims", targets: ["_CabiShims"]),
        .plugin(name: "WITOverlayPlugin", targets: ["WITOverlayPlugin"]),
        .plugin(name: "WITExtractorPlugin", targets: ["WITExtractorPlugin"]),
    ])

    package.targets.append(contentsOf: [
        .target(name: "WIT"),
        .testTarget(name: "WITTests", dependencies: ["WIT"]),
        .target(name: "WITOverlayGenerator", dependencies: ["WIT"]),
        .target(name: "_CabiShims"),
        .plugin(name: "WITOverlayPlugin", capability: .buildTool(), dependencies: ["WITTool"]),
        .plugin(name: "GenerateOverlayForTesting", capability: .buildTool(), dependencies: ["WITTool"]),
        .testTarget(
            name: "WITOverlayGeneratorTests",
            dependencies: ["WITOverlayGenerator", "WasmKit", "WasmKitWASI"],
            exclude: ["Fixtures", "Compiled", "Generated"],
            plugins: [.plugin(name: "GenerateOverlayForTesting")]
        ),
        .target(name: "WITExtractor"),
        .testTarget(
            name: "WITExtractorTests",
            dependencies: ["WITExtractor", "WIT"]
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
        .executableTarget(
            name: "WITTool",
            dependencies: [
                "WIT",
                "WITOverlayGenerator",
                "WITExtractor",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ])
#endif
