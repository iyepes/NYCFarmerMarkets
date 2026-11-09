import Foundation

/// Pure accessibility strings for the borough section headers in the Markets list.
nonisolated enum SectionHeaderAccessibility {
    /// Accessibility label in the form "<borough>, <count> markets".
    ///
    /// The form is literal, so a count of 1 reads "1 markets".
    static func label(borough: String, count: Int) -> String {
        "\(borough), \(count) markets"
    }

    /// Accessibility value describing the section state: "Expanded" or "Collapsed".
    static func value(isExpanded: Bool) -> String {
        isExpanded ? "Expanded" : "Collapsed"
    }

    /// Accessibility hint describing what activating the header does.
    static func hint(isExpanded: Bool) -> String {
        isExpanded ? "Double tap to collapse" : "Double tap to expand"
    }

    /// Accessibility identifier: "section-header-" followed by the borough name
    /// with every space replaced by a hyphen.
    static func identifier(borough: String) -> String {
        "section-header-" + borough.replacingOccurrences(of: " ", with: "-")
    }
}
