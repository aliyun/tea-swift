//
// Created by Axios on 2020/1/14.
//

import Foundation
import Tea

open class ListDriveResponse: TeaModel {
    @objc public var requestId: String = ""

    @objc public var items: [String: Any] = [String: NSObject]()

    @objc public var nextMarker: String = ""

    public override init() {
        super.init()
        self.__name["requestId"] = "requestId"
        self.__name["items"] = "items"
        self.__name["nextMarker"] = "next_marker"
    }
}


open class ListDriveRequestModel: TeaModel {
    @objc public var limit: Int = 0
    @objc public var marker: String = ""
    @objc public var owner: String = ""

    public override init() {
        super.init()
        self.__required["owner"] = true
    }
}

open class TestsUtils {
    public func _getRFC2616Date() -> String {
        let curr = Date();
        let formatter = DateFormatter();
        formatter.locale = Locale(identifier: "en_US");
        formatter.timeZone = TimeZone(identifier: "GMT");
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss";
        return formatter.string(from: curr) + " GMT";
    }

    public func _getStringToSign(_ request: TeaRequest) -> String {
        let method: String = request.method;
        let pathname: String = request.pathname;
        let headers: [String: String] = request.headers;
        let query: [String: Any] = request.query;

        let accept = headers["accept"] ?? "";
        let contentMD5 = headers["content-md5"] ?? "";
        let contentType = headers["content-type"] ?? "";
        let date = headers["date"] ?? "";

        let headerStr = String(method) + "\n" + String(accept) + "\n" + String(contentMD5) + "\n" + String(contentType) + "\n" + String(date);
        let canonicalizedHeaders: String = self.getCanonicalizedHeaders(headers: headers);
        let canonicalizedResource: String = getCanonicalizedResource(pathname: pathname, query: query);
        return headerStr + "\n" + canonicalizedHeaders + "\n" + canonicalizedResource;
    }

    public func getCanonicalizedHeaders(headers: [String: String]) -> String {
        let prefix: String = "x-acs-";
        var canonicalizedKeys: [String] = [String]();
        for (key, _) in headers {
            if (key.hasPrefix(prefix)) {
                canonicalizedKeys.append(key);
            }
        }
        canonicalizedKeys.sort();
        var result: String = "";
        var n = 0;
        for key in canonicalizedKeys {
            if n != 0 {
                result.append(contentsOf: "\n");
            }
            result.append(contentsOf: key);
            result.append(contentsOf: ":");
            result.append(contentsOf: headers[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "");
            n += 1;
        }
        return result;
    }

    public func getCanonicalizedResource(pathname: String, query: [String: Any]) -> String {
        if (query.count <= 0) {
            return pathname;
        }
        var keys: [String] = [String]();
        for (key, _) in query {
            keys.append(key);
        }
        keys.sort();
        var result: String = pathname + "?";
        for key in keys {
            result.append(key);
            result.append("=");
            result.append(query[key] as! String);
        }
        return result;
    }

    public func _toJSONString(_ dict: [TeaModel]) -> String {
        var dic: [[String: Any]] = [[String: Any]]();
        for model in dict {
            dic.append(model.toMap());
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dic, options: []) else {
            return "";
        }
        let json = String(data: data, encoding: String.Encoding.utf8)!;
        return json;
    }
}