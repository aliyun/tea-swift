//
// Created by Axios on 2020/2/21.
//

import Foundation
import SwiftyJSON
import CryptoSwift

public class TeaUtils {
    public static func stringifyMapValue(_ dict: [String: Any?]) -> [String: Any] {
        var map: [String: Any?] = dict
        for (key, val) in dict {
            if isBool(val) {
                map[key] = val as! Bool == true ? "true" : "false"
            } else if val as? Int == 0 {
                map[key] = "0"
            } else if !(val is String) {
                map[key] = "\(val ?? "")"
            }
        }
        return map as [String: Any]
    }

    public static func assertAsMap(_ any: Any?) -> Bool {
        guard let _: [String: Any] = any as? [String: Any] else {
            return false
        }
        return true
    }

    public static func getUserAgent(_ userAgent: String) -> String {
        getDefaultUserAgent() + " " + userAgent
    }

    public static func toJSONString(_ obj: Any) -> String {
        let json = JSON(obj)
        let r: String = json.rawString(.utf8, options: .fragmentsAllowed) ?? ""
        return r
    }

    public static func toFormString(query: [String: Any]) -> String {
        var url: String = ""
        if query.count > 0 {
            let keys = Array(query.keys).sorted()
            var arr: [String] = [String]()
            for key in keys {
                let value: String = "\(query[key] ?? "")"
                if value.isEmpty {
                    continue
                }
                arr.append(key + "=" + "\(value)".urlEncode())
            }
            arr = arr.sorted()
            if arr.count > 0 {
                url = arr.joined(separator: "&")
            }
        }
        return url
    }

    public static func getDateUTCString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: Date())
    }

    public static func getNonce() -> String {
        let timestamp: TimeInterval = Date().toTimestamp()
        let timestampStr: String = String(timestamp)
        return (String.randomString(len: 10) + timestampStr + UUID().uuidString).md5()
    }
}

func isBool(_ val: Any?) -> Bool {
    if val == nil {
        return false
    }
    if val is Bool {
        return true
    }
    return false
}

func osName() -> String {
    let osNameVersion: String = {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        let osName: String = {
            #if os(iOS)
            return "iOS"
            #elseif os(watchOS)
            return "watchOS"
            #elseif os(tvOS)
            return "tvOS"
            #elseif os(macOS)
            return "OSX"
            #elseif os(Linux)
            return "Linux"
            #else
            return "Unknown"
            #endif
        }()

        return "\(osName)/\(versionString)"
    }()
    return osNameVersion
}

func version() -> String {
    let package: String = {
        let afInfo = Bundle(for: TeaUtils.self).infoDictionary
        let build = afInfo?["CFBundleShortVersionString"]
        let name = afInfo?["CFBundleName"]
        return "\(name ?? "unknown")/\(build ?? "unknown")"
    }()
    return package
}

var defaultUserAgent: String = ""

func getDefaultUserAgent() -> String {
    if defaultUserAgent.isEmpty {
        defaultUserAgent += osName() + " " + version() + " TeaDSL/1"
    }
    return defaultUserAgent
}