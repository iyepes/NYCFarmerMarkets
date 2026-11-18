import Foundation

/// Pure page-step logic for the onboarding pager (VoiceOver adjust and Next).
nonisolated enum OnboardingPaging {
    /// The page index after moving `delta` pages, or nil when `count` or `current` is invalid
    /// or the result would leave `0..<count`. The result is never clamped.
    static func target(from current: Int, delta: Int, count: Int) -> Int? {
        guard count > 0, (0..<count).contains(current) else { return nil }
        let (result, overflow) = current.addingReportingOverflow(delta)
        guard !overflow, (0..<count).contains(result) else { return nil }
        return result
    }
}
