import ArgumentParser
import WasmParser

package struct WasmFeatureOptions: ParsableArguments {
    package init() {}

    @Option(name: .long, help: "Enable a WebAssembly feature (threads, memory64, simd, tail-call, reference-types)")
    var enableFeature: [String] = []

    @Option(name: .long, help: "Disable a WebAssembly feature")
    var disableFeature: [String] = []

    private static let featuresByName: [String: WasmFeatureSet] = [
        "threads": .threads,
        "memory64": .memory64,
        "reference-types": .referenceTypes,
        "tail-call": .tailCall,
        "simd": .simd,
    ]

    package var wasmFeatures: WasmFeatureSet {
        get throws {
            var features: WasmFeatureSet = .default
            for name in enableFeature {
                guard let feature = Self.featuresByName[name] else {
                    throw ValidationError("Unknown feature: '\(name)'. Available: \(Self.featuresByName.keys.sorted().joined(separator: ", "))")
                }
                features.insert(feature)
            }
            for name in disableFeature {
                guard let feature = Self.featuresByName[name] else {
                    throw ValidationError("Unknown feature: '\(name)'. Available: \(Self.featuresByName.keys.sorted().joined(separator: ", "))")
                }
                features.remove(feature)
            }
            return features
        }
    }
}
