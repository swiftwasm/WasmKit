import SystemExtras
import SystemPackage
import WasmParser

#if os(Windows)
    import ucrt
#endif

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import Darwin
#elseif canImport(Musl)
    import Musl
#elseif canImport(Glibc)
    import Glibc
#endif

/// Parse a given file as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(filePath: FilePath, features: WasmFeatureSet = .default) throws -> Module {
    #if os(Windows)
        // TODO: Upstream `O_BINARY` to `SystemPackage
        let accessMode = FileDescriptor.AccessMode(
            rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_BINARY
        )
    #else
        let accessMode: FileDescriptor.AccessMode = .readOnly
    #endif
    let fileHandle = try FileDescriptor.open(filePath, accessMode)
    let size = Int(try fileHandle.seek(offset: 0, from: .end))
    _ = try fileHandle.seek(offset: 0, from: .start)

    #if (os(macOS) || os(Linux)) && (arch(x86_64) || arch(arm64))
        // Memory-map the file and parse it in place: pages fault in lazily as the parser walks the
        // module, overlapping I/O with parsing and avoiding an upfront whole-file copy. Byte ranges
        // the parser retains (function bodies) are copied out, so the mapping is released after parse.
        if size > 0, let stream = MmapByteStream(fileDescriptor: fileHandle, size: size) {
            return try withThrowing {
                try parseModule(stream: stream, features: features)
            } defer: {
                try fileHandle.close()
            }
        }
    #endif

    return try withThrowing {
        // Fallback: bulk-read the whole file into memory, then parse in-memory. Far faster than
        // streaming in small chunks for large modules (fewer read syscalls, no sliding-window churn).
        // Size the buffer up front so we read straight into it without an intermediate copy.
        let bytes = try [UInt8](unsafeUninitializedCapacity: size) { buffer, count in
            let raw = UnsafeMutableRawBufferPointer(buffer)
            var total = 0
            while total < size {
                let n = try fileHandle.read(into: UnsafeMutableRawBufferPointer(rebasing: raw[total...]))
                if n == 0 { break }
                total += n
            }
            count = total
        }
        return try parseWasm(bytes: bytes, features: features)
    } defer: {
        try fileHandle.close()
    }
}

#if (os(macOS) || os(Linux)) && (arch(x86_64) || arch(arm64))
    /// A `ByteStream` backed by a read-only memory-mapped file. Pages fault in lazily as the parser
    /// reads, so parsing overlaps with I/O instead of paying an upfront whole-file copy. Function bodies
    /// are handed out as zero-copy ranges of the mapping (see `consumeBody`); the mapping is owned by a
    /// shared ``ModuleBacking`` and unmapped once neither the stream nor any parsed body references it.
    final class MmapByteStream: ByteStream {
        let backing: ModuleBacking
        private let base: UnsafeRawPointer
        private let count: Int
        var currentIndex: Int

        init?(fileDescriptor: FileDescriptor, size: Int) {
            guard let mapped = mmap(nil, size, PROT_READ, MAP_PRIVATE, fileDescriptor.rawValue, 0),
                mapped != MAP_FAILED
            else {
                return nil
            }
            // Hint sequential access so the kernel reads ahead aggressively.
            _ = posix_madvise(mapped, size, POSIX_MADV_SEQUENTIAL)
            self.base = UnsafeRawPointer(mapped)
            self.count = size
            self.currentIndex = 0
            self.backing = ModuleBacking(
                buffer: UnsafeRawBufferPointer(start: mapped, count: size),
                unmap: munmap
            )
        }

        private func byte(at index: Int) -> UInt8 {
            base.load(fromByteOffset: index, as: UInt8.self)
        }

        @discardableResult
        func consumeAny() throws(WasmParserError) -> UInt8 {
            guard currentIndex < count else {
                throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
            }
            defer { currentIndex += 1 }
            return byte(at: currentIndex)
        }

        @discardableResult
        func consume(_ expected: Set<UInt8>) throws(WasmParserError) -> UInt8 {
            guard currentIndex < count else {
                throw WasmParserError(kind: .parserUnexpectedEnd(expected: Set(expected)), offset: currentIndex)
            }
            let consumed = byte(at: currentIndex)
            guard expected.contains(consumed) else {
                throw WasmParserError(
                    kind: .parserUnexpectedByte(consumed, expected: Set(expected)), offset: currentIndex)
            }
            currentIndex += 1
            return consumed
        }

        func consume(count: Int) throws(WasmParserError) -> ArraySlice<UInt8> {
            guard count > 0 else { return [] }
            let updatedIndex = currentIndex + count
            guard updatedIndex <= self.count else {
                throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
            }
            defer { currentIndex = updatedIndex }
            let buffer = UnsafeRawBufferPointer(start: base + currentIndex, count: count)
            return [UInt8](buffer)[...]
        }

        func consumeBytes(count: Int) throws(WasmParserError) -> ModuleBytes {
            guard count > 0 else { return ModuleBytes(backing: backing, range: currentIndex..<currentIndex) }
            let updatedIndex = currentIndex + count
            guard updatedIndex <= self.count else {
                throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
            }
            defer { currentIndex = updatedIndex }
            // Zero-copy: a range of the shared memory-mapped backing.
            return ModuleBytes(backing: backing, range: currentIndex..<updatedIndex)
        }

        func peek() -> UInt8? {
            guard currentIndex < count else { return nil }
            return byte(at: currentIndex)
        }
    }
