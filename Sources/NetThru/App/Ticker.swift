import Foundation

/// Calls an action at a fixed interval on the main thread, also while a menu is open.
@MainActor
final class Ticker {
    /// How late a tick may fire, as a fraction of the interval, so macOS can batch wake-ups.
    private static let toleranceFraction = 0.1

    private let timer: Timer

    init(interval: TimeInterval, action: @escaping @MainActor @Sendable () -> Void) {
        timer = Timer(timeInterval: interval, repeats: true) { _ in
            MainActor.assumeIsolated { action() }
        }
        timer.tolerance = interval * Self.toleranceFraction
        // An open menu runs the run loop in event-tracking mode, which `.common` includes.
        RunLoop.main.add(timer, forMode: .common)
    }
}
