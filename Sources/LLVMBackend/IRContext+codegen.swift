import LLVMInterop
import WasmTypes

extension IRContext {
    func codegen(resultType: [ValueType]) -> IRType {
        switch resultType.count {
        case 0:
            return self.__voidTypeUnsafe()
        case 1:
            return codegen(type: resultType[0])
        default:
            var types = IRTypeVector()
            for t in resultType {
                types.push_back(codegen(type: t)._t)
            }
            return self.__structTypeUnsafe(types)
        }
    }

    func codegen(type: ValueType) -> IRType {
        switch type {
        case .i32:
            self.__i32TypeUnsafe()
        case .i64:
            self.__i64TypeUnsafe()
        case .f32:
            self.__f32TypeUnsafe()
        case .f64:
            self.__f64TypeUnsafe()
        case .v128, .ref(_):
            fatalError()
        }
    }

    func codegen(functionType: FunctionType) -> IRFunctionType {
        var parameterTypes = IRTypeVector()
        for parameterType in functionType.parameters {
            parameterTypes.push_back(codegen(type: parameterType)._t)
        }

        return self.__functionTypeUnsafe(parameterTypes, codegen(resultType: functionType.results))
    }
}
