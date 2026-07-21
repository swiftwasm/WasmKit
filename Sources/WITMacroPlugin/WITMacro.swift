import SwiftSyntax
import SwiftSyntaxMacros

/// Marker for `@WIT`. The extractor reads the attribute syntactically and never expands it, so `[]` is intentional.
public struct WITMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
