// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Swasm",
    products: [
		.library(
			name: "Swasm",
			targets: ["Swasm"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Swasm",
            dependencies: []),
        .testTarget(
            name: "SwasmTests",
            dependencies: ["Swasm"]),
    ],
    swiftLanguageVersions: [4]
)
