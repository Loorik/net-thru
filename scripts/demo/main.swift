// Renders the README animation: the app's real StatusView, fed a scripted traffic sequence,
// inside a mock menu bar. Writes demo-light.gif and demo-dark.gif into the given directory.
// Usage (see `make demo`): make-demo <output directory>
import Foundation

/// The README animation for one theme.
@MainActor
struct DemoAnimation {
    /// The app updates once a second, so this plays at 2.5× speed.
    private static let frameDelay = 0.4
    /// How long the animation pauses on a figure.
    private static let holdDelay = 1.6

    let script: TrafficScript
    let theme: Theme

    func write(to directory: URL) throws {
        let url = directory.appendingPathComponent(theme.fileName)
        let gif = try GifWriter(url: url, frameCount: script.samples.count)
        let renderer = DemoFrameRenderer(theme: theme)
        for frame in script.samples.indices {
            gif.add(renderer.render(samples(inFrame: frame)), delay: delay(ofFrame: frame))
        }
        try gif.finish()
        print("wrote \(url.path)")
    }

    private func samples(inFrame frame: Int) -> [TrafficSample] {
        script.window(endingAt: frame, length: StatusLayout.visibleSampleCount)
    }

    private func delay(ofFrame frame: Int) -> Double {
        script.holdFrames.contains(frame) ? Self.holdDelay : Self.frameDelay
    }
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
try MainActor.assumeIsolated {
    for theme in [Theme.light, Theme.dark] {
        try DemoAnimation(script: ReadmeTraffic.script, theme: theme).write(to: outputDirectory)
    }
}
