import XCTest
@testable import Porticide

final class LsofParserTests: XCTestCase {
    func testParsesTCPAndUDPPorts() {
        let output = """
        COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node     8123 me     23u  IPv4 0x000000000000 0t0  TCP *:3000 (LISTEN)
        python   9452 me     12u  IPv6 0x000000000000 0t0  TCP 127.0.0.1:8000 (LISTEN)
        dnsmasq  1200 me      7u  IPv4 0x000000000000 0t0  UDP *:5353
        """

        let entries = LsofParser.parse(output, portRange: 3000...9999)
        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(entries.contains { $0.port == 3000 && $0.pid == 8123 })
        XCTAssertTrue(entries.contains { $0.port == 8000 && $0.pid == 9452 })
        XCTAssertTrue(entries.contains { $0.port == 5353 && $0.pid == 1200 })
    }

    func testFiltersPortRange() {
        let output = """
        COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node     8123 me     23u  IPv4 0x000000000000 0t0  TCP *:3000 (LISTEN)
        """

        let entries = LsofParser.parse(output, portRange: 4000...9000)
        XCTAssertTrue(entries.isEmpty)
    }
}
