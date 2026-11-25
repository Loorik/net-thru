import NetThruKit
import Testing
@testable import MakeDemo

@Suite("TrafficScript")
struct TrafficScriptTests {
    private let samples = (1...4).map { TrafficSample(download: Double($0) * 1_000, upload: 0) }

    @Test func playsTrafficInOrder() {
        #expect(TrafficScript([.traffic(samples)]).samples == samples)
    }

    @Test func quietSamplesHaveNoTraffic() {
        #expect(TrafficScript([.quiet(count: 2)]).samples == [.idle, .idle])
    }

    @Test func windowWrapsAroundTheEnd() {
        let script = TrafficScript([.traffic(samples)])
        #expect(script.window(endingAt: 1, length: 3) == [samples[3], samples[0], samples[1]])
    }

    @Test func figuresAreFramedByQuietSamples() {
        let figure = Array(samples.prefix(2))
        #expect(TrafficScript([.figure(figure)]).samples == [.idle] + figure + [.idle, .idle])
    }

    @Test func holdFrameShowsTheWholeFigure() {
        let figure = Figures.heart
        let script = TrafficScript([.idle(count: 5), .figure(figure)])
        let hold = try! #require(script.holdFrames.first)
        #expect(script.window(endingAt: hold, length: figure.count + 3) == [.idle] + figure + [.idle, .idle])
    }

    @Test func idleTrafficIsTheSameEveryTime() {
        #expect(TrafficScript([.idle(count: 20)]).samples == TrafficScript([.idle(count: 20)]).samples)
    }

    @Test func idleTrafficIsAFewKilobytesAtMost() {
        let idle = TrafficScript([.idle(count: 100)]).samples
        #expect(idle.allSatisfy { $0.download <= 2_500 && $0.upload <= 1_800 })
        #expect(idle.contains { $0.download == 0 } && idle.contains { $0.download > 0 })
    }
}

@Suite("RepeatableRandom")
struct RepeatableRandomTests {
    @Test func producesTheSameSequenceEveryTime() {
        var first = RepeatableRandom(), second = RepeatableRandom()
        let firstValues = (0..<10).map { _ in first.value(in: 0...1) }
        #expect(firstValues == (0..<10).map { _ in second.value(in: 0...1) })
    }

    @Test func valuesStayInTheRequestedRange() {
        var random = RepeatableRandom()
        #expect((0..<1_000).allSatisfy { _ in (300...2_500).contains(random.value(in: 300...2_500)) })
    }
}

@MainActor
@Suite("README animation")
struct ReadmeAnimationTests {
    @Test(arguments: [Figures.heart, Figures.star, Figures.cat, Figures.tree])
    func figuresAreSymmetric(figure: [TrafficSample]) {
        #expect(figure == figure.reversed())
    }

    @Test(arguments: [Figures.heart, Figures.star, Figures.cat, Figures.tree])
    func figuresFitInViewWithTheirQuietFrame(figure: [TrafficSample]) {
        #expect(figure.count + 3 <= StatusLayout.visibleSampleCount)
    }

    /// The graph scales to the biggest rate in view; anything above the minimum scale would
    /// squash the figure.
    @Test func everyFigureIsShownAtFullSize() {
        let script = ReadmeTraffic.script
        #expect(script.holdFrames.count == 4)
        for frame in script.holdFrames {
            let window = script.window(endingAt: frame, length: StatusLayout.visibleSampleCount)
            #expect(window.allSatisfy { max($0.download, $0.upload) <= TrafficGraph.minimumPeakRate })
        }
    }

    @Test func pausesOnlyOnFigures() {
        let animation = DemoAnimation(script: ReadmeTraffic.script, theme: .light)
        let paused = ReadmeTraffic.script.samples.indices.filter { animation.delay(ofFrame: $0) == DemoAnimation.holdDelay }
        #expect(Set(paused) == ReadmeTraffic.script.holdFrames)
    }
}
