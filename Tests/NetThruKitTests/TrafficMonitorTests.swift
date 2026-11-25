import Testing
@testable import NetThruKit
import NetThruTestSupport

@MainActor
@Suite("TrafficMonitor")
struct TrafficMonitorTests {
    private let network = FakeNetwork()

    @Test func firstReadingOnlySetsTheBaseline() {
        let monitor = network.makeMonitor()
        network.set("en0", received: 5_000, sent: 5_000)
        monitor.takeSample()
        #expect(monitor.recentSamples.isEmpty)
        #expect(monitor.latestSample == .idle)
    }

    @Test func ratesAreBytesPerSecondBetweenReadings() {
        let monitor = monitorWithBaseline()
        transfer(on: monitor, received: 4_000, sent: 1_000, overSeconds: 2)
        #expect(monitor.latestSample == TrafficSample(download: 2_000, upload: 500))
    }

    @Test func countsOnlyPhysicalInterfaces() {
        let monitor = monitorWithBaseline()
        network.set("utun3", received: 0, sent: 0)
        network.set("lo0", received: 0, sent: 0)
        monitor.takeSample()
        network.transfer(on: "utun3", received: 50_000, sent: 50_000)
        network.transfer(on: "lo0", received: 50_000, sent: 50_000)
        transfer(on: monitor, received: 1_000, sent: 0, overSeconds: 1)
        #expect(monitor.latestSample == TrafficSample(download: 1_000, upload: 0))
    }

    @Test func keepsOnlyTheMostRecentSamples() {
        let monitor = monitorWithBaseline(historyLength: 3)
        for kilobytes in 1...5 {
            transfer(on: monitor, received: UInt64(kilobytes) * 1_000, sent: 0, overSeconds: 1)
        }
        #expect(monitor.recentSamples.map(\.download) == [3_000, 4_000, 5_000])
    }

    @Test func accumulatesTotals() {
        let monitor = monitorWithBaseline()
        transfer(on: monitor, received: 1_000, sent: 300, overSeconds: 1)
        transfer(on: monitor, received: 2_000, sent: 700, overSeconds: 1)
        #expect(monitor.totalDownloaded == 3_000)
        #expect(monitor.totalUploaded == 1_000)
    }

    @Test func trafficWhileTheLastReadingIsForgottenIsNotCounted() {
        let monitor = monitorWithBaseline()
        monitor.forgetLastReading()
        transfer(on: monitor, received: 900_000, sent: 0, overSeconds: 3_600)
        transfer(on: monitor, received: 1_000, sent: 0, overSeconds: 1)
        #expect(monitor.recentSamples == [TrafficSample(download: 1_000, upload: 0)])
        #expect(monitor.totalDownloaded == 1_000)
    }

    @Test func activeInterfacesAreUpAndHaveCarriedTraffic() {
        let monitor = network.makeMonitor()
        network.set("en0", received: 10, sent: 10)
        network.set("en1", received: 0, sent: 0)
        network.set("en2", received: 10, sent: 10, isUp: false)
        monitor.takeSample()
        #expect(monitor.activeInterfaceNames == ["en0"])
    }

    private func monitorWithBaseline(historyLength: Int = 14) -> TrafficMonitor {
        let monitor = network.makeMonitor(historyLength: historyLength)
        network.set("en0", received: 0, sent: 0)
        monitor.takeSample()
        return monitor
    }

    private func transfer(on monitor: TrafficMonitor, received: UInt64, sent: UInt64, overSeconds seconds: Int) {
        network.transfer(on: "en0", received: received, sent: sent)
        network.advance(seconds: seconds)
        monitor.takeSample()
    }
}
