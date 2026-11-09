import Foundation

/// Tracks which borough sections are expanded in the market list.
///
/// Two collections are used on purpose. While the user is not searching, their
/// choices live in `userExpanded`. While searching, every section defaults to
/// expanded and any manual toggles go into `searchOverrides` only, leaving
/// `userExpanded` untouched. When the search ends, `searchOverrides` is
/// discarded, so clearing a search restores the earlier manual state exactly.
/// Reusing a single set for both would make a section collapsed during search
/// come back expanded (or vice versa) after the search is cleared.
nonisolated struct SectionExpansionState: Equatable, Sendable {
    /// Boroughs the user expanded while not searching. Empty = everything collapsed.
    private(set) var userExpanded: Set<String> = []
    /// Per-borough choices made while searching. Discarded when the search ends.
    private(set) var searchOverrides: [String: Bool] = [:]

    init() {}

    /// True if the query is non-empty after trimming whitespace and newlines.
    static func isSearching(_ query: String) -> Bool {
        MarketSearch.isActive(query)
    }

    /// While searching, sections default to expanded unless overridden.
    /// Otherwise a section is expanded only if the user expanded it.
    func isExpanded(_ borough: String, query: String) -> Bool {
        if Self.isSearching(query) { return searchOverrides[borough] ?? true }
        return userExpanded.contains(borough)
    }

    /// Flips the section's state. Searching only touches `searchOverrides`;
    /// otherwise only `userExpanded` changes.
    mutating func toggle(_ borough: String, query: String) {
        let wasExpanded = isExpanded(borough, query: query)
        if Self.isSearching(query) {
            searchOverrides[borough] = !wasExpanded
        } else if wasExpanded {
            userExpanded.remove(borough)
        } else {
            userExpanded.insert(borough)
        }
    }

    /// Call when the query goes from non-empty to empty.
    mutating func endSearch() { searchOverrides.removeAll() }
}
