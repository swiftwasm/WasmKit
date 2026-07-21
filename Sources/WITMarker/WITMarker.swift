/// Marks a declaration for extraction into a WIT interface by the WITExtractor tool.
///
/// Expands to nothing; WITExtractor detects `@WIT` by parsing source, not expansion.
@attached(peer)
public macro WIT() = #externalMacro(module: "WITMacroPlugin", type: "WITMacro")
