import '../../../../core/result.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/place_data_source.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  const PlaceRepositoryImpl(this._source);

  final PlaceDataSource _source;

  @override
  Future<Result<List<Place>>> getPlaces() async {
    try {
      final models = await _source.fetchPlaces();
      return Success([for (final model in models) model.toEntity()]);
    } on Exception {
      return const Failed(
        Failure('Places could not be loaded. Try again in a moment.'),
      );
    }
  }
}
