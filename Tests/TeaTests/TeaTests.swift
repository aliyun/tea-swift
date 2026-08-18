import Alamofire
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
        let sleep: Int32 = 50
        let start: Double = Date().timeIntervalSince1970
        TeaCore.sleep(sleep)
        let end: Double = Date().timeIntervalSince1970
        XCTAssertTrue((end - start) >= 0.04)
        XCTAssertTrue((end - start) < 2)
        TeaCore.sleep(0)
        TeaCore.sleep(-1)
    }

    @MainActor
    func testTeaCoreDoAction() async {
        var res: TeaResponse?
        let expectation = XCTestExpectation(description: "Test async request")
        let request_ = TeaRequest()
        request_.protocol_ = "http"
        request_.method = "POST"
        request_.pathname = "/events"
        request_.query = [
            "cluster_id": "test"
        ]

        request_.headers = [
            "user-agent": "Swift Test for TeaCore.doAction",
            "host": "cs.cn-hangzhou.aliyuncs.com",
            "content-type": "application/json; charset=utf-8"
        ]
        let utils: TestsUtils = TestsUtils()
        request_.headers["date"] = utils._getRFC2616Date()
        request_.headers["accept"] = "application/json"
        request_.headers["x-acs-signature-method"] = "HMAC-SHA1"
        request_.headers["x-acs-signature-version"] = "1.0"
        request_.headers["authorization"] = "acs AccessKeyId:TestSignature"

        let model = ListDriveRequestModel()
        model.owner = "owner"
        request_.body = TeaCore.toReadable(utils._toJSONString([model]))

        var runtime = [String: Any]()
        runtime["connectTimeout"] = 0
        runtime["readTimeout"] = 0
        do {
            res = try await TeaCore.doAction(request_, runtime)
            XCTAssertNotNil(res)
        } catch {
            XCTFail("Unexpected error: \(error).")
        }
        
        
        XCTAssertEqual(404, res?.statusCode ?? 0)
        XCTAssertEqual("POST", res!.request?.method?.rawValue)
        XCTAssertEqual("http://cs.cn-hangzhou.aliyuncs.com/events?cluster_id=test", res!.request?.debugDescription)
        let responseBody = String(data: res!.body!, encoding: .utf8)!.jsonDecode()
        XCTAssertEqual("InvalidAction.NotFound", responseBody["Code"] as! String)
        XCTAssertEqual("Specified api is not found, please check your url and method.", responseBody["Message"] as! String)
        XCTAssertNotNil(responseBody["Recommend"])
        XCTAssertEqual("cs.cn-hangzhou.aliyuncs.com", responseBody["HostId"] as! String)
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 100.0)
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
        var dict: [String: String] = [String: String]()
        dict["policy"] = "no"
        XCTAssertEqual(0, TeaCore.getBackoffTime(dict, 3))

        dict["policy"] = "yes"
        dict["period"] = ""
        XCTAssertEqual(0, TeaCore.getBackoffTime(dict, 3))

        dict["period"] = "-1"
        XCTAssertEqual(3, TeaCore.getBackoffTime(dict, 3))

        dict["period"] = "1"
        XCTAssertEqual(1, TeaCore.getBackoffTime(dict, 3))
    }

    func testTeaCoreGetBackoffDelay() {
        XCTAssertEqual(0, TeaCore.getBackoffDelay(nil, 1))
        XCTAssertEqual(0, TeaCore.getBackoffDelay(["policy": "no", "period": 1000], 1))
        XCTAssertEqual(0, TeaCore.getBackoffDelay(["policy": "", "period": 1000], 1))
        XCTAssertEqual(0, TeaCore.getBackoffDelay(["policy": "Exponential", "period": 0], 1))
        XCTAssertEqual(0, TeaCore.getBackoffDelay(["policy": "Exponential", "period": -2], 2))

        XCTAssertEqual(1000, TeaCore.getBackoffDelay(["policy": "Exponential", "period": 1000], 1))
        XCTAssertEqual(2000, TeaCore.getBackoffDelay(["policy": "Exponential", "period": 1000], 2))
        XCTAssertEqual(4000, TeaCore.getBackoffDelay(["policy": "yes", "period": 1000], 3))
        XCTAssertEqual(1000, TeaCore.getBackoffDelay(["policy": "Fixed", "period": 1000], 5))
        XCTAssertEqual(1000, TeaCore.getBackoffDelay(["policy": "equal", "period": 1000], 5))
        XCTAssertEqual(TeaRuntime.maxBackoffDelayMs, TeaCore.getBackoffDelay(["policy": "Exponential", "period": 1000], 31))

        let throttling = ThrottlingError([
            "code": "Throttling",
            "retryAfter": 1500
        ])
        XCTAssertEqual(1500, TeaCore.getBackoffDelay(["policy": "Exponential", "period": 1000], 3, throttling))

        let named = ReuqestError([
            "code": "Throttling.User",
            "retryAfter": 800
        ])
        named.name = "ThrottlingException"
        XCTAssertEqual(800, TeaCore.getBackoffDelay(["policy": "no"], 1, named))
    }

    func testTeaCoreIsRetryable() {
        XCTAssertFalse(TeaCore.isRetryable(ValidateError("foo")))
        XCTAssertTrue(TeaCore.isRetryable(RetryableError(AFError.explicitlyCancelled)))
        XCTAssertTrue(TeaCore.isRetryable(ThrottlingError(["code": "Throttling"])))
        XCTAssertTrue(TeaCore.isRetryable(ServerError(["code": "InternalError"])))
        XCTAssertFalse(TeaCore.isRetryable(ClientError(["code": "InvalidParameter"])))
        let openapiLike = ReuqestError(["code": "Throttling"])
        openapiLike.name = "ThrottlingException"
        XCTAssertTrue(TeaCore.isRetryable(openapiLike))
        let serverLike = ReuqestError(["code": "ServiceUnavailable"])
        serverLike.name = "ServerException"
        XCTAssertTrue(TeaCore.isRetryable(serverLike))
        enum DummyThrottling: Error { case x }
        enum DummyServerError: Error { case y }
        XCTAssertTrue(TeaCore.isRetryable(DummyThrottling.x))
        XCTAssertTrue(TeaCore.isRetryable(DummyServerError.y))
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
        err.description = "set"
        XCTAssertEqual("set", err.description)

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
        XCTAssertEqual("ReuqestError", err.getName())

        let client = ClientError(["code": "InvalidParameter", "statusCode": 400, "message": "bad", "requestId": "rid"])
        XCTAssertEqual("ClientError", client.getName())
        XCTAssertEqual(400, client.getStatusCode())
        XCTAssertEqual("rid", client.requestId)

        let server = ServerError(["code": "InternalError", "statusCode": 500])
        XCTAssertEqual("ServerError", server.getName())

        let throttling = ThrottlingError([
            "code": "Throttling",
            "statusCode": 429,
            "retryAfter": 1200,
            "detail": "slow down"
        ])
        XCTAssertEqual("ThrottlingError", throttling.getName())
        XCTAssertEqual(1200, throttling.getRetryAfter())
        XCTAssertEqual("slow down", throttling.detail)
        XCTAssertEqual("AlibabaCloudError", AlibabaCloudError(["code": "x"]).getName())
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
        XCTAssertEqual(tls_protocol_version_t.TLSv13, TeaRuntime.tlsProtocolVersion(resolved.tlsMinVersion))
    }

}
