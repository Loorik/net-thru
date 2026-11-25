import Foundation

/// Compact, decimal (1 KB = 1000 bytes, like Activity Monitor) byte amounts: "0.4 KB", "12 KB",
/// "340 KB", "1.2 MB", "45 MB". Never more than three digits, so the menu bar width stays put.
package enum ByteFormat {
    private static let units = ["KB", "MB", "GB", "TB"]
    private static let unitFactor = 1000.0
    /// Values that would round to 1000 move up to the next unit: "1.0 MB", not "1000 KB".
    private static let nextUnitThreshold = 999.5
    /// Values that would round to "0.0" are shown as a plain "0".
    private static let zeroThreshold = 0.05
    /// Values that round to 10 or more are shown without a decimal.
    private static let decimalThreshold = 9.95
    private static let oneDecimal = "%.1f"
    private static let noDecimals = "%.0f"
    /// The widest number `formattedNumber` produces; all digits are equally wide.
    private static let widestNumber = "888"

    /// Strings at least as wide as anything `rate` produces, for sizing the menu bar item.
    package static let widestRates = units.map { "\(widestNumber) \($0)/s" }

    package static func rate(_ bytesPerSecond: Double, locale: Locale = .current) -> String {
        amount(bytesPerSecond, locale: locale) + "/s"
    }

    package static func amount(_ bytes: Double, locale: Locale = .current) -> String {
        let (value, unit) = inLargestFittingUnit(bytes)
        return "\(formattedNumber(value, locale: locale)) \(unit)"
    }

    private static func inLargestFittingUnit(_ bytes: Double) -> (value: Double, unit: String) {
        var value = max(bytes, 0) / unitFactor
        var unitIndex = units.startIndex
        while value >= nextUnitThreshold, unitIndex < units.endIndex - 1 {
            value /= unitFactor
            unitIndex += 1
        }
        return (value, units[unitIndex])
    }

    private static func formattedNumber(_ value: Double, locale: Locale) -> String {
        if value < zeroThreshold { return "0" }
        let format = value < decimalThreshold ? oneDecimal : noDecimals
        return String(format: format, locale: locale, value)
    }
}
