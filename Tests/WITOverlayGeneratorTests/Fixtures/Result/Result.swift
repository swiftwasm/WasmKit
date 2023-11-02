struct ResultTestWorldExportsImpl: ResultTestWorldExports {
    static func roundtripResult(v: Result<Void, ComponentError<Void>>) -> Result<Void, ComponentError<Void>> {
        return v
    }
    static func roundtripResultOk(v: Result<UInt32, ComponentError<Void>>) -> Result<UInt32, ComponentError<Void>> {
        return v
    }
    static func roundtripResultOkError(v: Result<UInt32, ComponentError<String>>) -> Result<UInt32, ComponentError<String>> {
        return v
    }
    static func roundtripResultError(v: Result<Void, ComponentError<String>>) -> Result<Void, ComponentError<String>> {
        return v
    }
}
