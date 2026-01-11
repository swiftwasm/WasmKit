// swift-tools-version:6.0

import PackageDescription

import class Foundation.ProcessInfo

let DarwinPlatforms: [Platform] = [.macOS, .iOS, .watchOS, .tvOS, .visionOS]

let package = Package(
    name: "WasmKit",
    platforms: [.macOS(.v10_13), .iOS(.v12)],
    products: [
        .library(name: "WasmKit", targets: ["WasmKit"]),
        .library(name: "WasmKitWASI", targets: ["WasmKitWASI"]),
        .library(name: "WASI", targets: ["WASI"]),
        .library(name: "WasmParser", targets: ["WasmParser"]),
        .library(name: "WAT", targets: ["WAT"]),
    ],
    targets: [
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

    ]
)

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-system", from: "1.5.0"),
    ]
} else {
    package.dependencies += [
        .package(path: "../swift-system"),
    ]
}
