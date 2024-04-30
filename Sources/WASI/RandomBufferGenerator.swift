import SwiftShims  // For swift_stdlib_random

/// A type that provides random bytes.
///
/// This type is similar to `RandomNumberGenerator` in Swift standard library,
/// but it provides a way to fill a buffer with random bytes instead of a single
/// random number.
public protocol RandomBufferGenerator {

    /// Fills the buffer with random bytes.
    ///
    /// - Parameter buffer: The destination buffer to fill with random bytes.
    mutating func fill(buffer: UnsafeMutableBufferPointer<UInt8>)
}

extension RandomBufferGenerator where Self: RandomNumberGenerator {
    public mutating func fill(buffer: UnsafeMutableBufferPointer<UInt8>) {
        // The buffer is filled with 8 bytes at once.
        let count = buffer.count / 8
        for i in 0..<count {
            let random = self.next()
            withUnsafeBytes(of: random) { randomBytes in
                let startOffset = i * 8
                let destination = UnsafeMutableBufferPointer(rebasing: buffer[startOffset..<(startOffset + 8)])
                UnsafeMutableRawBufferPointer(destination).copyMemory(from: randomBytes)
            }
        }

        // If the buffer size is not a multiple of 8, fill the remaining bytes.
        let remaining = buffer.count % 8
        if remaining > 0 {
            let random = self.next()
            withUnsafeBytes(of: random) { randomBytes in
                let startOffset = count * 8
                let destination = UnsafeMutableBufferPointer(rebasing: buffer[startOffset..<(startOffset + remaining)])
                UnsafeMutableRawBufferPointer(destination).copyMemory(
                    from: UnsafeRawBufferPointer(start: randomBytes.baseAddress, count: remaining)
                )
            }
        }
    }
}

extension SystemRandomNumberGenerator: RandomBufferGenerator {
    public mutating func fill(buffer: UnsafeMutableBufferPointer<UInt8>) {
        guard let baseAddress = buffer.baseAddress else { return }
        // Directly call underlying C function of SystemRandomNumberGenerator
        swift_stdlib_random(baseAddress, Int(buffer.count))
    }
}
