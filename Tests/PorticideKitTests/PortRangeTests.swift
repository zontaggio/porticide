import Testing
@testable import PorticideKit

struct PortRangeTests {
    @Test func keepsValidRange() {
        #expect(PortRange.normalized(3000, 9999) == 3000...9999)
    }

    @Test func acceptsBoundsInEitherOrder() {
        #expect(PortRange.normalized(9999, 3000) == 3000...9999)
    }

    @Test func clampsToValidPorts() {
        #expect(PortRange.normalized(0, 70000) == 1...65535)
    }
}
