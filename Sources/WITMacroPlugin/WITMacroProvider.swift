import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct WITMacroProvider: CompilerPlugin {
    let providingMacros: [Macro.Type] = [WITMacro.self]
}
