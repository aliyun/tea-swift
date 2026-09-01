import Foundation
#if canImport(CFNetwork)
import CFNetwork
#endif
#if canImport(Security)
import Security
#endif

/// Resolved HTTP runtime used by URLSession / Alamofire.
/// Timeout fields in RuntimeOptions are milliseconds; TimeInterval values are seconds.
public struct ResolvedRuntime: Equatable {
    public var connectTimeoutMs: Int
    public var readTimeoutMs: Int
    public var timeoutIntervalForRequest: TimeInterval
    public var timeoutIntervalForResource: TimeInterval
    public var maxIdleConns: Int
    public var ignoreSSL: Bool
    public var tlsMinVersion: String?
    public var httpProxy: String?
    public var httpsProxy: String?
    public var socks5Proxy: String?
    public var socks5NetWork: String?
    public var noProxy: String?
    public var bypassProxy: Bool
    public var proxyURL: String?
    public var proxyHost: String?
    public var proxyPort: Int?
    public var proxyUser: String?
    public var proxyPassword: String?
    public var proxyIsSOCKS5: Bool
    public var key: String?
    public var cert: String?
    public var ca: String?

    public init(
        connectTimeoutMs: Int = 5000,
        readTimeoutMs: Int = 10000,
        timeoutIntervalForRequest: TimeInterval = 10,
        timeoutIntervalForResource: TimeInterval = 15,
        maxIdleConns: Int = 128,
        ignoreSSL: Bool = false,
        tlsMinVersion: String? = nil,
        httpProxy: String? = nil,
        httpsProxy: String? = nil,
        socks5Proxy: String? = nil,
        socks5NetWork: String? = nil,
        noProxy: String? = nil,
        bypassProxy: Bool = false,
        proxyURL: String? = nil,
        proxyHost: String? = nil,
        proxyPort: Int? = nil,
        proxyUser: String? = nil,
        proxyPassword: String? = nil,
        proxyIsSOCKS5: Bool = false,
        key: String? = nil,
        cert: String? = nil,
        ca: String? = nil
    ) {
        self.connectTimeoutMs = connectTimeoutMs
        self.readTimeoutMs = readTimeoutMs
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.timeoutIntervalForResource = timeoutIntervalForResource
        self.maxIdleConns = maxIdleConns
        self.ignoreSSL = ignoreSSL
        self.tlsMinVersion = tlsMinVersion
        self.httpProxy = httpProxy
        self.httpsProxy = httpsProxy
        self.socks5Proxy = socks5Proxy
        self.socks5NetWork = socks5NetWork
        self.noProxy = noProxy
        self.bypassProxy = bypassProxy
        self.proxyURL = proxyURL
        self.proxyHost = proxyHost
        self.proxyPort = proxyPort
        self.proxyUser = proxyUser
        self.proxyPassword = proxyPassword
        self.proxyIsSOCKS5 = proxyIsSOCKS5
        self.key = key
        self.cert = cert
        self.ca = ca
    }
}

public struct ProxyURL: Equatable {
    public var scheme: String
    public var host: String
    public var port: Int
    public var user: String?
    public var password: String?

    public init(scheme: String, host: String, port: Int, user: String? = nil, password: String? = nil) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.user = user
        self.password = password
    }
}

open class TeaRuntime {
    public static let defaultConnectTimeoutMs: Int = 5 * 1000
    public static let defaultReadTimeoutMs: Int = 10 * 1000
    public static let defaultMaxIdleConnsPerHost: Int = 128

    public static func millisecondsToTimeInterval(_ milliseconds: Int) -> TimeInterval {
        return TimeInterval(milliseconds) / 1000.0
    }

    public static func intValue(_ any: Any?) -> Int? {
        if any == nil || any is NSNull {
            return nil
        }
        if let i = any as? Int {
            return i
        }
        if let i = any as? Int32 {
            return Int(i)
        }
        if let i = any as? Int64 {
            return Int(i)
        }
        if let n = any as? NSNumber {
            return n.intValue
        }
        if let s = any as? String, let i = Int(s) {
            return i
        }
        return nil
    }

    public static func boolValue(_ any: Any?) -> Bool {
        if let b = any as? Bool {
            return b
        }
        if let n = any as? NSNumber {
            return n.boolValue
        }
        if let s = any as? String {
            return s.lowercased() == "true" || s == "1"
        }
        return false
    }

