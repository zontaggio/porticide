import Testing
@testable import PorticideKit

struct WellKnownPortsTests {
    @Test func namesCommonDevPorts() {
        #expect(WellKnownPorts.service(on: 5173) == "Vite")
        #expect(WellKnownPorts.service(on: 5432) == "PostgreSQL")
    }

    @Test func returnsNilForUnknownPorts() {
        #expect(WellKnownPorts.service(on: 12345) == nil)
    }
}
