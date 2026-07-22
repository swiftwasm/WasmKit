/// Marks a declaration for extraction into a WIT interface by the WITExtractor tool.
///
/// Expands to nothing: WITExtractor detects `@WIT` by parsing source, not by expansion. Backed by
/// `Builtin.ExternalMacro` so the marker needs no macro plugin.
@attached(peer)
public macro WIT() = Builtin.ExternalMacro
