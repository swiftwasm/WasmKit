import WAT

@main
struct Entrypoint {
    static func main() {
        do throws(WatParserError) {
            let watString = readLine()
            print(
                wat2wasm(wat).map {
                    "0x\(String($0, radix: 16))"
                }
            )
        } catch {
            print(error.location)
        }
    }
}
