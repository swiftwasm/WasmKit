// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WasmKitDevUtils",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "WasmKitDevUtils", path: "Sources"),
    ]
)
