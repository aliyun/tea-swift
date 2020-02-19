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
        XCTAssertEqual("http://fake.domain.com:8080/index.html", url)

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

        let dict: [String: Any] = model.toMap()
        let limit: Int = dict["limit"] as! Int
        let marker: String = dict["marker"] as! String
        let owner: String = dict["owner"] as! String
        XCTAssertEqual(100, limit)
        XCTAssertEqual("fake-marker", marker)
        XCTAssertEqual("fake-owner", owner)
    }

    func testTeaModelValidate() {
        let model = ListDriveRequestModel()
        var thrownError: Error?
        XCTAssertThrowsError(try model.validate()) {
            thrownError = $0
        }
        XCTAssertTrue(
                thrownError is TeaException,
                "Unexpected error type: \(type(of: thrownError))"
        )
        model.owner = "notEmpty"

        XCTAssertTrue(try model.validate())
    }

    func testTeaModelToModel() {
        var dict: [String: Any] = [String: Any]()
        dict["limit"] = 1
        dict["marker"] = "marker"
        dict["owner"] = "owner"
        let model = TeaModel.toModel(dict, ListDriveRequestModel()) as! ListDriveRequestModel
        XCTAssertEqual(1, model.limit)
        XCTAssertEqual("marker", model.marker)
        XCTAssertEqual("owner", model.owner)
    }

    func testTeaCoreSleep() {
        let sleep: Int = 10
        let start: Double = Date().timeIntervalSince1970
        TeaCore.sleep(sleep)
        let end: Double = Date().timeIntervalSince1970
        XCTAssertTrue(Int((end - start)) >= sleep)
    }

    func testTeaCoreDoAction() {
        var res: TeaResponse?
        let expectation = XCTestExpectation(description: "Test async request")
        let request: requestCompletion = { done in
            let request_ = TeaRequest()
            request_.protocol_ = "http"
            request_.method = "POST"
            request_.pathname = "/v2/drive/list"

            request_.headers = [
                "user-agent": "Tea Test for TeaCore.doAction",
                "host": "sz16.api.alicloudccp.com",
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
            request_.body = utils._toJSONString([model])

            var runtime = [String: Any]()
            runtime["connectTimeout"] = 0
            runtime["readTimeout"] = 0
            res = TeaCore.doAction(request_, runtime)
            done(res)
        }
        let done: doneCompletion = { response in
            // do something when get response
            res = response as? TeaResponse
            XCTAssertNotNil(res)
            XCTAssertNil(res?.error)
            XCTAssertEqual("403", res?.statusCode ?? "0")
            XCTAssertEqual("{\"code\":\"InvalidParameter.Accesskeyid\",\"message\":\"The input parameter AccessKeyId is not valid. DoesNotExist\"}", String(bytes: res!.data, encoding: .utf8))
            expectation.fulfill()
        }

        TeaClient.async(request: request, done: done)

        wait(for: [expectation], timeout: 100.0)
    }

    func testTeaCoreAllowRetry() {
        var result: Bool = TeaCore.allowRetry(nil, 3, 0)
        XCTAssertFalse(result)

        var dict: [String: Int] = [String: Int]()
        dict["maxAttempts"] = 5
        result = TeaCore.allowRetry(dict, 0, 0)
        XCTAssertTrue(result)
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
        XCTAssertTrue(TeaCore.isRetryable(TeaException.ValidateError("foo")))
    }

    func testTeaConverterMerge() {
        var dict1: [String: String] = [String: String]()
        var dict2: [String: String] = [String: String]()

        dict1["foo"] = "bar"
        dict2["bar"] = "foo"

        let dict: [String: String] = TeaConverter.merge(dict1, dict2) as! [String: String]
        XCTAssertEqual(dict["foo"], "bar")
        XCTAssertEqual(dict["bar"], "foo")
    }

    static var allTests = [
        ("testTeaCoreComposeUrl", testTeaCoreComposeUrl),
        ("testTeaModelToMap", testTeaModelToMap),
        ("testTeaModelValidate", testTeaModelValidate),
        ("testTeaModelToModel", testTeaModelToModel),
        ("testTeaCoreSleep", testTeaCoreSleep),
        ("testTeaCoreDoAction", testTeaCoreDoAction),
        ("testTeaCoreAllowRetry", testTeaCoreAllowRetry),
        ("testTeaCoreGetBackoffTime", testTeaCoreGetBackoffTime),
        ("testTeaCoreIsRetryable", testTeaCoreIsRetryable),
        ("testTeaConverterMerge", testTeaConverterMerge),
    ]
}
