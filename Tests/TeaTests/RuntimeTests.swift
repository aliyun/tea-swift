import Foundation
import XCTest
@testable import Tea

final class RuntimeTests: XCTestCase {
    func testMillisecondsToTimeInterval() {
        XCTAssertEqual(0, TeaRuntime.millisecondsToTimeInterval(0), accuracy: 0.0001)
        XCTAssertEqual(5, TeaRuntime.millisecondsToTimeInterval(5000), accuracy: 0.0001)
        XCTAssertEqual(0.2, TeaRuntime.millisecondsToTimeInterval(200), accuracy: 0.0001)
        XCTAssertEqual(10, TeaRuntime.millisecondsToTimeInterval(10_000), accuracy: 0.0001)
    }

    func testIntValue() {
        XCTAssertNil(TeaRuntime.intValue(nil))
        XCTAssertNil(TeaRuntime.intValue(NSNull()))
        XCTAssertEqual(3, TeaRuntime.intValue(3))
        XCTAssertEqual(4, TeaRuntime.intValue(Int32(4)))
        XCTAssertEqual(5, TeaRuntime.intValue(Int64(5)))
        XCTAssertEqual(6, TeaRuntime.intValue(NSNumber(value: 6)))
        XCTAssertEqual(42, TeaRuntime.intValue(NSNumber(value: Int64(42))))
        XCTAssertTrue(TeaRuntime.boolValue(NSNumber(value: 1)))
        XCTAssertFalse(TeaRuntime.boolValue(NSNumber(value: 0)))
        XCTAssertEqual(7, TeaRuntime.intValue("7"))
        XCTAssertNil(TeaRuntime.intValue("x"))
        XCTAssertNil(TeaRuntime.intValue(["a": 1]))
    }

    func testBoolValue() {
        XCTAssertTrue(TeaRuntime.boolValue(true))
        XCTAssertFalse(TeaRuntime.boolValue(false))
        XCTAssertTrue(TeaRuntime.boolValue(NSNumber(value: true)))
        XCTAssertTrue(TeaRuntime.boolValue("true"))
        XCTAssertTrue(TeaRuntime.boolValue("TRUE"))
        XCTAssertTrue(TeaRuntime.boolValue("1"))
        XCTAssertFalse(TeaRuntime.boolValue("false"))
        XCTAssertFalse(TeaRuntime.boolValue(nil))
    }

    func testStringValue() {
        XCTAssertNil(TeaRuntime.stringValue(nil))
        XCTAssertNil(TeaRuntime.stringValue(NSNull()))
        XCTAssertNil(TeaRuntime.stringValue("  "))
        XCTAssertEqual("abc", TeaRuntime.stringValue("abc"))
        XCTAssertEqual("abc", TeaRuntime.stringValue(" abc "))
        XCTAssertNil(TeaRuntime.stringValue(1))
    }

    func testParseProxyURL() {
        XCTAssertNil(TeaRuntime.parseProxyURL(nil))
        XCTAssertNil(TeaRuntime.parseProxyURL(""))
        XCTAssertNil(TeaRuntime.parseProxyURL("   "))

        let http = TeaRuntime.parseProxyURL("http://user:pass@127.0.0.1:8080")
        XCTAssertEqual("http", http?.scheme)
        XCTAssertEqual("127.0.0.1", http?.host)
        XCTAssertEqual(8080, http?.port)
        XCTAssertEqual("user", http?.user)
        XCTAssertEqual("pass", http?.password)

        let hostOnly = TeaRuntime.parseProxyURL("proxy.local:3128", defaultScheme: "http", defaultPort: 8080)
        XCTAssertEqual("proxy.local", hostOnly?.host)
        XCTAssertEqual(3128, hostOnly?.port)

        let defaultPort = TeaRuntime.parseProxyURL("proxy.local", defaultScheme: "http", defaultPort: 8080)
        XCTAssertEqual(8080, defaultPort?.port)

        let socks = TeaRuntime.parseProxyURL("socks5://127.0.0.1:1080", defaultScheme: "socks5", defaultPort: 1080)
        XCTAssertEqual("socks5", socks?.scheme)
        XCTAssertEqual("127.0.0.1", socks?.host)
        XCTAssertEqual(1080, socks?.port)

        let ipv6 = TeaRuntime.parseProxyURL("http://[::1]:8080")
        XCTAssertEqual("::1", ipv6?.host)
        XCTAssertEqual(8080, ipv6?.port)

        let userOnly = TeaRuntime.parseProxyURL("http://alice@host:9")
        XCTAssertEqual("alice", userOnly?.user)
        XCTAssertNil(userOnly?.password)

        XCTAssertNil(TeaRuntime.parseProxyURL("http://"))
        let socksNoPort = TeaRuntime.parseProxyURL("socks5://127.0.0.1", defaultScheme: "http", defaultPort: 80)
        XCTAssertEqual("socks5", socksNoPort?.scheme)
        XCTAssertEqual(1080, socksNoPort?.port)
    }

