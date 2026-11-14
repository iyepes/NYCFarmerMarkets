//
//  FavoriteCueTests.swift
//  NYCFarmerMarketsTests
//
import Testing
@testable import NYCFarmerMarkets

struct FavoriteCueTests {
    @Test func removalIsAy() {
        #expect(FavoriteCue.removal == .ay)
    }

    @Test func removalIsNotTheHiss() {
        #expect(FavoriteCue.removal != .hiss)
    }

    @Test func toggleOffPlaysAy() {
        #expect(FavoriteCue.toggle(wasFavorite: true) == .ay)
    }

    @Test func toggleOnKeepsTheHiss() {
        #expect(FavoriteCue.toggle(wasFavorite: false) == .hiss)
    }
}
