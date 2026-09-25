import AppKit
import PorticideKit
import SwiftUI

/// The menu shown on right-click (or Control-click) of the menu bar icon.
/// Built fresh each time it opens, so it always reflects the current ports and settings.
@MainActor
final class StatusMenu: NSObject {
    private let viewModel: PortListViewModel
    private let settings: SettingsStore
    private let showPopover: () -> Void
    private let openSettings: () -> Void

    init(viewModel: PortListViewModel, settings: SettingsStore, showPopover: @escaping () -> Void, openSettings: @escaping () -> Void) {
        self.viewModel = viewModel
        self.settings = settings
        self.showPopover = showPopover
        self.openSettings = openSettings
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let running = viewModel.entries.filter { viewModel.stopStarts[$0.id] == nil }
        menu.addItem(.sectionHeader(running.isEmpty ? "No busy ports" : running.count == 1 ? "1 busy port" : "\(running.count) busy ports"))
        for entry in running {
            menu.addItem(serverItem(for: entry))
        }

        menu.addItem(.separator())
        menu.addItem(ActionItem("Show Porticide", perform: showPopover))
        menu.addItem(ActionItem("Refresh", key: "r", perform: viewModel.refresh))
        let stopAll = ActionItem(running.count > 1 ? "Stop All \(running.count) Servers" : "Stop All", perform: viewModel.stopAll)
        stopAll.isEnabled = !running.isEmpty
        menu.addItem(stopAll)

        menu.addItem(.separator())
        let systemProcesses = ActionItem("Show System Processes") { [settings] in
            settings.showSystemProcesses.toggle()
        }
        systemProcesses.state = settings.showSystemProcesses ? .on : .off
        menu.addItem(systemProcesses)

        let login = ActionItem("Open at Login") {
            try? LoginItem.setEnabled(!LoginItem.isEnabled)
        }
        login.state = LoginItem.isEnabled ? .on : .off
        login.isEnabled = LoginItem.isAvailable
        menu.addItem(login)
        menu.addItem(ActionItem("Settings…", key: ",", perform: openSettings))

        menu.addItem(.separator())
        menu.addItem(ActionItem("About Porticide", perform: Self.showAbout))
        menu.addItem(ActionItem("Porticide on GitHub") {
            NSWorkspace.shared.open(Self.repository)
        })

        menu.addItem(.separator())
        menu.addItem(ActionItem("Quit Porticide", key: "q", perform: viewModel.quit))
        return menu
    }

    /// "Vite  :5173" with the service logo, and a submenu of actions for it.
    private func serverItem(for entry: PortEntry) -> NSMenuItem {
        let item = NSMenuItem(title: entry.service.displayName, action: nil, keyEquivalent: "")
        item.attributedTitle = Self.title(for: entry)
        item.image = Self.icon(for: entry.service.kind)
        if let project = entry.projectPath {
            item.toolTip = (project as NSString).abbreviatingWithTildeInPath
        }

        let actions = viewModel.actions(for: entry)
        let submenu = NSMenu()
        if entry.service.kind.speaksHTTP {
            submenu.addItem(ActionItem("Open in Browser", perform: actions.openInBrowser))
            submenu.addItem(ActionItem("Copy URL", perform: actions.copyURL))
            submenu.addItem(.separator())
        }
        if entry.projectPath != nil {
            submenu.addItem(ActionItem("Show Project in Finder", perform: actions.revealProject))
            submenu.addItem(ActionItem("Open Project in Terminal", perform: actions.openTerminal))
            submenu.addItem(.separator())
        }
        submenu.addItem(ActionItem("Copy PID \(entry.pid)", perform: actions.copyPID))
        submenu.addItem(.separator())
        submenu.addItem(ActionItem("Stop") { actions.stop(false) })
        let forceQuit = ActionItem("Force Quit") { actions.stop(true) }
        forceQuit.isEnabled = entry.launchdLabel == nil // launchd jobs are always booted out.
        submenu.addItem(forceQuit)
        item.submenu = submenu
        return item
    }

    private static func title(for entry: PortEntry) -> NSAttributedString {
        let title = NSMutableAttributedString(string: "\(entry.service.displayName)  ")
        title.append(NSAttributedString(string: ":\(entry.port)", attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]))
        return title
    }

    private static var icons: [ServiceKind: NSImage] = [:]

    private static func icon(for kind: ServiceKind) -> NSImage? {
        if let cached = icons[kind] { return cached }
        let renderer = ImageRenderer(content: ServiceIcon(kind: kind, size: 16).padding(1))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage
        icons[kind] = image
        return image
    }

    static let repository = URL(string: "https://github.com/zontaggio/porticide")!

    private static func showAbout() {
        let credits = NSMutableAttributedString(
            string: "Kills busy ports.\n",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
        )
        credits.append(NSAttributedString(string: "github.com/zontaggio/porticide", attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .link: repository,
        ]))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        credits.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: credits.length))

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}

/// A menu item that runs a closure, so menus don't need an @objc selector per action.
private final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", perform handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: key)
        target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func run() {
        handler()
    }
}

private extension NSMenuItem {
    /// A disabled title row (NSMenuItem.sectionHeader is macOS 14+).
    static func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor,
        ])
        item.isEnabled = false
        return item
    }
}
