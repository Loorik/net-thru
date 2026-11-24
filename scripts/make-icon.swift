// Draws the app icon (a larger version of the menu bar graph) and writes an .icns file.
// Usage: swift scripts/make-icon.swift Resources/AppIcon.icns
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let workDir = FileManager.default.temporaryDirectory.appendingPathComponent("net-thru-icon-\(getpid())")
let iconset = workDir.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: 1024, height: 1024)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // macOS icon grid: an 824 pt rounded square centred on a 1024 pt canvas.
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
    NSGradient(starting: NSColor(white: 0.20, alpha: 1), ending: NSColor(white: 0.07, alpha: 1))!
        .draw(in: shape, angle: -90)

    let up: [CGFloat] = [0.25, 0.4, 0.3, 0.55, 0.45, 0.7, 0.5, 0.85, 0.6, 0.75]
    let down: [CGFloat] = [0.45, 0.6, 0.5, 0.8, 0.7, 0.95, 0.65, 0.85, 0.75, 1.0]
    let mid = body.midY
    let barWidth: CGFloat = 44, gap: CGFloat = 16, maxHeight: CGFloat = 270
    let x0 = body.midX - (CGFloat(up.count) * (barWidth + gap) - gap) / 2
    NSColor(white: 1, alpha: 0.35).setFill()
    NSRect(x: x0, y: mid - 3, width: CGFloat(up.count) * (barWidth + gap) - gap, height: 6).fill()
    for i in up.indices {
        let x = x0 + CGFloat(i) * (barWidth + gap)
        NSColor.systemRed.setFill()
        NSBezierPath(roundedRect: NSRect(x: x, y: mid + 10, width: barWidth, height: up[i] * maxHeight), xRadius: 8, yRadius: 8).fill()
        NSColor.systemBlue.setFill()
        let height = down[i] * maxHeight
        NSBezierPath(roundedRect: NSRect(x: x, y: mid - 10 - height, width: barWidth, height: height), xRadius: 8, yRadius: 8).fill()
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    try render(pixels: size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(pixels: size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()
try? FileManager.default.removeItem(at: workDir)
exit(iconutil.terminationStatus)
