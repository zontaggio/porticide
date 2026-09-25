import Foundation
import PorticideKit

final class PortMonitor: @unchecked Sendable {
    private let settings: SettingsStore
    private let scanner = PortScanner()
    private let queue = DispatchQueue(label: "porticide.monitor", qos: .userInitiated)
    private var timer: DispatchSourceTimer?

    var onUpdate: (([PortEntry]) -> Void)?

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func start() {
        stop()
        scheduleTimer()
        refresh()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func refresh() {
        let range = settings.portRange
        queue.async { [weak self] in
            guard let self else { return }
            let entries = self.scanner.scan(portRange: range)
            DispatchQueue.main.async {
                self.onUpdate?(entries)
            }
        }
    }

    private func scheduleTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 0.1, repeating: settings.effectiveRefreshInterval)
        timer.setEventHandler { [weak self] in
            self?.refresh()
        }
        timer.resume()
        self.timer = timer
    }
}
