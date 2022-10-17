import Alamofire
import Foundation
import Swift

#if swift(<5.5)
#error("Tea doesn't support Swift versions below 5.5.")
#endif

open class TeaError: Error {
    public var message: String?
    
    public init() {
    }
    
    public init(_ msg: String?) {
        message = msg
    }

    public func getMessage() -> String? {
        return message
    }
}

open class ValidateError: TeaError {
    public var data: Any?
    
    public init(_ any: Any?) {
        super.init()
        data = any
    }

    public override init(_ msg: String?) {
        super.init(msg)
    }
}

open class ReuqestError: TeaError {
    public var code: String?
    public var statusCode: Int?
    public var data: [String: Any]?
    public var description: String?
    public var accessDeniedDetail: [String: Any]?
    
    public init(_ map: [String: Any]?) {
        super.init()
        message = map?["message"] as? String
        code = map?["code"] as? String
        description = map?["description"] as? String
        accessDeniedDetail = map?["accessDeniedDetail"] as? [String: Any]
        if map?["data"] != nil {
            data = map?["data"] as? [String: Any]
            if data?["statusCode"] != nil {
                statusCode = data?["statusCode"] as? Int
            }
        }
    }
    
    public func getCode() -> String? {
        return code
    }

    public func getStatusCode() -> Int? {
        return statusCode
    }
    
}

open class RetryableError: TeaError {
    public var couse: Error?
    
    public init(_ err: Error?) {
        super.init(err?.localizedDescription)
        couse = err
    }
    
}

open class UnretryableError: TeaError {
    public var request: TeaRequest?
    public var couse: Error?
    
    public init(_ req: TeaRequest?, _ err: Error?) {
        super.init(err?.localizedDescription)
        request = req
        couse = err
    }
    
}

open class TeaCore {
    private static let bufferLength: Int = 1024
    private static let defaultConnectTimeout: Int = 5 * 1000
    private static let defaultReadTimeout: Int = 10 * 1000
    private static let defaultMaxIdleConnsPerHost : Int = 128
    

