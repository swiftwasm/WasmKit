import Testing

@testable import WASI

@Suite
struct GuestPathTests {
    @Test
    func parsing() {
        #expect(GuestPath("").isEmpty)
        #expect(GuestPath("").components.isEmpty)
        #expect(!GuestPath("").isAbsolute)

        #expect(GuestPath("/").isAbsolute)
        #expect(GuestPath("/").components.isEmpty)
        #expect(!GuestPath("/").isEmpty)

        #expect(GuestPath("a/b/c").components == [.regular("a"), .regular("b"), .regular("c")])
        #expect(!GuestPath("a/b/c").isAbsolute)
        #expect(GuestPath("/a/b").isAbsolute)
        #expect(GuestPath("/a/b").components == [.regular("a"), .regular("b")])

        // "." and ".." are structural components.
        #expect(GuestPath("./a/../b").components == [.currentDirectory, .regular("a"), .parentDirectory, .regular("b")])

        // Redundant and trailing separators are dropped; a trailing "/"'s
        // directory requirement is handled by callers before parsing.
        #expect(GuestPath("a//b/").components == [.regular("a"), .regular("b")])
        #expect(GuestPath("//a").isAbsolute)
        #expect(GuestPath("//a").components == [.regular("a")])

        // Guest paths are always '/'-separated: backslash is a name byte,
        // never a separator.
        #expect(GuestPath("a\\b").components == [.regular("a\\b")])
    }

    @Test
    func roundTrip() {
        #expect(GuestPath("a/b/c").string == "a/b/c")
        #expect(GuestPath("/a/b").string == "/a/b")
        #expect(GuestPath("a//b/").string == "a/b")
        #expect(GuestPath("/").string == "/")
        #expect(GuestPath("").string == "")
        #expect(GuestPath("../x/./y").string == "../x/./y")
    }

    @Test
    func lastComponentOperations() {
        var path = GuestPath("a/b")
        #expect(path.removeLastComponent() == .regular("b"))
        #expect(path.removeLastComponent() == .regular("a"))
        #expect(path.removeLastComponent() == nil)

    }
}
