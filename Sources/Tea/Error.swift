import Foundation

/// Darabonba 2.0 `$Error` / BaseError with stable `name` + `code` for retry matching.
open class BaseError: TeaError {
    public var name: String = "BaseError"
    public var code: String?

    public override init() {
        super.init()
    }

    public override init(_ msg: String?) {
        super.init(msg)
    }

    public init(_ map: [String: Any]) {
        super.init()
        if let c = map["code"] as? String {
            code = c
        } else if let c = map["code"] as? Int {
            code = String(c)
        }
        if let m = map["message"] as? String {
            message = m
        }
        if let n = map["name"] as? String {
            name = n
        }
        if message == nil, let c = code {
            message = "\(c)"
        }
    }

    public func getName() -> String {
        return name
    }

    public func getCode() -> String? {
        return code
    }
}

/// Darabonba 2.0 `$ResponseError`.
open class ResponseError: BaseError {
    public var statusCode: Int?
    public var retryAfter: Int64?
    public var data: [String: Any]?
    public var descriptionText: String?
    public var accessDeniedDetail: [String: Any]?
    public var detail: String?

    public override init(_ map: [String: Any]) {
        super.init(map)
        name = "ResponseError"
        if let n = map["name"] as? String {
            name = n
        }
        descriptionText = map["description"] as? String
        detail = map["detail"] as? String
        accessDeniedDetail = map["accessDeniedDetail"] as? [String: Any]
        if let ra = map["retryAfter"] as? Int64 {
            retryAfter = ra
        } else if let ra = map["retryAfter"] as? Int {
            retryAfter = Int64(ra)
        } else if let ra = map["retryAfter"] as? NSNumber {
            retryAfter = ra.int64Value
        }
        if let sc = map["statusCode"] as? Int {
            statusCode = sc
        } else if let sc = map["statusCode"] as? Int32 {
            statusCode = Int(sc)
        }
        if let d = map["data"] as? [String: Any] {
            data = d
            if statusCode == nil {
                if let sc = d["statusCode"] as? Int {
                    statusCode = sc
                } else if let sc = d["statusCode"] as? Int32 {
                    statusCode = Int(sc)
                } else if let sc = d["statusCode"] as? String, let v = Int(sc) {
                    statusCode = v
                }
            }
        }
    }

    public func getRetryAfter() -> Int64? {
        return retryAfter
    }

    public func getStatusCode() -> Int? {
        return statusCode
    }

    public func getDescription() -> String? {
        return descriptionText
    }

    public func getData() -> [String: Any]? {
        return data
    }

    public func getAccessDeniedDetail() -> [String: Any]? {
        return accessDeniedDetail
    }
}

public enum TeaErrors {
    public static func newError(_ data: [String: Any]) -> ResponseError {
        return ResponseError(data)
    }

    public static func newUnretryableError(_ ctx: RetryPolicyContext) -> Error {
        if let ex = ctx.exception {
            return ex
        }
        let e = UnretryableError(nil, nil)
        return e
    }

    public static func newUnretryableError(_ request: TeaRequest?) -> Error {
        return UnretryableError(request, nil)
    }
}
