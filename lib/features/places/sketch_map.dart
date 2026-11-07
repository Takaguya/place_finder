import 'domain/entities/geo_point.dart';

/// The hand-drawn test map of central Phnom Penh: its streets, rivers, parks and
/// area names.
///
/// The map screen draws these streets and the test route finder walks along
/// them, so a route always lines up with what is drawn. Real map tiles and a
/// routing service would replace this file.
///
/// Positions are sketched on a grid where (0, 0) is the north-west corner of
/// central Phnom Penh and (1, 1) is the south-east corner.
abstract final class SketchMap {
  static const double north = 11.60;
  static const double south = 11.52;
  static const double west = 104.88;
  static const double east = 104.95;

  static GeoPoint toGeo(double x, double y) {
    return GeoPoint(north - y * (north - south), west + x * (east - west));
  }
}

/// A named street on the test map.
class SketchStreet {
  SketchStreet(this.name, List<(double, double)> gridPoints, {this.isMain = false})
    : path = _smoothPath(gridPoints, pointsPerCurve: 12);

  final String name;

  /// Main roads are drawn wider and in a different colour.
  final bool isMain;

  /// The street as drawn, as closely spaced points along a smooth curve.
  final List<GeoPoint> path;
}

/// A river, drawn as a wide line.
class SketchRiver {
  SketchRiver(this.width, List<(double, double)> gridPoints)
    : path = _smoothPath(gridPoints, pointsPerCurve: 32);

  /// The river's width, in grid units.
  final double width;
  final List<GeoPoint> path;
}

enum SketchAreaKind { park, water, land }

/// An oval on the map. Land is drawn over the rivers, to make islands.
class SketchArea {
  const SketchArea(this.kind, this.x, this.y, this.radiusX, this.radiusY);

  final SketchAreaKind kind;
  final double x;
  final double y;
  final double radiusX;
  final double radiusY;

  GeoPoint get northWest => SketchMap.toGeo(x - radiusX, y - radiusY);
  GeoPoint get southEast => SketchMap.toGeo(x + radiusX, y + radiusY);
}

/// The name of an area, written on the map.
class SketchLabel {
  const SketchLabel(this.name, this.x, this.y);

  final String name;
  final double x;
  final double y;

  GeoPoint get at => SketchMap.toGeo(x, y);
}

/// Curves through the middle of each pair of grid points, starting and ending
/// exactly on the first and last points.
List<GeoPoint> _smoothPath(
  List<(double, double)> points, {
  required int pointsPerCurve,
}) {
  final smooth = <(double, double)>[points.first];
  var curveStart = points.first;
  for (var i = 1; i < points.length - 1; i++) {
    final control = points[i];
    final next = points[i + 1];
    final curveEnd = ((control.$1 + next.$1) / 2, (control.$2 + next.$2) / 2);
    for (var step = 1; step <= pointsPerCurve; step++) {
      final t = step / pointsPerCurve;
      final u = 1 - t;
      smooth.add((
        u * u * curveStart.$1 + 2 * u * t * control.$1 + t * t * curveEnd.$1,
        u * u * curveStart.$2 + 2 * u * t * control.$2 + t * t * curveEnd.$2,
      ));
    }
    curveStart = curveEnd;
  }
  smooth.add(points.last);
  return [for (final point in smooth) SketchMap.toGeo(point.$1, point.$2)];
}

