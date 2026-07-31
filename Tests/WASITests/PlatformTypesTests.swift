import Testing

@_spi(WASIPlatform) @testable import WASI

@Suite struct PlatformTypesTests {
    @Test func plainErrnoIsReportedAsItself() {
        #expect(WASIAbi.Errno.reportable(for: WASIAbi.Errno.EBADF) == .EBADF)
    }

    @Test func cleanupFailureReportsTheOperationErrno() {
        let failure = CleanupFailure(underlying: WASIAbi.Errno.ENOTDIR, cleanup: WASIAbi.Errno.EIO)
        #expect(WASIAbi.Errno.reportable(for: failure) == .ENOTDIR)
    }

    @Test func anUnrelatedErrorHasNoErrnoToReport() {
        #expect(WASIAbi.Errno.reportable(for: WASIError(description: "unrelated")) == nil)
    }
}
