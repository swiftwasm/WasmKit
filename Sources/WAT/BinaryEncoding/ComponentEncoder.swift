#if ComponentModel
struct ComponentEncoder {
    var underlying = Encoder()

    mutating func writeHeader() {
        underlying.output.append(contentsOf: [
            0x00, 0x61, 0x73, 0x6D,  // magic
            0x0d, 0x00, // version
            0x01, 0x00, // layer
        ])
    }

    mutating func encode(_ component: ComponentWat, options: EncodeOptions) throws {
        try underlying.section(id: 1) {
            for var module in component.modulesMap {
                $0.output.append(contentsOf: try WAT.encode(module: &module.wat, options: options))
            }
        }

        try underlying.section(id: 2) {
            $0.encodeVector(component.coreInstancesMap, encodeElement: {
                $1.encode($0.id?.value ?? "")
            })
        }
    }
}
#endif
