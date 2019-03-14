import Parser
import SwiftCLI
import WAKit

let main = CLI(name: "wakit")
main.commands = [RunCommand(), SpecTestCommand()]
main.goAndExit()
