import AppKit

/// The mirrored bar graph: upload bars above the midline, download bars below, newest on the right.
@MainActor
package struct TrafficGraph {
    /// The graph never scales below this rate, so background chatter stays a sliver.
    package nonisolated static let minimumPeakRate: Double = 10_000

    let samples: [TrafficSample]
    let midline: Midline

    func draw() {
        drawMidline()
        for direction in TrafficDirection.allCases {
            drawBars(direction)
        }
    }

    private func drawMidline() {
        NSColor.tertiaryLabelColor.setFill()
        let width = StatusLayout.graphWidth - midline.pixelSize
        NSRect(x: StatusLayout.horizontalPadding, y: midline.bottom, width: width, height: midline.pixelSize).fill()
    }

    private func drawBars(_ direction: TrafficDirection) {
        let scale = barScale(direction)
        direction.color.setFill()
        for (index, sample) in samples.enumerated() {
            let height = scale.height(for: sample.rate(direction))
            barRect(slot: firstSlot + index, height: height, direction).fill()
        }
    }

    /// Each direction has its own scale: upload is often a tiny fraction of download and would
    /// otherwise vanish. The numbers next to the graph give the absolute values.
    func barScale(_ direction: TrafficDirection) -> BarScale {
        let peak = max(Self.minimumPeakRate, samples.map { $0.rate(direction) }.max() ?? 0)
        let availableHeight = StatusLayout.halfHeight - midline.pixelSize / 2
        return BarScale(peakRate: peak, availableHeight: availableHeight, pixelSize: midline.pixelSize)
    }

    /// Samples fill the graph from the right while there are fewer than it can show.
    private var firstSlot: Int {
        StatusLayout.visibleSampleCount - samples.count
    }

    func barRect(slot: Int, height: CGFloat, _ direction: TrafficDirection) -> NSRect {
        let x = StatusLayout.horizontalPadding + CGFloat(slot) * StatusLayout.slotWidth
        let y = direction == .upload ? midline.top : midline.bottom - height
        return NSRect(x: x, y: y, width: StatusLayout.slotWidth - midline.pixelSize, height: height)
    }
}

/// Turns rates into bar heights for one direction of the graph.
struct BarScale {
    let peakRate: Double
    let availableHeight: CGFloat
    let pixelSize: CGFloat

    /// Any traffic at all gets at least one pixel, so activity is always visible.
    func height(for rate: Double) -> CGFloat {
        guard rate > 0 else { return 0 }
        let pixels = (CGFloat(rate / peakRate) * availableHeight / pixelSize).rounded()
        return max(pixelSize, pixels * pixelSize)
    }
}

extension TrafficDirection {
    var color: NSColor {
        switch self {
        case .upload: .systemRed
        case .download: .systemBlue
        }
    }
}
