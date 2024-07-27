#!/usr/bin/env python3
import subprocess
import os
import shutil
from dataclasses import dataclass

SOURCE_ROOT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..")

def available_engines():
    engines = {
        "WasmKit": lambda runner, path: runner.run_command([
            os.path.join(SOURCE_ROOT, ".build/release/wasmkit-cli"), "run", path,
        ]),
    }
    if shutil.which("wasmi_cli"):
        engines["wasmi"] = lambda runner, path: runner.run_command([
            "wasmi_cli", path,
        ])
    if shutil.which("wasmtime"):
        engines["wasmtime"] = lambda runner, path: runner.run_command([
            "wasmtime", path,
        ])
    return engines

@dataclass
class Benchmark:
    name: str
    path: str
    eta_sec: float

def available_benchmarks():
    benchmarks = [
        Benchmark("CoreMark", os.path.join(SOURCE_ROOT, "Vendor", "coremark", "coremark.wasm"), 20.0),
    ]
    return {b.name: b for b in benchmarks}

class Runner:

    def __init__(self, args, engines, benchmarks):
        self.verbose = args.verbose
        self.dry_run = args.dry_run

        def filter_dict(d, keys):
            if keys is None:
                return d
            return {k: v for k, v in d.items() if k in keys}
        
        self.engines = filter_dict(engines, args.engine)
        self.benchmarks = filter_dict(benchmarks, args.benchmark)

    def run_command(self, command):
        if self.verbose or self.dry_run:
            print(f"+ {command}")
        if not self.dry_run:
            subprocess.check_call(command)

    def build(self):
        """Build .wasm file to benchmark."""

        wasi_sdk_path = os.getenv("WASI_SDK_PATH")
        if wasi_sdk_path is None:
            raise Exception("WASI_SDK_PATH environment variable not set")

        vendor_path = os.path.join(SOURCE_ROOT, "Vendor")

        self.run_command([
            "make",
            "compile", "-C", os.path.join(vendor_path, "coremark"),
            "PORT_DIR=simple", f"CC={wasi_sdk_path}/bin/clang",
            "PORT_CFLAGS=-O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks",
            "EXE=.wasm"
        ])

        self.run_command([
            "swift", "build", "-c", "release", "--package-path", SOURCE_ROOT, "--product", "wasmkit-cli"
        ])

    def run(self):
        for engine_name, engine in sorted(self.engines.items(), key=lambda x: x[0]):
            for benchmark_name, benchmark in self.benchmarks.items():
                print(f"===== Running {benchmark_name} with {engine_name} (ETA: {benchmark.eta_sec} sec) =====")
                engine(self, benchmark.path)

def main():
    import argparse
    benchmarks = available_benchmarks()
    engines = available_engines()

    parser = argparse.ArgumentParser(description="Run benchmarks")
    parser.add_argument("--skip-build", action="store_true", help="Skip building the benchmark")
    parser.add_argument("--verbose", action="store_true", help="Print commands before running them")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running them")
    parser.add_argument("--engine", action="append", help="Engines to run", choices=engines.keys())
    parser.add_argument("--benchmark", action="append", help="Benchmarks to run", choices=benchmarks.keys())

    args = parser.parse_args()

    runner = Runner(args, engines, benchmarks)
    if not args.skip_build:
        runner.build()
    runner.run()

if __name__ == "__main__":
    main()
