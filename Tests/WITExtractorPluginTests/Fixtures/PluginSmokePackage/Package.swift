// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PluginSmokePackage",
    dependencies: [
        .package(path: "../../../../"),
    ],
    targets: [
        .target(name: "PluginSmokeModule"),
    ]
)
