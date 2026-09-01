import Foundation
import XCTest
@testable import Tea

final class RetryTests: XCTestCase {
    class AErr: BaseError {
        override init(_ map: [String: Any]) {
            super.init(map)
            name = "AErr"
        }
    }

    class BErr: BaseError {
        override init(_ map: [String: Any]) {
            super.init(map)
            name = "BErr"
        }
    }

    class CErr: ResponseError {
        override init(_ map: [String: Any]) {
            super.init(map)
            name = "BErr"
            if let n = map["name"] as? String {
                name = n
            } else {
                name = "CErr"
            }
        }
    }

    func testShouldRetryBasics() {
        var context = RetryPolicyContext(retriesAttempted: 3)
        XCTAssertFalse(TeaCore.shouldRetry(nil, context))

        context = RetryPolicyContext(retriesAttempted: 0)
        XCTAssertTrue(TeaCore.shouldRetry(nil, context))

        let condition1 = RetryCondition(
            maxAttempts: 3,
            exception: ["AErr"],
            errorCode: ["A1Err"]
        )
        var option = RetryOptions(retryable: true, retryCondition: [condition1])

        context = RetryPolicyContext(
            retriesAttempted: 3,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertFalse(TeaCore.shouldRetry(option, context))

        option = RetryOptions(retryable: true)
        XCTAssertFalse(TeaCore.shouldRetry(option, context))

        option = RetryOptions(retryable: true, retryCondition: [condition1])
        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertTrue(TeaCore.shouldRetry(option, context))

        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: AErr(["code": "B1Err", "message": "b1 error"])
        )
        XCTAssertTrue(TeaCore.shouldRetry(option, context))

        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: BErr(["code": "B1Err", "message": "b1 error"])
        )
        XCTAssertFalse(TeaCore.shouldRetry(option, context))

        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: BErr(["code": "A1Err", "message": "b1 error"])
        )
        XCTAssertTrue(TeaCore.shouldRetry(option, context))

        let condition2 = RetryCondition(
            maxAttempts: 3,
            exception: ["BErr"],
            errorCode: ["B1Err"]
        )
        option = RetryOptions(
            retryable: true,
            retryCondition: [condition2],
            noRetryCondition: [condition2]
        )
        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: AErr(["code": "B1Err", "message": "b1 error"])
        )
        XCTAssertFalse(TeaCore.shouldRetry(option, context))

        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: BErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertFalse(TeaCore.shouldRetry(option, context))
    }

    func testShouldRetryDefaultsMaxAttempts() {
        let conditionNoMax = RetryCondition(exception: ["AErr"], errorCode: ["A1Err"])
        XCTAssertEqual(3, conditionNoMax.maxAttempts)

        let option = RetryOptions(retryable: true, retryCondition: [conditionNoMax])
        var context = RetryPolicyContext(
            retriesAttempted: 1,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertTrue(TeaCore.shouldRetry(option, context))

        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertTrue(TeaCore.shouldRetry(option, context))

        context = RetryPolicyContext(
            retriesAttempted: 3,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertFalse(TeaCore.shouldRetry(option, context))

        let conditionZero = RetryCondition(
            maxAttempts: 0,
            exception: ["AErr"],
            errorCode: ["A1Err"]
        )
        XCTAssertEqual(0, conditionZero.maxAttempts)
        let optionZero = RetryOptions(retryable: true, retryCondition: [conditionZero])
        context = RetryPolicyContext(
            retriesAttempted: 1,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertFalse(TeaCore.shouldRetry(optionZero, context))
    }

    func testGetBackoffDelayPolicies() {
        let condition = RetryCondition(
            maxAttempts: 3,
            exception: ["AErr"],
            errorCode: ["A1Err"]
        )
        var option = RetryOptions(retryable: true, retryCondition: [condition])
        var context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertEqual(100, TeaCore.getBackoffDelay(option, context))

        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: BErr(["code": "B1Err", "message": "a1 error"])
        )
        XCTAssertEqual(100, TeaCore.getBackoffDelay(option, context))

        let fixed = FixedBackoffPolicy(period: 1000)
        let condition1 = RetryCondition(
            maxAttempts: 3,
            backoff: fixed,
            exception: ["AErr"],
            errorCode: ["A1Err"]
        )
        option = RetryOptions(retryable: true, retryCondition: [condition1])
        context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: AErr(["code": "A1Err", "message": "a1 error"])
        )
        XCTAssertEqual(1000, TeaCore.getBackoffDelay(option, context))

        let random = RandomBackoffPolicy(period: 1000, cap: 10000)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: random, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        XCTAssertTrue(TeaCore.getBackoffDelay(option, context) < 10000)

        let randomCap = RandomBackoffPolicy(period: 10000, cap: 10)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: randomCap, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        XCTAssertEqual(10, TeaCore.getBackoffDelay(option, context))

        // period * 2^retries: period=5, retries=2 → 5*4=20
        var exponential: BackoffPolicy = ExponentialBackoffPolicy(period: 5, cap: 10000)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: exponential, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        XCTAssertEqual(20, TeaCore.getBackoffDelay(option, context))

        // period=1000ms must multiply, not enter the exponent
        exponential = ExponentialBackoffPolicy(period: 1000, cap: 10000)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: exponential, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        XCTAssertEqual(4000, TeaCore.getBackoffDelay(option, context))

        exponential = ExponentialBackoffPolicy(period: 10, cap: 10000)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: exponential, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        XCTAssertEqual(40, TeaCore.getBackoffDelay(option, context))

        exponential = ExponentialBackoffPolicy(period: 1000, cap: 50)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: exponential, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        XCTAssertEqual(50, TeaCore.getBackoffDelay(option, context))

        var equalJitter: BackoffPolicy = EqualJitterBackoffPolicy(period: 5, cap: 10000)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 2, backoff: equalJitter, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        var backoffTime = TeaCore.getBackoffDelay(option, context)
        XCTAssertTrue(backoffTime >= 10 && backoffTime <= 20)

        equalJitter = EqualJitterBackoffPolicy(period: 1000, cap: 10000)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: equalJitter, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        backoffTime = TeaCore.getBackoffDelay(option, context)
        XCTAssertTrue(backoffTime >= 2000 && backoffTime <= 4000)

        var fullJitter: BackoffPolicy = FullJitterBackoffPolicy(period: 5, cap: 10000)
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 2, backoff: fullJitter, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        backoffTime = TeaCore.getBackoffDelay(option, context)
        XCTAssertTrue(backoffTime >= 0 && backoffTime < 20)

        fullJitter = FullJitterBackoffPolicy(period: 10, cap: 10000, policy: "ExponentialWithFullJitter")
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: fullJitter, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        backoffTime = TeaCore.getBackoffDelay(option, context)
        XCTAssertTrue(backoffTime >= 0 && backoffTime < 10000)

        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: fullJitter, exception: ["AErr"], errorCode: ["A1Err"], maxDelay: 1000)]
        )
        backoffTime = TeaCore.getBackoffDelay(option, context)
        XCTAssertTrue(backoffTime >= 0 && backoffTime <= 1000)

        fullJitter = FullJitterBackoffPolicy(period: 100, cap: 10000 * 10000, policy: "ExponentialWithFullJitter")
        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 2, backoff: fullJitter, exception: ["AErr"], errorCode: ["A1Err"])]
        )
        backoffTime = TeaCore.getBackoffDelay(option, context)
        XCTAssertTrue(backoffTime >= 0 && backoffTime <= 120 * 1000)
    }

    func testGetBackoffDelayRetryAfter() {
        let fullJitter = FullJitterBackoffPolicy(period: 100, cap: 10000 * 10000, policy: "ExponentialWithFullJitter")
        let context = RetryPolicyContext(
            retriesAttempted: 2,
            exception: CErr(["code": "CErr", "message": "c error", "retryAfter": 3000, "name": "CErr"])
        )
        var option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: fullJitter, exception: ["CErr"], errorCode: ["CErr"], maxDelay: 5000)]
        )
        XCTAssertEqual(3000, TeaCore.getBackoffDelay(option, context))

        option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(maxAttempts: 3, backoff: fullJitter, exception: ["CErr"], errorCode: ["CErr"], maxDelay: 1000)]
        )
        XCTAssertEqual(1000, TeaCore.getBackoffDelay(option, context))
    }

    func testBackoffPolicyFactory() {
        XCTAssertNotNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "Fixed", "period": 100]))
        XCTAssertNotNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "Random", "period": 100]))
        XCTAssertNotNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "Exponential", "period": 100]))
        XCTAssertNotNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "EqualJitter", "period": 100]))
        XCTAssertNotNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "ExponentialWithEqualJitter", "period": 100]))
        XCTAssertNotNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "FullJitter", "period": 100]))
        XCTAssertNotNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "ExponentialWithFullJitter", "period": 100]))
        XCTAssertNil(BackoffPolicyFactory.newBackoffPolicy(["policy": "Unknown"]))
    }

    func testRetryOptionsFromMap() {
        let option = RetryOptions([
            "retryable": true,
            "retryCondition": [[
                "maxAttempts": 2,
                "exception": ["AErr"],
                "errorCode": ["A1Err"],
                "backoff": ["policy": "Fixed", "period": 50],
                "maxDelay": 200
            ]] as [[String: Any]]
        ])
        XCTAssertTrue(option.retryable)
        XCTAssertEqual(1, option.retryCondition.count)
        XCTAssertEqual(2, option.retryCondition[0].maxAttempts)
        let context = RetryPolicyContext(
            retriesAttempted: 1,
            exception: AErr(["code": "A1Err", "message": "a"])
        )
        XCTAssertEqual(50, TeaCore.getBackoffDelay(option, context))
    }

    func testSleepMilliseconds() {
        let start = Date()
        TeaCore.sleep(50)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertGreaterThanOrEqual(elapsed, 0.04)
        XCTAssertLessThan(elapsed, 1.0)
        TeaCore.sleep(0)
        TeaCore.sleep(-1)
    }

    func testRetryConditionAndContextFromMap() {
        let condition = RetryCondition([:])
        XCTAssertEqual(DEFAULT_MAX_ATTEMPTS, condition.maxAttempts)
        XCTAssertNil(condition.backoff)

        let withPolicy = RetryCondition([
            "maxAttempts": 5,
            "backoff": FixedBackoffPolicy(period: 10) as BackoffPolicy,
            "exception": ["X"],
            "errorCode": ["Y"]
        ])
        XCTAssertEqual(5, withPolicy.maxAttempts)
        XCTAssertNotNil(withPolicy.backoff)

        let withNilBackoff = RetryCondition(["maxAttempts": 1, "backoff": NSNull()])
        XCTAssertNil(withNilBackoff.backoff)

        let option = RetryOptions([
            "retryable": true,
            "retryCondition": [condition],
            "noRetryCondition": [withPolicy]
        ])
        XCTAssertEqual(1, option.retryCondition.count)
        XCTAssertEqual(1, option.noRetryCondition.count)

        let optionMaps = RetryOptions([
            "retryable": false,
            "noRetryCondition": [[
                "exception": ["Z"],
                "errorCode": ["Z1"]
            ]] as [[String: Any]]
        ])
        XCTAssertEqual(1, optionMaps.noRetryCondition.count)

        let emptyOption = RetryOptions(["retryable": true, "retryCondition": "bad", "noRetryCondition": "bad"])
        XCTAssertTrue(emptyOption.retryCondition.isEmpty)
        XCTAssertTrue(emptyOption.noRetryCondition.isEmpty)

        let req = TeaRequest()
        let ctx = RetryPolicyContext([
            "key": "k",
            "retriesAttempted": 2,
            "httpRequest": req,
            "exception": AErr(["code": "A1Err", "message": "m"])
        ])
        XCTAssertEqual("k", ctx.key)
        XCTAssertEqual(2, ctx.retriesAttempted)
        XCTAssertTrue(ctx.httpRequest === req)
    }

    func testShouldRetryNilExceptionAndNonBaseError() {
        let option = RetryOptions(
            retryable: true,
            retryCondition: [RetryCondition(exception: ["AErr"], errorCode: ["A1Err"])]
        )
        let noEx = RetryPolicyContext(retriesAttempted: 1, exception: nil)
        XCTAssertFalse(TeaCore.shouldRetry(option, noEx))

        // Non-BaseError / non-ReuqestError falls through name/code helpers
        struct Plain: Error {}
        let ctx = RetryPolicyContext(retriesAttempted: 1, exception: Plain())
        XCTAssertFalse(TeaCore.shouldRetry(option, ctx))
        XCTAssertEqual(100, TeaCore.getBackoffDelay(option, ctx))
        XCTAssertEqual(100, TeaCore.getBackoffDelay(nil, ctx))
        XCTAssertEqual(100, TeaCore.getBackoffDelay(option, RetryPolicyContext(retriesAttempted: 1, exception: nil)))

        let reqErr = ReuqestError(["code": "A1Err", "message": "m"])
        let matched = RetryPolicyContext(retriesAttempted: 1, exception: reqErr)
        XCTAssertTrue(TeaCore.shouldRetry(option, matched))
    }

    func testRandomAndFullJitterZeroCeil() {
        let ctx = RetryPolicyContext(retriesAttempted: 0, exception: AErr(["code": "A1Err", "message": "m"]))
        XCTAssertEqual(0, RandomBackoffPolicy(period: 100).getDelayTime(ctx))
        XCTAssertEqual(0, FullJitterBackoffPolicy(period: 0, cap: 0).getDelayTime(ctx))
    }

    func testAnyOptionsOverloadsAndFactory() {
        let option = RetryOptions(retryable: true, retryCondition: [
            RetryCondition(exception: ["AErr"], errorCode: ["A1Err"])
        ])
        let ctx = RetryPolicyContext(retriesAttempted: 0)
        XCTAssertTrue(TeaCore.shouldRetry(option as Any, ctx))
        XCTAssertTrue(TeaCore.shouldRetry(["retryable": true] as [String: Any], ctx))
        let built = TeaCore.retryPolicyContext(retriesAttempted: 2, exception: AErr(["code": "A1Err", "message": "m"]))
        XCTAssertEqual(2, built.retriesAttempted)
        XCTAssertEqual(100, TeaCore.getBackoffDelay(["retryable": true] as [String: Any], built))
    }
}
