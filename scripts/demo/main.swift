// Renders the README animation: the real StatusView, fed a scripted traffic sequence, inside a
// mock menu bar. Writes demo-light.gif and demo-dark.gif into the given directory.
// Usage (see `make demo`): make-demo <output directory>
import AppKit
import ImageIO
import UniformTypeIdentifiers

typealias Sample = TrafficMonitor.Sample

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
let scale: CGFloat = 4
let frameDelay = 0.5 // seconds; the app itself updates once a second, so this is 2× speed

// MARK: - Traffic script

/// Small deterministic noise for idle background traffic.
var seed: UInt64 = 42
func noise(_ range: ClosedRange<Double>) -> Double {
    seed = seed &* 6364136223846793005 &+ 1442695040888963407
    return range.lowerBound + Double(seed >> 33) / Double(1 << 31) * (range.upperBound - range.lowerBound)
}

func idle(_ count: Int) -> [Sample] {
    (0..<count).map { _ in
        Sample(down: noise(0...1) < 0.3 ? 0 : noise(300...2_500), up: noise(0...1) < 0.4 ? 0 : noise(200...1_800))
    }
}

let MB = 1_000_000.0
let KB = 1_000.0
let download = zip(
    [0.8, 6.5, 24, 41, 47, 44, 49, 46, 48, 38, 12, 1.6].map { $0 * MB },
    [40, 200, 600, 1_000, 1_200, 1_100, 1_300, 1_200, 1_250, 900, 300, 50].map { $0 * KB }
).map { Sample(down: $0, up: $1) }
let settle = [Sample(down: 180 * KB, up: 12 * KB), Sample(down: 20 * KB, up: 4 * KB)]
let upload = zip(
    [60, 180, 210, 190, 220, 200, 205, 90, 20].map { $0 * KB },
    [1.8, 5.2, 6.1, 5.8, 6.3, 6.0, 5.9, 2.4, 0.3].map { $0 * MB }
).map { Sample(down: $0, up: $1) }
let script = idle(4) + download + settle + upload + idle(5)

// MARK: - Drawing

struct Theme {
    let appearance: NSAppearance.Name
    let page: NSColor   // GitHub's page background, so the rounded corners blend in
    let bar: NSColor
    let border: NSColor
    let file: String
}

let themes = [
    Theme(appearance: .aqua, page: .white, bar: NSColor(white: 0.955, alpha: 1),
          border: NSColor(white: 0, alpha: 0.09), file: "demo-light.gif"),
    Theme(appearance: .darkAqua, page: NSColor(srgbRed: 0x0d / 255, green: 0x11 / 255, blue: 0x17 / 255, alpha: 1),
          bar: NSColor(white: 0.14, alpha: 1), border: NSColor(white: 1, alpha: 0.1), file: "demo-dark.gif"),
]

let margin: CGFloat = 10
let barHeight: CGFloat = 30
let inset: CGFloat = 12
let itemGap: CGFloat = 14
let clock = "Tue 9:41" as NSString
let clockAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .medium)]
let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
let symbols = ["wifi", "battery.75percent"].map {
    NSImage(systemSymbolName: $0, accessibilityDescription: nil)!.withSymbolConfiguration(symbolConfiguration)!
}

let clockWidth = clock.size(withAttributes: clockAttributes).width.rounded(.up)
let barWidth = inset + StatusView.preferredWidth + itemGap
    + symbols.map(\.size.width).reduce(0, +) + CGFloat(symbols.count) * itemGap + clockWidth + inset
let canvas = NSSize(width: barWidth + 2 * margin, height: barHeight + 2 * margin)

func drawSymbol(_ image: NSImage, at x: CGFloat, midY: CGFloat) {
    // Tint the template symbol with the label colour of the current appearance.
    let tinted = NSImage(size: image.size, flipped: false) { rect in
        image.draw(in: rect)
        NSColor.labelColor.set()
        rect.fill(using: .sourceAtop)
        return true
    }
    tinted.draw(at: NSPoint(x: x, y: (midY - image.size.height / 2).rounded()), from: .zero, operation: .sourceOver, fraction: 1)
}

/// A transparent bitmap of `size` points at the output scale.
func makeBitmap(_ size: NSSize) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = size
    return rep
}

func renderFrame(history: [Sample], theme: Theme) -> CGImage {
    // The status item itself, drawn by the app's own view.
    let view = StatusView(frame: NSRect(x: 0, y: 0, width: StatusView.preferredWidth, height: barHeight))
    view.appearance = NSAppearance(named: theme.appearance)
    view.history = history
    let itemBitmap = makeBitmap(view.bounds.size)
    view.cacheDisplay(in: view.bounds, to: itemBitmap)
    let itemImage = NSImage(size: view.bounds.size)
    itemImage.addRepresentation(itemBitmap)

    let rep = makeBitmap(canvas)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSAppearance(named: theme.appearance)!.performAsCurrentDrawingAppearance {
        theme.page.setFill()
        NSRect(origin: .zero, size: canvas).fill()

        let bar = NSRect(x: margin, y: margin, width: barWidth, height: barHeight)
        let shape = NSBezierPath(roundedRect: bar.insetBy(dx: 0.25, dy: 0.25), xRadius: 8, yRadius: 8)
        theme.bar.setFill()
        shape.fill()
        theme.border.setStroke()
        shape.lineWidth = 0.5
        shape.stroke()

        var x = bar.minX + inset
        itemImage.draw(at: NSPoint(x: x, y: bar.minY), from: .zero, operation: .sourceOver, fraction: 1)
        x += StatusView.preferredWidth + itemGap
        for symbol in symbols {
            drawSymbol(symbol, at: x, midY: bar.midY)
            x += symbol.size.width + itemGap
        }
        var attributes = clockAttributes
        attributes[.foregroundColor] = NSColor.labelColor
        let font = clockAttributes[.font] as! NSFont
        clock.draw(at: NSPoint(x: x, y: bar.midY - (font.ascender + font.descender) / 2 + font.descender), withAttributes: attributes)
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.cgImage!
}

// MARK: - GIF

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
MainActor.assumeIsolated {
    for theme in themes {
        let url = outputDirectory.appendingPathComponent(theme.file)
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, script.count, nil)!
        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
        ] as CFDictionary)
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay,
                kCGImagePropertyGIFUnclampedDelayTime: frameDelay,
            ],
        ] as CFDictionary
        for index in script.indices {
            // The graph wraps around the end of the script, so the loop is seamless.
            let history = (0..<StatusView.sampleCount).map { offset in
                script[(index - StatusView.sampleCount + 1 + offset + script.count) % script.count]
            }
            CGImageDestinationAddImage(destination, renderFrame(history: history, theme: theme), frameProperties)
        }
        guard CGImageDestinationFinalize(destination) else { fatalError("Couldn't write \(url.path)") }
        print("wrote \(url.path)")
    }
}
