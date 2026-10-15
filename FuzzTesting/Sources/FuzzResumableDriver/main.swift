// Runs the resumable-call oracle on random inputs without libFuzzer, which does not work with
// the Swift runtime on macOS. With `--race`, another thread ticks the epoch while guests run.
//
//   FuzzResumableDriver [--race] [--seed N] [--count N] [--out DIR]
//   FuzzResumableDriver --replay FILE [--race]

import Foundation
import ResumableFuzzing
import WasmKit

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

final class Racer: @unchecked Sendable {
    let ticker: EpochTicker
    let lock = NSLock()
    var running = true
    let done = DispatchSemaphore(value: 0)

    init(_ ticker: EpochTicker) {
        self.ticker = ticker
        Thread.detachNewThread { [self] in
            while true {
                lock.lock()
                let keepGoing = running
                lock.unlock()
                guard keepGoing else { break }
                for _ in 0..<64 { ticker.increment() }
            }
            done.signal()
        }
    }

    func stop() {
        lock.lock()
        running = false
        lock.unlock()
        done.wait()
    }
}

var arguments = CommandLine.arguments.dropFirst().makeIterator()
var race = false
var seed = UInt64(UInt32.random(in: 0...UInt32.max))
var count = Int.max
var out = "FailCases/FuzzResumableDriver"
var replay: String?
while let argument = arguments.next() {
    switch argument {
    case "--race": race = true
    case "--seed": seed = UInt64(arguments.next()!)!
    case "--count": count = Int(arguments.next()!)!
    case "--out": out = arguments.next()!
    case "--replay": replay = arguments.next()!
    case "--unsliced": ResumableOracle.unsliced = true
    case "--no-deadlines": ResumableOracle.noDeadlines = true
    case "--big-slices": ResumableOracle.bigSlices = true
    case "--trace": ResumableOracle.trace = true
    default: fatalError("unknown argument \(argument)")
    }
}

let startRacer: ((EpochTicker) -> () -> Void)? =
    race
    ? { ticker in
        let racer = Racer(ticker)
        return { racer.stop() }
    } : nil

func runOne(_ bytes: [UInt8]) -> String? {
    do {
        try ResumableOracle.run(bytes: bytes, startRacer: startRacer)
    } catch let finding as Finding {
        return finding.description
    } catch {}
    return nil
}

if let replay {
    let bytes = [UInt8](FileManager.default.contents(atPath: replay)!)
    if let finding = runOne(bytes) {
        print(finding)
        exit(1)
    }
    print("no finding")
    exit(0)
}

/// Exits with status 3 when one input runs longer than this, leaving it as `pending-<seed>`.
let watchdogSeconds = 20.0
final class Watchdog: @unchecked Sendable {
    let lock = NSLock()
    var startedAt = Date()
    var iteration = 0

    func start(_ iteration: Int) {
        lock.lock()
        startedAt = Date()
        self.iteration = iteration
        lock.unlock()
    }

    func run() {
        Thread.detachNewThread { [self] in
            while true {
                Thread.sleep(forTimeInterval: 1)
                lock.lock()
                let elapsed = Date().timeIntervalSince(startedAt)
                let iteration = self.iteration
                lock.unlock()
                if elapsed > watchdogSeconds {
                    print("SLOW iteration \(iteration) ran \(Int(elapsed))s")
                    fflush(stdout)
                    exit(3)
                }
            }
        }
    }
}
let watchdog = Watchdog()
watchdog.run()

try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
var rng = SplitMix64(state: seed)
let started = Date()
for iteration in 0..<count {
    let length = Int.random(in: 16...2048, using: &rng)
    let bytes = (0..<length).map { _ in UInt8.random(in: 0...255, using: &rng) }
    // Written before running, so that a crash leaves the input behind.
    let pending = "\(out)/pending-\(seed)"
    FileManager.default.createFile(atPath: pending, contents: Data(bytes))
    watchdog.start(iteration)
    if let finding = runOne(bytes) {
        let name = "\(out)/finding-\(seed)-\(iteration)"
        FileManager.default.createFile(atPath: name, contents: Data(bytes))
        FileManager.default.createFile(atPath: name + ".txt", contents: Data(finding.utf8))
        print("FINDING \(name)\n\(finding.prefix(2000))")
    }
    if iteration % 1000 == 0 {
        print("seed \(seed) iteration \(iteration) \(Int(Date().timeIntervalSince(started)))s")
        fflush(stdout)
    }
}
try? FileManager.default.removeItem(atPath: "\(out)/pending-\(seed)")
