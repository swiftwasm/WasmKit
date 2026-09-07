#!/usr/bin/env python3
import subprocess
import os
import shutil
from dataclasses import dataclass

BENCHMARKS_ROOT = os.path.dirname(os.path.realpath(__file__))
SOURCE_ROOT = os.path.join(BENCHMARKS_ROOT, "..")


class Engine:
    def __call__(self, runner, path):
        raise NotImplementedError()


class SimpleEngine(Engine):
    def __init__(self, name, command_to_prepend):
        self.name = name
        self.command_to_prepend = command_to_prepend

    def command(self, path):
        return self.command_to_prepend + [path]

    def __call__(self, runner, path):
        runner.run_command(self.command(path))


def available_engines():
    engines = {}

    def add_engine(engine):
        engines[engine.name] = engine

    add_engine(SimpleEngine("WasmKit", [
        os.path.join(SOURCE_ROOT, ".build/release/wasmkit-cli"), "run",
    ]))

    if shutil.which("wasmtime"):
        add_engine(SimpleEngine("wasmtime", ["wasmtime", "run", "-C", "cache=n"]))
    if shutil.which("wasm3"):
        add_engine(SimpleEngine("wasm3", ["wasm3"]))
    if shutil.which("wasmi_cli"):
        add_engine(SimpleEngine("wasmi", ["wasmi_cli"]))
    return engines


@dataclass
class Benchmark:
    name: str
    eta_sec: float

    def build(self, runner):
        """Build whatever this benchmark needs before it can run."""


class CoreMarkBenchmark(Benchmark):
    def __init__(self):
        super().__init__("CoreMark", 20.0)
        self.path = os.path.join(
            SOURCE_ROOT, "Vendor", "coremark", "coremark.wasm")

    def build(self, runner):
        wasi_sdk_path = os.getenv("WASI_SDK_PATH")
        if wasi_sdk_path is None:
            raise Exception("WASI_SDK_PATH environment variable not set")

        runner.run_command([
            "make",
            "compile", "-C", os.path.join(SOURCE_ROOT, "Vendor", "coremark"),
            "PORT_DIR=simple", f"CC={wasi_sdk_path}/bin/clang",
            "PORT_CFLAGS=-O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks",
            "EXE=.wasm"
        ])
        runner.build_wasmkit_cli()

    def __call__(self, runner, engines):
        for engine_name, engine in engines.items():
            print(f"===== Running {self.name} with {engine_name} =====")
            engine(runner, self.path)


class WishYouWereFastBenchmark(Benchmark):
    def __init__(self):
        super().__init__("WishYouWereFast", 10.0)

        suites_path = os.path.join(
            SOURCE_ROOT, "Vendor", "wish-you-were-fast", "wasm", "suites")
        targets = []

        def add_dir(subpath):
            path = os.path.join(suites_path, subpath)
            if not os.path.exists(path):
                return
            for filename in os.listdir(path):
                if filename.endswith(".wasm"):
                    targets.append(os.path.join(path, filename))

        add_dir("libsodium")
        self.targets = sorted(targets)

    def build(self, runner):
        runner.build_wasmkit_cli()

    def __call__(self, runner, engines):
        # Save the result CSV file at ./results/{engine_name}/{target_name}.csv
        results_dir = runner.results_dir

        for i, target in enumerate(self.targets):
            for engine_name, engine in engines.items():
                runner.run_command([
                    "mkdir", "-p", os.path.join(results_dir, engine.name)])
                print(f"===== Running {i+1}/{len(self.targets)}: {target} with {engine_name} =====")
                if not isinstance(engine, SimpleEngine):
                    raise NotImplementedError(
                        "WishYouWereFastBenchmark only supports SimpleEngine")

                csv_path = os.path.join(
                    results_dir, engine.name, os.path.basename(target) + ".csv")
                command = engine.command(target)
                command = [
                    "hyperfine", "--warmup", "5", "--export-csv", csv_path,
                    " ".join(command)
                ]
                runner.run_command(command)


