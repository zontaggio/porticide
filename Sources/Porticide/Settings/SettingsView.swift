import PorticideKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let notifier: KillNotifier?

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginItemError: String?

    private static let refreshOptions: [TimeInterval] = [1, 2, 3, 5, 10, 30]

    var body: some View {
        Form {
            Section {
                LabeledContent("Port range") {
                    HStack(spacing: 6) {
                        portField(value: $settings.portStart)
                        Text("–").foregroundStyle(.secondary)
                        portField(value: $settings.portEnd)
                    }
                }
                Picker("Refresh every", selection: $settings.refreshInterval) {
                    ForEach(refreshOptions, id: \.self) { seconds in
                        Text(seconds == 1 ? "1 second" : "\(Int(seconds)) seconds").tag(seconds)
                    }
                }
            } header: {
                Text("Scanning")
            } footer: {
                Text("Porticide lists processes listening on TCP and UDP ports in this range.")
                    .settingsFootnote()
            }

            Section {
                Toggle("Ask before stopping", isOn: $settings.askBeforeStopping)
                Toggle("Play a sound", isOn: $settings.playSounds)
                Toggle("Trackpad haptics", isOn: $settings.hapticFeedback)
                Toggle("Notify when a process is stopped", isOn: $settings.showNotifications)
                    .disabled(!KillNotifier.isAvailable)
                    .onChange(of: settings.showNotifications) { enabled in
                        guard enabled, let notifier else { return }
                        Task {
                            // Turn the toggle back off if the user declines the system prompt.
                            if await !notifier.requestAuthorization() {
                                settings.showNotifications = false
                            }
                        }
                    }
            } header: {
                Text("Stopping")
            } footer: {
                Text("When asking is on, the first click arms the button and a second click stops the process. Haptics need a Force Touch trackpad.")
                    .settingsFootnote()
            }

            Section {
                Toggle("Show system processes", isOn: $settings.showSystemProcesses)
                Toggle("Show command lines", isOn: $settings.showCommandLines)
                Toggle("Show count in menu bar", isOn: $settings.showCountInMenuBar)
            } header: {
                Text("Display")
            } footer: {
                Text("System processes include macOS services such as AirPlay Receiver and apps' background helpers.")
                    .settingsFootnote()
            }

            Section("General") {
                launchAtLoginToggle
            }

            Section {
                about
            }
        }
        .formStyle(.grouped)
        .tint(Brand.teal)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var refreshOptions: [TimeInterval] {
        Self.refreshOptions.contains(settings.refreshInterval)
            ? Self.refreshOptions
            : (Self.refreshOptions + [settings.refreshInterval]).sorted()
    }

    private func portField(value: Binding<Int>) -> some View {
        TextField("", value: value, format: .number.grouping(.never))
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .frame(width: 64)
    }

    private var launchAtLoginToggle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle("Open at login", isOn: Binding(
                get: { launchAtLogin },
                set: { enabled in
                    do {
                        try LoginItem.setEnabled(enabled)
                        loginItemError = nil
                    } catch {
                        loginItemError = error.localizedDescription
                    }
                    launchAtLogin = LoginItem.isEnabled
                }
            ))
            .disabled(!LoginItem.isAvailable)

            if !LoginItem.isAvailable {
                Text("Available when running Porticide.app").settingsFootnote()
            } else if let loginItemError {
                Text(loginItemError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear { launchAtLogin = LoginItem.isEnabled }
    }

    private var about: some View {
        HStack(spacing: 12) {
            AppIconView(size: 40)
            VStack(alignment: .leading, spacing: 2) {
                (Text("Port") + Text("icide").foregroundColor(Brand.teal))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("Version \(Self.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Link("GitHub", destination: URL(string: "https://github.com/zontaggio/porticide")!)
                .font(.callout)
        }
        .padding(.vertical, 2)
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}

private extension Text {
    func settingsFootnote() -> some View {
        font(.caption).foregroundStyle(.secondary)
    }
}
