import 'package:flutter/services.dart';

/// Which build of the app this is, chosen with `flutter run --flavor`. The
/// Android side of each flavor is in `android/app/build.gradle.kts`.
enum AppFlavor {
  dev(appTitle: 'Place Finder Dev'),
  prod(appTitle: 'Place Finder');

  const AppFlavor({required this.appTitle});

  final String appTitle;

  bool get isProduction => this == prod;

  static AppFlavor get current => fromName(appFlavor);

  /// A build with no flavor, or an unknown one, counts as dev, so that nothing
  /// is ever mistaken for production.
  static AppFlavor fromName(String? name) => name == prod.name ? prod : dev;
}
