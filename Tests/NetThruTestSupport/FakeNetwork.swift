import Foundation
import NetThruKit

extension InterfaceCounters {
    package static func counters(received: UInt64, sent: UInt64, isUp: Bool = true) -> InterfaceCounters {
        InterfaceCounters(bytesReceived: received, bytesSent: sent, isUp: isUp)
    }
}

/// Interfaces and a clock that tests control, for driving a `TrafficMonitor`.
@MainActor
package final class FakeNetwork {
    private var counters: [String: InterfaceCounters] = [:]
    private var now = ContinuousClock.now

    package init() {}

    package func set(_ name: String, received: UInt64, sent: UInt64, isUp: Bool = true) {
        counters[name] = .counters(received: received, sent: sent, isUp: isUp)
    }

    /// Lets the interface transfer more bytes, as its cumulative counters would show.
    package func transfer(on name: String, received: UInt64, sent: UInt64) {
        let current = counters[name] ?? .counters(received: 0, sent: 0)
        set(name, received: current.bytesReceived + received, sent: current.bytesSent + sent)
    }

    package func advance(seconds: Int) {
        now = now.advanced(by: .seconds(seconds))
    }

    package func makeMonitor(historyLength: Int = 14) -> TrafficMonitor {
        TrafficMonitor(historyLength: historyLength, counters: { self.counters }, clock: { self.now })
    }
}
