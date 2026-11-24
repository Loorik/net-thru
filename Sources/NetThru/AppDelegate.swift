import AppKit
import ServiceManagement
import SystemConfiguration

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor = TrafficMonitor(capacity: StatusView.sampleCount)
    private let statusView = StatusView()
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    private let downloadedItem = NSMenuItem()
    private let uploadedItem = NSMenuItem()
    private let interfacesItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private var isMenuOpen = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // New menu bar items start out furthest left, the first place macOS hides items when
        // the bar is crowded. Until the user ⌘-drags it elsewhere (which macOS then remembers),
        // sit right next to the system items instead. The value is the distance from the right
        // edge of the screen; macOS orders the items by it.
        let autosaveName = "net-thru"
        UserDefaults.standard.register(defaults: ["NSStatusItem Preferred Position \(autosaveName)": 290])

        statusItem = NSStatusBar.system.statusItem(withLength: StatusView.preferredWidth)
        statusItem.autosaveName = autosaveName
        statusItem.menu = makeMenu()
        if let button = statusItem.button {
            // Plain autoresizing rather than constraints: constraints inside the status bar
            // button make AppKit run a layout pass on every redraw.
            statusView.frame = button.bounds
            statusView.autoresizingMask = [.width, .height]
            button.addSubview(statusView)
        }

        monitor.update()
        refresh()

        // Added in .common mode so the numbers keep moving while the menu is open.
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.monitor.resetBaseline() }
        }
    }

    private func tick() {
        monitor.update()
        refresh()
    }

    private func refresh() {
        statusView.history = monitor.history
        let current = monitor.current
        let label = "Upload \(ByteFormat.rate(current.up)), download \(ByteFormat.rate(current.down))"
        if let button = statusItem.button, button.accessibilityLabel() != label {
            button.setAccessibilityLabel(label)
        }
        if isMenuOpen {
            updateMenuItems()
        }
    }

    // MARK: - Menu

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        menu.addItem(.sectionHeader(title: "Since Launch"))
        for item in [downloadedItem, uploadedItem, interfacesItem] {
            item.isEnabled = false
        }
        menu.addItem(downloadedItem)
        menu.addItem(uploadedItem)
        menu.addItem(.separator())
        menu.addItem(interfacesItem)
        menu.addItem(.separator())

        launchAtLoginItem.target = self
        // Login items need the app bundle; there is nothing to register when run via `swift run`.
        launchAtLoginItem.isHidden = Bundle.main.bundleIdentifier == nil
        menu.addItem(launchAtLoginItem)
        menu.addItem(NSMenuItem(title: "Quit net-thru", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        updateMenuItems()
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
    }

    private func updateMenuItems() {
        downloadedItem.attributedTitle = row("Downloaded", ByteFormat.amount(Double(monitor.totalReceived)))
        uploadedItem.attributedTitle = row("Uploaded", ByteFormat.amount(Double(monitor.totalSent)))

        let names = interfaceDisplayNames()
        let interfaces = monitor.activeInterfaces.map { bsdName in
            names[bsdName].map { "\($0) (\(bsdName))" } ?? bsdName
        }
        interfacesItem.attributedTitle = row("Interfaces", interfaces.isEmpty ? "No connection" : interfaces.joined(separator: ", "))
    }

    /// A menu row with the label on the left and the value right-aligned.
    private func row(_ label: String, _ value: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [NSTextTab(textAlignment: .right, location: 200)]
        return NSAttributedString(
            string: "\(label)\t\(value)",
            attributes: [.paragraphStyle: paragraph, .font: NSFont.menuFont(ofSize: 0)]
        )
    }

    /// "Wi-Fi", "Thunderbolt Ethernet", ... keyed by BSD name.
    private func interfaceDisplayNames() -> [String: String] {
        let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []
        var names: [String: String] = [:]
        for interface in interfaces {
            if let bsdName = SCNetworkInterfaceGetBSDName(interface) as String?,
               let name = SCNetworkInterfaceGetLocalizedDisplayName(interface) as String? {
                names[bsdName] = name
            }
        }
        return names
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
    }
}
