import PorticideKit
import SwiftUI

/// Actions a row can trigger; implemented by the view model.
struct PortRowActions {
    var stop: (_ force: Bool) -> Void
    var openInBrowser: () -> Void
    var copyURL: () -> Void
    var revealProject: () -> Void
    var openTerminal: () -> Void
    var copyPID: () -> Void
}

struct PortRow: View {
    let entry: PortEntry
    let showCommandLine: Bool
    /// Stopping takes a second click on the armed button.
    let asksBeforeStopping: Bool
    /// 0 while the process is running; animates to 1 once it has been stopped.
    let stopProgress: Double
    let actions: PortRowActions

    @State private var isHovered = false
    @State private var isArmed = false

    private var isStopping: Bool { stopProgress > 0 }

    var body: some View {
        let fade = StopEffect.phase(stopProgress, from: 0.2, to: 0.55)
        let collapse = StopEffect.phase(stopProgress, from: 0.6, to: 1)

        CollapseLayout(fraction: 1 - collapse) {
            HStack(spacing: 10) {
                ServiceIcon(kind: entry.service.kind)
                    .saturation(1 - fade)
                labels
                    .opacity(1 - fade * 0.6)
                Spacer(minLength: 6)
                trailing
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(background)
            .opacity(1 - collapse)
        }
        .clipped(enabled: collapse > 0)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovered = hovering && !isStopping }
        }
        .contextMenu { if !isStopping { contextMenu } }
        .help(entry.commandLine ?? entry.processName)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.service.displayName) on port \(entry.port)")
        .accessibilityAction(named: "Stop") { if !isStopping { actions.stop(false) } }
    }

    // MARK: - Content

    private var labels: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 5) {
                Text(entry.service.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                if let detail = entry.service.detail {
                    Text(detail)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.07), in: Capsule())
                        .lineLimit(1)
                }
                if let label = entry.launchdLabel {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .help("Kept running by launchd (\(label)). Stopping it unloads the service until you log in again.")
                }
            }
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if showCommandLine, let commandLine = entry.commandLine {
                Text(commandLine)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    /// Where the server runs from, or a hint about what usually lives on this port.
    private var subtitle: String {
        if let project = entry.projectPath {
            return (project as NSString).abbreviatingWithTildeInPath
        }
        if entry.service.kind == .other, let hint = WellKnownPorts.service(on: entry.port) {
            return "Usually \(hint)"
        }
        if let executable = entry.executablePath {
            return Self.describe(executable: executable)
        }
        return "PID \(entry.pid)"
    }

    /// `/opt/homebrew/opt/postgresql@16/bin/postgres` → `Homebrew · postgresql@16`.
    static func describe(executable: String) -> String {
        let components = executable.split(separator: "/").map(String.init)
        for (prefix, name) in [(["opt", "homebrew"], "Homebrew"), (["usr", "local"], "Homebrew"), (["opt", "local"], "MacPorts")] {
            guard components.starts(with: prefix) else { continue }
            let rest = components.dropFirst(prefix.count)
            if let marker = rest.firstIndex(where: { $0 == "opt" || $0 == "Cellar" }), marker + 1 < rest.endIndex {
                return "\(name) · \(rest[marker + 1])"
            }
        }
        if let app = components.first(where: { $0.hasSuffix(".app") }) {
            return String(app.dropLast(4))
        }
        return (executable as NSString).abbreviatingWithTildeInPath
    }

    private var trailing: some View {
        HStack(spacing: 4) {
            // The slot is always laid out so the port column never shifts on hover.
            RowIconButton(systemImage: "safari", help: "Open http://localhost:\(entry.port)", action: actions.openInBrowser)
                .opacity(isHovered && !isArmed && entry.service.kind.speaksHTTP ? 1 : 0)
                .disabled(!entry.service.kind.speaksHTTP || isStopping || isArmed)
                .accessibilityHidden(!entry.service.kind.speaksHTTP)

            portLabel
                // The armed "Stop" button covers the port without changing the layout.
                .overlay(alignment: .trailing) {
                    if isArmed {
                        ConfirmStopButton(title: "Stop") {
                            isArmed = false
                            actions.stop(NSEvent.modifierFlags.contains(.option))
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)))
                    }
                }

            RowIconButton(
                systemImage: isArmed ? "xmark" : "xmark.circle.fill",
                help: isArmed ? "Cancel" : "Stop (⌥-click to force quit)",
                tint: isHovered && !isArmed ? .red : Color.secondary.opacity(0.55),
                size: isArmed ? 11 : 15
            ) {
                if isArmed {
                    withAnimation(.easeOut(duration: 0.15)) { isArmed = false }
                } else if asksBeforeStopping {
                    withAnimation(.easeOut(duration: 0.15)) { isArmed = true }
                } else {
                    actions.stop(NSEvent.modifierFlags.contains(.option))
                }
            }
            .disabled(isStopping)
        }
        .onChange(of: isHovered) { hovering in
            // Leaving the row disarms it, so a stray click later can't stop anything.
            if !hovering, isArmed {
                withAnimation(.easeOut(duration: 0.15)) { isArmed = false }
            }
        }
    }

    private var portLabel: some View {
        Text(verbatim: ":\(entry.port)")
            .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(.primary.opacity(isStopping ? 0.45 : 0.8))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.06), in: Capsule())
            .overlay(PortStrike(progress: stopProgress))
            .overlay(SparkBurst(progress: stopProgress, seed: entry.port, accent: entry.service.kind.brandColor))
    }

    private var background: some View {
        let flash = StopEffect.phase(stopProgress, from: 0, to: 0.25) * (1 - StopEffect.phase(stopProgress, from: 0.3, to: 0.7))
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(isHovered ? Color.primary.opacity(0.07) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Brand.teal.opacity(0.14 * flash))
            )
    }

    @ViewBuilder
    private var contextMenu: some View {
        if entry.service.kind.speaksHTTP {
            Button("Open in Browser", action: actions.openInBrowser)
            Button("Copy URL", action: actions.copyURL)
            Divider()
        }
        if entry.projectPath != nil {
            Button("Show Project in Finder", action: actions.revealProject)
            Button("Open Project in Terminal", action: actions.openTerminal)
            Divider()
        }
        Button("Copy PID \(String(entry.pid))", action: actions.copyPID)
        Divider()
        Button("Stop") { actions.stop(false) }
        Button("Force Quit") { actions.stop(true) }
    }
}

/// The red capsule that confirms a stop when "Ask before stopping" is on.
struct ConfirmStopButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 20)
                .background(Capsule().fill(Color.red))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Click to stop")
    }
}

/// A borderless icon button with a hover highlight.
struct RowIconButton: View {
    let systemImage: String
    let help: String
    var tint: Color = .secondary
    var size: CGFloat = 13
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.primary.opacity(isHovered ? 0.08 : 0)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(help)
        .accessibilityLabel(help)
    }
}

private extension View {
    @ViewBuilder
    func clipped(enabled: Bool) -> some View {
        if enabled { clipped() } else { self }
    }
}
