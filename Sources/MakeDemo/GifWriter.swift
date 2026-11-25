import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Writes frames into an endlessly looping GIF.
final class GifWriter {
    enum WriteError: Error {
        case cannotCreate(URL)
        case cannotFinish(URL)
    }

    private static let loopForever = 0

    private let url: URL
    private let destination: CGImageDestination

    init(url: URL, frameCount: Int) throws {
        let type = UTType.gif.identifier as CFString
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type, frameCount, nil) else {
            throw WriteError.cannotCreate(url)
        }
        self.url = url
        self.destination = destination
        CGImageDestinationSetProperties(destination, Self.gifProperties([kCGImagePropertyGIFLoopCount: Self.loopForever]))
    }

    func add(_ frame: CGImage, delay: Double) {
        let timing = [kCGImagePropertyGIFDelayTime: delay, kCGImagePropertyGIFUnclampedDelayTime: delay]
        CGImageDestinationAddImage(destination, frame, Self.gifProperties(timing))
    }

    func finish() throws {
        guard CGImageDestinationFinalize(destination) else { throw WriteError.cannotFinish(url) }
    }

    private static func gifProperties(_ properties: [CFString: Any]) -> CFDictionary {
        [kCGImagePropertyGIFDictionary: properties] as CFDictionary
    }
}
