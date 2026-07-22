// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PluginSmokePackage",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "WasmKit", path: "../../../../")
    ],
    targets: [
        .target(
            name: "PluginSmokeModule",
            dependencies: [.product(name: "WITMarker", package: "WasmKit")]
        )
    ]
)
