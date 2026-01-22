#if ComponentModel

    import BasicContainers
    import WasmParser
    import WasmTypes

    struct ComponentIndex: RawRepresentable {
        let rawValue: Int
    }

    struct ComponentInstanceIndex: RawRepresentable {
        let rawValue: Int
    }

    struct CanonIndex: RawRepresentable {
        let rawValue: Int
    }

#endif
