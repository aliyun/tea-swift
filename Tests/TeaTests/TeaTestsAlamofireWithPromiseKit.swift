//
// Created by Axios on 2020/1/14.
//

import Foundation

import XCTest
import AwaitKit
import Alamofire
import PromiseKit
@testable import Tea

final class TeaTestsAlamofireWithPromiseKit: XCTestCase {
    var url: String = "https://httpbin.org/get"
    var sessionManager: SessionManager?
    let queue: DispatchQueue = DispatchQueue(label: "AlamofirePromiseKit.TestsQueue")

    override func setUp() {
        super.setUp()
        let config: URLSessionConfiguration = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10000
        config.timeoutIntervalForResource = 10000
        sessionManager = Alamofire.SessionManager(configuration: config)
    }

    func testDataRequestResponse() {
        let promise = sessionManager?.request(url, method: HTTPMethod.get).response(queue: queue)
        let res: DefaultDataResponse = try! await(promise!)
        XCTAssertNotNil(res)

        let code: Int = res.response?.statusCode ?? -1
        XCTAssertEqual(200, code)

        let data: [String: AnyObject] = try! JSONSerialization.jsonObject(with: res.data!, options: .mutableContainers) as! [String: AnyObject]
        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)

        let url: String = data["url"] as! String
        XCTAssertEqual("https://httpbin.org/get", url)
    }

    func testDataRequestResponseString() {
        let promise: Promise? = sessionManager?.request(url, method: HTTPMethod.get).responseString(queue: queue)
        let res: DataResponse<String> = try! await(promise!)
        XCTAssertNotNil(res)

        let code: Int = res.response?.statusCode ?? -1
        XCTAssertEqual(200, code)

        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDataRequestResponseData() {
        let promise = sessionManager?.request(url, method: HTTPMethod.get).responseData(queue: queue)
        let res: DataResponse<Data> = try! await(promise!)
        XCTAssertNotNil(res)

        let code: Int = res.response?.statusCode ?? -1
        XCTAssertEqual(200, code)

        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDataRequestResponseJSON() {
        let promise: Promise? = sessionManager?.request(url, method: HTTPMethod.get).responseJSON(queue: queue)
        let res: DataResponse<Any> = try! await(promise!)
        XCTAssertNotNil(res)

        let code: Int = res.response?.statusCode ?? -1
        XCTAssertEqual(200, code)

        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDataRequestResponsePropertyList() {
        let promise: Promise? = sessionManager?.request(url, method: HTTPMethod.get).responsePropertyList(queue: queue)
        let res: DataResponse<Any> = try! await(promise!)
        XCTAssertNotNil(res)

        let code: Int = res.response?.statusCode ?? -1
        XCTAssertEqual(200, code)

        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDownloadRequestResponse() {
        let promise: Promise? = sessionManager?.download(url).response(queue: queue)
        let res: DefaultDownloadResponse = try! await(promise!)
        let code: Int = res.response?.statusCode ?? -1
        XCTAssertEqual(200, code)
    }

    func testDownloadRequestResponseData() {
        let promise: Promise? = sessionManager?.download(url).responseData(queue: queue)
        let res: DownloadResponse<Data> = try! await(promise!)
        let code: Int = res.response?.statusCode ?? -1
        XCTAssertEqual(200, code)
    }

    static var allTests = [
        ("testDataRequestResponse", testDataRequestResponse),
        ("testDataRequestResponseString", testDataRequestResponseString),
        ("testDataRequestResponseData", testDataRequestResponseData),
        ("testDataRequestResponseJSON", testDataRequestResponseJSON),
        ("testDataRequestResponsePropertyList", testDataRequestResponsePropertyList),
    ]
}