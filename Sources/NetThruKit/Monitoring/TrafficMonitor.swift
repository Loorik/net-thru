import Foundation

/// Turns the kernel's cumulative interface counters into transfer rates.
@MainActor
package final class TrafficMonitor {
    /// Current byte counters of every interface, keyed by BSD name.
    package typealias CounterSource = @MainActor () -> [String: InterfaceCounters]
    package typealias TimeSource = @MainActor () -> ContinuousClock.Instant

    private struct Reading {
        let time: ContinuousClock.Instant
        let counters: [String: InterfaceCounters]
    }

    /// Only `en*` interfaces are counted: Wi-Fi, Ethernet, USB/Thunderbolt adapters and iPhone
    /// tethering. That leaves out loopback, VPN tunnels (`utun*`, whose traffic also crosses
    /// `en*` and would be counted twice), bridges, AirDrop (`awdl*`) and other virtual interfaces.
    private static let countedInterfacePrefix = "en"

    /// Most recent samples, oldest first.
    package private(set) var recentSamples: [TrafficSample] = []
    package private(set) var totalDownloaded: UInt64 = 0
    package private(set) var totalUploaded: UInt64 = 0
    /// Counted interfaces that are up and have carried traffic (idle Thunderbolt ports also
    /// report being up).
    package private(set) var activeInterfaceNames: [String] = []

    private let historyLength: Int
    private let readInterfaceCounters: CounterSource
    private let now: TimeSource
    private var lastReading: Reading?

    package init(
        historyLength: Int,
        counters: @escaping CounterSource = InterfaceCountersReader.read,
        clock: @escaping TimeSource = { ContinuousClock.now }
    ) {
        self.historyLength = historyLength
        readInterfaceCounters = counters
        now = clock
    }

    package var latestSample: TrafficSample {
        recentSamples.last ?? .idle
    }

    package func takeSample() {
        let reading = readCounters()
        activeInterfaceNames = Self.activeInterfaceNames(in: reading)
        if let lastReading { record(from: lastReading, to: reading) }
        lastReading = reading
    }

    /// Forgets the last reading, e.g. after the Mac wakes from sleep, so traffic that happened
    /// while the display wasn't updating doesn't show up as one huge spike.
    package func forgetLastReading() {
        lastReading = nil
    }

    private func readCounters() -> Reading {
        let time = now()
        let counters = readInterfaceCounters().filter { Self.isCounted($0.key) }
        return Reading(time: time, counters: counters)
    }

    private func record(from old: Reading, to new: Reading) {
        let elapsedSeconds = (new.time - old.time) / .seconds(1)
        guard elapsedSeconds > 0 else { return }
        let transfer = Transfer(from: old.counters, to: new.counters)
        totalDownloaded += transfer.downloaded
        totalUploaded += transfer.uploaded
        append(transfer.rate(over: elapsedSeconds))
    }

    private func append(_ sample: TrafficSample) {
        recentSamples.append(sample)
        recentSamples.removeFirst(max(0, recentSamples.count - historyLength))
    }

    private static func isCounted(_ interfaceName: String) -> Bool {
        interfaceName.hasPrefix(countedInterfacePrefix)
    }

    private static func activeInterfaceNames(in reading: Reading) -> [String] {
        reading.counters.filter { $0.value.isUp && $0.value.hasCarriedTraffic }.keys.sorted()
    }
}
