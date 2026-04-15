import WAT

@main
struct Entrypoint {
    static func main() {
        var watString = ""
        while let line = readLine() {
            if !watString.isEmpty {
                watString += "\n"
            }
            watString += line
        }
        guard !watString.isEmpty else { return }

        do throws(WatParserError) {
            let bytes = try wat2wasm(watString)
            for byte in bytes {
                print("0x" + String(byte, radix: 16))
            }
        } catch {
            print(error)
        }
    }
}
