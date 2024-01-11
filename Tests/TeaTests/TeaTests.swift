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
        XCTAssertEqual("value1", response.items?["key1"] as! String)
        XCTAssertEqual("value2", response.items?["key2"] as! String)
        XCTAssertEqual("1", response.list?[0] as! String)
        XCTAssertEqual("2", response.list?[1] as! String)
        XCTAssertEqual("3", response.list?[2] as! String)
        XCTAssertEqual(1, response.nextMarker as! Int)
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
        let sleep: Int32 = 10
        let start: Double = Date().timeIntervalSince1970
        TeaCore.sleep(sleep)
        let end: Double = Date().timeIntervalSince1970
        XCTAssertTrue(Int((end - start)) >= sleep)
    }

    func testTeaCoreDoAction() async {
        var res: TeaResponse?
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
        res = try! await TeaCore.doAction(request_, runtime)
        XCTAssertNotNil(res)
        XCTAssertEqual(404, res?.statusCode ?? 0)
        XCTAssertEqual("POST", res!.request?.method?.rawValue)
        XCTAssertEqual("http://cs.cn-hangzhou.aliyuncs.com/events?cluster_id=test", res!.request?.debugDescription)
        let responseBody = String(data: res!.body!, encoding: .utf8)!.jsonDecode()
        XCTAssertEqual("InvalidAction.NotFound", responseBody["Code"] as! String)
        XCTAssertEqual("Specified api is not found, please check your url and method.", responseBody["Message"] as! String)
        let recommand = responseBody["Recommend"] as! String
        XCTAssertTrue(recommand.starts(with: "https://api.aliyun.com/troubleshoot?q=InvalidAction.NotFound&product=CS&requestId="))
        XCTAssertEqual("cs.cn-hangzhou.aliyuncs.com", responseBody["HostId"] as! String)
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

    func testTeaCoreIsRetryable() {
        XCTAssertFalse(TeaCore.isRetryable(ValidateError("foo")))
        XCTAssertTrue(TeaCore.isRetryable(RetryableError(AFError.explicitlyCancelled)))
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

    static var allTests = [
        ("testTeaCoreComposeUrl", testTeaCoreComposeUrl),
        ("testTeaModelToMap", testTeaModelToMap),
        ("testTeaModelValidate", testTeaModelValidate),
        ("testTeaModelFromMap", testTeaModelFromMap),
        ("testTeaCoreSleep", testTeaCoreSleep),
        ("testTeaCoreDoAction", testTeaCoreDoAction),
        ("testTeaCoreAllowRetry", testTeaCoreAllowRetry),
        ("testTeaCoreGetBackoffTime", testTeaCoreGetBackoffTime),
        ("testTeaCoreIsRetryable", testTeaCoreIsRetryable),
        ("testTeaConverterMerge", testTeaConverterMerge),
    ]
}
