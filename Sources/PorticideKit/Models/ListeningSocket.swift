/// A socket a process has open on a local port, as reported by `lsof`.
public struct ListeningSocket: Hashable, Sendable {
    public enum Transport: String, Sendable {
        case tcp = "TCP"
        case udp = "UDP"
    }

    public let port: Int
    public let pid: Int32
    public let processName: String
    public let user: String?
    public let transport: Transport

    public init(port: Int, pid: Int32, processName: String, user: String?, transport: Transport) {
        self.port = port
        self.pid = pid
        self.processName = processName
        self.user = user
        self.transport = transport
    }
}
