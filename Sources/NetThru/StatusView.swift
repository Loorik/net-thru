import AppKit

/// Contents of the menu bar item: a mirrored bar graph of the last few seconds (upload above
/// the midline, download below) followed by the current upload and download rates.
final class StatusView: NSView {
    static let sampleCount = 14
    static let upColor = NSColor.systemRed
    static let downColor = NSColor.systemBlue

    private static let barStride: CGFloat = 2
    private static let graphWidth = CGFloat(sampleCount) * barStride
    private static let inset: CGFloat = 3
    private static let graphGap: CGFloat = 5
    private static let arrowSize = NSSize(width: 5, height: 4)
    private static let arrowGap: CGFloat = 3
    /// Space between the upload line's baseline and the download line's cap height.
    private static let lineGap: CGFloat = 3
    private static let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium)
    /// The graph never scales below this rate, so background chatter stays a sliver.
    private static let minimumScale: Double = 10_000

    private static let textWidth = ByteFormat.widestRates
        .map { ($0 as NSString).size(withAttributes: [.font: font]).width }
        .max()!
        .rounded(.up)

    static let preferredWidth =
        inset + graphWidth + graphGap + arrowSize.width + arrowGap + textWidth + inset

    var history: [TrafficMonitor.Sample] = [] {
        didSet {
            if history != oldValue { needsDisplay = true }
        }
    }

    /// Clicks go to the status item's button underneath, which opens the menu.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidChangeEffectiveAppearance() {
        needsDisplay = true
    }

    override func viewDidChangeBackingProperties() {
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let scale = window?.backingScaleFactor ?? 2
        let pixel = 1 / scale
        // Centre the midline on a pixel row so the graph stays crisp.
        let mid = (bounds.midY * scale).rounded(.down) / scale + pixel / 2
        let capHeight = Self.font.capHeight
        let halfHeight = Self.lineGap / 2 + capHeight

        drawGraph(midY: mid, halfHeight: halfHeight, pixel: pixel)

        let current = history.last ?? TrafficMonitor.Sample(down: 0, up: 0)
        drawRate(current.up, baseline: mid + Self.lineGap / 2, pointingUp: true)
        drawRate(current.down, baseline: mid - Self.lineGap / 2 - capHeight, pointingUp: false)
    }

    private func drawGraph(midY: CGFloat, halfHeight: CGFloat, pixel: CGFloat) {
        let x0 = Self.inset
        NSColor.tertiaryLabelColor.setFill()
        NSRect(x: x0, y: midY - pixel / 2, width: Self.graphWidth - pixel, height: pixel).fill()

        // Each direction has its own scale: upload is often a tiny fraction of download and
        // would otherwise vanish. The numbers next to the graph give the absolute values.
        let upPeak = max(Self.minimumScale, history.map(\.up).max() ?? 0)
        let downPeak = max(Self.minimumScale, history.map(\.down).max() ?? 0)
        let available = halfHeight - pixel / 2
        func barHeight(_ rate: Double, peak: Double) -> CGFloat {
            guard rate > 0 else { return 0 }
            // Any traffic at all gets at least one pixel, so activity is always visible.
            return max(pixel, (CGFloat(rate / peak) * available / pixel).rounded() * pixel)
        }

        let barWidth = Self.barStride - pixel
        let firstSlot = Self.sampleCount - history.count
        for (index, sample) in history.enumerated() {
            let x = x0 + CGFloat(firstSlot + index) * Self.barStride
            let up = barHeight(sample.up, peak: upPeak)
            let down = barHeight(sample.down, peak: downPeak)
            Self.upColor.setFill()
            NSRect(x: x, y: midY + pixel / 2, width: barWidth, height: up).fill()
            Self.downColor.setFill()
            NSRect(x: x, y: midY - pixel / 2 - down, width: barWidth, height: down).fill()
        }
    }

    private func drawRate(_ rate: Double, baseline: CGFloat, pointingUp: Bool) {
        let font = Self.font
        let arrowX = Self.inset + Self.graphWidth + Self.graphGap
        let arrow = NSRect(
            x: arrowX,
            y: baseline + (font.capHeight - Self.arrowSize.height) / 2,
            width: Self.arrowSize.width,
            height: Self.arrowSize.height
        )
        let triangle = NSBezierPath()
        if pointingUp {
            triangle.move(to: NSPoint(x: arrow.minX, y: arrow.minY))
            triangle.line(to: NSPoint(x: arrow.maxX, y: arrow.minY))
            triangle.line(to: NSPoint(x: arrow.midX, y: arrow.maxY))
        } else {
            triangle.move(to: NSPoint(x: arrow.minX, y: arrow.maxY))
            triangle.line(to: NSPoint(x: arrow.maxX, y: arrow.maxY))
            triangle.line(to: NSPoint(x: arrow.midX, y: arrow.minY))
        }
        triangle.close()
        (pointingUp ? Self.upColor : Self.downColor).setFill()
        triangle.fill()

        let text = ByteFormat.rate(rate) as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        let width = text.size(withAttributes: attributes).width
        // `draw(at:)` takes the bottom of the line box, which sits one descender below the baseline.
        text.draw(at: NSPoint(x: bounds.maxX - Self.inset - width, y: baseline + font.descender), withAttributes: attributes)
    }
}
