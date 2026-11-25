import AppKit
import Testing
@testable import NetThruKit

@Suite("BarScale")
struct BarScaleTests {
    private let scale = BarScale(peakRate: 10_000, availableHeight: 7, pixelSize: 0.5)

    @Test func noTrafficHasNoBar() {
        #expect(scale.height(for: 0) == 0)
    }

    @Test func peakRateFillsTheAvailableHeight() {
        #expect(scale.height(for: 10_000) == 7)
    }

    @Test func anyTrafficGetsAtLeastOnePixel() {
        #expect(scale.height(for: 1) == 0.5)
    }

    @Test("Heights snap to whole pixels", arguments: [(5_000.0, 3.5), (3_000, 2.0), (3_300, 2.5)])
    func heightsSnapToWholePixels(rate: Double, expectedHeight: Double) {
        #expect(scale.height(for: rate) == CGFloat(expectedHeight))
    }
}

@MainActor
@Suite("TrafficGraph")
struct TrafficGraphTests {
    private let midline = Midline(centeredIn: NSRect(x: 0, y: 0, width: 90, height: 22), backingScale: 2)

    @Test func eachDirectionHasItsOwnScale() {
        let graph = TrafficGraph(samples: [TrafficSample(download: 4_000_000, upload: 80_000)], midline: midline)
        #expect(graph.barScale(.download).peakRate == 4_000_000)
        #expect(graph.barScale(.upload).peakRate == 80_000)
    }

    @Test func neverScalesBelowTheMinimumPeakRate() {
        let graph = TrafficGraph(samples: [TrafficSample(download: 300, upload: 0)], midline: midline)
        #expect(graph.barScale(.download).peakRate == TrafficGraph.minimumPeakRate)
    }

    @Test func uploadBarsGrowUpFromTheMidline() {
        let bar = TrafficGraph(samples: [], midline: midline).barRect(slot: 0, height: 3, .upload)
        #expect(bar.minY == midline.top)
        #expect(bar.height == 3)
    }

    @Test func downloadBarsGrowDownFromTheMidline() {
        let bar = TrafficGraph(samples: [], midline: midline).barRect(slot: 0, height: 3, .download)
        #expect(bar.maxY == midline.bottom)
    }

    @Test func barsLeaveAOnePixelGapBetweenSlots() {
        let graph = TrafficGraph(samples: [], midline: midline)
        let first = graph.barRect(slot: 0, height: 1, .upload), second = graph.barRect(slot: 1, height: 1, .upload)
        #expect(second.minX - first.maxX == midline.pixelSize)
    }
}

@Suite("Midline")
struct MidlineTests {
    @Test("Bars start on pixel boundaries", arguments: [(22.0, 1.0), (22, 2), (24, 2), (37, 2), (22, 3)])
    func barsStartOnPixelBoundaries(height: Double, backingScale: Double) {
        let bounds = NSRect(x: 0, y: 0, width: 90, height: height)
        let midline = Midline(centeredIn: bounds, backingScale: backingScale)
        #expect(isWholePixel(midline.top * backingScale))
        #expect(isWholePixel(midline.bottom * backingScale))
        #expect(isWholePixel((midline.top - midline.bottom) * backingScale - 1))
    }

    /// Allows for floating-point error, e.g. a third of a point at 3× scale.
    private func isWholePixel(_ value: CGFloat) -> Bool {
        abs(value - value.rounded()) < 1e-9
    }
}
