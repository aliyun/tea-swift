import Foundation
import XCTest
@testable import Tea

final class ErrorTests: XCTestCase {
    #if os(Linux)
    func testNestedTeaErrorsPreserveMessageAndCause() {
        let original = TeaError("network failed")
        let retryable = RetryableError(original)
        let request = TeaRequest()
        let final = UnretryableError(request, retryable)
        XCTAssertEqual(retryable.message, "network failed")
        XCTAssertEqual(final.message, "network failed")
        XCTAssertTrue(retryable.couse as? TeaError === original)
        XCTAssertTrue(final.couse as? RetryableError === retryable)
        XCTAssertTrue(final.request === request)
    }

    func testTeaErrorWithoutMessageCanBeWrapped() {
        let retryable = RetryableError(TeaError())
        XCTAssertNil(retryable.message)
        XCTAssertNil(UnretryableError(nil, retryable).message)
    }
    #endif

    func testNSErrorAndNilCanBeWrapped() {
        let original = NSError(domain: "TeaTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "network failed"])
        XCTAssertEqual(RetryableError(original).message, original.localizedDescription)
        XCTAssertEqual(UnretryableError(nil, original).message, original.localizedDescription)
        XCTAssertNil(RetryableError(nil).message)
        XCTAssertNil(UnretryableError(nil, nil).message)
    }
}
