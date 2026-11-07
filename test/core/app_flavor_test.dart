import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/core/config/app_flavor.dart';

void main() {
  test('finds each flavor from the name given to --flavor', () {
    expect(AppFlavor.fromName('dev'), AppFlavor.dev);
    expect(AppFlavor.fromName('prod'), AppFlavor.prod);
  });

  test('a build with no flavor, or an unknown one, is never production', () {
    expect(AppFlavor.fromName(null).isProduction, isFalse);
    expect(AppFlavor.fromName('staging').isProduction, isFalse);
  });

  test('only production uses the plain app name', () {
    expect(AppFlavor.prod.appTitle, 'Place Finder');
    expect(AppFlavor.dev.appTitle, 'Place Finder Dev');
  });
}
