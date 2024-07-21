#!/usr/bin/env python3

import os
import sys
import subprocess

def main():
  source_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
  build_dir = os.path.join(source_dir, ".build", "debug")
  if sys.platform == "win32":
    default_runtime_exe = "wasmkit-cli.exe"
    skip_json_filename = "skip.windows.json"
  else:
    default_runtime_exe = "wasmkit-cli"
    skip_json_filename = "skip.json"
  default_runtime_exe = os.path.join(build_dir, default_runtime_exe)

  if os.getenv("TEST_RUNTIME_EXE") is None and not os.path.exists(default_runtime_exe):
    print("Building wasmkit-cli")
    subprocess.run(["swift", "build", "--product", "wasmkit-cli"], check=True)

  env = os.environ.copy()
  env["TEST_RUNTIME_EXE"] = os.getenv("TEST_RUNTIME_EXE", default_runtime_exe)


  subprocess.run(
    [sys.executable, "./Vendor/wasi-testsuite/test-runner/wasi_test_runner.py",
      "--test-suite", "./Vendor/wasi-testsuite/tests/assemblyscript/testsuite/",
      "./Vendor/wasi-testsuite/tests/c/testsuite/",
      "./Vendor/wasi-testsuite/tests/rust/testsuite/",
      "--runtime-adapter", "IntegrationTests/WASI/adapter.py",
      "--exclude-filter", os.path.join(source_dir, "IntegrationTests", "WASI", skip_json_filename),
      *sys.argv[1:]],
    env=env, check=True)

if __name__ == "__main__":
  main()
