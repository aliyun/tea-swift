import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// One local HTTP request per test. A nil body echoes the received request.
final class HTTPTestServer {
    let port: Int
    private var listener: Int32
    private let finished = DispatchGroup()
    private let stopDelay = DispatchSemaphore(value: 0)

    init(statusCode: Int = 200, body: String? = nil, delay: TimeInterval = 0) throws {
        #if os(Linux)
        let fd = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #else
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        #endif
        guard fd >= 0 else { throw POSIXError(.EIO) }
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, length) }
        }
        guard bound == 0, listen(fd, 1) == 0 else {
            close(fd)
            throw POSIXError(.EADDRINUSE)
        }
        let named = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &length) }
        }
        guard named == 0 else {
            close(fd)
            throw POSIXError(.EIO)
        }
        port = Int(UInt16(bigEndian: address.sin_port))
        listener = fd
        let finished = self.finished
        let stopDelay = self.stopDelay
        finished.enter()
        DispatchQueue.global().async {
            defer { finished.leave() }
            let connection = accept(fd, nil, nil)
            guard connection >= 0 else { return }
            defer { close(connection) }
            var timeout = timeval(tv_sec: 3, tv_usec: 0)
            setsockopt(connection, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
            #if !os(Linux)
            var noSignal: Int32 = 1
            setsockopt(connection, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
            #endif
            var request = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while request.count < 1_048_576 {
                let count = recv(connection, &buffer, buffer.count, 0)
                guard count > 0 else { return }
                request.append(contentsOf: buffer.prefix(count))
                if let end = request.range(of: Data("\r\n\r\n".utf8)) {
                    let headers = String(decoding: request[..<end.lowerBound], as: UTF8.self)
                    let size = headers.components(separatedBy: "\r\n").first {
                        $0.lowercased().hasPrefix("content-length:")
                    }.flatMap { Int($0.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) } ?? 0
                    if request.count >= end.upperBound + size { break }
                }
            }
            if delay > 0 { _ = stopDelay.wait(timeout: .now() + delay) }
            let payload = body.map { Data($0.utf8) } ?? request
            var response = Data("HTTP/1.1 \(statusCode) Test\r\nContent-Length: \(payload.count)\r\nContent-Type: application/json\r\nX-Mock: tea\r\nConnection: close\r\n\r\n".utf8)
            response.append(payload)
            response.withUnsafeBytes { bytes in
                var sent = 0
                while sent < bytes.count {
                    #if os(Linux)
                    let count = send(connection, bytes.baseAddress!.advanced(by: sent), bytes.count - sent, Int32(MSG_NOSIGNAL))
                    #else
                    let count = send(connection, bytes.baseAddress!.advanced(by: sent), bytes.count - sent, 0)
                    #endif
                    guard count > 0 else { return }
                    sent += count
                }
            }
        }
    }

    func stop() {
        guard listener >= 0 else { return }
        shutdown(listener, Int32(SHUT_RDWR))
        close(listener)
        listener = -1
        stopDelay.signal()
        finished.wait()
    }

    deinit { stop() }
}
