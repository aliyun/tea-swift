import Foundation
import XCTest
@testable import Tea

final class StreamAndErrorTests: XCTestCase {
    func testSSEEventParse() {
        let text = """
        data: hello\n\
        event: message\n\
        id: 1\n\
        retry: 3000\n\
        \n\
        data: world\n\
        \n\
        : comment\n\
        data: x\n\
        retry: bad\n\
        \n
        """
        let events = TeaStream.parseSSEEvents(text)
        XCTAssertGreaterThanOrEqual(events.count, 2)
        XCTAssertEqual("hello", events[0].data)
        XCTAssertEqual("message", events[0].event)
        XCTAssertEqual("1", events[0].id)
        XCTAssertEqual(3000, events[0].retry)
        XCTAssertEqual("world", events[1].data)
    }

    func testSSENoSpacesAndInvalidRetry() {
        let text = "data:a\nevent:b\nid:c\nretry:xyz\n\ndata:d\n\n"
        let events = TeaStream.parseSSEEvents(text)
        XCTAssertEqual(2, events.count)
        XCTAssertEqual("a", events[0].data)
        XCTAssertEqual("b", events[0].event)
        XCTAssertEqual("c", events[0].id)
        XCTAssertNil(events[0].retry)
        XCTAssertEqual("d", events[1].data)
    }

    func testReadAsSSEAsync() async throws {
        let body = "data: one\nid: 1\n\ndata: two\n\n".data(using: .utf8)
        var collected: [SSEEvent] = []
        for try await event in TeaStream.readAsSSE(body) {
            collected.append(event)
        }
        XCTAssertEqual(2, collected.count)
        XCTAssertEqual("one", collected[0].data)
        XCTAssertEqual("1", collected[0].id)
        XCTAssertEqual("two", collected[1].data)
    }

    func testReadAsSSEChunks() async throws {
        let chunks = ["data: hel", "lo\n\ndata: ", "world\n\n"]
        var collected: [SSEEvent] = []
        for try await event in TeaStream.readAsSSE(chunks: chunks) {
            collected.append(event)
        }
        XCTAssertEqual(2, collected.count)
        XCTAssertEqual("hello", collected[0].data)
        XCTAssertEqual("world", collected[1].data)
    }

    func testStreamReadHelpers() throws {
        let data = "{\"a\":1}".data(using: .utf8)
        XCTAssertEqual([UInt8]("{\"a\":1}".utf8), TeaStream.readAsBytes(data))
        XCTAssertEqual("{\"a\":1}", TeaStream.readAsString(data))
        let json = try TeaStream.readAsJSON(data) as? [String: Any]
        XCTAssertEqual(1, json?["a"] as? Int)
        XCTAssertEqual([], TeaStream.readAsBytes(nil as Data?))
        XCTAssertEqual("", TeaStream.readAsString(nil))
        let empty = try TeaStream.readAsJSON(nil)
        XCTAssertTrue(empty is NSNull)
    }

    func testResponseErrorAndBuiltin() {
        let err = ResponseError([
            "code": "Throttling",
            "message": "too many",
            "retryAfter": Int64(1500),
            "statusCode": 400,
            "description": "desc",
            "detail": "detail",
            "accessDeniedDetail": ["k": "v"],
            "data": ["statusCode": 429]
        ])
        XCTAssertEqual("ResponseError", err.name)
        XCTAssertEqual("Throttling", err.code)
        XCTAssertEqual(1500, err.retryAfter)
        XCTAssertEqual(400, err.statusCode)
        XCTAssertEqual("desc", err.getDescription())
        XCTAssertEqual("detail", err.detail)
        XCTAssertEqual(["k": "v"] as NSDictionary, err.getAccessDeniedDetail()! as NSDictionary)

        let fromData = ResponseError([
            "code": "X",
            "message": "m",
            "data": ["statusCode": "503"]
        ])
        XCTAssertEqual(503, fromData.statusCode)

        let base = BaseError(["code": 42, "message": "n"])
        XCTAssertEqual("42", base.code)
        XCTAssertEqual("BaseError", base.getName())

        let created = TeaErrors.newError(["code": "E", "message": "m"])
        XCTAssertEqual("E", created.code)

        let ctx = RetryPolicyContext(exception: created)
        let unretryable = TeaErrors.newUnretryableError(ctx)
        XCTAssertTrue(unretryable is ResponseError)

        XCTAssertTrue(TeaBuiltin.isNull(nil))
        XCTAssertTrue(TeaBuiltin.isNull(NSNull()))
        XCTAssertFalse(TeaBuiltin.isNull("x"))
        XCTAssertEqual("fallback", TeaBuiltin.default(nil as String?, "fallback"))
        XCTAssertEqual("v", TeaBuiltin.default("v", "fallback"))
        XCTAssertEqual("d", TeaBuiltin.defaultAny(nil, "d") as? String)
        XCTAssertEqual("{\"a\":1}", TeaJSON.stringify(["a": 1]))
        XCTAssertEqual("", TeaJSON.stringify(nil))
        let parsed = TeaJSON.parse("{\"b\":2}") as? [String: Any]
        XCTAssertEqual(2, parsed?["b"] as? Int)
        XCTAssertNil(TeaJSON.parse(nil))
        XCTAssertEqual([UInt8]("hi".utf8), TeaBytes.from("hi", "utf-8"))
        XCTAssertEqual("6869", TeaBytes.toHex([0x68, 0x69]))
        _ = TeaEnv.get("PATH")
    }

