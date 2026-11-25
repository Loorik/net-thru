import Darwin
import Testing
@testable import NetThruKit

@Suite("InterfaceMessageParser")
struct InterfaceMessageParserTests {
    @Test func readsNameCountersAndState() {
        let counters = parse(RoutingMessages.interfaceInfo(name: "en0", received: 1_234, sent: 567))
        #expect(counters["en0"]?.bytesReceived == 1_234)
        #expect(counters["en0"]?.bytesSent == 567)
        #expect(counters["en0"]?.isUp == true)
    }

    @Test func interfaceThatIsUpButNotRunningIsNotUp() {
        let counters = parse(RoutingMessages.interfaceInfo(name: "en1", flags: IFF_UP))
        #expect(counters["en1"]?.isUp == false)
    }

    @Test func skipsOtherMessageTypes() {
        let messages = RoutingMessages.otherMessage() + RoutingMessages.interfaceInfo(name: "en0")
            + RoutingMessages.otherMessage() + RoutingMessages.interfaceInfo(name: "lo0")
        #expect(Set(parse(messages).keys) == ["en0", "lo0"])
    }

    @Test func stopsAtATruncatedMessage() {
        let truncated = Array(RoutingMessages.interfaceInfo(name: "en1").dropLast(4))
        #expect(Set(parse(RoutingMessages.interfaceInfo(name: "en0") + truncated).keys) == ["en0"])
    }

    @Test func stopsAtAZeroLengthMessage() {
        let zeroLength = [UInt8](repeating: 0, count: MemoryLayout<if_msghdr>.size)
        #expect(Set(parse(zeroLength + RoutingMessages.interfaceInfo(name: "en0")).keys).isEmpty)
    }

    @Test func emptyListHasNoInterfaces() {
        #expect(parse([]).isEmpty)
    }

    private func parse(_ messages: [UInt8]) -> [String: InterfaceCounters] {
        messages.withUnsafeBytes { InterfaceMessageParser(bytes: $0).countersByInterface() }
    }
}

@Suite("InterfaceCountersReader")
struct InterfaceCountersReaderTests {
    /// Every Mac has a loopback interface, so this checks the real kernel call end to end.
    @Test func readsTheLoopbackInterface() {
        #expect(InterfaceCountersReader.read()["lo0"]?.isUp == true)
    }
}

/// Routing messages laid out the way the kernel returns them: an `if_msghdr2` followed by the
/// interface's link-level address (`sockaddr_dl`), which carries its name.
enum RoutingMessages {
    static func interfaceInfo(
        name: String, received: UInt64 = 0, sent: UInt64 = 0, flags: Int32 = IFF_UP | IFF_RUNNING
    ) -> [UInt8] {
        var info = if_msghdr2()
        info.ifm_msglen = UInt16(MemoryLayout<if_msghdr2>.size + MemoryLayout<sockaddr_dl>.size)
        info.ifm_type = UInt8(RTM_IFINFO2)
        info.ifm_flags = flags
        info.ifm_data.ifi_ibytes = received
        info.ifm_data.ifi_obytes = sent
        return bytes(of: info) + linkAddress(named: name)
    }

    static func otherMessage() -> [UInt8] {
        var header = if_msghdr()
        header.ifm_msglen = UInt16(MemoryLayout<if_msghdr>.size)
        header.ifm_type = UInt8(RTM_NEWADDR)
        return bytes(of: header)
    }

    private static func linkAddress(named name: String) -> [UInt8] {
        var address = sockaddr_dl()
        address.sdl_nlen = UInt8(name.utf8.count)
        var addressBytes = bytes(of: address)
        let nameStart = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data)!
        addressBytes.replaceSubrange(nameStart..<nameStart + name.utf8.count, with: name.utf8)
        return addressBytes
    }

    private static func bytes<T>(of value: T) -> [UInt8] {
        withUnsafeBytes(of: value) { Array($0) }
    }
}
