import XCTest

import LZ4Tests

var tests = [XCTestCaseEntry]()
tests += LZ4Tests.__allTests()

XCTMain(tests)
