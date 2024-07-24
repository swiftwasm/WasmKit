#!/usr/bin/env python3

import argparse
import os
import subprocess

class CommandRunner:
    def __init__(self, verbose: bool = False, dry_run: bool = False):
        self.verbose = verbose
        self.dry_run = dry_run

    def run(self, args, **kwargs):
        if self.verbose or self.dry_run:
            print(' '.join(args))
        if self.dry_run:
            return
        return subprocess.run(args, **kwargs)


def main():
    parser = argparse.ArgumentParser(description='Build fuzzer')
    # Common options
    parser.add_argument(
        '-v', '--verbose', action='store_true', help='Print commands')
    parser.add_argument(
        '-n', '--dry-run', action='store_true',
        help='Print commands but do not execute them')

    # Subcommands
    subparsers = parser.add_subparsers(required=True)

    available_targets = list(os.listdir('Sources'))

    build_parser = subparsers.add_parser('build', help='Build the fuzzer')
    build_parser.add_argument(
        'target_name', type=str, help='Name of the target', choices=available_targets)
    build_parser.set_defaults(func=build)

    run_parser = subparsers.add_parser('run', help='Run the fuzzer')
    run_parser.add_argument(
        'target_name', type=str, help='Name of the target', choices=available_targets)
    run_parser.add_argument(
        '--skip-build', action='store_true',
        help='Skip building the fuzzer')
    run_parser.add_argument(
        'args', nargs=argparse.REMAINDER,
        help='Arguments to pass to the fuzzer')
    run_parser.set_defaults(func=run)

    seed_parser = subparsers.add_parser(
        'seed', help='Generate seed corpus for the fuzzer')
    seed_parser.set_defaults(func=seed)

    args = parser.parse_args()
    runner = CommandRunner(verbose=args.verbose, dry_run=args.dry_run)
    args.func(args, runner)


def seed(args, runner):
    def generate_seed_corpus(output_path: str):
        args = [
            "wasm-tools", "smith", "-o", output_path
        ]
        # Random stdin input
        stdin = os.urandom(1024)
        process = subprocess.Popen(args, stdin=subprocess.PIPE)
        process.communicate(input=stdin)
        if process.returncode != 0:
            raise Exception(f"Failed to generate seed corpus: {output_path}")

    output_dir = ".build/fuzz-corpus"
    os.makedirs(output_dir, exist_ok=True)

    for i in range(100):
        output = f"{output_dir}/corpus-{i}.wasm"
        generate_seed_corpus(output)
        print(f"Generated seed corpus: {output}")


def executable_path(target_name: str) -> str:
    return f'./.build/debug/{target_name}'


def build(args, runner: CommandRunner):
    print(f'Building fuzzer for {args.target_name}')

    runner.run([
        'swift', 'build', '--product', args.target_name
    ], check=True)

    print('Building fuzzer executable')
    output = executable_path(args.target_name)
    runner.run([
        'swiftc', f'./.build/debug/lib{args.target_name}.a', '-g',
        '-sanitize=fuzzer,address', '-o', output
    ], check=True)

    print('Fuzzer built successfully: ', output)


def run(args, runner: CommandRunner):

    if not args.skip_build:
        build(args, runner)

    print('Running fuzzer')

    artifact_dir = f'./FailCases/{args.target_name}/'
    os.makedirs(artifact_dir, exist_ok=True)
    fuzzer_args = [
        executable_path(args.target_name), './.build/fuzz-corpus',
        f'-artifact_prefix={artifact_dir}'
    ] + args.args
    runner.run(fuzzer_args, env={'SWIFT_BACKTRACE': 'enable=off'})


if __name__ == '__main__':
    main()
