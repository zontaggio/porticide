import Testing
@testable import PorticideKit

struct LsofParserTests {
    @Test func parsesSocketsGroupedByProcess() {
        let output = """
        p8123
        cnode
        Lme
        f23
        PTCP
        n*:3000
        f24
        PUDP
        n*:5353
        p9452
        cControlCenter
        Lme
        f12
        PTCP
        n127.0.0.1:8000
        """

        let sockets = LsofParser.parse(output, portRange: 3000...9999)

        #expect(sockets == [
            ListeningSocket(port: 3000, pid: 8123, processName: "node", user: "me", transport: .tcp),
            ListeningSocket(port: 5353, pid: 8123, processName: "node", user: "me", transport: .udp),
            ListeningSocket(port: 8000, pid: 9452, processName: "ControlCenter", user: "me", transport: .tcp),
        ])
    }

    @Test func dropsPortsOutsideRange() {
        let output = """
        p8123
        cnode
        f23
        PTCP
        n*:3000
        """

        #expect(LsofParser.parse(output, portRange: 4000...9000).isEmpty)
    }

    @Test func skipsUnboundSocketsAndMalformedProcesses() {
        let output = """
        p664
        cidentityservicesd
        f10
        PUDP
        n*:*
        pnotapid
        cnode
        f23
        PTCP
        n*:3000
        """

        #expect(LsofParser.parse(output, portRange: 1...65535).isEmpty)
    }

    @Test(arguments: [
        ("*:3000", 3000),
        ("127.0.0.1:8000", 8000),
        ("[::1]:5432", 5432),
        ("[fe80::1%lo0]:6379", 6379),
        ("127.0.0.1:5000->127.0.0.1:6000", 5000),
    ])
    func extractsLocalPort(address: String, port: Int) {
        #expect(LsofParser.port(fromAddress: address) == port)
    }
}
