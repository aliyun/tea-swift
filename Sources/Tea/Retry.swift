import Foundation

/// Default maxAttempts when omitted (align with Go / TypeScript).
public let DEFAULT_MAX_ATTEMPTS: Int = 3

private let MAX_DELAY_TIME_MS: Int = 120 * 1000
private let MIN_DELAY_TIME_MS: Int = 100
/// Default backoff cap: 3 days in milliseconds.
public let DEFAULT_MAX_CAP_MS: Int = 3 * 24 * 60 * 60 * 1000

public protocol BackoffPolicy {
    var policy: String { get }
    func getDelayTime(_ ctx: RetryPolicyContext) -> Int
}

open class FixedBackoffPolicy: BackoffPolicy {
    public let policy: String
    public let period: Int

    public init(period: Int, policy: String = "Fixed") {
        self.period = period
        self.policy = policy
    }

    public func getDelayTime(_ ctx: RetryPolicyContext) -> Int {
        return period
    }
}

open class RandomBackoffPolicy: BackoffPolicy {
    public let policy: String
    public let period: Int
    public let cap: Int

    public init(period: Int, cap: Int = 20 * 1000, policy: String = "Random") {
        self.period = period
        self.cap = cap
        self.policy = policy
    }

    public func getDelayTime(_ ctx: RetryPolicyContext) -> Int {
        let upper = ctx.retriesAttempted * period
        if upper <= 0 {
            return 0
        }
        let randomTime = Int.random(in: 0..<upper)
        if randomTime > cap {
            return cap
        }
        return randomTime
    }
}

open class ExponentialBackoffPolicy: BackoffPolicy {
    public let policy: String
    public let period: Int
    public let cap: Int

    public init(period: Int, cap: Int = DEFAULT_MAX_CAP_MS, policy: String = "Exponential") {
        self.period = period
        self.cap = cap
        self.policy = policy
    }

    public func getDelayTime(_ ctx: RetryPolicyContext) -> Int {
        // period * 2^retries (align with C# / standard exponential backoff)
        let delay = period * Int(pow(2.0, Double(ctx.retriesAttempted)))
        if delay > cap {
            return cap
        }
        return delay
    }
}

open class EqualJitterBackoffPolicy: BackoffPolicy {
    public let policy: String
    public let period: Int
    public let cap: Int

    public init(period: Int, cap: Int = DEFAULT_MAX_CAP_MS, policy: String = "EqualJitter") {
        self.period = period
        self.cap = cap
        self.policy = policy
    }

    public func getDelayTime(_ ctx: RetryPolicyContext) -> Int {
        let computed = period * Int(pow(2.0, Double(ctx.retriesAttempted)))
        let ceil = min(cap, computed)
        let half = ceil / 2
        return half + Int.random(in: 0...(half))
    }
}

open class FullJitterBackoffPolicy: BackoffPolicy {
    public let policy: String
    public let period: Int
    public let cap: Int

    public init(period: Int, cap: Int = DEFAULT_MAX_CAP_MS, policy: String = "FullJitter") {
        self.period = period
        self.cap = cap
        self.policy = policy
    }

    public func getDelayTime(_ ctx: RetryPolicyContext) -> Int {
        let computed = period * Int(pow(2.0, Double(ctx.retriesAttempted)))
        let ceil = min(cap, computed)
        if ceil <= 0 {
            return 0
        }
        return Int.random(in: 0..<ceil)
    }
}

public enum BackoffPolicyFactory {
    public static func newBackoffPolicy(_ option: [String: Any]) -> BackoffPolicy? {
        let policy = (option["policy"] as? String) ?? ""
        let period = intFromAny(option["period"]) ?? 0
        switch policy {
        case "Fixed":
            return FixedBackoffPolicy(period: period)
        case "Random":
            let cap = intFromAny(option["cap"]) ?? (20 * 1000)
            return RandomBackoffPolicy(period: period, cap: cap)
        case "Exponential":
            let cap = intFromAny(option["cap"]) ?? DEFAULT_MAX_CAP_MS
            return ExponentialBackoffPolicy(period: period, cap: cap)
        case "EqualJitter", "ExponentialWithEqualJitter":
            let cap = intFromAny(option["cap"]) ?? DEFAULT_MAX_CAP_MS
            return EqualJitterBackoffPolicy(period: period, cap: cap, policy: policy)
        case "FullJitter", "ExponentialWithFullJitter":
            let cap = intFromAny(option["cap"]) ?? DEFAULT_MAX_CAP_MS
            return FullJitterBackoffPolicy(period: period, cap: cap, policy: policy)
        default:
            return nil
        }
    }
}

open class RetryCondition {
    public var maxAttempts: Int
    public var backoff: BackoffPolicy?
    public var exception: [String]
    public var errorCode: [String]
    public var maxDelay: Int

    public init(_ condition: [String: Any] = [:]) {
        if let m = intFromAny(condition["maxAttempts"]) {
            maxAttempts = m
        } else {
            maxAttempts = DEFAULT_MAX_ATTEMPTS
        }
        if let bp = condition["backoff"] as? BackoffPolicy {
            backoff = bp
        } else if let map = condition["backoff"] as? [String: Any] {
            backoff = BackoffPolicyFactory.newBackoffPolicy(map)
        } else {
            backoff = nil
        }
        exception = stringArray(condition["exception"])
        errorCode = stringArray(condition["errorCode"])
        maxDelay = intFromAny(condition["maxDelay"]) ?? 0
    }

