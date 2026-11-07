# RFC: LLVM Backend for native code generation in WasmKit
## Motivation

While current WasmKit interpreter design is highly optimized, it doesn't scale for running large comprehensive test suites on Wasm that take 20-30 mins on host platforms compiled to native CPU (e.g. swiftlang/swift-collections package is one prominent example). We find that running the same test suite compiled to Wasm with the WasmKit interpreter is at least 5x slower.

This limitation is fundamental to interpreters, even when those rely on an optimized internal VM instruction set. For every VM instruction the real CPU executes at least 3 native instructions:

1. fetching VM instruction from memory,
2. branching to executable memory address that contains VM instruction implementation
3. executing the instruction implementation.

Even with the most optimized interpreter, we don't think sufficient proportion of Swift packages would adopt it for executing their test suites compiled Wasm if it's at least 3x slower than test suites compiled to native binary code.
This is a real and a high priority roadblock on our path to ensuring that Swift packages ecosystem is thoroughly tested on Wasm. Requiring other non-interpreter runtimes to be installed to get better performance is a burden for package authors, and also prevents WasmKit from gaining broader adoption.

### Proposed Solution

Generating native code from Wasm either ahead-of-time (AOT) or just-in-time (JIT) is an obvious solution, but there are multiple ways to achieve this.

As WasmKit is distributed with the Swift toolchain and is included in toolchain's build process for major platforms like Linux and macOS, we're proposing LLVM as a native codegen backend. LLVM provides a great ecosystem of optimization, instrumentation, and debugging tools that Swift compiler engineers are familiar with.

A proof of concept is already available as a draft PR on the WasmKit repository and implements enough Wasm instructions to AOT compile and run a trivial Wasm binary that uses basic control flow (conditional branching and function calls).

Important to note that deprecating or removing the interpreter is not considered in this proposal. We also don't propose the LLVM backend to be mandatory in all build configurations of WasmKit. Not only the existing interpreter is easy to build, test, and extend, it serves as a reference implementation for the Wasm spec that the LLVM backend can use as a baseline. There are additional scenarios where the intepreter still remains the best option, e.g. on platforms where dlopen/dlsym or their platform-specific counterparts are not available, or for Wasm debugging purposes as discussed in "Wasm Debugging Support" section below.

### AOT vs JIT

We find that JIT APIs in LLVM are not as stable as AOT, and require significantly more effort to set up. While the prototype doesn't utilize JIT, it does not preclude any implementations of JIT in the future.

The existing LLVM backend prototype links a Wasm module into a dynamically shared library that WasmKit can dlopen/dlsym and make calls into. APIs for this are well known and generated dynamic libraries can be easily cached on the file system. A content-addressable storage that maps hashes of Wasm modules to already compiled dynamic libraries would ensure that unchanged Wasm modules are not repeatedly recompiled by the LLVM backend.

### Codegen Performance

We can rely on the fact that Wasm binaries are usually already well optimized, and running additional optimization passes in WasmKit's LLVM backend brings diminishing returns. Fast enough codegen can be achieved by disabling long-running passes that don't bring significant run time improvements to the generated code. In combination with LLVM's FastISel and caching of codegen results from unchanged Wasm modules (or more granular caching from unchanged Wasm functions), we anticipate significant end-to-end performance improvements when compared to the existing WasmKit interpreter.

JITing Wasm functions lazily on demand can be considered for use cases that require further performance optimizations, but as improving performance for large test suites is a high priority, we think that it's worth considering simpler AOT solution at first for this use case.

### Wasm Debugging Support

To support debugging of Wasm modules with WasmKit, we initially considered transforming custom DWARF sections embedded in Wasm modules into DWARF sections in produced native object files. This transformation requires extra care to transform Wasm-specific DWARF extensions into DWARF for native architectures, while introducing significant divergence from the existing Wasm interpreting debugger implementation. Debugging native code introduces a significantly different workflow from the existing remote debugging setup. In the short to medium term, we propose the interpreting debugger to stay as the default debugging tool for WasmKit users. In the long term, a hybrid approach can be considered, where LLVM backend branches into the interpreter only for functions that have breakpoints enabled in them.

## Alternatives Considered

### Preserving Status Quo

While verifying that Swift packages build for Wasm, we don't think that not executing tests is sufficient to declare that Wasm is fully supported by a package. Installing different runtimes has been covered in the "Motivation" section as an unnecessary burden for adoption when compared to the proposed solution.

### Alternative Codegen Backends

As LLVM is the established and only backend for the Swift toolchain, we're currently not considering alternative backends for a few reasons. An alternative backend would introduce additional dependencies to the Swift toolchain, while WasmKit LLVM backend reuses only existing dependencies. As we'd like to build WasmKit with native codegen together with the Swift toolchain, we need to consider additional build time very carefully, and LLVM backend allows us to reuse a huge amount of existing build products, while the AOT Wasm → LLVM IR translation layer is relative small in builds in under a minute. We don't think that a comparable setup is achievable with alternative codegen backends.
