// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Experimental",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Exp1"),
        .executableTarget(name: "Exp2", dependencies: ["_CShim"]),
        .executableTarget(name: "Exp3", dependencies: ["_CShim"]),
        .executableTarget(name: "Exp4"),
        .executableTarget(name: "Exp5"),
        .executableTarget(name: "Exp6"),
        .executableTarget(name: "Exp7", dependencies: ["_CShim"]),
        .target(name: "_CShim"),
    ]
)
