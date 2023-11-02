import argparse
import subprocess
import sys
import os
import shlex

# shlex.split() splits according to shell quoting rules
WASMKIT_CLI = shlex.split(os.getenv("TEST_RUNTIME_EXE", "wasmkit-cli"))

parser = argparse.ArgumentParser()
parser.add_argument("--version", action="store_true")
parser.add_argument("--test-file", action="store")
parser.add_argument("--arg", action="append", default=[])
parser.add_argument("--env", action="append", default=[])
parser.add_argument("--dir", action="append", default=[])

args = parser.parse_args()

if args.version:
    print("wasmkit 0.1.0")
    sys.exit(0)

TEST_FILE = args.test_file
PROG_ARGS = args.arg
ENV_ARGS = [j for i in args.env for j in ["--env", i]]
DIR_ARGS = [j for i in args.dir for j in ["--dir", i]]

# HACK: WasmKit intentionally does not support fd_allocate
if TEST_FILE.endswith("fd_advise.wasm"):
    ENV_ARGS += ["--env", "NO_FD_ALLOCATE=1"]

r = subprocess.run(WASMKIT_CLI + ["run"] + DIR_ARGS + ENV_ARGS + [TEST_FILE] + ["--"] + PROG_ARGS)
sys.exit(r.returncode)
