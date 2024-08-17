#!/usr/bin/env python3
import os
import time
import subprocess
import shutil

dir_path = os.path.dirname(os.path.realpath(__file__))
fail_dir = os.path.join(dir_path, "FailCases", "FuzzDifferential")
tmp_dir = os.path.join(dir_path, ".build", "FuzzDifferential")


def run(args):
    # Initialize the iteration counter and start time
    i = 0
    start_time = time.time()

    os.makedirs(tmp_dir, exist_ok=True)

    while True:
        i += 1
        if i % 100 == 0:
            elapsed_time = time.time() - start_time
            iter_per_sec = i / elapsed_time
            print(f"#{i} (iter/s: {iter_per_sec:.2f})")

        # Generate a WebAssembly file using wasm-smith
        wasm_file = os.path.join(tmp_dir, "t.wasm")
        cmd = [
            "wasm-tools", "smith",
            "-o", wasm_file,
            "--ensure-termination",
            "--bulk-memory-enabled=true",
            "--saturating-float-to-int-enabled=true",
            "--sign-extension-ops-enabled=true",
            "--min-funcs=1",
            "--min-memories=1",
            "--max-imports=0",
            "--export-everything=true",
            "--max-memories=1",
            "--max-memory32-bytes=65536",
            "--memory-max-size-required=true"
        ]
        random_seed = os.urandom(100)
        subprocess.run(cmd, input=random_seed)

        # Run the target program with a timeout of 60 seconds
        try:
            subprocess.run([args.program, wasm_file], timeout=60, check=True)
        except subprocess.CalledProcessError:
            # If the target program fails, save the wasm file
            crash_file = os.path.join(fail_dir, f"diff-{i}.wasm")
            shutil.copy(wasm_file, crash_file)
            print(f"Found crash in iteration {i}")
        except subprocess.TimeoutExpired:
            timeout_file = os.path.join(fail_dir, f"timeout-{i}.wasm")
            shutil.copy(wasm_file, timeout_file)
            print(f"Timeout in iteration {i}")
        except KeyboardInterrupt:
            print("Interrupted by user")
            break


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Fuzz differential testing")
    default_program = os.path.join(
        dir_path, ".build", "debug", "FuzzDifferential")
    parser.add_argument(
        "program", nargs="?", default=default_program,
        help="Path to the target program"
    )
    args = parser.parse_args()
    run(args)


if __name__ == "__main__":
    main()
