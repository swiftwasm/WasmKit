<a href="https://github.com/akkyie/wakit">
<img alt="WAKit Icon" src="https://raw.github.com/wiki/akkyie/wakit/images/wakit_icon.png" width="100px">
</a>

# WAKit

[![Bitrise](https://img.shields.io/bitrise/245ae702db023bb5.svg?style=for-the-badge&token=YT7cvto4L9xPsTgPokfyDQ)](https://app.bitrise.io/app/245ae702db023bb5)

A WebAssembly runtime written in Swift.

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
    .package(url: "https://github.com/akkyie/WAKit", .branch("master")),
],
```

## Development

```sh
$ make bootstrap  # Install tools through Mint
$ make generate   # Run Sourcery to generate source code from templates
$ make build      # or `swift build`
```
