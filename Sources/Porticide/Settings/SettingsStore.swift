import Combine
import Foundation
import PorticideKit

/// User preferences, persisted in UserDefaults.
@MainActor
final class SettingsStore: ObservableObject {
    @Published var portStart: Int { didSet { defaults.set(portStart, forKey: Keys.portStart) } }
    @Published var portEnd: Int { didSet { defaults.set(portEnd, forKey: Keys.portEnd) } }
    @Published var refreshInterval: TimeInterval { didSet { defaults.set(refreshInterval, forKey: Keys.refreshInterval) } }
    /// Off by default: Porticide is a one-click tool. When on, stopping takes a second click.
    @Published var askBeforeStopping: Bool { didSet { defaults.set(askBeforeStopping, forKey: Keys.askBeforeStopping) } }
    @Published var showNotifications: Bool { didSet { defaults.set(showNotifications, forKey: Keys.showNotifications) } }
    @Published var showCommandLines: Bool { didSet { defaults.set(showCommandLines, forKey: Keys.showCommandLines) } }
    @Published var showCountInMenuBar: Bool { didSet { defaults.set(showCountInMenuBar, forKey: Keys.showCountInMenuBar) } }
    @Published var playSounds: Bool { didSet { defaults.set(playSounds, forKey: Keys.playSounds) } }
    @Published var showSystemProcesses: Bool { didSet { defaults.set(showSystemProcesses, forKey: Keys.showSystemProcesses) } }

    /// The range to scan. Safe to use even while the user is mid-edit with start > end.
    var portRange: ClosedRange<Int> { PortRange.normalized(portStart, portEnd) }

    /// Never poll faster than once a second, whatever is stored.
    var effectiveRefreshInterval: TimeInterval { max(refreshInterval, 1) }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        portStart = defaults.object(forKey: Keys.portStart) as? Int ?? 3000
        portEnd = defaults.object(forKey: Keys.portEnd) as? Int ?? 9999
        refreshInterval = defaults.object(forKey: Keys.refreshInterval) as? Double ?? 3.0
        askBeforeStopping = defaults.object(forKey: Keys.askBeforeStopping) as? Bool ?? false
        showNotifications = defaults.object(forKey: Keys.showNotifications) as? Bool ?? false
        showCommandLines = defaults.object(forKey: Keys.showCommandLines) as? Bool ?? false
        showCountInMenuBar = defaults.object(forKey: Keys.showCountInMenuBar) as? Bool ?? true
        playSounds = defaults.object(forKey: Keys.playSounds) as? Bool ?? true
        showSystemProcesses = defaults.object(forKey: Keys.showSystemProcesses) as? Bool ?? false
    }

    private enum Keys {
        static let portStart = "portStart"
        static let portEnd = "portEnd"
        static let refreshInterval = "refreshInterval"
        // A new key: 1.x stored "confirmBeforeKill" = true for everyone, which would keep
        // the old modal confirmation on for existing users.
        static let askBeforeStopping = "askBeforeStopping"
        static let showNotifications = "showNotifications"
        static let showCommandLines = "showDetailed" // Kept from 1.0 so existing preferences carry over.
        static let showCountInMenuBar = "showCountInMenuBar"
        static let playSounds = "playSounds"
        static let showSystemProcesses = "showSystemProcesses"
    }
}
