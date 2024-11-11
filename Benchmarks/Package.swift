// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Benchmarks",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(name: "WasmKit", path: "../"),
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
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
