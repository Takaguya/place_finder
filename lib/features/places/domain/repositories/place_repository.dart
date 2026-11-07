import '../../../../core/result.dart';
import '../entities/place.dart';

/// Where places come from. The domain only knows this contract, so sample data
/// can be replaced by a real API without changing any business rule or screen.
abstract interface class PlaceRepository {
  Future<Result<List<Place>>> getPlaces();
}
