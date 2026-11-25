import AppKit

/// Layout of the mock menu bar around net-thru's status item, in points: the status item, then
/// Wi-Fi and battery symbols, then a clock.
@MainActor
enum MockMenuBar {
    private static let margin: CGFloat = 10
    private static let height: CGFloat = 30
    private static let padding: CGFloat = 12
    private static let itemSpacing: CGFloat = 14
    private static let cornerRadius: CGFloat = 8
    private static let borderWidth: CGFloat = 0.5
    private static let symbolPointSize: CGFloat = 14
    private static let symbolNames = ["wifi", "battery.75percent"]
    private static let clockFontSize: CGFloat = 13

    static let clockText = "Tue 9:41" as NSString
    static let clockFont = NSFont.systemFont(ofSize: clockFontSize, weight: .medium)
    static let symbols = symbolNames.map(symbol(named:))
    static let statusItemSize = NSSize(width: StatusLayout.width, height: height)
    static let barRect = NSRect(x: margin, y: margin, width: barWidth(), height: height)
    static let canvasSize = NSSize(width: barRect.width + 2 * margin, height: height + 2 * margin)
    static let statusItemOrigin = NSPoint(x: barRect.minX + padding, y: barRect.minY)
    static let symbolXs = symbolPositions()
    static let clockOrigin = NSPoint(x: clockX(), y: clockBaselineOrigin())

    static func barShape() -> NSBezierPath {
        // Inset by half the border, so the stroke stays inside the bar.
        let rect = barRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        let shape = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        shape.lineWidth = borderWidth
        return shape
    }

    private static func symbol(named name: String) -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)!.withSymbolConfiguration(configuration)!
    }

    private static func barWidth() -> CGFloat {
        padding + StatusLayout.width + itemSpacing
            + symbols.map(\.size.width).reduce(0, +) + CGFloat(symbols.count) * itemSpacing + clockWidth() + padding
    }

    private static func clockWidth() -> CGFloat {
        clockText.size(withAttributes: [.font: clockFont]).width.rounded(.up)
    }

    /// Each symbol follows the previous item plus the item spacing.
    private static func symbolPositions() -> [CGFloat] {
        var x = statusItemOrigin.x + (StatusLayout.width + itemSpacing)
        var positions: [CGFloat] = []
        for symbol in symbols {
            positions.append(x)
            x += symbol.size.width + itemSpacing
        }
        return positions
    }

    private static func clockX() -> CGFloat {
        symbolXs.last! + (symbols.last!.size.width + itemSpacing)
    }

    /// Vertically centres the clock's glyphs; `draw(at:)` takes the bottom of the line box.
    private static func clockBaselineOrigin() -> CGFloat {
        barRect.midY - (clockFont.ascender + clockFont.descender) / 2 + clockFont.descender
    }
}
