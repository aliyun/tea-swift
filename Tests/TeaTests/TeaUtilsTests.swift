//
// Created by Axios on 2020/2/21.
//

import Foundation
import XCTest
@testable import Tea

final class TeaUtilsTests: XCTestCase {
    func testStringifyMapValue() {
        var source: [String: Any?] = [String: Any?]()
        var target: [String: String] = [String: String]()

        source["true"] = true
        target["true"] = "true"
        source["123"] = 123
        target["123"] = "123"
        source["foo"] = "bar"
        target["foo"] = "bar"
        source["0"] = 0
        target["0"] = "0"

        let result: [String: Any] = TeaUtils.stringifyMapValue(source)
        XCTAssertEqual(target["true"], result["true"] as? String)
        XCTAssertEqual(target["123"], result["123"] as? String)
        XCTAssertEqual(target["foo"], result["foo"] as? String)
        XCTAssertEqual(target["0"], result["0"] as? String)
    }

    func testAssertAsMap() {
        XCTAssertFalse(TeaUtils.assertAsMap(nil))
        XCTAssertFalse(TeaUtils.assertAsMap("string"))

        let map: [String: String] = [String: String]()
        XCTAssertTrue(TeaUtils.assertAsMap(map))
    }

    func testGetUserAgent() {
        let userAgent: String = TeaUtils.getUserAgent("CustomizedUserAgent")
        print(userAgent)
        XCTAssertTrue(userAgent.contains("CustomizedUserAgent"))
    }

    func testToJSONString() {
        var dict: [String: String] = [String: String]()
        dict["foo"] = "bar"
        XCTAssertEqual("{\"foo\":\"bar\"}", TeaUtils.toJSONString(dict))
    }

    func testToFormString() {
        var dict: [String: Any] = [String: Any]()
        dict["foo"] = "bar"
        dict["empty"] = ""
        dict["null"] = nil
        dict["withWhiteSpace"] = "a b"
        XCTAssertEqual("foo=bar&withWhiteSpace=a%20b", TeaUtils.toFormString(query: dict as [String: Any]))
    }

    func testGetDateUTCString() {
        let date: String = TeaUtils.getDateUTCString()
        XCTAssertEqual(20, date.lengthOfBytes(using: .utf8))
    }

    func testIsBool() {
        XCTAssertFalse(isBool(nil))
        XCTAssertFalse(isBool(""))
        XCTAssertFalse(isBool("true"))
        XCTAssertTrue(isBool(true))
    }

    func testGetNonce() {
        XCTAssertEqual(32, (TeaUtils.getNonce().lengthOfBytes(using: .utf8)))
    }
}