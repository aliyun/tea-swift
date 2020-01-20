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

    static var allTests = [
        ("testTeaCoreComposeUrl", testTeaCoreComposeUrl),
        ("testTeaModelToMap", testTeaModelToMap),
        ("testTeaModelValidate", testTeaModelValidate),
        ("testTeaModelToModel", testTeaModelToModel),
    ]
}
