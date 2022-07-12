import Foundation
import Tea

public class ListDriveResponse: TeaModel {
    public var requestId: String?

    public var items: [String: String]?
    
    public var list: [Any]?

    public var nextMarker: Int?
    
    public var model: Complex?
    
    public class Complex : TeaModel {
        public var name: String?
        public var code: NSNumber?
        
        public override func validate() throws -> Void {
            try self.validateRequired(self.code, "code")
        }
        
        public override func toMap() -> [String : Any] {
            var map = super.toMap()
            if self.name != nil {
                map["name"] = self.name
            }
            if self.code != nil {
                map["code"] = self.code
            }
            return map
        }
        
        public override func fromMap(_ dict: [String: Any]) -> Void {
            if dict.keys.contains("name") {
                self.name = dict["name"] as! String
            }
            if dict.keys.contains("code") {
                self.code = dict["code"] as! NSNumber
            }
        }
    }
    
    public override init() {
        super.init()
    }

    public init(_ dict: [String: Any]) {
        super.init()
        self.fromMap(dict)
    }
    
    public override func validate() throws -> Void {
        try self.model?.validate()
    }
    
    public override func toMap() -> [String : Any] {
        var map = super.toMap()
        if self.requestId != nil {
            map["requestId"] = self.requestId
        }
        if self.requestId != nil {
            map["requestId"] = self.requestId
        }
        if self.items != nil {
            map["items"] = self.items
        }
        if self.list != nil {
            map["list"] = self.list
        }
        if self.requestId != nil {
            map["nextMarker"] = self.nextMarker
        }
        if self.model != nil {
            map["model"] = self.model?.toMap()
        }
        return map
    }
    
    public override func fromMap(_ dict: [String: Any]) -> Void {
        if dict.keys.contains("requestId") {
            self.requestId = dict["requestId"] as! String
        }
        if dict.keys.contains("items") {
            self.items = dict["items"] as! [String: String]
        }
        if dict.keys.contains("list") {
            self.list = dict["list"] as! [Any]
        }
        if dict.keys.contains("nextMarker") {
            self.nextMarker = dict["nextMarker"] as! Int
        }
        if dict.keys.contains("model") {
            var model = Complex()
            model.fromMap(dict["model"] as! [String: Any])
            self.model = model
        }
    }
}

public class ListDriveRequestModel: TeaModel {
    public var limit: Int?
    public var marker: String?
    public var owner: String?
    
    public override init() {
        super.init()
    }

    public init(_ dict: [String: Any]) {
        super.init()
        self.fromMap(dict)
    }
    
    public override func validate() throws -> Void {
        try self.validateRequired(self.owner, "owner")
    }
    
    public override func toMap() -> [String : Any] {
        var map = super.toMap()
        if self.limit != nil {
            map["limit"] = self.limit
        }
        if self.marker != nil {
            map["marker"] = self.marker
        }
        if self.owner != nil {
            map["owner"] = self.owner
        }
        return map
    }
    
    public override func fromMap(_ dict: [String: Any]) -> Void {
        if dict.keys.contains("limit") {
            self.limit = dict["limit"] as! Int
        }
        if dict.keys.contains("marker") {
            self.marker = dict["marker"] as! String
        }
        if dict.keys.contains("owner") {
            self.owner = dict["owner"] as! String
        }
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
