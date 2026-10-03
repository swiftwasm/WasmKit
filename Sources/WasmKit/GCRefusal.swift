import WasmParser

extension HeapType {
    func checkImplemented() throws(WasmKitError) {
        switch self {
        // `implementedFunctionTypes()` refuses every type definition except a function type.
        case .concrete, .abstract(.funcRef), .abstract(.externRef), .abstract(.exnRef):
            return
        case .abstract(.any), .abstract(.eq), .abstract(.i31), .abstract(.structRef), .abstract(.arrayRef),
            .abstract(.noneRef), .abstract(.noExtern), .abstract(.noFunc), .abstract(.noExn):
            throw WasmKitError("heap type \(self) is not implemented yet")
        }
    }
}

extension ValueType {
    func checkImplemented() throws(WasmKitError) {
        if case .ref(let type) = self {
            try type.heapType.checkImplemented()
        }
    }
}

extension FunctionType {
    func checkImplemented() throws(WasmKitError) {
        for type in parameters {
            try type.checkImplemented()
        }
        for type in results {
            try type.checkImplemented()
        }
    }
}

extension ConstExpression {
    func checkImplemented() throws(WasmKitError) {
        for case .refNull(let type) in self {
            try type.checkImplemented()
        }
    }
}

extension Array where Element == RecursiveGroup {
    func implementedFunctionTypes() throws(WasmKitError) -> [FunctionType] {
        try map { (group) throws(WasmKitError) in
            guard group.types.count == 1, let type = group.types.first, type.isFinal, type.supertypes.isEmpty,
                case .function(let functionType) = type.body
            else {
                throw WasmKitError("GC type definitions are not implemented yet")
            }
            try functionType.checkImplemented()
            return functionType
        }
    }
}

extension Array where Element == Import {
    func checkImplemented() throws(WasmKitError) {
        for entry in self {
            switch entry.descriptor {
            case .table(let type): try type.elementType.heapType.checkImplemented()
            case .global(let type): try type.valueType.checkImplemented()
            case .function, .memory, .tag: break
            }
        }
    }
}

extension Array where Element == WasmParser.Table {
    func checkImplemented() throws(WasmKitError) {
        for table in self {
            try table.type.elementType.heapType.checkImplemented()
            try table.initializer?.checkImplemented()
        }
    }
}

extension Array where Element == WasmParser.Global {
    func checkImplemented() throws(WasmKitError) {
        for global in self {
            try global.type.valueType.checkImplemented()
            try global.initializer.checkImplemented()
        }
    }
}

extension Array where Element == ElementSegment {
    func checkImplemented() throws(WasmKitError) {
        for element in self {
            try element.type.heapType.checkImplemented()
            for item in element.initializer {
                try item.checkImplemented()
            }
            if case .active(_, let offset) = element.mode {
                try offset.checkImplemented()
            }
        }
    }
}

extension Array where Element == Code {
    func checkImplemented() throws(WasmKitError) {
        for code in self {
            for local in code.locals {
                try local.checkImplemented()
            }
        }
    }
}

extension Array where Element == DataSegment {
    func checkImplemented() throws(WasmKitError) {
        for case .active(let segment) in self {
            try segment.offset.checkImplemented()
        }
    }
}
