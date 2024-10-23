// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "FuzzTesting",
    products: [
        // Discussion: Why we build libraries instead of executables linking libFuzzer?
        //
        // First, libclang_rt.fuzzer.a defines the main function for the fuzzing process
        // and object files given by the user are expected not to have a "main" function
        // to avoid conflicts.
        // Fortunately, SwiftPM asks the compiler frontend to define the main entrypoint as
        // `<module_name>_main` for testing executable targets (`-entry-point-function-name`)
        // so object files of `executableTarget` targets are capable of being linked with
        // libclang_rt.fuzzer.a.
        // However, at link-time, SwiftPM asks the linker to rename the `<module_name>_main`
        // symbol back to `main` for the final executable (`--defsym main=<module_name>_main`)
        // and gold linker respects the renamed "main" symbol rather than the one defined in
        // libclang_rt.fuzzer.a, so the final executable does not start the fuzzing process.
        //
        // Instead of relying on the SwiftPM's linking process, we build libraries defining
        // fuzzing target functions and manually link them with fuzzing runtime libraries.
        .library(name: "FuzzTranslator", type: .static, targets: ["FuzzTranslator"]),
        .library(name: "FuzzExecute", type: .static, targets: ["FuzzExecute"]),
        // FuzzDifferential is not a libFuzzer-based target, so we build it as an executable.
        .executable(name: "FuzzDifferential", targets: ["FuzzDifferential"]),
    ],
    dependencies: [
        .package(path: "../"),
    ],
    targets: [
        .target(name: "FuzzTranslator", dependencies: [
            "WasmKitFuzzing",
            .product(name: "WasmKit", package: "WasmKit")
        ]),
        .target(name: "FuzzExecute", dependencies: [
            "WasmKitFuzzing",
            .product(name: "WasmKit", package: "WasmKit"),
        ]),
        .executableTarget(name: "FuzzDifferential", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
            .product(name: "WAT", package: "WasmKit"),
            "WasmCAPI",
        ]),
        .target(name: "WasmCAPI"),
        .target(name: "WasmKitFuzzing", dependencies: [
            .product(name: "WasmKit", package: "WasmKit"),
        ])
    ]
)
