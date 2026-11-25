import Darwin

/// Reads the counters of every interface, keyed by BSD name (`en0`, `utun3`, ...).
///
/// Uses `sysctl(NET_RT_IFLIST2)`, whose counters are 64-bit (`getifaddrs` only has 32-bit
/// ones). Recent macOS still truncates them for ordinary apps; see `CounterDelta`.
enum InterfaceCountersReader {
    static func read() -> [String: InterfaceCounters] {
        guard let messages = InterfaceListSysctl.fetchMessages() else { return [:] }
        return messages.withUnsafeBytes { InterfaceMessageParser(bytes: $0).countersByInterface() }
    }
}

/// The kernel's interface list, as raw routing messages.
private enum InterfaceListSysctl {
    private static let anyProtocol: Int32 = 0
    private static let anyAddressFamily: Int32 = 0
    private static let anyInterface: Int32 = 0
    /// Interfaces can appear between asking for the size and reading the list, so the buffer
    /// gets an extra 1/8 of room.
    private static let headroomDivisor = 8

    private static var managementInfoBase: [Int32] {
        [CTL_NET, PF_ROUTE, anyProtocol, anyAddressFamily, NET_RT_IFLIST2, anyInterface]
    }

    static func fetchMessages() -> [UInt8]? {
        guard let size = requiredBufferSize() else { return nil }
        return readMessages(bufferSize: size + size / headroomDivisor)
    }

    private static func requiredBufferSize() -> Int? {
        var mib = managementInfoBase
        var size = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0, size > 0 else { return nil }
        return size
    }

    private static func readMessages(bufferSize: Int) -> [UInt8]? {
        var mib = managementInfoBase
        var size = bufferSize
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &size, nil, 0) == 0 else { return nil }
        return Array(buffer.prefix(size))
    }
}

/// Walks the routing messages and picks out each interface's name and counters.
private struct InterfaceMessageParser {
    private static let headerSize = MemoryLayout<if_msghdr>.size
    private static let infoSize = MemoryLayout<if_msghdr2>.size
    /// Fields of the link-level address (`sockaddr_dl`) that follows each interface message.
    private static let nameLengthOffset = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_nlen)!
    private static let nameOffset = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data)!

    let bytes: UnsafeRawBufferPointer

    func countersByInterface() -> [String: InterfaceCounters] {
        let interfaces = messageRanges().compactMap(interface(in:))
        return Dictionary(interfaces, uniquingKeysWith: { _, latest in latest })
    }

    private func messageRanges() -> [Range<Int>] {
        var ranges: [Range<Int>] = []
        while let range = messageRange(startingAt: ranges.last?.upperBound ?? 0) {
            ranges.append(range)
        }
        return ranges
    }

    private func messageRange(startingAt start: Int) -> Range<Int>? {
        guard start + Self.headerSize <= bytes.count else { return nil }
        let length = Int(header(at: start).ifm_msglen)
        guard length > 0, start + length <= bytes.count else { return nil }
        return start..<start + length
    }

    private func header(at offset: Int) -> if_msghdr {
        bytes.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
    }

    private func interface(in message: Range<Int>) -> (String, InterfaceCounters)? {
        guard isInterfaceInfo(message), let name = interfaceName(in: message) else { return nil }
        let info = bytes.loadUnaligned(fromByteOffset: message.lowerBound, as: if_msghdr2.self)
        return (name, InterfaceCounters(info))
    }

    private func isInterfaceInfo(_ message: Range<Int>) -> Bool {
        Int32(header(at: message.lowerBound).ifm_type) == RTM_IFINFO2
            && message.count >= Self.infoSize + Self.nameOffset
    }

    private func interfaceName(in message: Range<Int>) -> String? {
        let address = message.lowerBound + Self.infoSize
        let nameStart = address + Self.nameOffset
        let name = nameStart..<nameStart + Int(bytes[address + Self.nameLengthOffset])
        guard !name.isEmpty, name.upperBound <= message.upperBound else { return nil }
        return String(decoding: bytes[name], as: UTF8.self)
    }
}
