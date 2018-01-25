@testable import CLITests
@testable import WAKitTests
import XCTest

XCTMain([
    testCase(WAKitTests.allTests),
    testCase(CLITests.allTests),
])