    public init(
        maxAttempts: Int = DEFAULT_MAX_ATTEMPTS,
        backoff: BackoffPolicy? = nil,
        exception: [String] = [],
        errorCode: [String] = [],
        maxDelay: Int = 0
    ) {
        self.maxAttempts = maxAttempts
        self.backoff = backoff
        self.exception = exception
        self.errorCode = errorCode
        self.maxDelay = maxDelay
    }
}

open class RetryOptions {
    public var retryable: Bool
    public var retryCondition: [RetryCondition]
    public var noRetryCondition: [RetryCondition]

    public init(_ options: [String: Any] = [:]) {
        retryable = boolFromAny(options["retryable"])
        if let list = options["retryCondition"] as? [RetryCondition] {
            retryCondition = list
        } else if let list = options["retryCondition"] as? [[String: Any]] {
            retryCondition = list.map { RetryCondition($0) }
        } else {
            retryCondition = []
        }
        if let list = options["noRetryCondition"] as? [RetryCondition] {
            noRetryCondition = list
        } else if let list = options["noRetryCondition"] as? [[String: Any]] {
            noRetryCondition = list.map { RetryCondition($0) }
        } else {
            noRetryCondition = []
        }
    }

    public init(
        retryable: Bool,
        retryCondition: [RetryCondition] = [],
        noRetryCondition: [RetryCondition] = []
    ) {
        self.retryable = retryable
        self.retryCondition = retryCondition
        self.noRetryCondition = noRetryCondition
    }
}

open class RetryPolicyContext {
    public var key: String?
    public var retriesAttempted: Int
    public var httpRequest: TeaRequest?
    public var httpResponse: TeaResponse?
    public var exception: Error?

    public init(_ options: [String: Any] = [:]) {
        key = options["key"] as? String
        retriesAttempted = intFromAny(options["retriesAttempted"]) ?? 0
        httpRequest = options["httpRequest"] as? TeaRequest
        httpResponse = options["httpResponse"] as? TeaResponse
        exception = options["exception"] as? Error
    }

    public init(
        key: String? = nil,
        retriesAttempted: Int = 0,
        httpRequest: TeaRequest? = nil,
        httpResponse: TeaResponse? = nil,
        exception: Error? = nil
    ) {
        self.key = key
        self.retriesAttempted = retriesAttempted
        self.httpRequest = httpRequest
        self.httpResponse = httpResponse
        self.exception = exception
    }
}

public enum TeaRetry {
    /// Whether another attempt should be made. Aligns with TypeScript / Go dara.
    public static func shouldRetry(_ options: RetryOptions?, _ ctx: RetryPolicyContext) -> Bool {
        if ctx.retriesAttempted == 0 {
            return true
        }
        guard let options = options, options.retryable else {
            return false
        }
        guard let ex = ctx.exception else {
            return false
        }
        let name = errorName(ex)
        let code = errorCode(ex)

        for condition in options.noRetryCondition {
            if condition.exception.contains(name) || condition.errorCode.contains(code) {
                return false
            }
        }
        for condition in options.retryCondition {
            if !condition.exception.contains(name) && !condition.errorCode.contains(code) {
                continue
            }
            let maxAttempts = condition.maxAttempts
            if ctx.retriesAttempted >= maxAttempts {
                return false
            }
            return true
        }
        return false
    }

    /// Backoff delay in **milliseconds**. Aligns with TypeScript / Go dara.
    public static func getBackoffDelay(_ options: RetryOptions?, _ ctx: RetryPolicyContext) -> Int {
        guard let options = options else {
            return MIN_DELAY_TIME_MS
        }
        guard let ex = ctx.exception else {
            return MIN_DELAY_TIME_MS
        }
        let name = errorName(ex)
        let code = errorCode(ex)
        for condition in options.retryCondition {
            if !condition.exception.contains(name) && !condition.errorCode.contains(code) {
                continue
            }
            let maxDelay = condition.maxDelay > 0 ? condition.maxDelay : MAX_DELAY_TIME_MS
            if let retryAfter = responseRetryAfter(ex), retryAfter > 0 {
                return min(Int(retryAfter), maxDelay)
            }
            guard let backoff = condition.backoff else {
                return MIN_DELAY_TIME_MS
            }
            return min(backoff.getDelayTime(ctx), maxDelay)
        }
        return MIN_DELAY_TIME_MS
    }
}

private func errorName(_ error: Error) -> String {
    if let e = error as? BaseError {
        return e.name
    }
    return String(describing: type(of: error))
}

private func errorCode(_ error: Error) -> String {
    if let e = error as? BaseError {
        return e.code ?? ""
    }
    if let e = error as? ReuqestError {
        return e.code ?? ""
    }
    return ""
}

private func responseRetryAfter(_ error: Error) -> Int64? {
    if let e = error as? ResponseError {
        return e.retryAfter
    }
    return nil
}

private func intFromAny(_ any: Any?) -> Int? {
    return TeaRuntime.intValue(any)
}

private func boolFromAny(_ any: Any?) -> Bool {
    return TeaRuntime.boolValue(any)
}

private func stringArray(_ any: Any?) -> [String] {
    if let arr = any as? [String] {
        return arr
    }
    return []
}
