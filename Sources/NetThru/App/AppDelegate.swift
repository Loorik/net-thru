import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// How often the rates are sampled, in seconds.
    private static let sampleInterval: TimeInterval = 1

    private let monitor = TrafficMonitor(historyLength: StatusLayout.visibleSampleCount)
    private var statusItem: StatusItemController?
    private var ticker: Ticker?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController(monitor: monitor)
        refreshWithNewSample()
        ticker = Ticker(interval: Self.sampleInterval) { [weak self] in self?.refreshWithNewSample() }
        forgetReadingAfterWake()
    }

    private func refreshWithNewSample() {
        monitor.takeSample()
        statusItem?.refresh()
    }

    /// Traffic while the Mac slept would otherwise show up as one huge spike after waking.
    private func forgetReadingAfterWake() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.monitor.forgetLastReading() }
        }
    }
}
