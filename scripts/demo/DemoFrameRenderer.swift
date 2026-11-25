import AppKit

/// Colours of the mock menu bar, matching GitHub's light and dark page backgrounds so the
/// rounded corners blend in.
struct Theme {
    static let light = Theme(
        appearance: .aqua, page: .white, bar: NSColor(white: 0.955, alpha: 1),
        border: NSColor(white: 0, alpha: 0.09), fileName: "demo-light.gif"
    )
    static let dark = Theme(
        appearance: .darkAqua, page: NSColor(srgbRed: 0x0d / 255, green: 0x11 / 255, blue: 0x17 / 255, alpha: 1), // #0d1117
        bar: NSColor(white: 0.14, alpha: 1), border: NSColor(white: 1, alpha: 0.1), fileName: "demo-dark.gif"
    )

    let appearance: NSAppearance.Name
    let page: NSColor
    let bar: NSColor
    let border: NSColor
    let fileName: String
}

/// One frame of the README animation: net-thru's real status view in a mock menu bar next to
/// Wi-Fi, battery and a clock.
@MainActor
struct DemoFrameRenderer {
    private static let fullyOpaque: CGFloat = 1

    let theme: Theme

    func render(_ samples: [TrafficSample]) -> CGImage {
        let statusItem = statusItemImage(samples)
        let canvas = Bitmap(size: MockMenuBar.canvasSize)
        canvas.draw(appearance: theme.appearance) { drawMenuBar(with: statusItem) }
        return canvas.cgImage
    }

    /// Drawn by the app's own view, exactly as in the menu bar.
    private func statusItemImage(_ samples: [TrafficSample]) -> NSImage {
        let view = StatusView(frame: NSRect(origin: .zero, size: MockMenuBar.statusItemSize))
        view.appearance = NSAppearance(named: theme.appearance)
        view.samples = samples
        let bitmap = Bitmap(size: view.bounds.size)
        view.cacheDisplay(in: view.bounds, to: bitmap.representation)
        return bitmap.image
    }

    private func drawMenuBar(with statusItem: NSImage) {
        drawPageBackground()
        drawBarShape()
        statusItem.draw(at: MockMenuBar.statusItemOrigin, from: .zero, operation: .sourceOver, fraction: Self.fullyOpaque)
        drawSymbols()
        drawClock()
    }

    private func drawPageBackground() {
        theme.page.setFill()
        NSRect(origin: .zero, size: MockMenuBar.canvasSize).fill()
    }

    private func drawBarShape() {
        let shape = MockMenuBar.barShape()
        theme.bar.setFill()
        shape.fill()
        theme.border.setStroke()
        shape.stroke()
    }

    private func drawSymbols() {
        for (symbol, x) in zip(MockMenuBar.symbols, MockMenuBar.symbolXs) {
            let y = (MockMenuBar.barRect.midY - symbol.size.height / 2).rounded()
            tinted(symbol).draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: Self.fullyOpaque)
        }
    }

    /// The template symbol in the label colour of the current appearance.
    private func tinted(_ symbol: NSImage) -> NSImage {
        NSImage(size: symbol.size, flipped: false) { rect in
            symbol.draw(in: rect)
            NSColor.labelColor.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }

    private func drawClock() {
        let attributes: [NSAttributedString.Key: Any] = [.font: MockMenuBar.clockFont, .foregroundColor: NSColor.labelColor]
        MockMenuBar.clockText.draw(at: MockMenuBar.clockOrigin, withAttributes: attributes)
    }
}

/// A transparent bitmap measured in points and drawn at the demo's output scale.
@MainActor
struct Bitmap {
    private static let scale: CGFloat = 4
    private static let bitsPerSample = 8
    private static let samplesPerPixel = 4
    /// Lets AppKit work out the row and pixel sizes itself.
    private static let automatic = 0

    let representation: NSBitmapImageRep

    init(size: NSSize) {
        representation = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width * Self.scale), pixelsHigh: Int(size.height * Self.scale),
            bitsPerSample: Self.bitsPerSample, samplesPerPixel: Self.samplesPerPixel, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: Self.automatic, bitsPerPixel: Self.automatic
        )!
        representation.size = size
    }

    var image: NSImage {
        let image = NSImage(size: representation.size)
        image.addRepresentation(representation)
        return image
    }

    var cgImage: CGImage {
        representation.cgImage!
    }

    func draw(appearance: NSAppearance.Name, _ drawing: () -> Void) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        NSAppearance(named: appearance)!.performAsCurrentDrawingAppearance(drawing)
        NSGraphicsContext.restoreGraphicsState()
    }
}
