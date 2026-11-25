import AppKit

/// Sizes and spacing of the menu bar item, in points.
@MainActor
enum StatusLayout {
    static let visibleSampleCount = 14
    /// Horizontal space per sample: the bar plus a one-pixel gap.
    static let slotWidth: CGFloat = 2
    static let graphWidth = CGFloat(visibleSampleCount) * slotWidth
    static let horizontalPadding: CGFloat = 3
    static let graphToArrowSpacing: CGFloat = 5
    static let arrowSize = NSSize(width: 5, height: 4)
    static let arrowToTextSpacing: CGFloat = 3
    /// Space between the upload line's baseline and the download line's cap height.
    static let lineSpacing: CGFloat = 3
    static let fontSize: CGFloat = 9
    static let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
    /// Assumed until the view is in a window (Retina).
    static let defaultBackingScale: CGFloat = 2

    static let arrowX = horizontalPadding + graphWidth + graphToArrowSpacing
    static let textWidth = widestRateWidth()
    static let width = arrowX + arrowSize.width + arrowToTextSpacing + textWidth + horizontalPadding

    /// How far the graph and the text reach above and below the midline.
    static var halfHeight: CGFloat {
        lineSpacing / 2 + font.capHeight
    }

    private static func widestRateWidth() -> CGFloat {
        let widths = ByteFormat.widestRates.map { ($0 as NSString).size(withAttributes: [.font: font]).width }
        return widths.max()!.rounded(.up)
    }
}
