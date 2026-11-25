/// The scripted traffic and figures of the README animation.
enum ReadmeTraffic {
    static let script = TrafficScript([
        .idle(count: 3),
        .figure(Figures.heart),
        .idle(count: 1),
        .traffic(Bursts.download + Bursts.settle),
        .figure(Figures.star),
        .traffic(Bursts.upload),
        .idle(count: 2),
        .figure(Figures.cat),
        .quiet(count: 1),
        .figure(Figures.tree),
        .idle(count: 2),
    ])
}

/// Real traffic: a large download, the trickle after it, and a large upload.
enum Bursts {
    private static let megabyte = 1_000_000.0
    private static let kilobyte = 1_000.0

    static let download = samples(
        download: megabytes([0.8, 6.5, 24, 41, 47, 44, 49, 46, 48, 38, 12, 1.6]),
        upload: kilobytes([40, 200, 600, 1_000, 1_200, 1_100, 1_300, 1_200, 1_250, 900, 300, 50])
    )
    static let settle = samples(download: kilobytes([180, 20]), upload: kilobytes([12, 4]))
    static let upload = samples(
        download: kilobytes([60, 180, 210, 190, 220, 200, 205, 90, 20]),
        upload: megabytes([1.8, 5.2, 6.1, 5.8, 6.3, 6.0, 5.9, 2.4, 0.3])
    )

    private static func samples(download: [Double], upload: [Double]) -> [TrafficSample] {
        zip(download, upload).map { TrafficSample(download: $0, upload: $1) }
    }

    private static func megabytes(_ values: [Double]) -> [Double] {
        values.map { $0 * megabyte }
    }

    private static func kilobytes(_ values: [Double]) -> [Double] {
        values.map { $0 * kilobyte }
    }
}

/// Easter eggs: shapes drawn by the graph's outline, upload bars above the midline and download
/// bars below. Heights are fractions of the graph's minimum scale; each figure is symmetric, so
/// only its left half (up to the middle bar) is listed.
enum Figures {
    static let heart = figure(upload: [0.4, 0.7, 0.82, 0.7, 0.45, 0.22], download: [0.35, 0.5, 0.62, 0.74, 0.87, 1])
    static let star = figure(upload: [0.1, 0.2, 0.28, 0.36, 0.62, 1], download: [0, 0.2, 0.95, 0.7, 0.4, 0.2])
    static let cat = figure(upload: [0.35, 0.75, 1, 0.5, 0.42, 0.44], download: [0.25, 0.45, 0.58, 0.66, 0.7, 0.72])
    static let tree = figure(upload: [0.05, 0.14, 0.4, 0.64, 0.82, 1], download: [0, 0, 0, 0, 0.3, 0.3])

    private static func figure(upload: [Double], download: [Double]) -> [TrafficSample] {
        zip(mirrored(upload), mirrored(download)).map {
            TrafficSample(download: $1 * TrafficGraph.minimumPeakRate, upload: $0 * TrafficGraph.minimumPeakRate)
        }
    }

    private static func mirrored(_ leftHalf: [Double]) -> [Double] {
        leftHalf + leftHalf.dropLast().reversed()
    }
}
