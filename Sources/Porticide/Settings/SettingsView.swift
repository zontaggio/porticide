import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
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
                Toggle("Show notifications", isOn: $settings.showNotifications)
                Toggle("Show detailed view", isOn: $settings.showDetailed)
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
