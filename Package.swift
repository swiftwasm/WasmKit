// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "WAKit",
    products: [
        .library(
            name: "WAKit",
            targets: ["WAKit"]),
        .library(
            name: "Parser",
            targets: ["Parser"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "WAKit",
            dependencies: ["Parser"],
            path: "./Sources/WAKit"
        ),
        .testTarget(
            name: "WAKitTests",
            dependencies: ["WAKit"],
            path: "./Tests/WAKitTests"),
        .target(
            name: "Parser",
            dependencies: [],
            path: "./Sources/Parser"
        ),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"],
            path: "./Tests/ParserTests"),
    ],
    swiftLanguageVersions: [4]
)
