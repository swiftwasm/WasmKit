#!/usr/bin/env python3

import subprocess
import json


def all_swiftpm_targets():
    # List up all SwiftPM targets by "swift package dump-package"
    output = subprocess.run(
        ["swift", "package", "dump-package"], stdout=subprocess.PIPE)
    package = json.loads(output.stdout)
    targets = []
    for target in package["targets"]:
        if target["type"] == "plugin":
            continue
        targets.append(target["name"])

    return targets


def run(arguments):
    print("Running: " + " ".join(arguments))
    subprocess.run(arguments, check=True)


def main():
    targets = all_swiftpm_targets()
    # NOTE: SystemExtras is not included in the list of targets because it
    #       follows swift-system style conventions, which is different from
    #       swift-format.
    targets.remove("SystemExtras")

    arguments = ["swift", "package",
                 "--allow-writing-to-package-directory", "format-source-code"]
    for target in targets:
        arguments.append("--target")
        arguments.append(target)

    run(arguments)
    run(["swift", "format", "--in-place", "Package.swift"])


if __name__ == "__main__":
    main()
