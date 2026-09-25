import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let notifier: KillNotifier
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginItemError: String?

    private let portFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimum = 1
        formatter.maximum = 65535
        formatter.allowsFloats = false
        return formatter
    }()

    private let intervalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimum = 1
        formatter.maximum = 60
        formatter.allowsFloats = true
        return formatter
    }()

    var body: some View {
        Form {
            Section("Port Range") {
                HStack {
                    TextField("Start", value: $settings.portStart, formatter: portFormatter)
                        .frame(width: 80)
                    Text("–")
                    TextField("End", value: $settings.portEnd, formatter: portFormatter)
                        .frame(width: 80)
                }
            }

            Section("Refresh") {
                TextField("Seconds", value: $settings.refreshInterval, formatter: intervalFormatter)
                    .frame(width: 80)
            }

            Section("Behavior") {
                Toggle("Confirm before kill", isOn: $settings.confirmBeforeKill)
                launchAtLoginToggle
                Toggle("Notify when a process is stopped", isOn: $settings.showNotifications)
                    .disabled(!KillNotifier.isAvailable)
                    .onChange(of: settings.showNotifications) { enabled in
                        guard enabled else { return }
                        Task {
                            // Turn the toggle back off if the user declines the system prompt.
                            if await !notifier.requestAuthorization() {
                                settings.showNotifications = false
                            }
                        }
                    }
                Toggle("Show command lines", isOn: $settings.showCommandLines)
                Toggle("Show system processes", isOn: $settings.showSystemProcesses)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var launchAtLoginToggle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle("Launch at login", isOn: Binding(
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
                Text("Available when running Porticide.app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let loginItemError {
                Text(loginItemError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear { launchAtLogin = LoginItem.isEnabled }
    }
}
