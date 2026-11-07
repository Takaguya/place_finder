# Place Finder Demo Project

## Description 

This is a Demo for Application for finding malls, restaurants, cafes and markets that are both good and close to you.

## Features For the Demo

- Search bar
- Map viewer
- Select location for places
- Get direction
- Show routes
- Show time travel by walking

## Project Structure

```
lib/
  main.dart, app.dart
  app_router.dart           Matches each route name to its screen
  injection.dart            Connects the layers. The only file that picks a data source.
  core/                     Result type and theme
  features/places/
    sketch_map.dart         The test map's streets and artwork, used only by the map and the route finder
    domain/                 Business rules in plain Dart, with no Flutter
      entities/             Place, PlaceQuery, RankedPlace, UserPosition, GeoPoint, WalkingRoute
      services/             PlaceRanker: what "good and close" means
      usecases/             SearchPlaces, GetUserPosition, GetWalkingRoute, OpenInMapsApp
      repositories/         Contracts that the data layer fulfils
    data/                   Where data comes from, and everything that talks to the phone
      datasources/          Contracts (place_, route_, location_data_source) and their implementations
      models/               The data source's shape, converted into entities
      repositories/         Implementations of the domain contracts
    presentation/
      bloc/                 Events in, states out. No widgets.
      place_routes.dart     Route names, and how to open each screen
      pages/                The only widgets that talk to the BLoC
      widgets/
        atoms/              Rank pin, rating, open status, filter pill, back button
        molecules/          Search field, sort selector, place row, route step
        organisms/          Map, search header, results and directions panels, place summary
        templates/          Map with a bottom sheet (layout only)
```

## What each pattern is for

| Pattern | What it's for | Example in this app |
|---|---|---|
| Clean Architecture | Changing where data comes from without touching the rest of the app | Real places need one new data source and one changed line in `injection.dart`. Screens and ranking stay the same. |
| BLoC | Keeping logic out of screens, so it can be tested without drawing anything | `place_search_bloc_test.dart` checks searching and filtering with no widgets. |
| Atomic Design | Building screens from small shared pieces | `RatingLabel` is one widget used by the results list and the details screen, so changing it updates both. |
| Central routes | Letting screens open each other without knowing how each is built | `SearchPage` asks for the details route. Only `app_router.dart` knows which page that is. |

## Routes

| Route | Screen | Needs |
|---|---|---|
| `/` | `SearchPage` | Nothing |
| `/place` | `PlaceDetailsPage` | `PlaceRouteArgs` |
| `/place/directions` | `DirectionsPage` | `PlaceRouteArgs` |





