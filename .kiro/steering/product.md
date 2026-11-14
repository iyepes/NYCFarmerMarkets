---
inclusion: always
---

# Product: Spooky Markets (NYC Farmer Markets)

SwiftUI app that lists New York City farmers markets with a light, spooky theme. Display name "Spooky Markets"; Xcode project, target and scheme are `NYCFarmerMarkets`; bundle id `com.hacemoscontactos.NYCFarmerMarkets`. GitHub repo `iyepes/NYCFarmerMarkets` is PUBLIC: everything committed is public.

## Data

- Source: NYC Open Data dataset `8vwk-6iz2` (`MarketService.defaultURL`, `$limit=5000`). The dataset has one row per market per year; `MarketService.parse` keeps only the most recent year and removes duplicate ids.
- Offline cache: the last successful fetch is saved as JSON (`MarketCache`, `Application Support/markets-cache.json`). On launch the cache is shown first, then refreshed from the network. If the refresh fails with cached data, an offline banner is shown; with no data, the splash shows a friendly failure (`LoadFailureMessage`) and a Retry button.
- Favorites: market ids in `UserDefaults` key `favoriteMarketIDs` (`FavoritesStore`). Ids with no matching market are kept in storage but not shown.

## Screens

- Splash (`SplashView`): logo, loading caption, minimum display time (`SplashDecision`), failure message and Retry.
- Tabs (`RootTabView`):
  - **Markets**: list grouped by borough (Manhattan, Brooklyn, Queens, Bronx, Staten Island, then unknown) in collapsible sections, with search by name, address or borough.
  - **Map**: pins for markets; shows the same search results as the Markets list (`MarketStore.searchQuery` is shared) with a filter indicator.
  - **Favorites**: favorite markets sorted by name, swipe to remove.
- Detail: one shared sheet (`MarketStore.selectedMarket`) opened from any tab, with favorite toggle, "Go to Map" (in-app map, `MarketLocationMapView`) and "Directions" (Apple Maps).

## Tone

User-facing text is lightly spooky ("Summoning markets…", "Nothing lurking here"). Accessibility labels stay plain and descriptive ("Loading farmers markets", "No markets found").

## Platforms

iOS 26.5, macOS 26.4, visionOS 26.5 (`SUPPORTED_PLATFORMS` includes `xros`). iOS is the main target and the only one verified on screen; macOS builds and runs unit tests; visionOS is compiled but not verified.
