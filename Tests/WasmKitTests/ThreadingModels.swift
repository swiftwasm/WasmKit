import WasmKit

/// The platform's default threading model, and token threading where that isn't the default.
let testedThreadingModels: [EngineConfiguration.ThreadingModel] = {
    let defaultModel = EngineConfiguration().threadingModel
    return defaultModel == .token ? [.token] : [defaultModel, .token]
}()
