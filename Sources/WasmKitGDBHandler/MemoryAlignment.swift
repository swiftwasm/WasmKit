//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension Int {
    mutating func roundUpToAlignment<Type>(for: Type.Type) {
        // Alignment is always positive, we can use unchecked subtraction here.
        let alignmentGuide = MemoryLayout<Type>.alignment &- 1

        // But we can't use unchecked addition.
        self = (self + alignmentGuide) & (~alignmentGuide)
    }
}
