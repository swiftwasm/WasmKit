//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// Runs `deferred` after `work`, exactly once, also when `work` throws.
/// - Throws: The error thrown by `work`, or by `deferred` when `work` succeeded. When both throw,
///           a ``CleanupFailure`` carrying `work`'s error as ``CleanupFailure/underlying``.
/// - Returns: The result of `work`.
/// - SeeAlso: ``withAsyncThrowing(do:defer:)``
@discardableResult
package func withThrowing<T>(
    do work: () throws -> T,
    defer deferred: () throws -> Void
) throws -> T {
    let result: T
    do {
        result = try work()
    } catch {
        throw CleanupFailure.preserving(error, cleanup: deferred)
    }
    try deferred()
    return result
}

/// Runs async `deferred` after async `work`, exactly once, also when `work` throws.
/// - Throws: The error thrown by `work`, or by `deferred` when `work` succeeded. When both throw,
///           a ``CleanupFailure`` carrying `work`'s error as ``CleanupFailure/underlying``.
/// - Returns: The result of `work`.
/// - SeeAlso: ``withThrowing(do:defer:)``
@discardableResult
package func withAsyncThrowing<T: Sendable>(
    do work: @Sendable () async throws -> T,
    defer deferred: @Sendable () async throws -> Void
) async throws -> T {
    let result: T
    do {
        result = try await work()
    } catch {
        throw await CleanupFailure.preserving(error, cleanup: deferred)
    }
    try await deferred()
    return result
}
