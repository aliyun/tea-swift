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

final class InsecureServerTrustManager: ServerTrustManager, @unchecked Sendable {
    init() {
        super.init(allHostsMustBeEvaluated: false, evaluators: [:])
    }

    override func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        return DisabledTrustEvaluator()
    }
}

open class TeaCore {
    private static let bufferLength: Int = 1024
    private static let defaultConnectTimeout: Int = TeaRuntime.defaultConnectTimeoutMs
    private static let defaultReadTimeout: Int = TeaRuntime.defaultReadTimeoutMs
    private static let defaultMaxIdleConnsPerHost : Int = TeaRuntime.defaultMaxIdleConnsPerHost
    

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
    public static func doAction(_ request: TeaRequest, _ config: URLSessionConfiguration = URLSessionConfiguration.default, serverTrustManager: ServerTrustManager? = nil) async throws -> TeaResponse {
        let session = Session(configuration: config, serverTrustManager: serverTrustManager)
        if request.body != nil {
            let task = session.upload(
                request.body!,
                to: TeaCore.composeUrl(request),
                method: HTTPMethod(rawValue: request.method),
                headers: HTTPHeaders(request.headers))
                .serializingData()
            let response = await task.response
            return try TeaResponse(response)
        } else {
            let task = session.request(
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
        let resolved = TeaRuntime.resolve(
            runtime,
            host: request.headers["host"],
            isHTTPS: request.protocol_.lowercased() == "https"
        )
        let config = URLSessionConfiguration.default
        TeaRuntime.apply(resolved, to: config)
        let trust: ServerTrustManager? = resolved.ignoreSSL ? InsecureServerTrustManager() : nil
        return try await TeaCore.doAction(request, config, serverTrustManager: trust)
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

    /// Darabonba 2.0: whether another attempt should be made.
    public static func shouldRetry(_ options: RetryOptions?, _ ctx: RetryPolicyContext) -> Bool {
        return TeaRetry.shouldRetry(options, ctx)
    }

    /// Convenience for generated code that reads `_runtime["retryOptions"]` as `Any?`.
    public static func shouldRetry(_ options: Any?, _ ctx: RetryPolicyContext) -> Bool {
        if let o = options as? RetryOptions {
            return shouldRetry(o, ctx)
        }
        if let map = options as? [String: Any] {
            return shouldRetry(RetryOptions(map), ctx)
        }
        return shouldRetry(nil as RetryOptions?, ctx)
    }

    /// Darabonba 2.0: backoff delay in **milliseconds**.
    public static func getBackoffDelay(_ options: RetryOptions?, _ ctx: RetryPolicyContext) -> Int {
        return TeaRetry.getBackoffDelay(options, ctx)
    }

    /// Convenience for generated code that reads `_runtime["retryOptions"]` as `Any?`.
    public static func getBackoffDelay(_ options: Any?, _ ctx: RetryPolicyContext) -> Int {
        if let o = options as? RetryOptions {
            return getBackoffDelay(o, ctx)
        }
        if let map = options as? [String: Any] {
            return getBackoffDelay(RetryOptions(map), ctx)
        }
        return getBackoffDelay(nil as RetryOptions?, ctx)
    }

    /// Factory for generated retry loops (avoids needing a model ctor in the generator).
    public static func retryPolicyContext(
        retriesAttempted: Int,
        exception: Error? = nil,
        httpRequest: TeaRequest? = nil,
        httpResponse: TeaResponse? = nil
    ) -> RetryPolicyContext {
        return RetryPolicyContext(
            retriesAttempted: retriesAttempted,
            httpRequest: httpRequest,
            httpResponse: httpResponse,
            exception: exception
        )
    }

    public static func isRetryable(_ e: Error) -> Bool {
        return e is RetryableError
    }
    
    public static func timeNow() -> Int32 {
        return Int32(Date().timeIntervalSince1970)
    }

    /// Classic Tea 1.x: `time` is **seconds** (paired with `getBackoffTime`).
    public static func sleep(_ time: Int32) -> Void {
        Thread.sleep(forTimeInterval: Double(time))
    }

    /// Darabonba 2.0: `milliseconds` (paired with `getBackoffDelay`).
    public static func sleep(_ milliseconds: Int) -> Void {
        if milliseconds <= 0 {
            return
        }
        Thread.sleep(forTimeInterval: Double(milliseconds) / 1000.0)
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

    open func fromMap(_ dict: [String: Any?]?) -> Void { }
    
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
        if res?.error != nil {
            throw RetryableError(res?.error)
        }
        statusCode = Int32(res?.response?.statusCode ?? 0)
        body = res?.data
        request = res?.request
        response = res?.response
        headers = response?.headers.dictionary ?? [:]
        statusMessage = res?.debugDescription ?? ""
    }

    public init(statusCode: Int32, headers: [String: String] = [:], body: Data? = nil, statusMessage: String = "") {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.statusMessage = statusMessage
        self.request = nil
        self.response = nil
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

