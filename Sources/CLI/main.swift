import SwiftCLI
import Parser
import WAKit

let main = CLI(name: "wakit")
main.commands = [SpecTestCommand()]
main.goAndExit()
