import AppKit

/// The horizontal line the bars grow from, centred on a pixel row so the graph stays crisp.
struct Midline {
    let y: CGFloat
    let pixelSize: CGFloat

    init(centeredIn bounds: NSRect, backingScale: CGFloat) {
        pixelSize = 1 / backingScale
        y = (bounds.midY * backingScale).rounded(.down) / backingScale + pixelSize / 2
    }

    /// Where upload bars start.
    var top: CGFloat {
        y + pixelSize / 2
    }

    /// Where download bars start.
    var bottom: CGFloat {
        y - pixelSize / 2
    }
}
