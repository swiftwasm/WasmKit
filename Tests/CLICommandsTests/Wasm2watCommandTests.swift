import ArgumentParser
import CLICommands
import Foundation
import Testing
import WAT

@Suite struct Wasm2watCommandTests {
    @Test func decodesEveryProposalWithoutFlags() throws {
        try PreopenFixture.withProbeDirectory { directory in
            let input = directory.appendingPathComponent("multi-memory.wasm")
            let output = directory.appendingPathComponent("multi-memory.wat")
            let binary = try wat2wasm(
                "(module (memory 1) (memory 1) (func (result i32) i32.const 0 i32.load 1))", features: .all)
            try Data(binary).write(to: input)
            let command = try Wasm2wat.parse([input.path, "-o", output.path])
            try command.run()
            #expect(
                try String(contentsOf: output, encoding: .utf8) == """
                    (module
                      (type (;0;) (func (result i32)))
                      (func (;0;) (type 0) (result i32)
                        i32.const 0
                        i32.load 1
                      )
                      (memory (;0;) 1)
                      (memory (;1;) 1)
                    )

                    """)
        }
    }
}
