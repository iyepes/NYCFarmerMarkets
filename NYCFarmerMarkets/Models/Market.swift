//
//  Market.swift
//  NYCFarmerMarkets
//

import Foundation
import CoreLocation

/// A farmers market from the NYC Open Data "NYC Farmers Markets" dataset (8vwk-6iz2).
nonisolated struct Market: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let borough: String
    let address: String
    let year: String?
    let communityDistrict: String?
    let latitude: Double?
    let longitude: Double?
    let daysOfOperation: String?
    let hoursOfOperation: String?
    let acceptsEBT: String?
    let openYearRound: String?
    let healthDeptCooking: String?

    static let unknownBorough = "Unknown"

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: Raw API record

    /// One row exactly as returned by the API (every value is a string).
    struct Raw: Decodable, Sendable {
        let year: String?
        let marketname: String?
        let borough: String?
        let streetaddress: String?
        let community_district: String?
        let latitude: String?
        let longitude: String?
        let daysoperation: String?
        let hoursoperations: String?
        let accepts_ebt: String?
        let open_year_round: String?
        let nyc_dept_of_health_cooking: String?
    }

    /// Builds a market from a raw row. Returns nil when there is no name.
    init?(raw: Raw) {
        guard let name = Market.clean(raw.marketname) else { return nil }
        let address = Market.clean(raw.streetaddress) ?? ""
        self.name = name
        self.address = address
        self.id = Market.makeID(name: name, address: address)
        self.borough = Market.normalizeBorough(raw.borough)
        self.year = Market.clean(raw.year)
        self.communityDistrict = Market.clean(raw.community_district)
        self.latitude = Market.parseCoordinate(raw.latitude)
        self.longitude = Market.parseCoordinate(raw.longitude)
        self.daysOfOperation = Market.clean(raw.daysoperation)
        self.hoursOfOperation = Market.clean(raw.hoursoperations)
        self.acceptsEBT = Market.clean(raw.accepts_ebt)?.capitalizedFirst
        self.openYearRound = Market.clean(raw.open_year_round)?.capitalizedFirst
        self.healthDeptCooking = Market.clean(raw.nyc_dept_of_health_cooking)?.capitalizedFirst
    }

    // MARK: Helpers

    static func makeID(name: String, address: String) -> String {
        "\(name.lowercased())|\(address.lowercased())"
    }

    static func normalizeBorough(_ value: String?) -> String {
        guard let cleaned = clean(value) else { return unknownBorough }
        // Canonicalize capitalization ("brooklyn" -> "Brooklyn").
        let known = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
        if let match = known.first(where: { $0.caseInsensitiveCompare(cleaned) == .orderedSame }) {
            return match
        }
        return cleaned
    }

    static func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    static func parseCoordinate(_ value: String?) -> Double? {
        guard let text = clean(value), let number = Double(text), number != 0 else { return nil }
        return number
    }
}

private extension String {
    /// "yes" -> "Yes"; leaves the rest of the string untouched.
    nonisolated var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
