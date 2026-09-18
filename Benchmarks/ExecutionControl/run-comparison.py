#!/usr/bin/env python3
"""Run matched processes in balanced order and retain their complete raw results."""

import argparse
import hashlib
import itertools
import json
import platform
import statistics
import subprocess
from pathlib import Path


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def describe(values):
    ordered = sorted(values)
    median = statistics.median(ordered)
    return {
        "count": len(values),
        "median_ms": median,
        "minimum_ms": ordered[0],
        "maximum_ms": ordered[-1],
        "mean_ms": statistics.mean(ordered),
        "stdev_ms": statistics.stdev(ordered) if len(values) > 1 else 0,
        "median_absolute_deviation_ms": statistics.median(abs(v - median) for v in ordered),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--patched", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--samples", type=int, default=7)
    parser.add_argument("--warmups", type=int, default=2)
    parser.add_argument("--iterations", type=int, default=100_000_000)
    parser.add_argument("--calls", type=int, default=1_000_000)
    parser.add_argument("--exceptions", type=int, default=100_000)
    parser.add_argument("--threading", choices=["token", "direct"], default="token")
    parser.add_argument("--workloads", default="dispatch,exports,imports,exceptions")
    parser.add_argument("--fixture", type=Path)
    parser.add_argument("--renders", type=int, default=1000)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    modes = ["baseline", "unmetered", "controlled"] if args.threading == "token" else ["baseline", "unmetered"]
    orders = list(itertools.permutations(modes))
    if args.threading == "direct":
        orders *= 3
    binaries = {"baseline": args.baseline.resolve(), "unmetered": args.patched.resolve(), "controlled": args.patched.resolve()}
    metadata = {
        "platform": platform.platform(),
        "machine": platform.machine(),
        "orders": orders,
        "arguments": {k: str(v) if isinstance(v, Path) else v for k, v in vars(args).items()},
        "executables": {mode: {"path": str(path), "sha256": sha256(path)} for mode, path in binaries.items()},
        "runner_sha256": sha256(__file__),
    }
    (args.output / "inputs.json").write_text(json.dumps(metadata, indent=2) + "\n")
    collected = {}
    rounds = []
    for number, order in enumerate(orders, 1):
        for mode in order:
            command = [str(binaries[mode]), "--mode", "unmetered" if mode == "baseline" else mode,
                       "--threading", args.threading, "--workloads", args.workloads,
                       "--samples", str(args.samples), "--warmups", str(args.warmups),
                       "--iterations", str(args.iterations), "--calls", str(args.calls),
                       "--exceptions", str(args.exceptions)]
            if args.fixture:
                command += ["--fixture", str(args.fixture.resolve()), "--renders", str(args.renders)]
            prefix = args.output / f"{number}-{mode}"
            prefix.with_suffix(".command.json").write_text(json.dumps(command, indent=2) + "\n")
            result = subprocess.run(command, text=True, capture_output=True)
            prefix.with_suffix(".stdout.json").write_text(result.stdout)
            prefix.with_suffix(".stderr.txt").write_text(result.stderr)
            if result.returncode:
                raise RuntimeError(f"{mode} round {number} failed with {result.returncode}")
            measurements = json.loads(result.stdout)
            for item in measurements:
                name = item["workload"]
                collected.setdefault(name, {}).setdefault(mode, []).extend(item["milliseconds"])
                rounds.append({"round": number, "mode": mode, "workload": name,
                               "median_ms": statistics.median(item["milliseconds"])})
            print(f"Completed round {number} with {mode}.", flush=True)
    summary = {}
    for workload, variants in collected.items():
        summary[workload] = {mode: describe(values) for mode, values in variants.items()}
        base = summary[workload]["baseline"]["median_ms"]
        for mode in variants:
            summary[workload][mode]["median_delta_percent"] = (summary[workload][mode]["median_ms"] / base - 1) * 100
    (args.output / "summary.json").write_text(json.dumps({"summary": summary, "round_medians": rounds}, indent=2) + "\n")


if __name__ == "__main__":
    main()
