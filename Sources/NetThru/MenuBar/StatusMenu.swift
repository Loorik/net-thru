import AppKit

/// The menu that opens when clicking the menu bar item.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()

    private let monitor: TrafficMonitor
    private let downloadedRow = InfoRow(label: "Downloaded")
    private let uploadedRow = InfoRow(label: "Uploaded")
    private let interfacesRow = InfoRow(label: "Interfaces")
    private let launchAtLoginItem = NSMenuItem(
        title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: ""
    )
    private var isOpen = false

    init(monitor: TrafficMonitor) {
        self.monitor = monitor
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
        configureLaunchAtLoginItem()
        addItems()
    }

    func refreshIfOpen() {
        if isOpen { refreshRows() }
    }

    func menuWillOpen(_ menu: NSMenu) {
        isOpen = true
        refreshRows()
        launchAtLoginItem.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    func menuDidClose(_ menu: NSMenu) {
        isOpen = false
    }

    private func configureLaunchAtLoginItem() {
        launchAtLoginItem.target = self
        launchAtLoginItem.isHidden = !LaunchAtLogin.isAvailable
    }

    private func addItems() {
        menu.addItem(.sectionHeader(title: "Since Launch"))
        menu.addItem(downloadedRow.item)
        menu.addItem(uploadedRow.item)
        menu.addItem(.separator())
        menu.addItem(interfacesRow.item)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(Self.makeQuitItem())
    }

    private static func makeQuitItem() -> NSMenuItem {
        NSMenuItem(title: "Quit net-thru", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func refreshRows() {
        downloadedRow.value = ByteFormat.amount(Double(monitor.totalDownloaded))
        uploadedRow.value = ByteFormat.amount(Double(monitor.totalUploaded))
        interfacesRow.value = InterfaceDescriptions.describe(monitor.activeInterfaceNames)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLogin.toggle()
        } catch {
            presentError(error)
        }
    }

    /// net-thru has no windows, so it has to come to the front before an alert can show.
    private func presentError(_ error: Error) {
        NSApp.activate()
        NSAlert(error: error).runModal()
    }
}