    func testShouldBypassProxy() {
        XCTAssertFalse(TeaRuntime.shouldBypassProxy(host: nil, noProxy: "example.com"))
        XCTAssertFalse(TeaRuntime.shouldBypassProxy(host: "ecs.aliyuncs.com", noProxy: nil))
        XCTAssertFalse(TeaRuntime.shouldBypassProxy(host: "ecs.aliyuncs.com", noProxy: ""))
        XCTAssertTrue(TeaRuntime.shouldBypassProxy(host: "ecs.aliyuncs.com", noProxy: "*"))
        XCTAssertTrue(TeaRuntime.shouldBypassProxy(host: "ecs.aliyuncs.com", noProxy: "ecs.aliyuncs.com"))
        XCTAssertTrue(TeaRuntime.shouldBypassProxy(host: "ecs.cn-hangzhou.aliyuncs.com", noProxy: ".aliyuncs.com"))
        XCTAssertTrue(TeaRuntime.shouldBypassProxy(host: "ecs.cn-hangzhou.aliyuncs.com", noProxy: "*.aliyuncs.com"))
        XCTAssertTrue(TeaRuntime.shouldBypassProxy(host: "Aliyuncs.com", noProxy: "aliyuncs.com"))
        XCTAssertFalse(TeaRuntime.shouldBypassProxy(host: "example.com", noProxy: "aliyuncs.com"))
        XCTAssertTrue(TeaRuntime.shouldBypassProxy(host: "foo.bar.com", noProxy: "example.com, foo.bar.com; baz"))
        XCTAssertTrue(TeaRuntime.shouldBypassProxy(host: "aliyuncs.com", noProxy: ".aliyuncs.com"))
    }

    func testTlsProtocolVersion() {
        XCTAssertNil(TeaRuntime.tlsProtocolVersion(nil))
        XCTAssertNil(TeaRuntime.tlsProtocolVersion(""))
        XCTAssertNil(TeaRuntime.tlsProtocolVersion("sslv3"))
        XCTAssertEqual(tls_protocol_version_t.TLSv13, TeaRuntime.tlsProtocolVersion("TLSv1.3"))
        XCTAssertEqual(tls_protocol_version_t.TLSv12, TeaRuntime.tlsProtocolVersion("tls1.2"))
        XCTAssertEqual(tls_protocol_version_t.TLSv11, TeaRuntime.tlsProtocolVersion("1.1"))
        XCTAssertEqual(tls_protocol_version_t.TLSv10, TeaRuntime.tlsProtocolVersion("TLSv1.0"))
        XCTAssertEqual(tls_protocol_version_t.TLSv10, TeaRuntime.tlsProtocolVersion("tlsv1"))
    }

    func testResolveTimeoutsAndDefaults() {
        let empty = TeaRuntime.resolve([:])
        XCTAssertEqual(5000, empty.connectTimeoutMs)
        XCTAssertEqual(10000, empty.readTimeoutMs)
        XCTAssertEqual(10, empty.timeoutIntervalForRequest, accuracy: 0.0001)
        XCTAssertEqual(15, empty.timeoutIntervalForResource, accuracy: 0.0001)
        XCTAssertEqual(128, empty.maxIdleConns)
        XCTAssertFalse(empty.ignoreSSL)

        let custom = TeaRuntime.resolve([
            "connectTimeout": 200,
            "readTimeout": 1500,
            "maxIdleConns": 8,
            "ignoreSSL": true,
            "tlsMinVersion": "TLSv1.2",
            "key": "client.key",
            "cert": "client.pem",
            "ca": "ca.pem"
        ])
        XCTAssertEqual(200, custom.connectTimeoutMs)
        XCTAssertEqual(1500, custom.readTimeoutMs)
        XCTAssertEqual(1.5, custom.timeoutIntervalForRequest, accuracy: 0.0001)
        XCTAssertEqual(1.7, custom.timeoutIntervalForResource, accuracy: 0.0001)
        XCTAssertEqual(8, custom.maxIdleConns)
        XCTAssertTrue(custom.ignoreSSL)
        XCTAssertEqual("TLSv1.2", custom.tlsMinVersion)
        XCTAssertEqual("client.key", custom.key)
        XCTAssertEqual("client.pem", custom.cert)
        XCTAssertEqual("ca.pem", custom.ca)
    }

    func testResolveZeroMeansDefault() {
        let zero = TeaRuntime.resolve([
            "connectTimeout": 0,
            "readTimeout": 0,
            "maxIdleConns": 0
        ])
        XCTAssertEqual(5000, zero.connectTimeoutMs)
        XCTAssertEqual(10000, zero.readTimeoutMs)
        XCTAssertEqual(128, zero.maxIdleConns)
    }

    func testResolveHttpProxy() {
        let resolved = TeaRuntime.resolve([
            "httpProxy": "http://user:secret@127.0.0.1:8080"
        ], host: "example.com", isHTTPS: false)
        XCTAssertFalse(resolved.bypassProxy)
        XCTAssertEqual("127.0.0.1", resolved.proxyHost)
        XCTAssertEqual(8080, resolved.proxyPort)
        XCTAssertEqual("user", resolved.proxyUser)
        XCTAssertEqual("secret", resolved.proxyPassword)
        XCTAssertFalse(resolved.proxyIsSOCKS5)
        let dict = TeaRuntime.connectionProxyDictionary(resolved)
        XCTAssertEqual(1, dict?["HTTPEnable"] as? Int)
        XCTAssertEqual("127.0.0.1", dict?["HTTPProxy"] as? String)
        XCTAssertEqual(8080, dict?["HTTPPort"] as? Int)
        XCTAssertEqual(1, dict?["HTTPSEnable"] as? Int)
    }

