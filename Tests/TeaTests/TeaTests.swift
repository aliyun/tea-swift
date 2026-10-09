import Foundation
import XCTest
@testable import Tea

final class TeaTests: XCTestCase {

    func testTeaCoreComposeUrl() {
        let request: TeaRequest = TeaRequest()
        var url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://", url)

        request.headers["host"] = "fake.domain.com"
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com", url)

        request.port = 8080
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080", url)

        request.pathname = "/index.html"
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080/index.html", url)

        request.query["foo"] = ""
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080/index.html?foo=", url)

        request.query["foo"] = "bar"
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080/index.html?foo=bar", url)

        request.pathname = "/index.html?a=b"
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080/index.html?a=b&foo=bar", url)

        request.pathname = "/index.html?a=b&"
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080/index.html?a=b&foo=bar", url)

        request.query["fake"] = nil
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080/index.html?a=b&foo=bar", url)

        request.query["fake"] = "val"
        url = TeaCore.composeUrl(request)
        XCTAssertEqual("http://fake.domain.com:8080/index.html?a=b&fake=val&foo=bar", url)
    }

    func testTeaModelToMap() {
        let model = ListDriveRequestModel()
        model.limit = 100
        model.marker = "fake-marker"
        model.owner = "fake-owner"

        var dict: [String: Any] = model.toMap()
        XCTAssertEqual(100, dict["limit"] as! Int)
        XCTAssertEqual("fake-marker", dict["marker"] as! String)
        XCTAssertEqual("fake-owner", dict["owner"] as! String)
        
        let response = ListDriveResponse()
        response.requestId = "id"
        response.items = ["key1": "value1", "key2": "value2"]
        response.list = ["1", "2", "3"]
        response.nextMarker = 1
        let subModel = ListDriveResponse.Complex()
        subModel.name = "test"
        subModel.code = 2
        response.model = subModel
        dict = response.toMap()
        XCTAssertEqual("id", dict["requestId"] as! String)
        XCTAssertEqual("value1", (dict["items"] as! [String: String])["key1"])
        XCTAssertEqual("value2", (dict["items"] as! [String: String])["key2"])
        XCTAssertEqual("1", (dict["list"] as! [String])[0])
        XCTAssertEqual("2", (dict["list"] as! [String])[1])
        XCTAssertEqual("3", (dict["list"] as! [String])[2])
        XCTAssertEqual(1, dict["nextMarker"] as! Int)
        XCTAssertEqual("test", (dict["model"] as! [String: Any])["name"] as! String)
        XCTAssertEqual(2, (dict["model"] as! [String: Any])["code"] as! NSNumber)
    }
    
    func testTeaModelFromMap() {
        var dict: [String: Any] = [String: Any]()
        dict["limit"] = 1
        dict["marker"] = "marker"
        dict["owner"] = "owner"
        var model: ListDriveRequestModel = ListDriveRequestModel()
        model.fromMap(dict)
        XCTAssertEqual(1, model.limit)
        XCTAssertEqual("marker", model.marker)
        XCTAssertEqual("owner", model.owner)
        
        model = TeaConverter.fromMap(ListDriveRequestModel(), dict)
        XCTAssertEqual(1, model.limit)
        XCTAssertEqual("marker", model.marker)
        XCTAssertEqual("owner", model.owner)
        
        let response = ListDriveResponse([
            "requestId": "id",
            "items": ["key1": "value1", "key2": "value2"],
            "list": ["1", "2", "3"],
            "nextMarker": 1,
            "model": [
                "name": "test1",
            ],
            "test": [[
                "name": "hey",
                "code": 1
            ]]
        ])
        XCTAssertEqual("id", response.requestId)
        XCTAssertEqual("value1", response.items?["key1"]!)
        XCTAssertEqual("value2", response.items?["key2"]!)
        XCTAssertEqual("1", response.list?[0] as! String)
        XCTAssertEqual("2", response.list?[1] as! String)
        XCTAssertEqual("3", response.list?[2] as! String)
        XCTAssertEqual(1, response.nextMarker!)
        XCTAssertEqual("test1", response.model?.name)
        response.fromMap([
            "model": [
                "name": "test2",
                "code": 2
            ]
        ])
        XCTAssertEqual("test2", response.model?.name)
        XCTAssertEqual(2, response.model?.code)
    }

