import Foundation

/// Compact, decimal (1 KB = 1000 bytes, like Activity Monitor) byte amounts: "0.4 KB", "12 KB",
/// "340 KB", "1.2 MB", "45 MB". Never more than three digits, so the menu bar width stays put.
enum ByteFormat {
    private static let units = ["KB", "MB", "GB", "TB"]

    static func rate(_ bytesPerSecond: Double) -> String {
        amount(bytesPerSecond) + "/s"
    }

    static func amount(_ bytes: Double) -> String {
        var value = max(bytes, 0) / 1000
        var unit = 0
        while value >= 999.5, unit < units.count - 1 {
            value /= 1000
            unit += 1
        }
        if value < 0.05 {
            return "0 \(units[unit])"
        }
        let format = value < 9.95 ? "%.1f" : "%.0f"
        return String(format: format, locale: .current, value) + " " + units[unit]
    }

    /// Strings at least as wide as anything `rate` produces, for sizing the menu bar item.
    static let widestRates = units.map { "888 \($0)/s" }
}
