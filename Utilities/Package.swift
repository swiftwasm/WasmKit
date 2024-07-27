// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WasmKitDevUtils",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "WasmKitDevUtils", path: "Sources"),
    ]
)
