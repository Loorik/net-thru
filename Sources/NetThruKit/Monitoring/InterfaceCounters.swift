import Darwin

/// Cumulative byte counters of one network interface, as reported by the kernel.
package struct InterfaceCounters: Sendable {
    package var bytesReceived: UInt64
    package var bytesSent: UInt64
    package var isUp: Bool

    package init(bytesReceived: UInt64, bytesSent: UInt64, isUp: Bool) {
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.isUp = isUp
    }

    var hasCarriedTraffic: Bool {
        bytesReceived > 0 || bytesSent > 0
    }
}

extension InterfaceCounters {
    init(_ info: if_msghdr2) {
        bytesReceived = info.ifm_data.ifi_ibytes
        bytesSent = info.ifm_data.ifi_obytes
        isUp = Self.isUpAndRunning(info.ifm_flags)
    }

    private static func isUpAndRunning(_ flags: Int32) -> Bool {
        flags & IFF_UP != 0 && flags & IFF_RUNNING != 0
    }
}
