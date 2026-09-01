import Foundation

/// Lightweight Darabonba builtins used by OpenApiV2 generated Swift.
public enum TeaBuiltin {
    public static func isNull(_ any: Any?) -> Bool {
        if any == nil {
            return true
        }
        if any is NSNull {
            return true
        }
        return false
    }

    public static func `default`<T>(_ value: T?, _ defaultValue: T) -> T {
        if isNull(value) {
            return defaultValue
        }
        return value!
    }

    public static func defaultAny(_ value: Any?, _ defaultValue: Any?) -> Any? {
        if isNull(value) {
            return defaultValue
        }
        return value
    }
}

open class TeaJSON {
    public static func stringify(_ any: Any?) -> String {
        guard let any = any, !(any is NSNull) else {
            return ""
        }
        if let s = any as? String {
            return s
        }
        guard JSONSerialization.isValidJSONObject(any) else {
            return ""
        }
        guard let data = try? JSONSerialization.data(withJSONObject: any, options: []),
              let str = String(data: data, encoding: .utf8) else {
            return ""
        }
        return str
    }

    public static func parse(_ text: String?) -> Any? {
        guard let text = text, let data = text.data(using: .utf8), !data.isEmpty else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers])
    }
}

open class TeaEnv {
    public static func get(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
}

open class TeaBytes {
    public static func from(_ string: String, _ encoding: String = "utf-8") -> [UInt8] {
        if encoding.lowercased() == "utf-8" || encoding.lowercased() == "utf8" {
            return [UInt8](string.utf8)
        }
        return [UInt8](string.utf8)
    }

    public static func toHex(_ bytes: [UInt8]) -> String {
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}
