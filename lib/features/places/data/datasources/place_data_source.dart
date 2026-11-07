import '../models/place_model.dart';

/// Supplies places. Implement this with an API to replace the sample data.
abstract interface class PlaceDataSource {
  Future<List<PlaceModel>> fetchPlaces();
}
