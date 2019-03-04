// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "WAKit",
    products: [
        .library(
            name: "WAKit",
            targets: ["WAKit"]
        ),
        .library(
            name: "Parser",
            targets: ["Parser"]
        ),
        .executable(
            name: "wakit",
            targets: ["CLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "WAKit",
            dependencies: ["Parser", "Tagged"],
            path: "./Sources/WAKit"
        ),
        .testTarget(
            name: "WAKitTests",
            dependencies: ["WAKit"],
            path: "./Tests/WAKitTests"
        ),
        .target(
            name: "Parser",
            dependencies: [],
            path: "./Sources/Parser"
        ),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"],
            path: "./Tests/ParserTests"
        ),
        .target(
            name: "CLI",
            dependencies: ["WAKit"],
            path: "./Sources/CLI"
        ),
    ],
    swiftLanguageVersions: [4]
)
