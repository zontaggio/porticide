import Foundation
import PorticideKit
import UserNotifications

/// Posts a notification after processes are stopped.
@MainActor
final class KillNotifier: NSObject {
    /// UNUserNotificationCenter crashes outside an app bundle, e.g. under `swift run`.
    static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    private var center: UNUserNotificationCenter? {
        Self.isAvailable ? .current() : nil
    }

    override init() {
        super.init()
        center?.delegate = self
    }

    /// Asks for permission the first time; returns whether notifications are allowed.
    func requestAuthorization() async -> Bool {
        guard let center else { return false }
        // The completion-handler API keeps `center` on the main actor; the async
        // variant would send it across isolation domains.
        return await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func notifyStopped(_ entries: [PortEntry]) {
        guard let center, !entries.isEmpty else { return }

        let content = UNMutableNotificationContent()
        if entries.count == 1, let entry = entries.first {
            content.title = "Stopped \(entry.service.displayName)"
            content.body = "Port \(entry.port) is free."
        } else {
            content.title = "Stopped \(entries.count) processes"
            content.body = "Freed ports " + entries.map { String($0.port) }.joined(separator: ", ") + "."
        }

        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}

extension KillNotifier: UNUserNotificationCenterDelegate {
    /// Porticide counts as the active app right after a click in its popover;
    /// without this, macOS would suppress the banner.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
