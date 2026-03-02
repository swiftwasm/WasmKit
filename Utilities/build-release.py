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


def is_elf(file_path):
    """Check if the file is an ELF binary."""
    with open(file_path, 'rb') as f:
        header = f.read(4)
    return header == b'\x7fELF'


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-o", "--output", required=True)
    parser.add_argument("-s", "--semantic-version", required=True)
    parser.add_argument("extra_build_args", nargs="*")

    args = parser.parse_args()

    # Check that `README.md` has been updated with the latest version.
    version_ok = False
    with open(os.path.join(SOURCE_ROOT, 'README.md')) as file:
      for line in file:
        if f'from: "{args.semantic_version}"' in line:
            version_ok = True

    if not version_ok:
      print("Expected README.md to contain a reference to the newly released version in Package.swift sample.", file=sys.stderr)
      sys.exit(1)

    # Check that `CLI.swift` has been updated with the latest version.
    version_ok = False
    with open(os.path.join(SOURCE_ROOT, 'Sources', 'CLI', 'CLI.swift')) as file:
      for line in file:
        if f'version: "{args.semantic_version}"' in line:
            version_ok = True

    if not version_ok:
      print("Expected `Sources/CLI/CLI.swift` to specify the newly released version.", file=sys.stderr)
      sys.exit(1)

    build_args = ["swift", "build", "-c", "release", "--product", "wasmkit-cli", "--package-path", SOURCE_ROOT] + args.extra_build_args
    bin_path = subprocess.check_output(build_args + ["--show-bin-path"], text=True).strip()

    run(build_args)

    if not args.output.endswith(".tar.gz"):
        raise ValueError("Output file name must end with .tar.gz")
    archive_path = args.output[:-len(".tar.gz")]
    shutil.rmtree(archive_path, ignore_errors=True)
    os.makedirs(archive_path)

    src_exe_path = os.path.join(bin_path, "wasmkit-cli")
    dest_exe_path = os.path.join(archive_path, "wasmkit")
    if is_elf(src_exe_path):
        # For ELF binaries, use strip to remove debug symbols because
        # most of static archives in static linux Swift SDK contains
        # debug sections.
        run(["llvm-strip", src_exe_path, "--strip-debug", "-o", dest_exe_path])
    else:
        shutil.copy(src_exe_path, dest_exe_path)

    with tarfile.open(args.output, "w:gz") as tar:
        tar.add(archive_path, arcname=os.path.basename(archive_path))

    print(f"Release binary is available at {args.output}")

if __name__ == "__main__":
    main()