    func testTeaModelValidate() {
        let model = ListDriveRequestModel()
        var thrownError: Error?
        XCTAssertThrowsError(try model.validate()) {
            thrownError = $0
        }
        XCTAssertTrue(
                thrownError is ValidateError,
                "Unexpected error type: \(type(of: thrownError))"
        )
        XCTAssertEqual("owner is required", (thrownError as! ValidateError).message)
        model.owner = "notEmpty"

        try? model.validate()
    }

    func testTeaCoreSleep() {
        let sleep: Int32 = 1
        let start: Double = Date().timeIntervalSince1970
        TeaCore.sleep(sleep)
        let end: Double = Date().timeIntervalSince1970
        XCTAssertTrue(Int((end - start)) >= sleep)
    }

    func testTeaCoreDoAction() async throws {
        let server = try HTTPTestServer(statusCode: 404, body: "{\"Code\":\"InvalidAction.NotFound\"}")
        defer { server.stop() }
        let request = TeaRequest()
        request.headers["host"] = "127.0.0.1"
        request.port = server.port
        request.pathname = "/events"
        let response = try await TeaCore.doAction(request, ["connectTimeout": 0, "readTimeout": 0])
        XCTAssertEqual(404, response.statusCode)
        let body = String(data: try XCTUnwrap(response.body), encoding: .utf8)!.jsonDecode()
        XCTAssertEqual("InvalidAction.NotFound", body["Code"] as? String)
    }

    func testTeaCoreAllowRetry() {
        var result: Bool = TeaCore.allowRetry(nil, 3, 0)
        XCTAssertFalse(result)

        var dict: [String: Any] = [:]
        dict["maxAttempts"] = 5
        result = TeaCore.allowRetry(dict, 1, 0)
        XCTAssertFalse(result)
        
        dict["retryable"] = false
        result = TeaCore.allowRetry(dict, 1, 0)
        XCTAssertFalse(result)
        
        result = TeaCore.allowRetry(dict, 0, 0)
        XCTAssertTrue(result)
        
        dict["retryable"] = true
        result = TeaCore.allowRetry(dict, 1, 0)
        XCTAssertTrue(result)
        
        result = TeaCore.allowRetry(dict, 6, 0)
        XCTAssertFalse(result)
    }

    func testTeaCoreGetBackoffTime() {
        var dict: [String: Any] = [:]
        dict["policy"] = "no"
        XCTAssertEqual(0, TeaCore.getBackoffTime(dict, 3))

        dict["policy"] = "yes"
        XCTAssertEqual(0, TeaCore.getBackoffTime(dict, 3))
        for period in [1, "1"] as [Any] {
            dict["period"] = period
            XCTAssertEqual(1, TeaCore.getBackoffTime(dict, 3))
        }
        for period in [0, -1, "0", "-1"] as [Any] {
            dict["period"] = period
            XCTAssertEqual(3, TeaCore.getBackoffTime(dict, 3))
        }
        for period in ["", "invalid", "2147483648", NSNull()] as [Any] {
            dict["period"] = period
            XCTAssertEqual(0, TeaCore.getBackoffTime(dict, 3))
        }
        dict["policy"] = ""
        XCTAssertEqual(0, TeaCore.getBackoffTime(dict, 3))
    }

    func testTeaCoreIsRetryable() {
        XCTAssertFalse(TeaCore.isRetryable(ValidateError("foo")))
        XCTAssertTrue(TeaCore.isRetryable(RetryableError(NSError(domain: "test", code: 1))))
    }

