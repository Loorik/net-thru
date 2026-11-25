import Darwin

/// Cumulative byte counters of one network interface, as reported by the kernel.
struct InterfaceCounters {
    var bytesReceived: UInt64
    var bytesSent: UInt64
    var isUp: Bool

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
