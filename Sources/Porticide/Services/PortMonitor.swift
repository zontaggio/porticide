import Foundation
import PorticideKit

/// Scans ports on a fixed interval and reports results on the main actor.
@MainActor
final class PortMonitor {
    var onUpdate: (([PortEntry]) -> Void)?

    private let scanner = PortScanner()
    private var loop: Task<Void, Never>?
    private var portRange: ClosedRange<Int> = PortRange.valid

    func start(portRange: ClosedRange<Int>, interval: TimeInterval) {
        self.portRange = portRange
        loop?.cancel()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.scan()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    /// Scans right away, outside the regular schedule.
    func refresh() {
        Task { await scan() }
    }

    private func scan() async {
        let entries = await scanner.scan(portRange: portRange)
        onUpdate?(entries)
    }
}
