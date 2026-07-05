// swift-tools-version:6.3
import PackageDescription

let package = Package(
    name: "embedded-wat",
    platforms: [.macOS(.v15), .iOS(.v18)],
    dependencies: [
        .package(path: "../../", traits: [])
    ],
    targets: [
        .executableTarget(
            name: "embedded-wat",
            dependencies: [
                .product(name: "WAT", package: "WasmKit")
            ]
        )
    ]
)