class WasmiBenchmarksBenchmark(Benchmark):
    """Replays the wasmi-benchmarks suite through the WasmKit library.

    Unlike the other benchmarks here this one does not shell out to a runtime
    executable per module: the suite drives exported `setup`/`run`/`teardown`
    functions in-process, so it only supports the WasmKit engine. Run wasmi's
    own criterion harness in the vendored checkout for comparable numbers; see
    README.md.
    """

    def __init__(self):
        super().__init__("WasmiBenchmarks", 120.0)
        self.harness = os.path.join(
            BENCHMARKS_ROOT, ".build", "release", "WasmiBenchmarks")
        self.suite_path = os.path.join(SOURCE_ROOT, "Vendor", "wasmi-benchmarks")

    def build(self, runner):
        runner.run_command([
            "swift", "build", "-c", "release", "--package-path", BENCHMARKS_ROOT,
            "--product", "WasmiBenchmarks",
        ])

    def __call__(self, runner, engines):
        if "WasmKit" not in engines:
            print(f"===== Skipping {self.name}: only the WasmKit engine is supported =====")
            return
        if not os.path.exists(self.suite_path):
            raise Exception(
                f"{self.suite_path} not found; "
                "run ./Vendor/checkout-dependency --category benchmark")

        # Written at the top level of the results directory: the layout
        # `concat_results` merges is hyperfine's, and this CSV is not that.
        runner.run_command(["mkdir", "-p", runner.results_dir])
        csv_path = os.path.join(runner.results_dir, "wasmi-benchmarks.csv")

        print(f"===== Running {self.name} with WasmKit =====")
        command = [self.harness, "--root", self.suite_path]
        if runner.verbose or runner.dry_run:
            print(f"+ {command} > {csv_path}")
        if runner.dry_run:
            return
        output = subprocess.check_output(command, text=True)
        print(output, end="")
        with open(csv_path, "w") as f:
            f.write("case,mean_ms,min_ms,iters\n")
            f.write(output)


def available_benchmarks():
    benchmarks = [
        CoreMarkBenchmark(),
        WishYouWereFastBenchmark(),
        WasmiBenchmarksBenchmark(),
    ]
    return {b.name: b for b in benchmarks}


class Runner:

    def __init__(self, args, engines, benchmarks):
        self.verbose = args.verbose
        self.dry_run = args.dry_run
        self.results_dir = args.results_dir

        def filter_dict(d, keys):
            if keys is None:
                return d
            return {k: v for k, v in d.items() if k in keys}

        self.engines = filter_dict(engines, args.engine)
        self.benchmarks = filter_dict(benchmarks, args.benchmark)
        self.built_wasmkit_cli = False

    def run_command(self, command):
        if self.verbose or self.dry_run:
            print(f"+ {command}")
        if not self.dry_run:
            subprocess.check_call(command)

    def build_wasmkit_cli(self):
        """Build wasmkit-cli, once per run, for the executable-driven benchmarks."""
        if self.built_wasmkit_cli:
            return
        self.built_wasmkit_cli = True
        self.run_command([
            "swift", "build", "-c", "release", "--package-path", SOURCE_ROOT, "--product", "wasmkit-cli"
        ])

    def build(self):
        """Build what the selected benchmarks need."""
        for benchmark in self.benchmarks.values():
            benchmark.build(self)

    def run(self):
        engines = dict(sorted(self.engines.items(), key=lambda x: x[0]))
        for benchmark_name, benchmark in self.benchmarks.items():
            print(f"===== Running {benchmark_name} (ETA: {benchmark.eta_sec} sec) =====")
            benchmark(self, engines)


def concat_results(args):
    import glob

    results_dir = args.results_dir
    results = []
    original_header = None
    for csv_path in glob.glob(os.path.join(results_dir, "*/*.csv"), recursive=True):
        engine_name = csv_path.split("/")[-2]
        target_name = csv_path.split("/")[-1].replace(".csv", "")
        with open(csv_path) as f:
            lines = f.readlines()
            if len(lines) == 1:
                print(f"Warning: {csv_path} is empty")
                continue
            if original_header is None:
                original_header = lines[0]
            for line in lines[1:]:
                results.append(f"{engine_name},{target_name},{line}")

    with open(os.path.join(results_dir, "data.csv"), "w") as f:
        f.write(f"engine,target,{original_header}")
        f.writelines(results)


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
    parser.add_argument("--step", action="append", help="Steps to run",
                        choices=["build", "run", "concat"])
    parser.add_argument("--results-dir", help="Directory to save results",
                        default="./.build/results")

    args = parser.parse_args()
    if args.step is None:
        args.step = ["build", "run", "concat"]

    runner = Runner(args, engines, benchmarks)
    if not args.skip_build and "build" in args.step:
        runner.build()
    if "run" in args.step:
        runner.run()
    if "concat" in args.step:
        concat_results(args)


if __name__ == "__main__":
    main()
