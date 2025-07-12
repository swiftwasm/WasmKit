#!/usr/bin/env python3
#
# Builds the release tarball of the wasmkit binary

import os
import sys
import subprocess
import shutil
import tarfile

SOURCE_ROOT = os.path.relpath(os.path.join(os.path.dirname(__file__), ".."))

def run(arguments):
    print("Running: " + " ".join(arguments))
    subprocess.run(arguments, check=True)

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-o", "--output", required=True)
    parser.add_argument("extra_build_args", nargs="*")
    
    args = parser.parse_args()

    build_args = ["swift", "build", "-c", "release", "--product", "wasmkit-cli", "--package-path", SOURCE_ROOT] + args.extra_build_args
    bin_path = subprocess.check_output(build_args + ["--show-bin-path"], text=True).strip()

    run(build_args)

    if not args.output.endswith(".tar.gz"):
        raise ValueError("Output file name must end with .tar.gz")
    archive_path = args.output[:-len(".tar.gz")]
    shutil.rmtree(archive_path, ignore_errors=True)
    os.makedirs(archive_path)

    dest_exe_path = os.path.join(archive_path, "wasmkit")
    shutil.copy(os.path.join(bin_path, "wasmkit-cli"), dest_exe_path)

    with tarfile.open(args.output, "w:gz") as tar:
        tar.add(archive_path, arcname=os.path.basename(archive_path))

    print(f"Release binary is available at {args.output}")

if __name__ == "__main__":
    main()