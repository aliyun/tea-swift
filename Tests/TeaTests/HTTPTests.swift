import Foundation
import XCTest
@testable import Tea

final class HTTPTests: XCTestCase {
    func testRequestAndErrorResponse() async throws {
        let server = try HTTPTestServer(statusCode: 404)
        defer { server.stop() }
        let request = TeaRequest()
        request.headers = ["host": "127.0.0.1", "x-test": "value", "content-length": "13"]
        request.port = server.port
        request.method = "POST"
        request.pathname = "/echo"
        request.query = ["a": "hello world"]
        request.body = TeaCore.toReadable("{\"test\":true}")
        let response = try await TeaCore.doAction(request)
        XCTAssertEqual(404, response.statusCode)
        XCTAssertEqual("tea", response.headers.first { $0.key.lowercased() == "x-mock" }?.value)
        let received = String(decoding: try XCTUnwrap(response.body), as: UTF8.self)
        XCTAssertTrue(received.hasPrefix("POST /echo?a=hello%20world HTTP/1.1\r\n"))
        XCTAssertTrue(received.lowercased().contains("x-test: value\r\n"))
        XCTAssertTrue(received.hasSuffix("\r\n\r\n{\"test\":true}"))
    }

    func testGetAndEmptyBody() async throws {
        let server = try HTTPTestServer(statusCode: 204, body: "")
        defer { server.stop() }
        let request = TeaRequest()
        request.headers["host"] = "127.0.0.1"
        request.port = server.port
        request.pathname = "/"
        let response = try await TeaCore.doAction(request)
        XCTAssertEqual(204, response.statusCode)
        XCTAssertTrue(response.body?.isEmpty ?? true)
    }

    func testReadTimeoutIsRetryable() async throws {
        let server = try HTTPTestServer(delay: 3)
        defer { server.stop() }
        let request = TeaRequest()
        request.headers["host"] = "127.0.0.1"
        request.port = server.port
        request.pathname = "/"
        let start = Date()
        do {
            _ = try await TeaCore.doAction(request, ["connectTimeout": 500, "readTimeout": 100])
            XCTFail("Delayed response must time out")
        } catch {
            XCTAssertTrue(TeaCore.isRetryable(error))
            XCTAssertLessThan(Date().timeIntervalSince(start), 2)
        }
    }

    func testConnectionFailureIsRetryable() async throws {
        let server = try HTTPTestServer()
        let request = TeaRequest()
        request.headers["host"] = "127.0.0.1"
        request.port = server.port
        request.pathname = "/"
        server.stop()
        do {
            _ = try await TeaCore.doAction(request, ["connectTimeout": 100, "readTimeout": 100])
            XCTFail("Closed local port must fail")
        } catch {
            XCTAssertTrue(TeaCore.isRetryable(error))
        }
    }

    func testAsyncSleepUsesSecondsAndCanBeCancelled() async throws {
        let start = Date()
        try await TeaCore.sleepAsync(1)
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.9)
        let sleeper = Task { try await TeaCore.sleepAsync(60) }
        sleeper.cancel()
        do {
            try await sleeper.value
            XCTFail("Cancelled sleep must throw")
        } catch is CancellationError {
        }
        try await TeaCore.sleepAsync(0)
        try await TeaCore.sleepAsync(-1)
    }
}
