import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var hoveredEntry: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .padding(.horizontal, 12)
            content
            Divider()
                .padding(.horizontal, 12)
            footer
        }
        .frame(width: 380)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "network")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Porticide")
                    .font(.system(size: 15, weight: .semibold))
                HStack(spacing: 4) {
                    Text("Ports \(String(viewModel.portStart))–\(String(viewModel.portEnd))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.quaternary)
                    Text(timeAgo(viewModel.lastUpdated))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Active badge
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.entries.isEmpty ? Color.gray : Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.entries.isEmpty ? .clear : .green.opacity(0.5), radius: 4)
                Text("\(viewModel.entries.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Content
    private var content: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                loadingView
            } else if viewModel.entries.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .frame(minHeight: 120, maxHeight: 340)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Scanning ports…")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.green)
            Text("All clear!")
                .font(.system(size: 14, weight: .medium))
            Text("No active ports in range")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(viewModel.entries) { entry in
                    PortRow(
                        entry: entry,
                        detailed: viewModel.showDetailed,
                        isHovered: hoveredEntry == entry.id,
                        onKill: { viewModel.kill(entry: entry, force: false) }
                    )
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredEntry = isHovered ? entry.id : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: 0) {
            footerButton(icon: "arrow.clockwise", label: "Refresh", showSpinner: viewModel.isLoading) {
                viewModel.refresh()
            }
            Divider()
                .frame(height: 20)
            footerButton(icon: "xmark.circle", label: "Kill All", disabled: viewModel.entries.isEmpty) {
                viewModel.killAll()
            }
            Divider()
                .frame(height: 20)
            footerButton(icon: "gearshape", label: "Settings") {
                viewModel.openSettings()
            }

            Spacer()

            Toggle(isOn: $viewModel.showDetailed) {
                Text("Details")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .onChange(of: viewModel.showDetailed) { _ in
                viewModel.updateDetailedSetting()
            }

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 8)

            footerButton(icon: "power", label: "Quit") {
                viewModel.quit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func footerButton(icon: String, label: String, showSpinner: Bool = false, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if showSpinner {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(disabled ? .tertiary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(label)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        return "\(minutes)m ago"
    }
}

// MARK: - Port Row
private struct PortRow: View {
    let entry: PortEntry
    let detailed: Bool
    let isHovered: Bool
    let onKill: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Port badge
            Text(verbatim: String(entry.port))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 52, height: 28)
                .background(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 6)
                )

            // Service info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: entry.iconName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(iconColor)
                    Text(entry.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    if let detail = entry.detail {
                        Text(detail)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                    }
                }
                if let path = entry.projectPath {
                    Text(path)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                if detailed, let command = entry.commandLine {
                    Text(command)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.quaternary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            // PID and kill
            HStack(spacing: 8) {
                Text(verbatim: String(entry.pid))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)

                Button(action: onKill) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isHovered ? .red : .secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Kill process")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }

    private var gradientColors: [Color] {
        switch entry.displayName {
        case let name where name.contains("vite"):
            return [Color.purple, Color.pink]
        case let name where name.contains("next"):
            return [Color.black, Color.gray]
        case let name where name.contains("streamlit"):
            return [Color.red, Color.orange]
        case let name where name.contains("django"):
            return [Color.green, Color.mint]
        case let name where name.contains("flask"):
            return [Color.gray, Color.black]
        case let name where name.contains("bun"):
            return [Color.orange, Color.yellow]
        case let name where name.contains("webpack"):
            return [Color.blue, Color.cyan]
        case let name where name.contains("docker"):
            return [Color.blue, Color.indigo]
        case let name where name.contains("node"):
            return [Color.green, Color.mint]
        case let name where name.contains("python"):
            return [Color.yellow, Color.blue]
        default:
            return [Color.gray, Color.secondary]
        }
    }

    private var iconColor: Color {
        switch entry.displayName {
        case let name where name.contains("vite"): return .purple
        case let name where name.contains("next"): return .primary
        case let name where name.contains("streamlit"): return .red
        case let name where name.contains("django"): return .green
        case let name where name.contains("flask"): return .gray
        case let name where name.contains("bun"): return .orange
        case let name where name.contains("webpack"): return .blue
        case let name where name.contains("docker"): return .blue
        case let name where name.contains("node"): return .green
        case let name where name.contains("python"): return .yellow
        default: return .secondary
        }
    }
}
// Basic SwiftUI popover layout
// Refactor: Extract common UI components