#endif

/// Parse a given byte array as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: [UInt8], features: WasmFeatureSet = .default) throws(WasmKitError) -> Module {
    let stream = StaticByteStream(bytes: bytes)
    let module = try parseModule(stream: stream, features: features)
    return module
}

/// Parse a given byte slice as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: ArraySlice<UInt8>, features: WasmFeatureSet = .default) throws -> Module {
    let stream = StaticByteStream(bytes: bytes)
    let module = try parseModule(stream: stream, features: features)
    return module
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
func parseModule<Stream: ByteStream>(stream: Stream, features: WasmFeatureSet = .default) throws(WasmKitError) -> Module {
    var types: [FunctionType] = []
    var typeIndices: [TypeIndex] = []
    var codes: [Code] = []
    var tables: [TableType] = []
    var memories: [MemoryType] = []
    var globals: [WasmParser.Global] = []
    var tags: [WasmParser.Tag] = []
    var elements: [ElementSegment] = []
    var data: [DataSegment] = []
    var start: FunctionIndex?
    var imports: [Import] = []
    var exports: [Export] = []
    var customSections: [CustomSection] = []
    var dataCount: UInt32?

    var parser = WasmParser.Parser<Stream>(
        stream: stream, features: features
    )

    while let payload = try WasmKitError.wrap({ () throws(WasmParserError) in try parser.parseNext() }) {
        switch payload {
        case .header: break
        case .customSection(let customSection):
            customSections.append(customSection)
        case .typeSection(let typeSection):
            types = typeSection
        case .importSection(let importSection):
            imports = importSection
        case .functionSection(let types):
            typeIndices = types
        case .tableSection(let tableSection):
            tables = tableSection.map(\.type)
        case .memorySection(let memorySection):
            memories = memorySection.map(\.type)
        case .globalSection(let globalSection):
            globals = globalSection
        case .tagSection(let tagSection):
            tags = tagSection
        case .exportSection(let exportSection):
            exports = exportSection
        case .startSection(let functionIndex):
            start = functionIndex
        case .elementSection(let elementSection):
            elements = elementSection
        case .codeSection(let codeSection):
            codes = codeSection
        case .dataSection(let dataSection):
            data = dataSection
        case .dataCount(let count):
            dataCount = count
        }
    }

    guard typeIndices.count == codes.count else {
        throw
            WasmKitError(
                message: .inconsistentFunctionAndCodeLength(
                    functionCount: typeIndices.count,
                    codeCount: codes.count
                ),
                offset: parser.offset
            )
    }

    if let dataCount = dataCount, dataCount != UInt32(data.count) {
        throw
            WasmKitError(
                message: .inconsistentDataCountAndDataSectionLength(
                    dataCount: dataCount,
                    dataSection: data.count
                ),
                offset: parser.offset
            )
    }

    let functions = try codes.enumerated().map { index, code throws(WasmKitError) in
        // SAFETY: The number of typeIndices is guaranteed to be the same as the number of codes
        let funcTypeIndex = typeIndices[index]
        let funcType = try Module.resolveType(funcTypeIndex, typeSection: types)
        return GuestFunction(
            type: funcType,
            code: code
        )
    }

    return Module(
        types: types,
        functions: functions,
        elements: elements,
        data: data,
        start: start,
        imports: imports,
        exports: exports,
        globals: globals,
        memories: memories,
        tables: tables,
        tags: tags,
        customSections: customSections,
        features: features,
        dataCount: dataCount
    )
}
