import ArgumentParser
import CLICommands
import Testing
import WasmKitWASI

@Suite struct RunOptionsTests {
    @Test func identityDirGrantsTheSameGuestPath() throws {
        let run = try Run.parse(["--dir", "/host/dir", "module.wasm"])
        let preopens = try run.derivePreopens()
        #expect(preopens.count == 1)
        #expect(preopens.first?.hostPath == "/host/dir")
        #expect(preopens.first?.guestPath == "/host/dir")
    }

    @Test func mappedDirSplitsHostFromGuest() throws {
        let run = try Run.parse(["--dir", "/host/dir::/", "module.wasm"])
        let preopens = try run.derivePreopens()
        #expect(preopens.count == 1)
        #expect(preopens.first?.hostPath == "/host/dir")
        #expect(preopens.first?.guestPath == "/")
    }

    @Test func mappedDirAcceptsAnEmptyGuestPath() throws {
        let run = try Run.parse(["--dir", "/host::", "module.wasm"])
        let preopens = try run.derivePreopens()
        #expect(preopens.first?.hostPath == "/host")
        #expect(preopens.first?.guestPath == "")
    }

    @Test func dirWithMoreThanOneSeparatorIsRejected() throws {
        let error = #expect(throws: (any Error).self) {
            _ = try Run.parse(["--dir", "/host::/a::/b", "module.wasm"])
        }
        let thrown = try #require(error)
        #expect(Run.exitCode(for: thrown) == .validationFailure)
        let message = Run.message(for: thrown)
        #expect(message.contains("'/host::/a::/b'"))
        #expect(message.contains("more than one '::'"))
    }

    @Test func repeatedDirsKeepCommandLineOrder() throws {
        let run = try Run.parse(["--dir", "/a::/x", "--dir", "/b::/y", "module.wasm"])
        let preopens = try run.derivePreopens()
        #expect(preopens.map(\.hostPath) == ["/a", "/b"])
        #expect(preopens.map(\.guestPath) == ["/x", "/y"])
    }

    @Test func argv0DefaultsToTheModulePath() throws {
        let run = try Run.parse(["module.wasm", "extra"])
        #expect(run.deriveWASIArguments() == ["module.wasm", "extra"])
    }

    @Test func argv0OptionOverridesTheFirstWASIArgument() throws {
        let run = try Run.parse(["--argv0", "/cross-build/wasm32/python.wasm", "module.wasm", "extra"])
        #expect(run.deriveWASIArguments() == ["/cross-build/wasm32/python.wasm", "extra"])
    }

    @Test func emptyArgv0IsPassedThroughVerbatim() throws {
        let run = try Run.parse(["--argv0", "", "module.wasm", "extra"])
        #expect(run.deriveWASIArguments() == ["", "extra"])
    }

    @Test func emptyDirIsAnIdentityGrantOfAnEmptyPath() throws {
        let run = try Run.parse(["--dir", "", "module.wasm"])
        let preopens = try run.derivePreopens()
        #expect(preopens.first?.hostPath == "")
        #expect(preopens.first?.guestPath == "")
    }

    @Test func dirWithAnEmptyHostKeepsTheGuestPath() throws {
        let run = try Run.parse(["--dir", "::/guest", "module.wasm"])
        let preopens = try run.derivePreopens()
        #expect(preopens.first?.hostPath == "")
        #expect(preopens.first?.guestPath == "/guest")
    }

    @Test func windowsDriveLetterIsNotASeparator() throws {
        let run = try Run.parse(["--dir", #"C:\dir::/mnt"#, "module.wasm"])
        let preopens = try run.derivePreopens()
        #expect(preopens.first?.hostPath == #"C:\dir"#)
        #expect(preopens.first?.guestPath == "/mnt")
    }

    @Test func environmentValueKeepsInnerEqualsSigns() throws {
        let run = try Run.parse(["--env", "LS_COLORS=di=1:ln=2", "module.wasm"])
        #expect(run.deriveEnvironment() == ["LS_COLORS": "di=1:ln=2"])
    }

    @Test func lastEnvironmentValueWinsForADuplicateKey() throws {
        let run = try Run.parse(["--env", "A=1", "--env", "A=2", "module.wasm"])
        #expect(run.deriveEnvironment() == ["A": "2"])
    }
}

#if WasmDebuggingSupport
    @Suite struct RunDebuggerOptionTests {
        @Test func debuggerPortWithSignpostIsRejectedAsAUsageError() throws {
            let error = #expect(throws: (any Error).self) {
                _ = try Run.parse(["--debugger-port", "4455", "--enable-signpost", "module.wasm"])
            }
            #expect(Run.exitCode(for: try #require(error)) == .validationFailure)
        }

        @Test func debuggerPortWithProfilingIsRejectedAsAUsageError() throws {
            let error = #expect(throws: (any Error).self) {
                _ = try Run.parse(["--debugger-port", "4455", "--profile", "/tmp/p.json", "module.wasm"])
            }
            #expect(Run.exitCode(for: try #require(error)) == .validationFailure)
        }
    }
#endif
