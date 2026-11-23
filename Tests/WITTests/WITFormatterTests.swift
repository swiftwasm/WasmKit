import Testing

@testable import WIT

@Suite
struct WITFormatterTests {
    private func format(_ text: String, includeDocs: Bool = true) throws -> String {
        WITFormatter.format(
            sourceFile: try SourceFileSyntax.parse(text, fileName: "test.wit").syntax, includeDocs: includeDocs)
    }

    @Test func fileItemsKeepSourceOrder() throws {
        let text = """
            package a:b;

            @since(version = 0.2.0)
            use wasi:io/streams@0.2.10 as streams;
            use wasi:io/poll@0.2.10;

            interface c {
            }

            @since(version = 0.2.0)
            world w {
              import c;
            }

            interface e {
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func fileWithoutPackageDeclaration() throws {
        let text = """
            interface c {
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func writesOneLinePerWrite() throws {
        struct ChunkRecorder: TextOutputStream {
            var chunks: [String] = []
            mutating func write(_ string: String) { chunks.append(string) }
        }
        let file = try SourceFileSyntax.parse("interface i {\n  f: func();\n\n  g: func();\n}\n", fileName: "test.wit")
        var formatter = WITFormatter(output: ChunkRecorder())
        formatter.write(sourceFile: file.syntax)
        #expect(formatter.output.chunks == ["interface i {\n", "  f: func();\n", "\n", "  g: func();\n", "}\n"])
    }

    @Test func interfaceItemsKeepSourceOrder() throws {
        let text = """
            interface i {
              f: func();

              use j.{x};
              use j.{y as z};

              type t = u8;
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func inlineInterface() throws {
        let text = """
            world w {
              import x: interface {
                f: func();

                type t = u8;
              }
              export y: interface {
              }
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func singleNamedResult() throws {
        let text = """
            interface i {
              f: func() -> (a: u32);

              g: func() -> (a: u32, b: string);
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func floatTypes() throws {
        let text = """
            interface i {
              type a = f32;

              type b = f64;
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func typeSpellings() throws {
        let text = """
            interface i {
              type a = list<u8>;

              type b = option<string>;

              type c = tuple<bool, char>;

              type d = result;

              type e = result<u8>;

              type f = result<_, u8>;

              type g = result<u8, string>;

              type h = future;

              type j = future<u8>;

              type k = stream;

              type l = stream<u8>;

              type m = stream<_, u8>;

              type n = stream<u8, u8>;

              type o = own<r>;

              type p = borrow<r>;
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test(arguments: WITKeyword.allCases.map(\.rawValue))
    func keywordIdentifiers(keyword: String) throws {
        let text = """
            interface i {
              record %\(keyword) {
                %\(keyword): u8,
              }
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func keywordPackageNames() throws {
        let text = """
            package %use:%type;

            interface %interface {
              use %use:%type/%interface.{%as};
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func docs() throws {
        let text = """
            package a:b;

            /// interface docs
            interface i {
              // plain comment
              /// type docs
              @since(version = 0.2.0)
              record r {
                /// field docs
                x: u8,
              }

              variant v {
                /// case docs
                c(u8),
              }

              enum e {
                /// enum case docs
                a,
              }

              flags f {
                /// flag docs
                a,
              }

              union u {
                /// union case docs
                u8,
              }

              resource res {
                /// constructor docs
                constructor();
                /// method docs
                m: func();
                /// static docs
                s: static func();
              }

              /// function docs
              g: func();
            }

            /// world docs
            world w {
              /// import docs
              import i;
              /// export docs
              export g: func();
            }

            """
        let output = try format(text)
        #expect(output == text)
    }

    @Test func omitsDocsWhenAsked() throws {
        let text = """
            /// interface docs
            interface i {
              /// function docs
              f: func();
            }

            """
        let output = try format(text, includeDocs: false)
        #expect(
            output == """
                interface i {
                  f: func();
                }

                """)
    }
}
