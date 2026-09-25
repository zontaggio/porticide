import PorticideKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: PortListViewModel
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 12)
            content
            if let notice = viewModel.notice {
                NoticeBanner(notice: notice, onDismiss: viewModel.dismissNotice)
                    .id(notice.id)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Divider().padding(.horizontal, 12)
            footer
        }
        .frame(width: 348)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: viewModel.notice?.id)
        .tint(Brand.teal)
        .background(shortcuts)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            AppIconView(size: 32)

            VStack(alignment: .leading, spacing: 1) {
                (Text("Port") + Text("icide").foregroundColor(Brand.teal))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                HStack(spacing: 5) {
                    LiveIndicator(isActive: !viewModel.entries.isEmpty)
                    Text(viewModel.statusText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
            }

            Spacer()

            OptionsMenu(viewModel: viewModel, settings: settings)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isScanning && viewModel.entries.isEmpty {
            VStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text("Scanning ports…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
        } else if viewModel.entries.isEmpty {
            EmptyStateView(portRange: viewModel.portRange)
        } else {
            ScrollView {
                TimelineView(.animation(minimumInterval: nil, paused: !viewModel.isAnimatingStops)) { timeline in
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.sections) { section in
                        if viewModel.sections.count > 1 {
                            SectionHeader(title: section.title, showsContainerIcon: section.isContainerGroup)
                        }
                        ForEach(section.entries) { entry in
                            PortRow(
                                entry: entry,
                                showCommandLine: settings.showCommandLines,
                                asksBeforeStopping: settings.askBeforeStopping,
                                stopProgress: viewModel.stopProgress(for: entry.id, at: timeline.date),
                                actions: viewModel.actions(for: entry)
                            )
                            .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: viewModel.entries.map(\.id))
                }
            }
            // Legacy scrollers ("Show scroll bars: Always") take width from the content; as
            // rows collapse the list crosses the height limit and the whole port column would
            // jump sideways. Scrolling still works with the trackpad or wheel.
            .scrollIndicators(.never)
            .frame(maxHeight: 400)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text(verbatim: "Ports \(viewModel.portRange.lowerBound)–\(viewModel.portRange.upperBound)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Spacer()
            StopAllButton(
                count: viewModel.entries.count - viewModel.stopStarts.count,
                asksBeforeStopping: settings.askBeforeStopping,
                action: viewModel.stopAll
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// Keyboard shortcuts while the popover is focused.
    private var shortcuts: some View {
        Group {
            Button("Refresh", action: viewModel.refresh).keyboardShortcut("r")
            Button("Settings", action: viewModel.openSettings).keyboardShortcut(",")
            Button("Quit", action: viewModel.quit).keyboardShortcut("q")
        }
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Components

private struct SectionHeader: View {
    let title: String
    var showsContainerIcon = false

    var body: some View {
        HStack(spacing: 4) {
            if showsContainerIcon {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 9))
            }
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
        }
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

/// A dot that softly pulses while ports are busy.
private struct LiveIndicator: View {
    let isActive: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(isActive ? Brand.teal : Color.secondary.opacity(0.5))
            .frame(width: 6, height: 6)
            .background(
                Circle()
                    .stroke(Brand.teal, lineWidth: 1.5)
                    .scaleEffect(pulse ? 2.4 : 1)
                    .opacity(isActive && !pulse ? 0.7 : 0)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
            }
    }
}

private struct OptionsMenu: View {
    @ObservedObject var viewModel: PortListViewModel
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Menu {
            Toggle("Show System Processes", isOn: $settings.showSystemProcesses)
            Toggle("Show Command Lines", isOn: $settings.showCommandLines)
            Divider()
            Button("Refresh", action: viewModel.refresh)
            Button("Settings…", action: viewModel.openSettings)
            Divider()
            Button("Quit Porticide", action: viewModel.quit)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .tint(.secondary)
        .fixedSize()
        .help("Options")
    }
}

/// "Stop All", which arms itself for a few seconds when "Ask before stopping" is on.
private struct StopAllButton: View {
    let count: Int
    let asksBeforeStopping: Bool
    let action: () -> Void

    @State private var isArmed = false
    @State private var isHovered = false
    @State private var disarm: Task<Void, Never>?

    var body: some View {
        Button {
            if asksBeforeStopping && !isArmed {
                arm()
            } else {
                isArmed = false
                action()
            }
        } label: {
            Label(isArmed ? "Stop \(count)?" : "Stop All", systemImage: isArmed ? "exclamationmark.circle.fill" : "xmark.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isArmed ? Color.white : count > 0 ? Color.red : Color.secondary.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color.red.opacity(isArmed ? 1 : count > 0 ? (isHovered ? 0.16 : 0.1) : 0.04))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isArmed)
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private func arm() {
        isArmed = true
        disarm?.cancel()
        disarm = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            isArmed = false
        }
    }
}

/// Shown when nothing is listening: the mark draws its slash in on appear.
private struct EmptyStateView: View {
    let portRange: ClosedRange<Int>
    @State private var slash: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            PorticideMark(socketColor: .secondary.opacity(0.35), slashProgress: slash)
                .frame(width: 54, height: 54)
                .padding(.bottom, 4)
            Text("All ports are free")
                .font(.system(size: 14, weight: .semibold))
            Text(verbatim: "Nothing is listening on \(portRange.lowerBound)–\(portRange.upperBound).")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .onAppear {
            slash = 0
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) { slash = 1 }
        }
    }
}
