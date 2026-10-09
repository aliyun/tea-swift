#if !os(Linux)
import Foundation
import Alamofire
import Tea
import XCTest

private final class LegacyResponse: TeaResponse {
    override init(_ res: DataResponse<Data, AFError>?) throws {
        try super.init(res)
    }
}

final class ResponseCompatibilityTests: XCTestCase {
    func testAlamofireResponsePreservesPublicAPI() throws {
        let url = URL(string: "https://example.com/test")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        let body = Data("{}".utf8)
        let original = DataResponse<Data, AFError>(request: request, response: response,
                                                   data: body, metrics: nil,
                                                   serializationDuration: 0, result: .success(body))

        for result in [try TeaResponse(original), try LegacyResponse(original)] {
            XCTAssertEqual(result.request, request)
            XCTAssertTrue(result.response === response)
            XCTAssertEqual(result.statusCode, 201)
            XCTAssertEqual(result.body, body)
            XCTAssertEqual(result.headers, response.headers.dictionary)
            XCTAssertEqual(result.statusMessage, original.debugDescription)
        }

        let synthetic = TeaResponse(statusCode: 200)
        XCTAssertNil(synthetic.request)
        XCTAssertNil(synthetic.response)
        XCTAssertThrowsError(try TeaResponse(DataResponse<Data, AFError>(
            request: request, response: nil, data: nil, metrics: nil,
            serializationDuration: 0, result: .failure(.explicitlyCancelled)))) {
            XCTAssertTrue($0 is RetryableError)
        }
    }
}
#endif
