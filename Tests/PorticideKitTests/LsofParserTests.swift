import Testing
@testable import PorticideKit

struct LsofParserTests {
    @Test func parsesTCPAndUDPSockets() {
        let output = """
        COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node     8123 me     23u  IPv4 0x000000000000 0t0  TCP *:3000 (LISTEN)
        python   9452 me     12u  IPv6 0x000000000000 0t0  TCP 127.0.0.1:8000 (LISTEN)
        dnsmasq  1200 me      7u  IPv4 0x000000000000 0t0  UDP *:5353
        """

        let sockets = LsofParser.parse(output, portRange: 3000...9999)

        #expect(sockets == [
            ListeningSocket(port: 3000, pid: 8123, processName: "node", user: "me", transport: .tcp),
            ListeningSocket(port: 8000, pid: 9452, processName: "python", user: "me", transport: .tcp),
            ListeningSocket(port: 5353, pid: 1200, processName: "dnsmasq", user: "me", transport: .udp),
        ])
    }

    @Test func dropsPortsOutsideRange() {
        let output = """
        COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node     8123 me     23u  IPv4 0x000000000000 0t0  TCP *:3000 (LISTEN)
        """

        #expect(LsofParser.parse(output, portRange: 4000...9000).isEmpty)
    }

    @Test func ignoresMalformedLines() {
        let output = """
        COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        garbage
        node     notapid me  23u  IPv4 0x000000000000 0t0  TCP *:3000 (LISTEN)
        """

        #expect(LsofParser.parse(output, portRange: 1...65535).isEmpty)
    }
}