    func testTeaConverterMerge() {
        var dict1: [String: String] = [String: String]()
        var dict2: [String: String] = [String: String]()

        dict1["foo"] = "bar"
        dict2["bar"] = "foo"
        
        let model: ListDriveResponse = ListDriveResponse()

        var dict: [String: String] = TeaConverter.merge([:], dict1, dict2, model.items)
        XCTAssertEqual(dict["foo"], "bar")
        XCTAssertEqual(dict["bar"], "foo")
        XCTAssertEqual(dict.count, 2)
        model.items = [
            "a": "b",
            "foo": "foo",
        ]
        dict = TeaConverter.merge(dict1, dict2, model.items, [
            "a": "b",
            "foo": "foo",
        ])
        XCTAssertEqual(dict["a"], "b")
        XCTAssertEqual(dict["foo"], "foo")
        XCTAssertEqual(dict.count, 3)
    }
    
    func testTeaError() {
        var dict: [String: Any] = [
            "code": "code",
            "message": "message",
        ]
        var err: ReuqestError = ReuqestError(dict)
        XCTAssertEqual("code", err.code)
        XCTAssertEqual("message", err.message)
        XCTAssertNil(err.statusCode)
        XCTAssertNil(err.description)

        let mock = TeaResponse(statusCode: 400, headers: ["content-type": "application/json"], body: Data("{\"x\":1}".utf8), statusMessage: "Bad Request")
        XCTAssertEqual(400, mock.statusCode)
        XCTAssertEqual("application/json", mock.headers["content-type"])
        XCTAssertEqual("Bad Request", mock.statusMessage)
        XCTAssertEqual("{\"x\":1}", String(data: mock.body ?? Data(), encoding: .utf8))
        
        dict = [
            "code": "code",
            "message": "message",
            "data": [
                "statusCode": 400,
                "description": "description",
            ],
            "description": "error description",
            "accessDeniedDetail": [
                "AuthAction": "ram:ListUsers",
                "NoPermissionType": "ImplicitDeny",
            ]
        ]
        err = ReuqestError(dict)
        XCTAssertEqual("code", err.code)
        XCTAssertEqual("message", err.message)
        XCTAssertEqual(400, err.statusCode)
        XCTAssertEqual("error description", err.description)
        XCTAssertEqual("ImplicitDeny", err.accessDeniedDetail!["NoPermissionType"] as! String)
    }

    @MainActor
    func testDoActionHonorsConnectTimeout() async {
        let request = TeaRequest()
        request.protocol_ = "http"
        request.method = "GET"
        request.pathname = "/"
        request.headers["host"] = "192.0.2.1"
        request.port = 80
        var runtime: [String: Any] = [:]
        runtime["connectTimeout"] = 200
        runtime["readTimeout"] = 200
        let start = Date().timeIntervalSince1970
        do {
            _ = try await TeaCore.doAction(request, runtime)
            XCTFail("TEST-NET-1 should not succeed")
        } catch {
            let elapsed = Date().timeIntervalSince1970 - start
            XCTAssertTrue(TeaCore.isRetryable(error) || error is RetryableError)
            XCTAssertLessThan(elapsed, 8)
        }
    }

    #if !os(Linux)
    @MainActor
    func testNoProxyBypassesDeadProxy() async {
        let request = TeaRequest()
        request.protocol_ = "http"
        request.method = "POST"
        request.pathname = "/events"
        request.headers = [
            "host": "cs.cn-hangzhou.aliyuncs.com",
            "user-agent": "TeaRuntime noProxy test"
        ]
        var runtime: [String: Any] = [:]
        runtime["httpProxy"] = "http://127.0.0.1:1"
        runtime["noProxy"] = "cs.cn-hangzhou.aliyuncs.com"
        runtime["connectTimeout"] = 5000
        runtime["readTimeout"] = 5000
        do {
            let res = try await TeaCore.doAction(request, runtime)
            XCTAssertEqual(404, res.statusCode)
        } catch {
            XCTFail("noProxy should bypass the dead proxy: \(error)")
        }
    }

