import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(swift_lz4_runnerTests.allTests),
    ]
}
#endif
