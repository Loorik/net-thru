import AppKit

/// One line of text next to the graph: a coloured arrow and the rate, right-aligned.
@MainActor
struct RateLabel {
    private static let attributes: [NSAttributedString.Key: Any] = [
        .font: StatusLayout.font,
        .foregroundColor: NSColor.labelColor,
    ]

    let direction: TrafficDirection
    let rate: Double
    let midline: Midline

    func draw(rightEdge: CGFloat) {
        drawArrow()
        drawRate(rightEdge: rightEdge)
    }

    /// Upload is written above the midline, download below it.
    private var baseline: CGFloat {
        let halfSpacing = StatusLayout.lineSpacing / 2
        switch direction {
        case .upload: return midline.y + halfSpacing
        case .download: return midline.y - halfSpacing - StatusLayout.font.capHeight
        }
    }

    private func drawArrow() {
        direction.color.setFill()
        NSBezierPath.arrowhead(in: arrowRect, pointing: direction).fill()
    }

    /// Vertically centred on the digits.
    private var arrowRect: NSRect {
        let size = StatusLayout.arrowSize
        let y = baseline + (StatusLayout.font.capHeight - size.height) / 2
        return NSRect(origin: NSPoint(x: StatusLayout.arrowX, y: y), size: size)
    }

    private func drawRate(rightEdge: CGFloat) {
        let text = ByteFormat.rate(rate) as NSString
        let x = rightEdge - StatusLayout.horizontalPadding - text.size(withAttributes: Self.attributes).width
        // `draw(at:)` takes the bottom of the line box, which sits one descender below the baseline.
        text.draw(at: NSPoint(x: x, y: baseline + StatusLayout.font.descender), withAttributes: Self.attributes)
    }
}

extension NSBezierPath {
    /// A triangle filling `rect`, pointing up for upload and down for download.
    static func arrowhead(in rect: NSRect, pointing direction: TrafficDirection) -> NSBezierPath {
        let baseY = direction == .upload ? rect.minY : rect.maxY
        let tipY = direction == .upload ? rect.maxY : rect.minY
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX, y: baseY))
        path.line(to: NSPoint(x: rect.maxX, y: baseY))
        path.line(to: NSPoint(x: rect.midX, y: tipY))
        path.close()
        return path
    }
}
