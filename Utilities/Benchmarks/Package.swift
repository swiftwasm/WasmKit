// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WasmKitBenchmarks",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(name: "WasmKit", path: "../.."),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.92.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.2.1"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.6.4"),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.29.8"),
    ],
    targets: [
        .executableTarget(
            name: "WasmParserBenchmark",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "WasmKit", package: "WasmKit"),
                .product(name: "WAT", package: "WasmKit"),
                .product(name: "_NIOFileSystem", package: "swift-nio"),
            ],
            path: "Benchmarks/WasmParserBenchmark",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
    ]
)
