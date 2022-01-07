<a href="https://github.com/akkyie/wakit">
<img alt="WAKit Icon" src="https://raw.github.com/wiki/akkyie/wakit/images/wakit_icon.png" width="100px">
</a>

# WAKit

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/akkyie/WAKit/Build%20and%20test)

A WebAssembly runtime written in Swift. Originally developed and maintained by [@akkyie](https://github.com/akkyie).

🚧 Highly experimental. Do not expect to work.

## Usage

### Command Line Tool

```sh
$ swift build # or prefix `swift run` before the command below
$ # Usage: wakit run <path> <functionName> [<arguments>] ...
$ wakit run Examples/wasm/fib.wasm fib i32:10
[I32(89)]
```

### As a Library

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/akkyie/WAKit", .branch("main")),
],
```

## Development

```sh
$ make bootstrap  # Install tools through Mint
$ make generate   # Run Sourcery to generate source code from templates
$ make build      # or `swift build`
```

To run the core spec test suite run this:

```sh
$ make spectest   # Process core spec tests if needed and check their assertions with WAKit
```
