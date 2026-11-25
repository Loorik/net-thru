import NetThruKit

/// The traffic the README animation plays: idle chatter, a big download, an upload and, in
/// between, a few figures drawn by the graph's outline.
struct TrafficScript {
    enum Segment {
        case idle(count: Int)
        case quiet(count: Int)
        case traffic([TrafficSample])
        /// Framed by quiet samples so it's the biggest thing in view and keeps its proportions.
        case figure([TrafficSample])
    }

    private static let quietBeforeFigure = 1
    private static let quietAfterFigure = 2

    private(set) var samples: [TrafficSample] = []
    /// Frames where a figure is fully in view; the animation pauses on them.
    private(set) var holdFrames: Set<Int> = []
    private var idleTraffic = IdleTraffic()

    init(_ segments: [Segment]) {
        for segment in segments {
            append(segment)
        }
    }

    /// The samples shown in the frame whose newest sample is `index`. The graph wraps around
    /// the end of the script, so the animation loops seamlessly.
    func window(endingAt index: Int, length: Int) -> [TrafficSample] {
        (index - length + 1...index).map { samples[($0 + samples.count) % samples.count] }
    }

    private mutating func append(_ segment: Segment) {
        switch segment {
        case .idle(let count): samples += (0..<count).map { _ in idleTraffic.nextSample() }
        case .quiet(let count): samples += Array(repeating: .idle, count: count)
        case .traffic(let traffic): samples += traffic
        case .figure(let figure): appendFigure(figure)
        }
    }

    private mutating func appendFigure(_ figure: [TrafficSample]) {
        append(.quiet(count: Self.quietBeforeFigure))
        samples += figure
        append(.quiet(count: Self.quietAfterFigure))
        holdFrames.insert(samples.count - 1)
    }
}

/// Random-looking but repeatable background traffic of a few hundred bytes to a few KB.
struct IdleTraffic {
    private static let downloadSilenceChance = 0.3
    private static let downloadRange = 300.0...2_500
    private static let uploadSilenceChance = 0.4
    private static let uploadRange = 200.0...1_800

    private var random = RepeatableRandom()

    mutating func nextSample() -> TrafficSample {
        let download = rate(silenceChance: Self.downloadSilenceChance, range: Self.downloadRange)
        let upload = rate(silenceChance: Self.uploadSilenceChance, range: Self.uploadRange)
        return TrafficSample(download: download, upload: upload)
    }

    private mutating func rate(silenceChance: Double, range: ClosedRange<Double>) -> Double {
        random.chance(silenceChance) ? 0 : random.value(in: range)
    }
}

/// A 64-bit linear congruential generator, so the animation is the same on every run.
struct RepeatableRandom {
    private static let multiplier: UInt64 = 6364136223846793005
    private static let increment: UInt64 = 1442695040888963407
    private static let seed: UInt64 = 42
    /// The generator's top bits are the most random; this many of them make up a value.
    private static let valueBits: UInt64 = 31

    private var state = seed

    mutating func value(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextFraction() * (range.upperBound - range.lowerBound)
    }

    mutating func chance(_ probability: Double) -> Bool {
        nextFraction() < probability
    }

    private mutating func nextFraction() -> Double {
        state = state &* Self.multiplier &+ Self.increment
        let topBits = state >> (UInt64(UInt64.bitWidth) - Self.valueBits)
        return Double(topBits) / Double(UInt64(1) << Self.valueBits)
    }
}
