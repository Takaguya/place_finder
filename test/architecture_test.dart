import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fails if code breaks the layering rules, so the separation between business
/// logic and UI can't quietly erode over time.
void main() {
  const places = 'lib/features/places';
  const widgets = '$places/presentation/widgets';

  /// Lists `import` lines in [directory] containing any of [forbidden].
  List<String> violations(String directory, List<String> forbidden) {
    final files = Directory(directory)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    return [
      for (final file in files)
        for (final line in file.readAsLinesSync())
          if (line.startsWith('import ') && forbidden.any(line.contains))
            '${file.path}: $line',
    ];
  }

  group('Clean Architecture', () {
    test('the domain layer knows nothing about Flutter or outer layers', () {
      expect(
        violations('$places/domain', [
          'package:flutter',
          'package:geolocator',
          '/data/',
          '/presentation/',
          'sketch_map',
        ]),
        isEmpty,
      );
    });

    test('the data layer knows nothing about the UI', () {
      expect(
        violations('$places/data', ['package:flutter', '/presentation/']),
        isEmpty,
      );
    });

    test('the presentation layer never reaches into the data layer', () {
      expect(
        violations('$places/presentation', [
          '/data/',
          'package:geolocator',
          'package:url_launcher',
        ]),
        isEmpty,
      );
    });

    test('repositories depend on data source contracts, not implementations', () {
      expect(
        violations('$places/data/repositories', [
          'sample_place_data_source',
          'sketch_route_data_source',
          'device_location_data_source',
        ]),
        isEmpty,
      );
    });

    test('only the route finder and the map know about the test map', () {
      final users = violations('lib', ['sketch_map.dart']).where(
        (line) =>
            !line.contains('sketch_route_data_source.dart:') &&
            !line.contains('place_map.dart:'),
      );

      expect(users, isEmpty);
    });
  });

  group('BLoC', () {
    test('the BLoC contains no widgets', () {
      expect(
        violations('$places/presentation/bloc', ['package:flutter/']),
        isEmpty,
      );
    });

    test('only pages talk to the BLoC', () {
      expect(violations(widgets, ['flutter_bloc', '/bloc/']), isEmpty);
    });
  });

  group('Routing', () {
    test('pages open each other through routes, never by importing a page', () {
      expect(violations('$places/presentation/pages', ['_page.dart']), isEmpty);
    });

    test('the feature never imports the router that sits above it', () {
      expect(violations(places, ['app_router.dart']), isEmpty);
    });

    test('only the routes file in the feature knows about go_router', () {
      final users = violations(places, ['package:go_router']).where(
        (line) => !line.contains('place_routes.dart:'),
      );

      expect(users, isEmpty);
    });
  });

  group('Atomic Design', () {
    test('atoms use no larger pieces', () {
      expect(
        violations('$widgets/atoms', [
          'molecules/',
          'organisms/',
          'templates/',
          'pages/',
        ]),
        isEmpty,
      );
    });

    test('molecules use no larger pieces', () {
      expect(
        violations('$widgets/molecules', [
          'organisms/',
          'templates/',
          'pages/',
        ]),
        isEmpty,
      );
    });

    test('organisms use no templates or pages', () {
      expect(
        violations('$widgets/organisms', ['templates/', 'pages/']),
        isEmpty,
      );
    });

    test('templates only arrange slots, using no other pieces', () {
      expect(
        violations('$widgets/templates', [
          'atoms/',
          'molecules/',
          'organisms/',
          'pages/',
        ]),
        isEmpty,
      );
    });
  });
}
