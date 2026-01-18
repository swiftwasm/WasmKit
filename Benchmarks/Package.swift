// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Benchmarks",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(name: "WasmKit", path: "../"),
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.92.2"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.6.4"),
    ]
)

// Benchmark of WishYouWereFast
package.targets += [
    .executableTarget(
        name: "WishYouWereFast",
        dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WasmKitWASI", package: "WasmKit"),
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Benchmarks/WishYouWereFast",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]

// Benchmark of MicroBench
package.targets += [
    .executableTarget(
        name: "MicroBench",
        dependencies: [
            .product(name: "WAT", package: "WasmKit"),
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WasmKitWASI", package: "WasmKit"),
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Benchmarks/MicroBench",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]

// Benchmark of MacroPlugin
package.targets += [
    .executableTarget(
        name: "MacroPlugin",
        dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WasmKitWASI", package: "WasmKit"),
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Benchmarks/MacroPlugin",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]

// Benchmark of WasmParser module
package.targets += [
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
