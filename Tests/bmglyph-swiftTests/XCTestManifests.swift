import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(bmglyph_swiftTests.allTests),
    ]
}
#endif
