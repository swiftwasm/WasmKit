// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CrossModulePackage",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "WasmKit", path: "../../../../")
    ],
    targets: [
        .target(name: "ExternalLib"),
        .target(
            name: "CrossModuleAPI",
            dependencies: ["ExternalLib", .product(name: "WITMarker", package: "WasmKit")]
        ),
        .target(
            name: "CrossModuleFunc",
            dependencies: ["ExternalLib", .product(name: "WITMarker", package: "WasmKit")]
        ),
    ]
)
