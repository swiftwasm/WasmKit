#!/usr/bin/env python3
import os
import time
import subprocess
import shutil
import asyncio

dir_path = os.path.dirname(os.path.realpath(__file__))
fail_dir = os.path.join(dir_path, "FailCases", "FuzzDifferential")
tmp_dir = os.path.join(dir_path, ".build", "FuzzDifferential")


def dump_crash_wasm(file, prefix):
    import hashlib
    with open(file, "rb") as f:
        content = f.read()
        hash_value = hashlib.sha1(content).hexdigest()
    crash_file = os.path.join(fail_dir, f"{prefix}-{hash_value}.wasm")
    shutil.copy(file, crash_file)
    return crash_file


async def run_single(lane, i, program):
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
    found = False
    try:
        proc = await asyncio.create_subprocess_exec(program, wasm_file)
        await asyncio.wait_for(proc.wait(), timeout=60)
        if proc.returncode != 0:
            # If the target program fails, save the wasm file
            crash_file = dump_crash_wasm(wasm_file, "diff")
            print(f"Found crash in iteration {i};"
                  f" reproduce with {program} {crash_file}")
            found = True
    except TimeoutError:
        timeout_file = os.path.join(fail_dir, f"timeout-{i}.wasm")
        shutil.copy(wasm_file, timeout_file)
        print(f"Timeout in iteration {i};"
              f" reproduce with {program} {timeout_file})")
    except KeyboardInterrupt:
        print("Interrupted by user")
        exit(0)

    return (lane, i, found)


class Progress:
    def __init__(self):
        self.i = 0

    def start_new(self, lane):
        new = self.i
        self.i += 1
        return new

    def complete(self, i, lane, found):
        pass

    def finalize(self):
        pass


class StdoutProgress(Progress):
    def __init__(self):
        super().__init__()
        self.start_time = time.time()

    def complete(self, i, lane, found):
        if self.i % 100 == 0:
            elapsed_time = time.time() - self.start_time
            iter_per_sec = self.i / elapsed_time
            print(f"#{self.i} (iter/s: {iter_per_sec:.2f})")


class CursesProgress(Progress):
    def __init__(self, max_lanes, curses):
        super().__init__()
        self.curses = curses
        self.stdscr = curses.initscr()
        self.start_time = time.time()
        self.completed_by_lane = {i: 0 for i in range(max_lanes)}
        self.max_lanes = max_lanes
        self.found_diffs = 0
        self.show_overview()

    def start_new(self, lane):
        task_id = super().start_new(lane)

        if self.completed_by_lane[lane] % 40 == 0:
            elapsed_time = time.time() - self.start_time
            throughput = self.completed_by_lane[lane] / elapsed_time
            self.show_lane_status(lane, throughput, task_id)

        self.completed_by_lane[lane] = self.completed_by_lane[lane] + 1
        return task_id

    def show_lane_status(self, lane, throughput, new_task_id):
        status = (
            f"Lane #{lane:02}:"
            f" Running task {new_task_id} ({throughput:.2f} iter/s)"
        )
        try:
            self.stdscr.addstr(1 + lane, 0, status)
            # Move the cursor to the bottom of the screen
            self.stdscr.move(1 + self.max_lanes, 0)
            self.stdscr.refresh()
        except self.curses.error:
            pass

    def complete(self, i, lane, found):
        # Update overview line if a new diff is found
        if found:
            self.found_diffs += 1
            self.show_overview()

    def show_overview(self):
        self.stdscr.addstr(0, 0, f"Found {self.found_diffs} diffs")
        self.stdscr.refresh()

    def finalize(self):
        self.curses.echo()
        self.curses.nocbreak()
        self.curses.endwin()


async def run(args, progress, num_lanes):
    os.makedirs(tmp_dir, exist_ok=True)

    lanes = [
        asyncio.create_task(run_single(
            i, progress.start_new(i), args.program
        )) for i in range(num_lanes)
    ]

    try:
        while True:
            # Run the target program with a timeout of 60 seconds
            try:
                done, pending = await asyncio.wait(
                    lanes, return_when=asyncio.FIRST_COMPLETED)
                for result in done:
                    lane, task_id, found = result.result()
                    progress.complete(task_id, lane, found)
                    lanes[lane] = asyncio.create_task(
                        run_single(lane, progress.start_new(lane),
                                   args.program)
                    )
            except KeyboardInterrupt:
                print("Interrupted by user")
                break
    finally:
        print("Cleaning up...")
        for lane in lanes:
            lane.cancel()
        progress.finalize()


def derive_progress(args):
    if args.progress == "stdout":
        return StdoutProgress()
    elif args.progress == "curses" and os.isatty(1):
        try:
            import curses
            return CursesProgress(args.jobs, curses)
        except ImportError:
            print("Curses is not available; falling back to stdout")
    return StdoutProgress()


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Fuzz differential testing")
    default_program = os.path.join(
        dir_path, ".build", "debug", "FuzzDifferential")
    parser.add_argument(
        "program", nargs="?", default=default_program,
        help="Path to the target program"
    )
    parser.add_argument(
        "-j", "--jobs", type=int, default=os.cpu_count(),
        help="Number of parallel jobs"
    )
    parser.add_argument(
        "--progress", choices=["stdout", "curses"], default="curses",
        help="Progress display mode"
    )

    args = parser.parse_args()

    progress = derive_progress(args)
    asyncio.run(run(args, progress, args.jobs))


if __name__ == "__main__":
    main()