    public static func stringValue(_ any: Any?) -> String? {
        if any == nil || any is NSNull {
            return nil
        }
        if let s = any as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }

    public static func parseProxyURL(_ raw: String?, defaultScheme: String = "http", defaultPort: Int = 80) -> ProxyURL? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        var scheme = defaultScheme
        if let range = value.range(of: "://") {
            scheme = String(value[..<range.lowerBound]).lowercased()
            value = String(value[range.upperBound...])
        }
        var user: String?
        var password: String?
        if let at = value.lastIndex(of: "@") {
            let cred = String(value[..<at])
            value = String(value[value.index(after: at)...])
            if let colon = cred.firstIndex(of: ":") {
                user = String(cred[..<colon])
                password = String(cred[cred.index(after: colon)...])
            } else {
                user = cred
            }
        }
        var host = value
        var port = defaultPort
        if host.hasPrefix("["), let end = host.firstIndex(of: "]") {
            let ip = String(host[host.index(after: host.startIndex)..<end])
            let rest = String(host[host.index(after: end)...])
            host = ip
            if rest.hasPrefix(":"), let parsed = Int(rest.dropFirst()) {
                port = parsed
            }
        } else if let colon = host.lastIndex(of: ":") {
            let maybePort = String(host[host.index(after: colon)...])
            if let parsed = Int(maybePort) {
                port = parsed
                host = String(host[..<colon])
            }
        }
        if host.isEmpty {
            return nil
        }
        if scheme == "socks5" || scheme == "socks" {
            if defaultPort == 80 && (raw?.contains("://") != true || defaultScheme != "socks5") && port == defaultPort {
                port = 1080
            }
        }
        return ProxyURL(scheme: scheme, host: host, port: port, user: user, password: password)
    }

    public static func shouldBypassProxy(host: String?, noProxy: String?) -> Bool {
        guard let host = host?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !host.isEmpty else {
            return false
        }
        guard let noProxy = noProxy, !noProxy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        let tokens = noProxy.split(whereSeparator: { $0 == "," || $0 == " " || $0 == ";" }).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }.filter { !$0.isEmpty }
        for token in tokens {
            if token == "*" {
                return true
            }
            if token.hasPrefix(".") {
                if host.hasSuffix(token) || host == String(token.dropFirst()) {
                    return true
                }
            } else if token.hasPrefix("*.") {
                let suffix = String(token.dropFirst())
                if host.hasSuffix(suffix) {
                    return true
                }
            } else if host == token || host.hasSuffix("." + token) {
                return true
            }
        }
        return false
    }

    public static func tlsProtocolVersion(_ version: String?) -> tls_protocol_version_t? {
        guard let version = version?.trimmingCharacters(in: .whitespacesAndNewlines), !version.isEmpty else {
            return nil
        }
        switch version.lowercased() {
        case "tlsv1.3", "tls1.3", "1.3":
            return .TLSv13
        case "tlsv1.2", "tls1.2", "1.2":
            return .TLSv12
        case "tlsv1.1", "tls1.1", "1.1":
            return .TLSv11
        case "tlsv1.0", "tls1.0", "1.0", "tlsv1":
            return .TLSv10
        default:
            return nil
        }
    }

    public static func resolve(_ runtime: [String: Any], host: String? = nil, isHTTPS: Bool = false) -> ResolvedRuntime {
        var connect = intValue(runtime["connectTimeout"]) ?? 0
        if connect <= 0 {
            connect = defaultConnectTimeoutMs
        }
        var read = intValue(runtime["readTimeout"]) ?? 0
        if read <= 0 {
            read = defaultReadTimeoutMs
        }
        var maxIdle = intValue(runtime["maxIdleConns"]) ?? 0
        if maxIdle <= 0 {
            maxIdle = defaultMaxIdleConnsPerHost
        }
        let httpProxy = stringValue(runtime["httpProxy"])
        let httpsProxy = stringValue(runtime["httpsProxy"])
        let socks5Proxy = stringValue(runtime["socks5Proxy"])
        let socks5NetWork = stringValue(runtime["socks5NetWork"])
        let noProxy = stringValue(runtime["noProxy"])
        let bypass = shouldBypassProxy(host: host, noProxy: noProxy)
        var resolved = ResolvedRuntime(
            connectTimeoutMs: connect,
            readTimeoutMs: read,
            timeoutIntervalForRequest: millisecondsToTimeInterval(read),
            timeoutIntervalForResource: millisecondsToTimeInterval(connect + read),
            maxIdleConns: maxIdle,
            ignoreSSL: boolValue(runtime["ignoreSSL"]),
            tlsMinVersion: stringValue(runtime["tlsMinVersion"]),
            httpProxy: httpProxy,
            httpsProxy: httpsProxy,
            socks5Proxy: socks5Proxy,
            socks5NetWork: socks5NetWork,
            noProxy: noProxy,
            bypassProxy: bypass,
            key: stringValue(runtime["key"]),
            cert: stringValue(runtime["cert"]),
            ca: stringValue(runtime["ca"])
        )
        if !bypass {
            let socks = parseProxyURL(socks5Proxy, defaultScheme: "socks5", defaultPort: 1080)
            let https = parseProxyURL(httpsProxy, defaultScheme: "http", defaultPort: 8080)
            let http = parseProxyURL(httpProxy, defaultScheme: "http", defaultPort: 8080)
            let chosen: ProxyURL?
            if let socks = socks {
                chosen = socks
                resolved.proxyIsSOCKS5 = true
            } else if isHTTPS, let https = https {
                chosen = https
            } else {
                chosen = http ?? https
            }
            if let chosen = chosen {
                resolved.proxyURL = "\(chosen.scheme)://\(chosen.host):\(chosen.port)"
                resolved.proxyHost = chosen.host
                resolved.proxyPort = chosen.port
                resolved.proxyUser = chosen.user
                resolved.proxyPassword = chosen.password
                if chosen.scheme == "socks5" || chosen.scheme == "socks" {
                    resolved.proxyIsSOCKS5 = true
                }
            }
        }
        return resolved
    }

    public static func connectionProxyDictionary(_ resolved: ResolvedRuntime) -> [AnyHashable: Any]? {
        guard !resolved.bypassProxy, let host = resolved.proxyHost, let port = resolved.proxyPort else {
            return nil
        }
        var dict: [AnyHashable: Any] = [:]
        if resolved.proxyIsSOCKS5 {
            dict["SOCKSEnable"] = 1
            dict["SOCKSProxy"] = host
            dict["SOCKSPort"] = port
            dict[kCFStreamPropertySOCKSProxyHost] = host
            dict[kCFStreamPropertySOCKSProxyPort] = port
            dict[kCFStreamPropertySOCKSVersion] = kCFStreamSocketSOCKSVersion5
            if let user = resolved.proxyUser {
                dict[kCFStreamPropertySOCKSUser] = user
            }
            if let password = resolved.proxyPassword {
                dict[kCFStreamPropertySOCKSPassword] = password
            }
        } else {
            dict["HTTPEnable"] = 1
            dict["HTTPProxy"] = host
            dict["HTTPPort"] = port
            dict["HTTPSEnable"] = 1
            dict["HTTPSProxy"] = host
            dict["HTTPSPort"] = port
            if let user = resolved.proxyUser {
                dict["kCFProxyUsername"] = user
            }
            if let password = resolved.proxyPassword {
                dict["kCFProxyPassword"] = password
            }
        }
        return dict
    }

    public static func apply(_ resolved: ResolvedRuntime, to config: URLSessionConfiguration) {
        config.timeoutIntervalForRequest = resolved.timeoutIntervalForRequest
        config.timeoutIntervalForResource = resolved.timeoutIntervalForResource
        config.httpMaximumConnectionsPerHost = resolved.maxIdleConns
        // Floor at TLS 1.2: never apply TLS 1.0/1.1 to URLSession (insecure).
        if case .TLSv13 = tlsProtocolVersion(resolved.tlsMinVersion) {
            config.tlsMinimumSupportedProtocolVersion = .TLSv13
        } else {
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
        }
        config.connectionProxyDictionary = connectionProxyDictionary(resolved)
    }

    public static func urlSessionConfiguration(_ runtime: [String: Any], request: TeaRequest? = nil) -> URLSessionConfiguration {
        let host = request?.headers["host"]
        let isHTTPS = (request?.protocol_ ?? "https").lowercased() == "https"
        let resolved = resolve(runtime, host: host, isHTTPS: isHTTPS)
        let config = URLSessionConfiguration.default
        apply(resolved, to: config)
        return config
    }
}
