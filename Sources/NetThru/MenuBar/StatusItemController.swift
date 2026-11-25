import AppKit
import NetThruKit

/// The menu bar item: the graph view on top of a status bar button, plus its menu.
@MainActor
final class StatusItemController {
    private static let autosaveName = "net-thru"

    private let monitor: TrafficMonitor
    private let statusItem: NSStatusItem
    private let statusView = StatusView()
    private let menu: StatusMenu

    init(monitor: TrafficMonitor) {
        MenuBarPosition.preferNextToSystemItems(autosaveName: Self.autosaveName)
        self.monitor = monitor
        statusItem = NSStatusBar.system.statusItem(withLength: StatusLayout.width)
        menu = StatusMenu(monitor: monitor)
        configureStatusItem()
    }

    func refresh() {
        statusView.samples = monitor.recentSamples
        updateAccessibilityLabel()
        menu.refreshIfOpen()
    }

    private func configureStatusItem() {
        statusItem.autosaveName = Self.autosaveName
        statusItem.menu = menu.menu
        embedStatusView()
    }

    /// Plain autoresizing rather than constraints: constraints inside the status bar button make
    /// AppKit run a layout pass on every redraw.
    private func embedStatusView() {
        guard let button = statusItem.button else { return }
        statusView.frame = button.bounds
        statusView.autoresizingMask = [.width, .height]
        button.addSubview(statusView)
    }

    private func updateAccessibilityLabel() {
        let label = Self.accessibilityLabel(for: monitor.latestSample)
        guard let button = statusItem.button, button.accessibilityLabel() != label else { return }
        button.setAccessibilityLabel(label)
    }

    private static func accessibilityLabel(for sample: TrafficSample) -> String {
        "Upload \(ByteFormat.rate(sample.upload)), download \(ByteFormat.rate(sample.download))"
    }
}
