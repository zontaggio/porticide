import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var portStart: Int { didSet { persist(); onChange?() } }
    @Published var portEnd: Int { didSet { persist(); onChange?() } }
    @Published var refreshInterval: TimeInterval { didSet { persist(); onChange?() } }
    @Published var confirmBeforeKill: Bool { didSet { persist() } }
    @Published var launchAtLogin: Bool { didSet { persist() } }
    @Published var showNotifications: Bool { didSet { persist() } }
    @Published var showDetailed: Bool { didSet { persist() } }
    @Published var showSystemProcesses: Bool { didSet { persist(); onChange?() } }

    var onChange: (() -> Void)?

    private let defaults = UserDefaults.standard

    init() {
        let start = defaults.object(forKey: Keys.portStart) as? Int ?? 3000
        let end = defaults.object(forKey: Keys.portEnd) as? Int ?? 9999
        let interval = defaults.object(forKey: Keys.refreshInterval) as? Double ?? 3.0
        let confirm = defaults.object(forKey: Keys.confirmBeforeKill) as? Bool ?? true
        let launch = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        let notify = defaults.object(forKey: Keys.showNotifications) as? Bool ?? false
        let detailed = defaults.object(forKey: Keys.showDetailed) as? Bool ?? false
        let showSystem = defaults.object(forKey: Keys.showSystemProcesses) as? Bool ?? false

        portStart = start
        portEnd = end
        refreshInterval = interval
        confirmBeforeKill = confirm
        launchAtLogin = launch
        showNotifications = notify
        showDetailed = detailed
        showSystemProcesses = showSystem
    }

    private func persist() {
        defaults.set(portStart, forKey: Keys.portStart)
        defaults.set(portEnd, forKey: Keys.portEnd)
        defaults.set(refreshInterval, forKey: Keys.refreshInterval)
        defaults.set(confirmBeforeKill, forKey: Keys.confirmBeforeKill)
        defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
        defaults.set(showNotifications, forKey: Keys.showNotifications)
        defaults.set(showDetailed, forKey: Keys.showDetailed)
        defaults.set(showSystemProcesses, forKey: Keys.showSystemProcesses)
    }

    private enum Keys {
        static let portStart = "portStart"
        static let portEnd = "portEnd"
        static let refreshInterval = "refreshInterval"
        static let confirmBeforeKill = "confirmBeforeKill"
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let showDetailed = "showDetailed"
        static let showSystemProcesses = "showSystemProcesses"
    }
}
// Fix: Settings not persisting correctly
// Add system process filter option
