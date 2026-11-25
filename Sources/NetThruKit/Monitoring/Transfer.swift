/// Bytes downloaded and uploaded across all counted interfaces between two readings.
struct Transfer {
    private(set) var downloaded: UInt64 = 0
    private(set) var uploaded: UInt64 = 0

    init(from old: [String: InterfaceCounters], to new: [String: InterfaceCounters]) {
        for (name, counters) in new {
            // Interfaces that just appeared contribute nothing until the next reading.
            guard let previous = old[name] else { continue }
            add(from: previous, to: counters)
        }
    }

    func rate(over seconds: Double) -> TrafficSample {
        TrafficSample(download: Double(downloaded) / seconds, upload: Double(uploaded) / seconds)
    }

    private mutating func add(from old: InterfaceCounters, to new: InterfaceCounters) {
        downloaded += CounterDelta.bytes(from: old.bytesReceived, to: new.bytesReceived)
        uploaded += CounterDelta.bytes(from: old.bytesSent, to: new.bytesSent)
    }
}

/// Bytes transferred between two readings of the same interface counter.
///
/// macOS only gives apps without special entitlements coarse counters: rounded to 1 KB and
/// wrapping around at 4 GB (2^32). So a counter that went down has usually wrapped.
enum CounterDelta {
    private static let wrapAround: UInt64 = 1 << 32
    /// More than this in one reading means the counter was reset rather than wrapped.
    private static let largestPlausibleDelta: UInt64 = 1 << 31

    static func bytes(from old: UInt64, to new: UInt64) -> UInt64 {
        if new >= old { return new - old }
        return bytesAcrossWrap(from: old, to: new) ?? 0
    }

    private static func bytesAcrossWrap(from old: UInt64, to new: UInt64) -> UInt64? {
        // A full 64-bit counter can't wrap in practice, so it must have been reset.
        guard old < wrapAround else { return nil }
        let delta = wrapAround - old + new
        return delta < largestPlausibleDelta ? delta : nil
    }
}
