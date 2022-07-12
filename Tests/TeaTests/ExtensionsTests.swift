import Foundation
import XCTest
@testable import Tea

final class ExtensionsTests: XCTestCase {
    func testToBytes() {
        XCTAssertEqual([115, 116, 114, 105, 110, 103], "string".toBytes())
    }

    func testJsonDecode() {
        let target: [String: String] = ["foo": "bar"]
        let result: [String: String] = "{\"foo\":\"bar\"}".jsonDecode() as! [String: String]
        XCTAssertEqual(target, result)

        let res = "".jsonDecode()
        XCTAssertEqual(0, res.count)
    }

    func testIsNumber() {
        XCTAssertTrue("1".isNumber())
        XCTAssertFalse("t".isNumber())
    }
}
