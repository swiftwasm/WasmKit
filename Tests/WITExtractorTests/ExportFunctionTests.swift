#if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
    import Testing

    struct ExportFunctionTests {
        @Test func noParameter() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public func noParameter() {}
                """,
                """
                package swift:wasmkit;

                interface test {
                    no-parameter: func();
                }
                """)
        }

        @Test func parameters() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public func withParameters(x: String, y: Int) {}
                """,
                """
                package swift:wasmkit;

                interface test {
                    with-parameters: func(x: string, y: s64);
                }
                """)
        }

        @Test func parameterUsesInternalNameNotExternalLabel() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public func area(of shape: Double) -> Double { shape }
                """,
                """
                package swift:wasmkit;

                interface test {
                    area: func(shape: f64) -> f64;
                }
                """)
        }

        @Test func unlabeledAndExternalLabelParameters() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public func scale(_ factor: Double, by amount: Double) -> Double { factor * amount }
                """,
                """
                package swift:wasmkit;

                interface test {
                    scale: func(factor: f64, amount: f64) -> f64;
                }
                """)
        }

        @Test func result() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public func withResult() -> Int { return 0 }
                """,
                """
                package swift:wasmkit;

                interface test {
                    with-result: func() -> s64;
                }
                """)
        }

        @Test func multipleResult() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public func withMultipleResult() -> (x: Int, y: Int) {
                    return (0, 1)
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    with-multiple-result: func() -> tuple<s64, s64>;
                }
                """)
        }
        // Anonymous param has no name; an empty WIT name is malformed, so it gets an alphabetical placeholder.
        @Test func doublyAnonymousParameterFallsBackToAlphabetical() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public func ignoreBoth(_ _: Int) -> Int { 0 }
                """,
                """
                package swift:wasmkit;

                interface test {
                    ignore-both: func(a: s64) -> s64;
                }
                """)
        }
    }
#endif
