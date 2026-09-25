import SwiftUI

/// Colours from the Porticide logo.
enum Brand {
    /// The slash that strikes through a port.
    static let teal = Color(red: 0x00 / 255, green: 0xBB / 255, blue: 0xA9 / 255)
    static let ink = Color(red: 0x12 / 255, green: 0x16 / 255, blue: 0x1B / 255)
}

extension Color {
    /// Creates a colour from a hex value such as `0x9135FF`.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
