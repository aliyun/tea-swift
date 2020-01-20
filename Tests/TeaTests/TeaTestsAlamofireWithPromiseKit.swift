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
    var config: URLSessionConfiguration = URLSessionConfiguration.default
    var delegate: SessionDelegate = SessionDelegate()
    var sessionManager: SessionManager? = nil

    override func setUp() {
        super.setUp()
        config.timeoutIntervalForRequest = 10000
        config.timeoutIntervalForResource = 10000
        sessionManager = Alamofire.SessionManager(configuration: config)
    }

    func testDataRequestResponse() {
        guard let promise = sessionManager?.request(url, method: HTTPMethod.get).response() else {
            return
        }
        let res: DefaultDataResponse = try! await(promise)
        XCTAssertNotNil(res)
        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDataRequestResponseString() {
        guard let promise = sessionManager?.request(url, method: HTTPMethod.get).responseString() else {
            return
        }
        let res: DataResponse<String> = try! await(promise)
        XCTAssertNotNil(res)
        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDataRequestResponseData() {
        guard let promise = sessionManager?.request(url, method: HTTPMethod.get).responseData() else {
            return
        }
        let res: DataResponse<Data> = try! await(promise)
        XCTAssertNotNil(res)
        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDataRequestResponseJSON() {
        guard let promise = sessionManager?.request(url, method: HTTPMethod.get).responseJSON() else {
            return
        }
        let res: DataResponse<Any> = try! await(promise)
        XCTAssertNotNil(res)
        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }

    func testDataRequestResponsePropertyList() {
        guard let promise = sessionManager?.request(url, method: HTTPMethod.get).responsePropertyList() else {
            return
        }
        let res: DataResponse<Any> = try! await(promise)
        XCTAssertNotNil(res)
        let result: String = String(data: res.data!, encoding: .utf8) ?? ""
        XCTAssertFalse(result.isEmpty)
    }
}