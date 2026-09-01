import Foundation

private let DATA_PREFIX = "data:"
private let EVENT_PREFIX = "event:"
private let ID_PREFIX = "id:"
private let RETRY_PREFIX = "retry:"

/// Darabonba `$SSEEvent`.
open class SSEEvent {
    public var data: String?
    public var id: String?
    public var event: String?
    public var retry: Int?

    public init(_ map: [String: Any] = [:]) {
        data = map["data"] as? String
        id = map["id"] as? String
        event = map["event"] as? String
        if let r = map["retry"] as? Int {
            retry = r
        } else if let r = map["retry"] as? Int32 {
            retry = Int(r)
        } else if let r = map["retry"] as? NSNumber {
            retry = r.intValue
        }
    }

    public init(data: String? = nil, id: String? = nil, event: String? = nil, retry: Int? = nil) {
        self.data = data
        self.id = id
        self.event = event
        self.retry = retry
    }
}

private func isDigitsOnly(_ str: String) -> Bool {
    !str.isEmpty && str.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
}

private struct EventParseResult {
    var events: [SSEEvent]
    var remain: String
}

private func tryGetEvents(head: String, chunk: String) -> EventParseResult {
    let all = head + chunk
    var start = all.startIndex
    var events: [SSEEvent] = []
    var i = all.startIndex
    while i < all.endIndex {
        let next = all.index(after: i)
        if next < all.endIndex, all[i] == "\n", all[next] == "\n" {
            let part = String(all[start..<i])
            let lines = part.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            let event = SSEEvent()
            for line in lines {
                if line.hasPrefix(DATA_PREFIX) {
                    event.data = String(line.dropFirst(DATA_PREFIX.count)).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix(EVENT_PREFIX) {
                    event.event = String(line.dropFirst(EVENT_PREFIX.count)).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix(ID_PREFIX) {
                    event.id = String(line.dropFirst(ID_PREFIX.count)).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix(RETRY_PREFIX) {
                    let retry = String(line.dropFirst(RETRY_PREFIX.count)).trimmingCharacters(in: .whitespaces)
                    if isDigitsOnly(retry) {
                        event.retry = Int(retry)
                    }
                } else if line.hasPrefix(":") {
                    // comment line — ignore
                }
            }
            events.append(event)
            start = all.index(next, offsetBy: 1)
            i = start
            continue
        }
        i = next
    }
    let remain = String(all[start...])
    return EventParseResult(events: events, remain: remain)
}

/// Darabonba `$Stream` helpers (bytes / string / JSON / SSE).
open class TeaStream {
    public static func readAsBytes(_ data: Data?) -> [UInt8] {
        guard let data = data else {
            return []
        }
        return [UInt8](data)
    }

    public static func readAsBytes(_ stream: InputStream) throws -> [UInt8] {
        stream.open()
        defer { stream.close() }
        var result: [UInt8] = []
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read < 0 {
                throw stream.streamError ?? TeaError("stream read failed")
            }
            if read == 0 {
                break
            }
            result.append(contentsOf: buffer[0..<read])
        }
        return result
    }

    public static func readAsString(_ data: Data?) -> String {
        guard let data = data else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    public static func readAsJSON(_ data: Data?) throws -> Any {
        let str = readAsString(data)
        guard let raw = str.data(using: .utf8), !raw.isEmpty else {
            return NSNull()
        }
        return try JSONSerialization.jsonObject(with: raw, options: [.mutableContainers])
    }

    /// Parse SSE text already buffered (used by unit tests and non-streaming bodies).
    public static func parseSSEEvents(_ text: String) -> [SSEEvent] {
        let result = tryGetEvents(head: "", chunk: text.hasSuffix("\n\n") ? text : text + "\n\n")
        return result.events
    }

    /// Async SSE iterator over an in-memory body (`Data`). Aligns with `$Stream.readAsSSE`.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public static func readAsSSE(_ data: Data?) -> AsyncThrowingStream<SSEEvent, Error> {
        let text = readAsString(data)
        return AsyncThrowingStream { continuation in
            Task {
                let events = parseSSEEvents(text)
                for event in events {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    /// Async SSE iterator over a byte stream delivered in chunks (simulates progressive read).
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public static func readAsSSE(chunks: [String]) -> AsyncThrowingStream<SSEEvent, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                var rest = ""
                for chunk in chunks {
                    let parsed = tryGetEvents(head: rest, chunk: chunk)
                    rest = parsed.remain
                    for event in parsed.events {
                        continuation.yield(event)
                    }
                }
                if !rest.isEmpty {
                    let parsed = tryGetEvents(head: rest, chunk: "\n\n")
                    for event in parsed.events {
                        continuation.yield(event)
                    }
                }
                continuation.finish()
            }
        }
    }
}
