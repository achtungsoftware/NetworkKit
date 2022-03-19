import XCTest
@testable import NetworkKit

final class NetworkKitTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NetworkKit().text, "Hello, World!")
    }
}
