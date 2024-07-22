// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "PluginSmokePackage",
    dependencies: [
        .package(path: "../../../../")
    ],
    targets: [
        .target(name: "PluginSmokeModule")
    ]
)
