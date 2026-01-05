import WasmKit

package final class LLInstance {
    package init() {}

    package let exports = LLExports()

    package func export(_ name: String) -> LLExternalValue {
        fatalError()
    }

    package func exportedFunction(name: String) -> LLFunction? {
        fatalError()
    }
}

package struct LLExports: ~Copyable {
}

package struct LLFunction {
    package func invoke(_ args: [Value]) -> [Value] {
        fatalError()
    }
}
package struct LLGlobal {
    package var value: Value { fatalError() }
}
package struct LLMemory {}
package struct LLTable {}

package enum LLExternalValue {
    case function(LLFunction)
    case global(LLGlobal)
    case memory(LLMemory)
    case table(LLTable)
}
