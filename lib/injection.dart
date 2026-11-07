// Connects the layers. This is the only file that knows which concrete data
// sources are in use, so swapping test data for a real service happens here.

import 'features/places/data/datasources/device_location_data_source.dart';
import 'features/places/data/datasources/sample_place_data_source.dart';
import 'features/places/data/datasources/sketch_route_data_source.dart';
import 'features/places/data/repositories/location_repository_impl.dart';
import 'features/places/data/repositories/maps_app_repository_impl.dart';
import 'features/places/data/repositories/place_repository_impl.dart';
import 'features/places/data/repositories/route_repository_impl.dart';
import 'features/places/domain/entities/geo_point.dart';
import 'features/places/domain/entities/user_position.dart';
import 'features/places/domain/usecases/get_user_position.dart';
import 'features/places/domain/usecases/get_walking_route.dart';
import 'features/places/domain/usecases/open_in_maps_app.dart';
import 'features/places/domain/usecases/search_places.dart';
import 'features/places/presentation/bloc/place_search_bloc.dart';

/// The area the sample places cover.
const ServiceArea phnomPenh = ServiceArea(
  name: 'Phnom Penh',
  centre: GeoPoint(11.5564, 104.9282),
  centreName: 'Independence Monument',
  radiusKm: 20,
);

PlaceSearchBloc createPlaceSearchBloc() {
  const placeRepository = PlaceRepositoryImpl(SamplePlaceDataSource());
  const locationRepository = LocationRepositoryImpl(DeviceLocationDataSource());

  return PlaceSearchBloc(
    getUserPosition: const GetUserPosition(
      locationRepository,
      serviceArea: phnomPenh,
    ),
    searchPlaces: SearchPlaces(placeRepository),
  );
}

GetWalkingRoute createGetWalkingRoute() {
  return GetWalkingRoute(RouteRepositoryImpl(SketchRouteDataSource()));
}

OpenInMapsApp createOpenInMapsApp() {
  return const OpenInMapsApp(MapsAppRepositoryImpl());
}
