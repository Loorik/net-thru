import Foundation
import NetThruKit

/// The README animation for one theme.
@MainActor
struct DemoAnimation {
    /// The app updates once a second, so this plays at 2.5× speed.
    static let frameDelay = 0.4
    /// How long the animation pauses on a figure.
    static let holdDelay = 1.6

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

    func samples(inFrame frame: Int) -> [TrafficSample] {
        script.window(endingAt: frame, length: StatusLayout.visibleSampleCount)
    }

    func delay(ofFrame frame: Int) -> Double {
        script.holdFrames.contains(frame) ? Self.holdDelay : Self.frameDelay
    }
}
