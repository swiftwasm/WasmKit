// swift-tools-version:4.0

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
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.1.4"),
        .package(url: "https://github.com/Nike-Inc/Willow.git", from: "5.1.0"),
    ],
    targets: [
        .target(
            name: "WAKit",
            dependencies: ["LEB"],
            path: "./Sources/WAKit"
        ),
        .testTarget(
            name: "WAKitTests",
            dependencies: ["WAKit"],
            path: "./Tests/WAKitTests"
        ),
        .target(
            name: "CLI",
            dependencies: ["WAKit", "SwiftCLI", "Rainbow", "Willow"],
            path: "./Sources/CLI"
        ),
    ],
    swiftLanguageVersions: [4]
)
