#if canImport(os.signpost)
import os.signpost

/// A `RuntimeInterceptor` that emits signposts for each function call
/// - Note: This interceptor is available only on Apple platforms
@_documentation(visibility: internal)
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public class SignpostTracer: RuntimeInterceptor {
    /// The `OSSignposter` to use for emitting signposts
    let signposter: OSSignposter
    /// The stack of signpost states for each function call in progress
    private var signpostStates: [OSSignpostIntervalState] = []

    /// Initialize a new `SignpostProfiler` with the given `OSSignposter`
    /// - Parameter signposter: The `OSSignposter` to use for emitting signposts
    public init(signposter: OSSignposter) {
        self.signposter = signposter
    }

    /// The name of the function call signpost
    private var functionCallName: StaticString {
        "Function Call"
    }

    public func onEnterFunction(_ function: Function, store: Store) {
        let name = store.nameRegistry.symbolicate(function.handle)
        let state = self.signposter.beginInterval(functionCallName, "\(name)")
        signpostStates.append(state)
    }

    public func onExitFunction(_ function: Function, store: Store) {
        let state = signpostStates.popLast()!
        self.signposter.endInterval(functionCallName, state)
    }
}
#endif