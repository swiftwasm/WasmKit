// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "Examples",
    platforms: [.macOS(.v15), .iOS(.v18)],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(name: "Factorial", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WAT", package: "WasmKit")
        ]),
        .executableTarget(name: "PrintAdd", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WAT", package: "WasmKit")
        ]),
        .executableTarget(name: "StringPassing", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WAT", package: "WasmKit")
        ]),
        .executableTarget(name: "HostCallSuspension", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WAT", package: "WasmKit")
        ]),
        .executableTarget(name: "WASI-Hello", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WasmKitWASI", package: "WasmKit"),
            .product(name: "WAT", package: "WasmKit"),
        ]),
    ]
)