    func testResolveHttpsProxyPreferredForHTTPS() {
        let resolved = TeaRuntime.resolve([
            "httpProxy": "http://http-proxy:8080",
            "httpsProxy": "http://https-proxy:8443"
        ], host: "ecs.aliyuncs.com", isHTTPS: true)
        XCTAssertEqual("https-proxy", resolved.proxyHost)
        XCTAssertEqual(8443, resolved.proxyPort)
    }

    func testResolveSocks5TakesPriority() {
        let resolved = TeaRuntime.resolve([
            "httpProxy": "http://http-proxy:8080",
            "socks5Proxy": "socks5://127.0.0.1:1080",
            "socks5NetWork": "tcp"
        ], host: "example.com", isHTTPS: true)
        XCTAssertTrue(resolved.proxyIsSOCKS5)
        XCTAssertEqual("127.0.0.1", resolved.proxyHost)
        XCTAssertEqual(1080, resolved.proxyPort)
        XCTAssertEqual("tcp", resolved.socks5NetWork)
        let dict = TeaRuntime.connectionProxyDictionary(resolved)
        XCTAssertEqual(1, dict?["SOCKSEnable"] as? Int)
        XCTAssertEqual("127.0.0.1", dict?["SOCKSProxy"] as? String)
    }

    func testNoProxyBypasses() {
        let resolved = TeaRuntime.resolve([
            "httpProxy": "http://127.0.0.1:8080",
            "noProxy": "ecs.aliyuncs.com,.aliyuncs.com"
        ], host: "ecs.cn-hangzhou.aliyuncs.com", isHTTPS: true)
        XCTAssertTrue(resolved.bypassProxy)
        XCTAssertNil(resolved.proxyHost)
        XCTAssertNil(TeaRuntime.connectionProxyDictionary(resolved))
    }

    func testApplyToURLSessionConfiguration() {
        let resolved = TeaRuntime.resolve([
            "connectTimeout": 400,
            "readTimeout": 800,
            "maxIdleConns": 4,
            "tlsMinVersion": "TLSv1.2",
            "httpProxy": "http://127.0.0.1:9090"
        ], host: "example.com", isHTTPS: false)
        let config = URLSessionConfiguration.default
        TeaRuntime.apply(resolved, to: config)
        XCTAssertEqual(0.8, config.timeoutIntervalForRequest, accuracy: 0.0001)
        XCTAssertEqual(1.2, config.timeoutIntervalForResource, accuracy: 0.0001)
        XCTAssertEqual(4, config.httpMaximumConnectionsPerHost)
        XCTAssertEqual(tls_protocol_version_t.TLSv12, config.tlsMinimumSupportedProtocolVersion)
        XCTAssertNotNil(config.connectionProxyDictionary)
    }

    func testUrlSessionConfigurationHelper() {
        let request = TeaRequest()
        request.protocol_ = "https"
        request.headers["host"] = "example.com"
        let config = TeaRuntime.urlSessionConfiguration([
            "readTimeout": 2500,
            "connectTimeout": 500
        ], request: request)
        XCTAssertEqual(2.5, config.timeoutIntervalForRequest, accuracy: 0.0001)
        XCTAssertEqual(3.0, config.timeoutIntervalForResource, accuracy: 0.0001)

        let noHost = TeaRuntime.urlSessionConfiguration(["readTimeout": 1000], request: TeaRequest())
        XCTAssertEqual(1.0, noHost.timeoutIntervalForRequest, accuracy: 0.0001)
        let noReq = TeaRuntime.urlSessionConfiguration(["readTimeout": 1000], request: nil)
        XCTAssertEqual(1.0, noReq.timeoutIntervalForRequest, accuracy: 0.0001)
    }

    func testSocks5UserPasswordInDictionary() {
        let resolved = TeaRuntime.resolve([
            "socks5Proxy": "socks5://bob:pwd@10.0.0.1:1080"
        ], host: "example.com")
        let dict = TeaRuntime.connectionProxyDictionary(resolved)!
        XCTAssertEqual("bob", dict[kCFStreamPropertySOCKSUser] as? String)
        XCTAssertEqual("pwd", dict[kCFStreamPropertySOCKSPassword] as? String)
    }

    func testHttpProxyUserPasswordInDictionary() {
        let resolved = TeaRuntime.resolve([
            "httpProxy": "http://bob:pwd@10.0.0.1:8080"
        ], host: "example.com")
        let dict = TeaRuntime.connectionProxyDictionary(resolved)!
        XCTAssertEqual("bob", dict["kCFProxyUsername"] as? String)
        XCTAssertEqual("pwd", dict["kCFProxyPassword"] as? String)
    }
}
