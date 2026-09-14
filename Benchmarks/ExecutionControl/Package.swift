// swift-tools-version: 6.3

import Foundation
import PackageDescription

let enginePath = ProcessInfo.processInfo.environment["WASMKIT_BENCH_ENGINE"] ?? "../.."
let controls = ProcessInfo.processInfo.environment["WASMKIT_BENCH_CONTROL_API"] != "0"
let package = Package(
    name: "ExecutionControlBenchmark",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "engine-bench", targets: ["EngineBench"])],
    dependencies: [
        .package(name: "WasmKit", path: enginePath),
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.8.2"),
    ],
    targets: [
        .executableTarget(
            name: "EngineBench",
            dependencies: [
                .product(name: "WasmKit", package: "WasmKit"),
                .product(name: "WAT", package: "WasmKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: (controls ? [.define("CONTROLLED")] : []) + [
                .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])
            ])
    ],
    swiftLanguageModes: [.v6]
)
