import Testing

import WASI

@Test func joinGuestPathContract() {
    #expect(MemoryFileSystem.joinGuestPath("/", "f.txt") == "/f.txt")  // root base
    #expect(MemoryFileSystem.joinGuestPath("/a", "b") == "/a/b")  // common case
    #expect(MemoryFileSystem.joinGuestPath("/sandbox/", "foo") == "/sandbox/foo")  // trailing-slash base collapses to one "/"
}
