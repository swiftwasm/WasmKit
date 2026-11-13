import ArgumentParser
import CLICommands
import Foundation
import Testing
import WAT

@Suite struct Wasm2watCommandTests {
    static let multiMemoryModule = "(module (memory 1) (memory 1) (func (result i32) i32.const 0 i32.load 1))"
    static let multiMemoryText = """
        (module
          (type (;0;) (func (result i32)))
          (func (;0;) (type 0) (result i32)
            i32.const 0
            i32.load 1
          )
          (memory (;0;) 1)
          (memory (;1;) 1)
        )

        """

    /// The command enables every feature, so a multi-memory module needs no flag.
    @Test func writesMultiMemoryTextToTheOutputPathWithoutFlags() throws {
        try PreopenFixture.withProbeDirectory { directory in
            let input = directory.appendingPathComponent("multi-memory.wasm")
            let output = directory.appendingPathComponent("multi-memory.wat")
            try Data(wat2wasm(Self.multiMemoryModule, features: .all)).write(to: input)
            let command = try Wasm2wat.parse([input.path, "-o", output.path])
            try command.run()
            #expect(try String(contentsOf: output, encoding: .utf8) == Self.multiMemoryText)
        }
    }
}