/// Every street on the test map. Each one crosses at least one other, so any
/// point can be reached from any other, including over the two bridges.
final List<SketchStreet> sketchStreets = [
  SketchStreet('Street 598', [
    (-5, 0.12),
    (0.2, 0.10),
    (0.52, 0.02),
    (0.75, -5),
  ], isMain: true),
  SketchStreet('Russian Blvd', [
    (-5, 0.36),
    (0.2, 0.34),
    (0.5, 0.37),
    (0.76, 0.37),
  ], isMain: true),
  SketchStreet('Monivong Blvd', [
    (0.585, -5),
    (0.59, 0.1),
    (0.57, 0.5),
    (0.55, 5),
  ], isMain: true),
  SketchStreet('Norodom Blvd', [
    (0.665, -5),
    (0.67, 0.2),
    (0.66, 0.6),
    (0.64, 5),
  ]),
  SketchStreet('Sihanouk Blvd', [
    (-5, 0.58),
    (0.3, 0.56),
    (0.6, 0.55),
    (0.77, 0.53),
  ]),
  SketchStreet('Mao Tse Toung Blvd', [
    (-5, 0.78),
    (0.3, 0.75),
    (0.6, 0.72),
    (0.76, 0.70),
  ]),
  SketchStreet('Kampuchea Krom Blvd', [
    (0.18, 0.33),
    (0.45, 0.42),
    (0.7, 0.46),
    (0.77, 0.45),
  ]),
  SketchStreet('Toul Kork Road', [
    (0.42, -5),
    (0.43, 0.1),
    (0.40, 0.4),
    (0.42, 5),
  ]),
  SketchStreet('Street 1003', [
    (0.2, -5),
    (0.22, 0.3),
    (0.18, 0.7),
    (0.2, 5),
  ]),
  SketchStreet('Chroy Changvar Bridge', [
    (0.655, 0.17),
    (0.95, 0.16),
    (1.4, 0.14),
    (5, 0.1),
  ]),
  SketchStreet('Koh Pich Bridge', [(0.70, 0.53), (0.865, 0.65)]),
  SketchStreet('Chroy Changvar Road', [
    (0.84, -5),
    (0.85, 0.1),
    (0.87, 0.30),
  ]),
  SketchStreet('Street 63', [(0.50, 0.35), (0.52, 0.9)]),
  SketchStreet('Street 51', [(0.62, 0.36), (0.60, 0.8)]),
  SketchStreet('Street 278', [(0.45, 0.63), (0.75, 0.62)]),
];

final List<SketchRiver> sketchRivers = [
  // Tonle Sap
  SketchRiver(0.06, [
    (0.80, -5),
    (0.81, -0.2),
    (0.79, 0.2),
    (0.80, 0.5),
    (0.84, 0.6),
  ]),
  // Mekong, north
  SketchRiver(0.10, [(3, -5), (1.2, -0.2), (1.0, 0.35), (0.86, 0.58)]),
  // Mekong, south
  SketchRiver(0.13, [(0.86, 0.58), (0.93, 0.8), (1.2, 1.4), (2, 5)]),
  // Bassac
  SketchRiver(0.06, [(0.84, 0.6), (0.76, 0.8), (0.72, 1.2), (0.66, 5)]),
];

const List<SketchArea> sketchAreas = [
  SketchArea(SketchAreaKind.park, 0.30, 0.52, 0.10, 0.06),
  SketchArea(SketchAreaKind.park, 0.07, 0.30, 0.09, 0.06),
  SketchArea(SketchAreaKind.park, 0.72, 0.50, 0.03, 0.05),
  SketchArea(SketchAreaKind.water, 0.55, 0.19, 0.035, 0.045),
  // Koh Pich
  SketchArea(SketchAreaKind.land, 0.865, 0.66, 0.035, 0.04),
];

const List<SketchLabel> sketchLabels = [
  SketchLabel('Sen Sok', 0.05, 0.20),
  SketchLabel('Toul Kork', 0.22, 0.40),
  SketchLabel('Prampir Makara', 0.40, 0.46),
  SketchLabel('Daun Penh', 0.60, 0.43),
  SketchLabel('BKK1', 0.50, 0.59),
  SketchLabel('Chamkar Mon', 0.64, 0.69),
  SketchLabel('Toul Tom Poung', 0.34, 0.79),
  SketchLabel('Koh Pich', 0.82, 0.745),
  SketchLabel('Chroy Changvar', 0.84, 0.22),
  SketchLabel('Meanchey', 0.60, 1.00),
];
