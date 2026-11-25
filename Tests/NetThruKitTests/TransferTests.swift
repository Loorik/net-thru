import Testing
@testable import NetThruKit
import NetThruTestSupport

@Suite("CounterDelta")
struct CounterDeltaTests {
    private let wrapAround: UInt64 = 1 << 32

    @Test func increaseIsTheDifference() {
        #expect(CounterDelta.bytes(from: 100, to: 250) == 150)
    }

    @Test func unchangedCounterMeansNoTraffic() {
        #expect(CounterDelta.bytes(from: 500, to: 500) == 0)
    }

    @Test func countsBytesAcrossA32BitWrap() {
        #expect(CounterDelta.bytes(from: wrapAround - 1_000, to: 3_000) == 4_000)
    }

    @Test func wrapToExactlyZero() {
        #expect(CounterDelta.bytes(from: wrapAround - 1, to: 0) == 1)
    }

    @Test func aWrapOfJustUnder2GBIsCounted() {
        #expect(CounterDelta.bytes(from: wrapAround - 1_500_000_000, to: 0) == 1_500_000_000)
    }

    @Test func anApparentWrapOfExactly2GBIsAReset() {
        #expect(CounterDelta.bytes(from: wrapAround - (1 << 31), to: 0) == 0)
    }

    @Test("An apparent wrap of 2 GB or more is a reset", arguments: [
        (UInt64(1_000_000_000), UInt64(1_000)),
        (UInt64(1_000_000), UInt64(200)),
    ])
    func largeApparentWrapIsAReset(old: UInt64, new: UInt64) {
        #expect(CounterDelta.bytes(from: old, to: new) == 0)
    }

    @Test func sixtyFourBitCounterGoingDownIsAReset() {
        #expect(CounterDelta.bytes(from: wrapAround + 5_000, to: 1_000) == 0)
    }
}

@Suite("Transfer")
struct TransferTests {
    private let before: [String: InterfaceCounters] = [
        "en0": .counters(received: 1_000, sent: 100), "en1": .counters(received: 0, sent: 0),
    ]
    private let after: [String: InterfaceCounters] = [
        "en0": .counters(received: 3_000, sent: 400), "en1": .counters(received: 500, sent: 50),
    ]

    @Test func sumsAllInterfaces() {
        let transfer = Transfer(from: before, to: after)
        #expect(transfer.downloaded == 2_500)
        #expect(transfer.uploaded == 350)
    }

    @Test func ignoresInterfacesThatJustAppeared() {
        let new = ["en0": InterfaceCounters.counters(received: 9_000, sent: 9_000)]
        let transfer = Transfer(from: [:], to: new)
        #expect(transfer.downloaded == 0)
        #expect(transfer.uploaded == 0)
    }

    @Test func rateIsBytesPerSecond() {
        let old = ["en0": InterfaceCounters.counters(received: 0, sent: 0)]
        let new = ["en0": InterfaceCounters.counters(received: 3_000, sent: 1_000)]
        #expect(Transfer(from: old, to: new).rate(over: 2) == TrafficSample(download: 1_500, upload: 500))
    }
}
