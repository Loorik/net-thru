import AppKit

/// A disabled menu item with a label on the left and a right-aligned value.
@MainActor
final class InfoRow {
    /// Where the right-aligned values end, in points from the menu's left edge.
    private static let valueTabStop: CGFloat = 200
    /// `menuFont(ofSize:)` treats 0 as "the standard menu font size".
    private static let standardFontSize: CGFloat = 0
    private static let attributes: [NSAttributedString.Key: Any] = [
        .paragraphStyle: valueAlignedRight(),
        .font: NSFont.menuFont(ofSize: standardFontSize),
    ]

    let item = NSMenuItem()
    private let label: String

    var value = "" {
        didSet { item.attributedTitle = title() }
    }

    init(label: String) {
        self.label = label
        item.isEnabled = false
    }

    private func title() -> NSAttributedString {
        NSAttributedString(string: "\(label)\t\(value)", attributes: Self.attributes)
    }

    private static func valueAlignedRight() -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [NSTextTab(textAlignment: .right, location: valueTabStop)]
        return paragraph
    }
}
