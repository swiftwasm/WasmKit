// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FuzzTesting",
    products: [
        .library(name: "FuzzTranslator", type: .static, targets: ["FuzzTranslator"]),
        .library(name: "FuzzExecute", type: .static, targets: ["FuzzExecute"]),
    ],
    dependencies: [
        .package(path: "../"),
    ],
    targets: [
        .target(name: "FuzzTranslator", dependencies: [
            .product(name: "WasmKit", package: "WasmKit")
        ]),
        .target(name: "FuzzExecute", dependencies: [
            .product(name: "WasmKit", package: "WasmKit")
        ]),
    ]
)

for target in package.targets {
    target.swiftSettings = [.unsafeFlags(["-Xfrontend", "-sanitize=fuzzer,address"])]
}