    func testSSEEventInit() {
        let e = SSEEvent(["data": "d", "id": "i", "event": "e", "retry": 1])
        XCTAssertEqual("d", e.data)
        XCTAssertEqual("i", e.id)
        XCTAssertEqual("e", e.event)
        XCTAssertEqual(1, e.retry)
        let e2 = SSEEvent(data: "x", id: "y", event: "z", retry: 2)
        XCTAssertEqual("x", e2.data)
        XCTAssertEqual(2, e2.retry)
        let e3 = SSEEvent(["retry": Int32(9)])
        XCTAssertEqual(9, e3.retry)
        let e4 = SSEEvent(["retry": NSNumber(value: 8)])
        XCTAssertEqual(8, e4.retry)
    }

    func testReadAsBytesFromInputStream() throws {
        let bytes = try TeaStream.readAsBytes(TeaCore.toReadable("abc"))
        XCTAssertEqual([UInt8]("abc".utf8), bytes)
    }

    func testReadAsSSETrailingRemain() async throws {
        // leftover without trailing blank line is flushed at end
        var collected: [SSEEvent] = []
        for try await event in TeaStream.readAsSSE(chunks: ["data: tail"]) {
            collected.append(event)
        }
        XCTAssertEqual(1, collected.count)
        XCTAssertEqual("tail", collected[0].data)
    }

    func testErrorHelpersAndBranches() {
        let empty = BaseError()
        XCTAssertEqual("BaseError", empty.name)
        let msgOnly = BaseError("hello")
        XCTAssertEqual("hello", msgOnly.message)
        let codeOnly = BaseError(["code": "C"])
        XCTAssertEqual("C", codeOnly.message)
        XCTAssertEqual("C", codeOnly.getCode())

        let err = ResponseError([
            "code": "T",
            "message": "m",
            "retryAfter": NSNumber(value: 42),
            "statusCode": Int32(418),
            "data": ["statusCode": Int32(419)]
        ])
        XCTAssertEqual(42, err.getRetryAfter())
        XCTAssertEqual(418, err.getStatusCode())
        XCTAssertNotNil(err.getData())

        let fromDataInt32 = ResponseError([
            "code": "T",
            "message": "m",
            "data": ["statusCode": Int32(420)]
        ])
        XCTAssertEqual(420, fromDataInt32.statusCode)

        let bare = TeaErrors.newUnretryableError(RetryPolicyContext())
        XCTAssertTrue(bare is UnretryableError)
        let fromReq = TeaErrors.newUnretryableError(TeaRequest())
        XCTAssertTrue(fromReq is UnretryableError)
    }

    func testBuiltinMoreBranches() {
        XCTAssertEqual("keep", TeaBuiltin.default("keep" as String?, "fallback"))
        XCTAssertEqual("s", TeaJSON.stringify("s"))
        XCTAssertEqual("", TeaJSON.stringify(TeaCore.self)) // invalid JSON object
        XCTAssertEqual([UInt8]("x".utf8), TeaBytes.from("x", "latin1"))
    }
}
