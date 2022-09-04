// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "WAKit",
    products: [
        .library(
            name: "WAKit",
            targets: ["WAKit"]
        ),
        .executable(
            name: "wakit",
            targets: ["CLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/akkyie/SwiftLEB", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.2"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.1.4"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "WAKit",
            dependencies: [.product(name: "LEB", package: "SwiftLEB")]
        ),
        .testTarget(
            name: "WAKitTests",
            dependencies: ["WAKit"]
        ),
        .target(
            name: "CLI",
            dependencies: [
                "WAKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Rainbow",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SystemPackage", package: "swift-system")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
