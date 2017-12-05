// swift-tools-version:4.0

import PackageDescription

public let package = Package(
    name: "Swasm",
    products: [
        .library(
            name: "Swasm",
            targets: ["Swasm"]),
        ],
    dependencies: [
        .package(url: "https://github.com/akkyie/antlr4-swift.git", from: "4.0.0"),
        .package(url: "https://github.com/antitypical/Result.git", from: "3.2.0"),
        ],
    targets: [
        .target(
            name: "Swasm",
            dependencies: ["Antlr4", "Result"]),
        .testTarget(
            name: "SwasmTests",
            dependencies: ["Swasm"]),
        ],
    swiftLanguageVersions: [4]
)
