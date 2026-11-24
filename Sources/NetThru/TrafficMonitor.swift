import Foundation

/// Turns the kernel's cumulative interface counters into transfer rates.
@MainActor
final class TrafficMonitor {
    struct Sample: Equatable {
        var down: Double // bytes per second
        var up: Double
    }

    /// Only `en*` interfaces are counted: Wi-Fi, Ethernet, USB/Thunderbolt adapters and iPhone
    /// tethering. That leaves out loopback, VPN tunnels (`utun*`, whose traffic also crosses
    /// `en*` and would be counted twice), bridges, AirDrop (`awdl*`) and other virtual interfaces.
    static func isCounted(_ interface: String) -> Bool {
        interface.hasPrefix("en")
    }

    /// Most recent samples, oldest first.
    private(set) var history: [Sample] = []
    private(set) var totalReceived: UInt64 = 0
    private(set) var totalSent: UInt64 = 0
    /// Counted interfaces that are up and have carried traffic (idle Thunderbolt ports also
    /// report being up).
    private(set) var activeInterfaces: [String] = []

    private let capacity: Int
    private let clock = ContinuousClock()
    private var previous: (time: ContinuousClock.Instant, counters: [String: InterfaceCounters])?

    init(capacity: Int) {
        self.capacity = capacity
    }

    var current: Sample {
        history.last ?? Sample(down: 0, up: 0)
    }

    /// Forgets the last reading, e.g. after the Mac wakes from sleep, so traffic that happened
    /// while the display wasn't updating doesn't show up as one huge spike.
    func resetBaseline() {
        previous = nil
    }

    func update() {
        let now = clock.now
        let counters = InterfaceCountersReader.read().filter { Self.isCounted($0.key) }
        activeInterfaces = counters
            .filter { $0.value.isUp && ($0.value.received > 0 || $0.value.sent > 0) }
            .keys.sorted()

        defer { previous = (now, counters) }
        guard let previous else { return }
        let elapsed = (now - previous.time) / .seconds(1)
        guard elapsed > 0 else { return }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        for (name, new) in counters {
            // Interfaces that just appeared contribute nothing until the next reading.
            guard let old = previous.counters[name] else { continue }
            received += Self.bytes(from: old.received, to: new.received)
            sent += Self.bytes(from: old.sent, to: new.sent)
        }
        totalReceived += received
        totalSent += sent

        history.append(Sample(down: Double(received) / elapsed, up: Double(sent) / elapsed))
        if history.count > capacity {
            history.removeFirst(history.count - capacity)
        }
    }

    /// Bytes transferred between two readings of the same counter.
    ///
    /// macOS only gives apps without special entitlements coarse counters: rounded to 1 KB
    /// and wrapping around at 4 GB (2^32). So a counter that went down has usually wrapped.
    private static func bytes(from old: UInt64, to new: UInt64) -> UInt64 {
        if new >= old { return new - old }
        // A full 64-bit counter can't wrap in practice, so it must have been reset.
        guard old < 1 << 32 else { return 0 }
        let wrapped = (1 << 32) - old + new
        // More than 2 GB in one reading is a reset, not a wrap.
        return wrapped < 1 << 31 ? wrapped : 0
    }
}
