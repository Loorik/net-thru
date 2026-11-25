import AppKit
import NetThruKit
import NetThruTestSupport
import Testing
@testable import NetThru

@Suite("InterfaceDescriptions")
struct InterfaceDescriptionsTests {
    private let displayNames = ["en0": "Wi-Fi", "en5": "Thunderbolt Ethernet"]

    @Test func noInterfacesMeansNoConnection() {
        #expect(describe([]) == "No connection")
    }

    @Test func showsTheDisplayNameWithTheBSDName() {
        #expect(describe(["en0"]) == "Wi-Fi (en0)")
    }

    @Test func fallsBackToTheBSDName() {
        #expect(describe(["en7"]) == "en7")
    }

    @Test func listsSeveralInterfaces() {
        #expect(describe(["en0", "en5"]) == "Wi-Fi (en0), Thunderbolt Ethernet (en5)")
    }

    private func describe(_ bsdNames: [String]) -> String {
        InterfaceDescriptions.describe(bsdNames, displayNames: displayNames)
    }
}

@MainActor
@Suite("InfoRow")
struct InfoRowTests {
    private let row = InfoRow(label: "Uploaded")

    @Test func cannotBeClicked() {
        #expect(!row.item.isEnabled)
    }

    @Test func showsTheLabelAndTheValueSeparatedByATab() {
        row.value = "12 KB"
        #expect(row.item.attributedTitle?.string == "Uploaded\t12 KB")
    }

    @Test func alignsTheValueRight() {
        row.value = "12 KB"
        let style = row.item.attributedTitle?.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(style?.tabStops.first?.alignment == .right)
    }
}

@MainActor
@Suite("StatusMenu")
struct StatusMenuTests {
    private let network = FakeNetwork()

    @Test func itemsAreInOrder() {
        let labels = openMenu(for: network.makeMonitor()).menu.items.map(label)
        #expect(labels == ["Since Launch", "Downloaded", "Uploaded", "", "Interfaces", "", "Launch at Login", "Quit net-thru"])
    }

    @Test func showsTheTotalsSinceLaunch() {
        let monitor = monitorAfterTransfer(received: 12_000, sent: 45_000)
        let menu = openMenu(for: monitor)
        #expect(value(of: "Downloaded", in: menu) == "12 KB")
        #expect(value(of: "Uploaded", in: menu) == "45 KB")
    }

    @Test func updatesWhileOpen() {
        let monitor = monitorAfterTransfer(received: 12_000, sent: 0)
        let menu = openMenu(for: monitor)
        network.transfer(on: "en0", received: 30_000, sent: 0)
        network.advance(seconds: 1)
        monitor.takeSample()
        menu.refreshIfOpen()
        #expect(value(of: "Downloaded", in: menu) == "42 KB")
    }

    @Test func quitsWithCommandQ() {
        let quit = openMenu(for: network.makeMonitor()).menu.items.last
        #expect(quit?.keyEquivalent == "q")
        #expect(quit?.action == #selector(NSApplication.terminate(_:)))
    }

    private func openMenu(for monitor: TrafficMonitor) -> StatusMenu {
        let statusMenu = StatusMenu(monitor: monitor)
        statusMenu.menuWillOpen(statusMenu.menu)
        return statusMenu
    }

    private func monitorAfterTransfer(received: UInt64, sent: UInt64) -> TrafficMonitor {
        let monitor = network.makeMonitor()
        network.set("en0", received: 0, sent: 0)
        monitor.takeSample()
        network.transfer(on: "en0", received: received, sent: sent)
        network.advance(seconds: 1)
        monitor.takeSample()
        return monitor
    }

    private func label(_ item: NSMenuItem) -> String {
        title(item).components(separatedBy: "\t")[0]
    }

    private func value(of label: String, in statusMenu: StatusMenu) -> String? {
        let row = statusMenu.menu.items.first { self.label($0) == label }
        return row.map(title)?.components(separatedBy: "\t").last
    }

    private func title(_ item: NSMenuItem) -> String {
        item.attributedTitle?.string ?? item.title
    }
}
