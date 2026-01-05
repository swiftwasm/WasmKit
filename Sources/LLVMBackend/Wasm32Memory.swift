import Darwin

package struct Wasm32Memory: ~Copyable {
    // let memory: UnsafeMutableRawPointer

    init() {
        // 1. fd = open(tmpfile)
        // 2. unlink(tmpfile)
        // 3. memory = mmap(nullptr, 8GB (4GB base + 4GB offset), PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0)
        // 4. fruncate(fd) to initialize or handle `memory.grow`
    }
}
