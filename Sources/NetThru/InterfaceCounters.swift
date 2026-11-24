import Darwin

/// Cumulative byte counters of one network interface, as reported by the kernel.
struct InterfaceCounters {
    var received: UInt64
    var sent: UInt64
    var isUp: Bool
}

enum InterfaceCountersReader {
    /// Reads the counters of every interface, keyed by BSD name (`en0`, `utun3`, ...).
    ///
    /// Uses `sysctl(NET_RT_IFLIST2)`, whose counters are 64-bit (`getifaddrs` only has 32-bit
    /// ones). Recent macOS still truncates them for ordinary apps; see `TrafficMonitor.bytes`.
    static func read() -> [String: InterfaceCounters] {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &length, nil, 0) == 0, length > 0 else { return [:] }
        // Interfaces can appear between the two calls, so leave some headroom.
        length += length / 8
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &length, nil, 0) == 0 else { return [:] }

        var result: [String: InterfaceCounters] = [:]
        buffer.withUnsafeBytes { raw in
            let messageSize = MemoryLayout<if_msghdr2>.size
            let nameOffset = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data)!
            var offset = 0
            while offset + MemoryLayout<if_msghdr>.size <= length {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                let messageLength = Int(header.ifm_msglen)
                guard messageLength > 0 else { break }
                defer { offset += messageLength }

                guard Int32(header.ifm_type) == RTM_IFINFO2, offset + messageLength <= length,
                      messageLength >= messageSize + nameOffset else { continue }
                let message = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)

                // The link-level address (sockaddr_dl) that follows the message carries the name.
                let address = offset + messageSize
                let nameLength = Int(raw[address + 5]) // sdl_nlen
                let nameStart = address + nameOffset
                guard nameLength > 0, nameStart + nameLength <= offset + messageLength else { continue }
                let name = String(decoding: raw[nameStart..<nameStart + nameLength], as: UTF8.self)

                let flags = message.ifm_flags
                result[name] = InterfaceCounters(
                    received: message.ifm_data.ifi_ibytes,
                    sent: message.ifm_data.ifi_obytes,
                    isUp: flags & IFF_UP != 0 && flags & IFF_RUNNING != 0
                )
            }
        }
        return result
    }
}
