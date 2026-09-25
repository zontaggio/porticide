import AppKit
import SwiftUI

@MainActor
enum MenuBarIcon {
    /// The Porticide mark as an 18 pt template image, so macOS tints it for the menu bar.
    static let image: NSImage = {
        let renderer = ImageRenderer(content: PorticideMark(socketColor: .black, slashColor: .black).frame(width: 18, height: 18))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage(systemSymbolName: "powerplug", accessibilityDescription: nil)!
        image.isTemplate = true
        image.accessibilityDescription = "Porticide"
        return image
    }()
}
