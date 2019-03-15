import SwiftCLI

let main = CLI(name: "wakit")
main.commands = [RunCommand(), SpecTestCommand()]
main.goAndExit()
