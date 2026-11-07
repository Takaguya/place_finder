import 'package:url_launcher/url_launcher.dart';

import '../../../../core/result.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/repositories/maps_app_repository.dart';

/// Opens Google Maps, using the app if it's installed.
class MapsAppRepositoryImpl implements MapsAppRepository {
  const MapsAppRepositoryImpl();

  static const Failure _couldNotOpen = Failure(
    'Maps could not be opened on this device.',
  );

  @override
  Future<Result<void>> openWalkingDirections({required GeoPoint to}) async {
    final directions = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${to.latitude},${to.longitude}',
      'travelmode': 'walking',
    });
    try {
      final opened = await launchUrl(
        directions,
        mode: LaunchMode.externalApplication,
      );
      return opened ? const Success<void>(null) : const Failed(_couldNotOpen);
    } on Exception {
      return const Failed(_couldNotOpen);
    }
  }
}
