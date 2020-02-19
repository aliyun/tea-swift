import Alamofire
import Foundation
import Swift
import AlamofirePromiseKit
import AwaitKit

public enum TeaException: Error {
    case Error(Any?)
    case Unretryable(TeaRequest?)
    case ValidateError(String?)
}

open class TeaCore: NSObject {
    private static let bufferLength: Int = 1024
    private static let bodyMethod: [String] = ["POST", "PUT", "PATCH"]
    private static let defaultTimeout: Int = 10000

    public static func composeUrl(_ request: TeaRequest) -> String {
        var url: String = ""
        let host: String = request.headers["host"] ?? ""
        url = url + request.protocol_.lowercased() + "://" + host
        if request.port != 80 {
            url = url + ":" + String(request.port)
        }
        url = url + request.pathname
        if request.query.count > 0 {
            var arr: [String] = [String]()
            for (key, value) in request.query {
                if value is String, (value as! String).isEmpty {
                    continue
                }
                arr.append(key + "=" + (value as! String))
            }
            arr = arr.sorted()
            if arr.count > 0 {
                if url.contains("?") {
                    if url.last != "&" {
                        url = url + "&"
                    }
                } else {
                    url = url + "?"
                }
                url = url + arr.joined(separator: "&")
            }
        }
        return url
    }

    public static func sleep(_ time: Int) {
        Darwin.sleep(UInt32(time))
    }

    public static func doAction(_ request: TeaRequest, _ config: URLSessionConfiguration = URLSessionConfiguration.default) -> TeaResponse {
        let promise = Alamofire.request(
                TeaCore.composeUrl(request),
                method: HTTPMethod(rawValue: request.method) ?? HTTPMethod.get,
                parameters: request.query,
                encoding: URLEncoding.default,
                headers: request.headers
        ).response();
        let res: DefaultDataResponse = try! await(promise)
        return TeaResponse(res)
    }

    public static func doAction(_ request: TeaRequest, _ runtime: [String: Any]) -> TeaResponse {
        let config: URLSessionConfiguration = URLSessionConfiguration.default
        var connectTimeout: Int = runtime["connectTimeout"] as! Int
        var readTimeout: Int = runtime["readTimeout"] as! Int
        if connectTimeout == 0 {
            connectTimeout = defaultTimeout
        }
        if readTimeout == 0 {
            readTimeout = defaultTimeout
        }
        config.timeoutIntervalForRequest = TimeInterval(connectTimeout)
        config.timeoutIntervalForResource = TimeInterval(readTimeout)
        return TeaCore.doAction(request, config)
    }

    public static func allowRetry(_ dict: Any?, _ retryTimes: Int, _ now: Int32) -> Bool {
        let dic = dict as? [String: Any]
        let isNotExists = dic?["maxAttempts"] == nil
        if dict == nil || isNotExists {
            return false
        }
        let maxAttempts: Int = dic?["maxAttempts"] as! Int
        return maxAttempts >= retryTimes
    }

    public static func getBackoffTime(_ dict: Any?, _ retryTimes: Int) -> Int {
        var backOffTime: Int = 0
        let dic = dict as? [String: Any]
        let policy: String = dic?["policy"] as! String
        if policy == "" || policy.isEmpty || policy == "no" {
            return backOffTime
        }

        let period: String = dic?["period"] as! String
        if period != "" {
            backOffTime = Int(period)!
            if backOffTime <= 0 {
                return retryTimes
            }
        }

        return backOffTime
    }

    public static func isRetryable(_ e: Error) -> Bool {
        return e is TeaException
    }
}

open class TeaConverter: NSObject {
    public static func merge(_ dict: [String: Any]...) -> [String: Any] {
        var mergeDict: [String: Any] = [String: Any]()
        for dic in dict {
            for (k, v) in dic {
                mergeDict[k] = v
            }
        }
        return mergeDict
    }
}

open class TeaModel: NSObject {
    public var __name: [String: String] = [String: String]()

    public var __required: [String: Bool] = [String: Bool]()

    public func toMap() -> [String: Any] {
        var dict: [String: Any] = [String: Any]()
        let mirror = Mirror(reflecting: self)
        for (label, value) in mirror.children {
            dict[label!] = value
        }
        return dict
    }

    public func validate() throws -> Bool {
        let mirror = Mirror(reflecting: self)
        let required = __required
        for (label, value) in mirror.children {
            if required[label!] == true {
                if value is String {
                    if (value as! String).isEmpty {
                        throw TeaException.ValidateError(label)
                    }
                }
            }
        }
        return true
    }

    public static func toModel(_ dict: [String: Any], _ obj: NSObject) -> Any? {
        for (key, value) in dict {
            obj.setValue(value, forKey: key)
        }
        return obj
    }
}

open class TeaRequest: NSObject {
    public var requestType: String = "default"

    public var protocol_: String = "http"

    public var method: String = "GET"

    public var pathname: String = ""

    public var headers: [String: String] = [String: String]()

    public var query: [String: Any] = [String: Any]()

    public var body: String = ""

    public var port: Int = 80

    public var host: String = ""

    public override init() {
    }
}

open class TeaResponse: CustomDebugStringConvertible {
    public var headers: [String: String] = [String: String]()

    /// The status code of the response.
    public let statusCode: String

    // The status message of the response
    public let statusMessage: String

    /// The response data.
    public let data: Data

    /// The original URLRequest for the response.
    public let request: URLRequest?

    /// The HTTPURLResponse object.
    public let response: HTTPURLResponse?

    public let error: Error?

    public init(_ res: DefaultDataResponse?) {
        statusCode = "\(res?.response?.statusCode ?? 0)"
        data = (res?.data)!
        request = res?.request
        response = res?.response
        error = res?.error
        statusMessage = res.debugDescription
    }

    /// A text description of the `Response`.
    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.count)"
    }

    /// A text description of the `Response`. Suitable for debugging.
    public var debugDescription: String {
        return description
    }
}