    public static func composeUrl(_ request: TeaRequest) -> String {
        var url: String = ""
        let host: String = request.headers["host"] ?? ""
        url = url + request.protocol_.lowercased() + "://" + host
        if request.port != 80 {
            url = url + ":" + String(request.port)
        }
        url = url + request.pathname
        if request.query.count > 0 {
            let query: String = httpQueryString(request.query)
            if query.lengthOfBytes(using: .utf8) > 0 {
                if url.contains("?") {
                    if url.last != "&" {
                        url += "&"
                    }
                    url += query
                } else {
                    url += "?" + query
                }
            }
        }
        return url
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public static func doAction(_ request: TeaRequest, _ config: URLSessionConfiguration = URLSessionConfiguration.default) async throws -> TeaResponse {
        if request.body != nil {
            let task = AF.upload(
                request.body!,
                to: TeaCore.composeUrl(request),
                method: HTTPMethod(rawValue: request.method),
                headers: HTTPHeaders(request.headers))
                .serializingData()
            let response = await task.response
            return try TeaResponse(response)
        } else {
            let task = AF.request(
                TeaCore.composeUrl(request),
                method: HTTPMethod(rawValue: request.method),
                headers: HTTPHeaders(request.headers))
                .serializingData()
            let response = await task.response
            return try TeaResponse(response)
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public static func doAction(_ request: TeaRequest, _ runtime: [String: Any]) async throws -> TeaResponse {
        let config: URLSessionConfiguration = URLSessionConfiguration.default
        var connectTimeout: Int? = runtime["connectTimeout"] as? Int
        if connectTimeout == 0 {
            connectTimeout = defaultConnectTimeout
        }
        var readTimeout: Int? = runtime["readTimeout"] as? Int
        if readTimeout == 0 {
            readTimeout = defaultReadTimeout
        }
        var maxIdleConns: Int? = runtime["maxIdleConns"] as? Int
        if maxIdleConns == 0 {
            maxIdleConns = defaultMaxIdleConnsPerHost
        }
        config.timeoutIntervalForRequest = TimeInterval(connectTimeout ?? defaultConnectTimeout)
        config.timeoutIntervalForResource = TimeInterval(readTimeout ?? defaultReadTimeout)
        config.httpMaximumConnectionsPerHost = maxIdleConns ?? defaultMaxIdleConnsPerHost
        return try await TeaCore.doAction(request, config)
    }
    
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public static func doAction(_ request: TeaRequest) async throws -> TeaResponse {
        let runtime: [String: Any] = [:]
        return try await TeaCore.doAction(request, runtime)
    }

    public static func allowRetry(_ dict: Any?, _ retryTimes: Int32, _ now: Int32) -> Bool {
        if(retryTimes < 1){
            return true
        }
        let dic = dict as? [String: Any]
        let retryable = dic?["retryable"]
        let isNotExists = dic?["maxAttempts"] == nil
        if dict == nil || retryable == nil  || !(retryable as! Bool) || isNotExists {
            return false
        }
        let maxAttempts: Int = dic?["maxAttempts"] as! Int
        return maxAttempts >= retryTimes
    }

    public static func getBackoffTime(_ dict: Any?, _ retryTimes: Int32) -> Int32 {
        var backOffTime: Int32 = 0
        let dic = dict as? [String: Any]
        let policy: String = dic?["policy"] as! String
        if policy == "" || policy.isEmpty || policy == "no" {
            return backOffTime
        }

        let period: String = dic?["period"] as! String
        if period != "" {
            backOffTime = Int32(period)!
            if backOffTime <= 0 {
                return retryTimes
            }
        }

        return backOffTime
    }

    public static func isRetryable(_ e: Error) -> Bool {
        return e is RetryableError
    }
    
    public static func timeNow() -> Int32 {
        return Int32(Date().timeIntervalSince1970)
    }
    
    public static func sleep(_ time: Int32) -> Void {
        Thread.sleep(forTimeInterval: Double(time))
    }
    
    public static func toReadable(_ string: String) -> InputStream {
        return toReadable(string.toBytes())
    }
    
    public static func toReadable(_ bytes: [UInt8]) -> InputStream {
        let data = Data.init(bytes: bytes, count: bytes.count)
        return InputStream.init(data: data)
    }
}

open class TeaConverter {
    public static func merge<T: Any>(_ dict: [String: T]?...) -> [String: T] {
        var mergeDict: [String: T] = [:]
        for dic in dict {
            if (dic != nil) {
                for (k, v) in dic! {
                    mergeDict[k] = v
                }
            }
        }
        return mergeDict
    }
    
    public static func fromMap<T: TeaModel>(_ model: T, _ dict: [String: Any]) -> T {
        model.fromMap(dict)
        return model
    }
}

open class TeaModel {
    
    public init() { }

    open func toMap() -> [String: Any] {
        return [:]
    }

    open func fromMap(_ dict: [String: Any]) -> Void { }
    
    open func validate() throws -> Void { }
    
    public func validateRequired(_ prop: Any?, _ name: String) throws -> Void {
        if prop == nil {
            throw ValidateError("\(name) is required")
        }
    }
    
    public func validateMaxLength(_ prop: Any?, _ name: String, _ maxLen: Int) throws -> Void {
        if prop == nil {
            return
        }
        if prop is String && (prop as! String).count > maxLen{
            throw ValidateError("\(name) is exceed max-length: \(maxLen)")
        }
        if prop is Dictionary<String, Any> && (prop as! Dictionary<String, Any>).count > maxLen{
            throw ValidateError("\(name) is exceed max-length: \(maxLen)")
        }
        if prop is Array<Any> && (prop as! Array<Any>).count > maxLen{
            throw ValidateError("\(name) is exceed max-length: \(maxLen)")
        }
    }
    
    public func validateMinLength(_ prop: Any?, _ name: String, _ minLen: Int) throws -> Void {
        if prop == nil {
            return
        }
        if prop is String && (prop as! String).count < minLen{
            throw ValidateError("\(name) is less than min-length: \(minLen)")
        }
        if prop is Dictionary<String, Any> && (prop as! Dictionary<String, Any>).count < minLen{
            throw ValidateError("\(name) is less than min-length: \(minLen)")
        }
        if prop is Array<Any> && (prop as! Array<Any>).count < minLen{
            throw ValidateError("\(name) is less than min-length: \(minLen)")
        }
    }
    
    public func validateMaximum(_ prop: Int?, _ name: String, _ maximum: Int) throws -> Void {
        if prop == nil {
            return
        }
        if prop! > maximum {
            throw ValidateError("\(name) is greater than the maximum: \(maximum)")
        }
    }
    
    public func validateMinimum(_ prop: Int?, _ name: String, _ minimum: Int) throws -> Void {
        if prop == nil {
            return
        }
        if prop! < minimum {
            throw ValidateError("\(name) is less than the minimum: \(minimum)")
        }
    }
    
    public func validateMaximum(_ prop: Int32?, _ name: String, _ maximum: Int) throws -> Void {
        if prop == nil {
            return
        }
        if prop! > maximum {
            throw ValidateError("\(name) is greater than the maximum: \(maximum)")
        }
    }
    
    public func validateMinimum(_ prop: Int32?, _ name: String, _ minimum: Int) throws -> Void {
        if prop == nil {
            return
        }
        if prop! < minimum {
            throw ValidateError("\(name) is less than the minimum: \(minimum)")
        }
    }
    
    public func validatePattern(_ prop: String?, _ name: String, _ pattern: String) throws -> Void {
        if prop?.range(of: pattern, options: .regularExpression) != nil {
            throw ValidateError("\(name) is not match: \(pattern)")
        }
    }
}

open class TeaRequest {
    public var requestType: String = "default"

    public var protocol_: String = "http"

    public var method: String = "GET"

    public var pathname: String = ""

    public var headers: [String: String] = [String: String]()

    public var query: [String: String] = [String: String]()

    public var body: InputStream?

    public var port: Int = 80
    
    public init() { }
}

open class TeaResponse {
    public var headers: [String: String] = [String: String]()
    
    /// The status code of the response.
    public let statusCode: Int32

    /// The status message of the response
    public let statusMessage: String

    /// The response data.
    public let body: Data?
    
    /// The original URLRequest for the response.
    public let request: URLRequest?

    /// The HTTPURLResponse object.
    public let response: HTTPURLResponse?

    public init(_ res: DataResponse<Data, AFError>?) throws {
        statusCode = Int32(res?.response?.statusCode ?? 0)
        body = res?.data
        request = res?.request
        response = res?.response
        headers = (response?.headers.dictionary)!
        statusMessage = res.debugDescription
        if res?.error != nil {
            throw RetryableError(res?.error)
        }
    }
}

func httpQueryString(_ query: [String: Any]) -> String {
    var url: String = ""
    if query.count > 0 {
        let keys = Array(query.keys).sorted()
        var arr: [String] = [String]()
        for key in keys {
            let value = query[key]
            if value == nil {
                continue
            }
            arr.append(key.urlEncode() + "=" + "\(value ?? "")".urlEncode())
        }
        if arr.count > 0 {
            url = arr.joined(separator: "&")
        }
    }
    return url
}

