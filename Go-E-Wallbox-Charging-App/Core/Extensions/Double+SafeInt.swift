import Foundation

extension Double {
    /// Rounds and converts to `Int` without trapping: `nil` for NaN, infinity, or values outside the `Int` range.
    var safeRoundedInt: Int? {
        guard isFinite else { return nil }
        return Int(exactly: rounded())
    }

    /// Like `safeRoundedInt`, but clamped into `range`. NaN yields `fallback`,
    /// values beyond the `Int` range saturate at the matching end of `range`.
    func safeRoundedInt(clampedTo range: ClosedRange<Int>, fallback: Int = 0) -> Int {
        guard !isNaN else { return fallback }
        guard let value = safeRoundedInt else {
            return self > 0 ? range.upperBound : range.lowerBound
        }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}
