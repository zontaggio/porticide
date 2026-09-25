import Foundation
import ServiceManagement

/// Registers Porticide to open at login. Backed by SMAppService, so the
/// system (System Settings › General › Login Items) is the source of truth.
@MainActor
enum LoginItem {
    /// Login items need a real app bundle; `swift run` produces a bare binary.
    static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    static var isEnabled: Bool {
        isAvailable && SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
