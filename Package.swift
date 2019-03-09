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
        .package(url: "https://github.com/akkyie/SwiftLEB", from: "0.1.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.1.4"),
    ],
    targets: [
        .target(
            name: "WAKit",
            dependencies: ["Parser", "Tagged", "LEB"],
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
            dependencies: ["WAKit", "SwiftCLI", "Rainbow"],
            path: "./Sources/CLI"
        ),
    ],
    swiftLanguageVersions: [4]
)
