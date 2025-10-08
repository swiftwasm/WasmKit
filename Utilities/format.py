#!/usr/bin/env python3

import subprocess
import os

SOURCE_ROOT = os.path.relpath(os.path.join(os.path.dirname(__file__), ".."))


def run(arguments):
    print("Running: " + " ".join(arguments))
    subprocess.run(arguments, check=True)


def build_swift_format():
    # Build swift-format
    package_path = os.path.join(SOURCE_ROOT, "Vendor", "swift-format")
    bin_path = os.path.join(package_path, ".build", "release", "swift-format")
    if os.path.exists(bin_path):
        return bin_path

    run(["./Vendor/checkout-dependency", "swift-format"])

    run([
      "swift", "build", "-c", "release",
      "--package-path", package_path])
    return bin_path


def main():
    targets = []
    for targets_dir in ["Sources", "Tests"]:
        targets_path = os.path.join(SOURCE_ROOT, targets_dir)
        for target in os.listdir(targets_path):
            if not os.path.isdir(os.path.join(targets_path, target)):
                continue
            targets.append(os.path.join(targets_dir, target))

    # NOTE: SystemExtras is not included in the list of targets because it
    #       follows swift-system style conventions, which is different from
    #       swift-format.
    targets.remove(os.path.join("Sources", "SystemExtras"))

    # swift_format = build_swift_format()

    arguments = [
        "swift", "format", "format", "--in-place", "--recursive", "--parallel"
    ]
    for target in targets:
        arguments.append(os.path.join(SOURCE_ROOT, target))
    arguments.append(os.path.join(SOURCE_ROOT, "Package.swift"))
    run(arguments)


if __name__ == "__main__":
    main()
