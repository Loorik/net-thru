import Foundation
import Testing
@testable import NetThruKit

@Suite("ByteFormat")
struct ByteFormatTests {
    private let english = Locale(identifier: "en_US")

    @Test("Uses the largest unit that keeps the number under 1000", arguments: [
        (0.0, "0 KB"), (-5, "0 KB"), (49, "0 KB"), (51, "0.1 KB"), (420, "0.4 KB"),
        (9_949, "9.9 KB"), (9_951, "10 KB"), (12_345, "12 KB"), (999_499, "999 KB"),
        (999_500, "1.0 MB"), (1_234_567, "1.2 MB"), (45_600_000, "46 MB"),
        (999_500_000, "1.0 GB"), (2_100_000_000, "2.1 GB"), (7.3e12, "7.3 TB"),
    ])
    func amount(bytes: Double, expected: String) {
        #expect(ByteFormat.amount(bytes, locale: english) == expected)
    }

    @Test func rateIsTheAmountPerSecond() {
        #expect(ByteFormat.rate(1_234_567, locale: english) == "1.2 MB/s")
    }

    @Test func usesTheLocalesDecimalSeparator() {
        #expect(ByteFormat.amount(1_234_567, locale: Locale(identifier: "de_DE")) == "1,2 MB")
    }

    @Test func widestRatesCoverEveryUnit() {
        #expect(ByteFormat.widestRates == ["888 KB/s", "888 MB/s", "888 GB/s", "888 TB/s"])
    }
}
