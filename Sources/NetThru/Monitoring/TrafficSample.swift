/// The two directions traffic flows in.
enum TrafficDirection: CaseIterable {
    case upload
    case download
}

/// Transfer rates at one moment, in bytes per second.
struct TrafficSample: Equatable {
    static let idle = TrafficSample(download: 0, upload: 0)

    var download: Double
    var upload: Double

    func rate(_ direction: TrafficDirection) -> Double {
        switch direction {
        case .upload: upload
        case .download: download
        }
    }
}
