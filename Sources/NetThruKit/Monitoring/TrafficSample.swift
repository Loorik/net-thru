/// The two directions traffic flows in.
package enum TrafficDirection: CaseIterable, Sendable {
    case upload
    case download
}

/// Transfer rates at one moment, in bytes per second.
package struct TrafficSample: Equatable, Sendable {
    package static let idle = TrafficSample(download: 0, upload: 0)

    package var download: Double
    package var upload: Double

    package init(download: Double, upload: Double) {
        self.download = download
        self.upload = upload
    }

    package func rate(_ direction: TrafficDirection) -> Double {
        switch direction {
        case .upload: upload
        case .download: download
        }
    }
}
