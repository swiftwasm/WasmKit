import struct SystemPackage.FileDescriptor

#if os(Windows)
    import ucrt
#endif

enum Platform {
    #if os(Windows)
        // TODO: Upstream `O_BINARY` to `SystemPackage
        static let readOnlyBinaryAccessMode = FileDescriptor.AccessMode(
            rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_BINARY
        )
        static let readOnlyTextAccessMode = FileDescriptor.AccessMode(
            rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_TEXT
        )
    #else
        static let readOnlyBinaryAccessMode: FileDescriptor.AccessMode = .readOnly
        static let readOnlyTextAccessMode: FileDescriptor.AccessMode = .readOnly
    #endif
}
