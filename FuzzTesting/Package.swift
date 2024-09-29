// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FuzzTesting",
    products: [
        .library(name: "FuzzTranslator", type: .static, targets: ["FuzzTranslator"]),
        .library(name: "FuzzExecute", type: .static, targets: ["FuzzExecute"]),
        .executable(name: "FuzzDifferential", targets: ["FuzzDifferential"]),
    ],
    dependencies: [
        .package(path: "../"),
    ],
    targets: [
        .target(name: "FuzzTranslator", dependencies: [
            .product(name: "WasmKit", package: "WasmKit")
        ]),
        .target(name: "FuzzExecute", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
        ]),
        .executableTarget(name: "FuzzDifferential", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WAT", package: "WasmKit"),
            "WasmCAPI",
        ]),
        .target(name: "WasmCAPI"),
    ]
)

let libFuzzerTargets = ["FuzzTranslator", "FuzzExecute"]

for target in package.targets {
    guard libFuzzerTargets.contains(target.name) else { continue }
    target.swiftSettings = [.unsafeFlags(["-Xfrontend", "-sanitize=fuzzer,address"])]
}
