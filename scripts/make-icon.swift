// Draws the app icon (a larger version of the menu bar graph) and writes an .icns file.
// Usage: swift scripts/make-icon.swift Resources/AppIcon.icns
import AppKit

/// Apple's icon grid: a rounded square centred on a 1024 pt canvas.
enum IconGrid {
    static let canvasSize = NSSize(width: 1024, height: 1024)
    static let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    static let cornerRadius: CGFloat = 185
}

/// The graph on the icon: upload bars above the midline, download bars below.
enum IconGraph {
    static let uploadHeights: [CGFloat] = [0.25, 0.4, 0.3, 0.55, 0.45, 0.7, 0.5, 0.85, 0.6, 0.75]
    static let downloadHeights: [CGFloat] = [0.45, 0.6, 0.5, 0.8, 0.7, 0.95, 0.65, 0.85, 0.75, 1.0]
    static let barWidth: CGFloat = 44
    static let barSpacing: CGFloat = 16
    static let barCornerRadius: CGFloat = 8
    static let maxBarHeight: CGFloat = 270
    /// Gap between the midline's centre and the start of each bar.
    static let barClearance: CGFloat = 10
    static let midlineThickness: CGFloat = 6

    static let width = CGFloat(uploadHeights.count) * (barWidth + barSpacing) - barSpacing
    static let originX = IconGrid.body.midX - width / 2
    static let midY = IconGrid.body.midY
}

enum IconColors {
    static let backgroundTop = NSColor(white: 0.20, alpha: 1)
    static let backgroundBottom = NSColor(white: 0.07, alpha: 1)
    static let midline = NSColor(white: 1, alpha: 0.35)
    static let upload = NSColor.systemRed
    static let download = NSColor.systemBlue
}

enum Iconset {
    /// Point sizes macOS asks for; each also comes at twice the pixels for Retina screens.
    static let pointSizes = [16, 32, 128, 256, 512]
    static let retinaFactor = 2
    static let bitsPerSample = 8
    static let samplesPerPixel = 4
    /// Lets AppKit work out the row and pixel sizes itself.
    static let automatic = 0
    /// `NSGradient` angle for a gradient running from the top down.
    static let topToBottom: CGFloat = -90
}

func renderIcon(pixels: Int) -> Data {
    let bitmap = makeBitmap(pixels: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

func makeBitmap(pixels: Int) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: Iconset.bitsPerSample,
        samplesPerPixel: Iconset.samplesPerPixel, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: Iconset.automatic, bitsPerPixel: Iconset.automatic
    )!
    bitmap.size = IconGrid.canvasSize
    return bitmap
}

func drawIcon() {
    drawBackground()
    drawMidline()
    drawBars()
}

func drawBackground() {
    let shape = NSBezierPath(roundedRect: IconGrid.body, xRadius: IconGrid.cornerRadius, yRadius: IconGrid.cornerRadius)
    let gradient = NSGradient(starting: IconColors.backgroundTop, ending: IconColors.backgroundBottom)!
    gradient.draw(in: shape, angle: Iconset.topToBottom)
}

func drawMidline() {
    IconColors.midline.setFill()
    let y = IconGraph.midY - IconGraph.midlineThickness / 2
    NSRect(x: IconGraph.originX, y: y, width: IconGraph.width, height: IconGraph.midlineThickness).fill()
}

func drawBars() {
    for (index, (upload, download)) in zip(IconGraph.uploadHeights, IconGraph.downloadHeights).enumerated() {
        let x = IconGraph.originX + CGFloat(index) * (IconGraph.barWidth + IconGraph.barSpacing)
        fillBar(uploadBarRect(x: x, height: upload * IconGraph.maxBarHeight), color: IconColors.upload)
        fillBar(downloadBarRect(x: x, height: download * IconGraph.maxBarHeight), color: IconColors.download)
    }
}

func uploadBarRect(x: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: IconGraph.midY + IconGraph.barClearance, width: IconGraph.barWidth, height: height)
}

func downloadBarRect(x: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: IconGraph.midY - IconGraph.barClearance - height, width: IconGraph.barWidth, height: height)
}

func fillBar(_ rect: NSRect, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: IconGraph.barCornerRadius, yRadius: IconGraph.barCornerRadius).fill()
}

func writeIconset(to directory: URL) throws {
    for size in Iconset.pointSizes {
        try renderIcon(pixels: size).write(to: directory.appendingPathComponent("icon_\(size)x\(size).png"))
        let retinaPixels = size * Iconset.retinaFactor
        try renderIcon(pixels: retinaPixels).write(to: directory.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
    }
}

/// Packs the iconset into an .icns file and returns iconutil's exit status.
func convertToIcns(iconset: URL, output: URL) throws -> Int32 {
    let iconutil = Process()
    iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
    try iconutil.run()
    iconutil.waitUntilExit()
    return iconutil.terminationStatus
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let workDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("net-thru-icon-\(getpid())")
let iconset = workDirectory.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try writeIconset(to: iconset)
let status = try convertToIcns(iconset: iconset, output: output)
try? FileManager.default.removeItem(at: workDirectory)
exit(status)