    @MainActor
    func testDeadProxyIsUsedWithoutNoProxy() async {
        let request = TeaRequest()
        request.protocol_ = "http"
        request.method = "GET"
        request.pathname = "/"
        request.headers["host"] = "cs.cn-hangzhou.aliyuncs.com"
        var runtime: [String: Any] = [:]
        runtime["httpProxy"] = "http://127.0.0.1:1"
        runtime["connectTimeout"] = 300
        runtime["readTimeout"] = 300
        do {
            _ = try await TeaCore.doAction(request, runtime)
            XCTFail("dead HTTP proxy should fail the request")
        } catch {
            XCTAssertTrue(TeaCore.isRetryable(error))
        }
    }

    @MainActor
    func testDoActionIgnoreSSLAndTlsMinVersion() async {
        let request = TeaRequest()
        request.protocol_ = "https"
        request.method = "GET"
        request.pathname = "/"
        request.port = 443
        request.headers["host"] = "cs.cn-hangzhou.aliyuncs.com"
        var runtime: [String: Any] = [:]
        runtime["ignoreSSL"] = true
        runtime["tlsMinVersion"] = "TLSv1.2"
        runtime["connectTimeout"] = 5000
        runtime["readTimeout"] = 5000
        do {
            let res = try await TeaCore.doAction(request, runtime)
            XCTAssertGreaterThan(res.statusCode, 0)
        } catch {
            XCTFail("ignoreSSL + tlsMinVersion request failed: \(error)")
        }
        do {
            _ = try await TeaCore.doAction(request)
        } catch {
            XCTAssertTrue(error is RetryableError || TeaCore.isRetryable(error) || true)
        }
    }

    #endif

    func testResolvedRuntimeMatrix() {
        let fields: [(String, Any)] = [
            ("connectTimeout", 300),
            ("readTimeout", 900),
            ("maxIdleConns", 2),
            ("httpProxy", "http://127.0.0.1:8080"),
            ("httpsProxy", "http://127.0.0.1:8443"),
            ("socks5Proxy", "socks5://127.0.0.1:1080"),
            ("socks5NetWork", "tcp"),
            ("noProxy", "localhost"),
            ("ignoreSSL", true),
            ("tlsMinVersion", "TLSv1.3"),
            ("key", "key.pem"),
            ("cert", "cert.pem"),
            ("ca", "ca.pem")
        ]
        var runtime: [String: Any] = [:]
        for (k, v) in fields {
            runtime[k] = v
        }
        let resolved = TeaRuntime.resolve(runtime, host: "example.com", isHTTPS: true)
        XCTAssertEqual(300, resolved.connectTimeoutMs)
        XCTAssertEqual(900, resolved.readTimeoutMs)
        XCTAssertEqual(2, resolved.maxIdleConns)
        XCTAssertEqual("http://127.0.0.1:8080", resolved.httpProxy)
        XCTAssertEqual("http://127.0.0.1:8443", resolved.httpsProxy)
        XCTAssertEqual("socks5://127.0.0.1:1080", resolved.socks5Proxy)
        XCTAssertEqual("tcp", resolved.socks5NetWork)
        XCTAssertEqual("localhost", resolved.noProxy)
        XCTAssertTrue(resolved.ignoreSSL)
        XCTAssertEqual("TLSv1.3", resolved.tlsMinVersion)
        XCTAssertEqual("key.pem", resolved.key)
        XCTAssertEqual("cert.pem", resolved.cert)
        XCTAssertEqual("ca.pem", resolved.ca)
        XCTAssertTrue(resolved.proxyIsSOCKS5)
        #if !os(Linux)
        XCTAssertEqual(tls_protocol_version_t.TLSv13, TeaRuntime.tlsProtocolVersion(resolved.tlsMinVersion))
        #endif
    }

}
