import ArgumentParser
import WAT
import Foundation

struct Wat2wasm: ParsableCommand {
    @Argument var path: String
    @Option(name: .short) var output: String

    func run() throws {
        let bytes = try wat2wasm(String(contentsOfFile: path))
        try Data(bytes).write(to: URL(fileURLWithPath: output))
    }
}
