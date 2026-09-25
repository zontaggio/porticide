import Darwin
import Foundation
import Testing
@testable import PorticideKit

/// Runs the real `lsof` against a socket opened by the test process itself.
struct PortScannerTests {
    @Test func findsSocketListeningInThisProcess() async throws {
        let listener = try TCPListener()
        defer { listener.close() }

        let entries = await PortScanner().scan(portRange: listener.port...listener.port)
        let entry = try #require(entries.first { $0.pid == getpid() })

        #expect(entry.port == listener.port)
        #expect(entry.socket.transport == .tcp)
        #expect(entry.executablePath == Bundle.main.executablePath.map { URL(fileURLWithPath: $0).resolvingSymlinksInPath().path })
        #expect(entry.commandLine?.isEmpty == false)
    }
}

/// A TCP socket listening on an ephemeral port on the loopback interface.
private struct TCPListener {
    struct SocketError: Error { let call: String }

    let descriptor: Int32
    let port: Int

    init() throws {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw SocketError(call: "socket") }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = 0
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)

        let bound = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                bind(descriptor, sockaddrPointer, length) == 0
                    && listen(descriptor, 1) == 0
                    && getsockname(descriptor, sockaddrPointer, &length) == 0
            }
        }
        guard bound else {
            Darwin.close(descriptor)
            throw SocketError(call: "bind/listen")
        }
        self.descriptor = descriptor
        port = Int(UInt16(bigEndian: address.sin_port))
    }

    func close() {
        Darwin.close(descriptor)
    }
}
