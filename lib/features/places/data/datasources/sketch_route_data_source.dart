import 'dart:math' as math;

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/walking_route.dart';
import '../../sketch_map.dart';
import 'route_data_source.dart';

/// Finds walking routes along the streets of the test map.
///
/// This stands in for a routing service. To use a real one, implement
/// [RouteDataSource] with its API and change one line in `injection.dart`.
class SketchRouteDataSource implements RouteDataSource {
  SketchRouteDataSource({List<SketchStreet>? streets})
    : _streets = streets ?? sketchStreets;

  final List<SketchStreet> _streets;

  /// Built once, the first time a route is requested.
  late final _StreetGraph _graph = _StreetGraph.from(_streets);

  @override
  Future<WalkingRoute> fetchWalkingRoute({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    return _graph.findRoute(from, to);
  }
}

/// A piece of street between two neighbouring points.
class _Edge {
  const _Edge(this.to, this.km, this.street);

  final int to;
  final double km;
  final String street;
}

/// A point along a street, at a position counted in path segments.
class _Stop {
  const _Stop(this.position, this.node);

  final double position;
  final int node;
}

/// The closest place on the street network to some point.
class _Snap {
  const _Snap(this.point, this.nodeA, this.nodeB, this.street);

  final GeoPoint point;
  final int nodeA;
  final int nodeB;
  final String street;

  bool isOnSameEdgeAs(_Snap other) =>
      nodeA == other.nodeA && nodeB == other.nodeB;
}

/// One stretch of a route along a single street.
class _Walk {
  _Walk(this.street, GeoPoint start) : points = [start];

  final String street;
  final List<GeoPoint> points;
  double km = 0;

  void add(GeoPoint point) {
    km += points.last.distanceKmTo(point);
    points.add(point);
  }

  void append(_Walk next) {
    points.addAll(next.points.skip(1));
    km += next.km;
  }

  void prepend(_Walk previous) {
    points.insertAll(0, previous.points.take(previous.points.length - 1));
    km += previous.km;
  }
}

/// The streets as a network that can be searched for the shortest path.
class _StreetGraph {
  _StreetGraph._(this._nodes, this._edges);

  /// Builds the network, joining streets at every point where they cross.
  factory _StreetGraph.from(List<SketchStreet> streets) {
    final nodes = <GeoPoint>[];
    int addNode(GeoPoint point) {
      nodes.add(point);
      return nodes.length - 1;
    }

    final stops = [
      for (final street in streets)
        [
          for (final (index, point) in street.path.indexed)
            _Stop(index.toDouble(), addNode(point)),
        ],
    ];

    for (var a = 0; a < streets.length; a++) {
      for (var b = a + 1; b < streets.length; b++) {
        final pathA = streets[a].path;
        final pathB = streets[b].path;
        for (var i = 0; i < pathA.length - 1; i++) {
          for (var j = 0; j < pathB.length - 1; j++) {
            final hit = _crossing(pathA[i], pathA[i + 1], pathB[j], pathB[j + 1]);
            if (hit == null) continue;
            final node = addNode(_between(pathA[i], pathA[i + 1], hit.$1));
            stops[a].add(_Stop(i + hit.$1, node));
            stops[b].add(_Stop(j + hit.$2, node));
          }
        }
      }
    }

    final edges = [for (final _ in nodes) <_Edge>[]];
    for (final (index, street) in streets.indexed) {
      final ordered = stops[index]
        ..sort((x, y) => x.position.compareTo(y.position));
      for (var i = 0; i < ordered.length - 1; i++) {
        final a = ordered[i].node;
        final b = ordered[i + 1].node;
        final km = nodes[a].distanceKmTo(nodes[b]);
        edges[a].add(_Edge(b, km, street.name));
        edges[b].add(_Edge(a, km, street.name));
      }
    }
    return _StreetGraph._(nodes, edges);
  }

  final List<GeoPoint> _nodes;
  final List<List<_Edge>> _edges;

  /// A stretch shorter than this is too small to be worth an instruction.
  static const double _shortestStepKm = 0.02;

  /// Measuring a street's direction over this distance ignores tiny wiggles.
  static const double _bearingSampleKm = 0.03;

  /// A change of direction up to this many degrees counts as going straight.
  static const double _straightAheadDegrees = 35;

  WalkingRoute findRoute(GeoPoint from, GeoPoint to) {
    final start = _nearestOnStreet(from);
    final end = _nearestOnStreet(to);
    final walks = _walkBetween(start, end);
    _mergeShortWalks(walks);

    // The walks to and from the street are part of the first and last steps.
    walks.first.km += from.distanceKmTo(start.point);
    walks.last.km += end.point.distanceKmTo(to);

    return WalkingRoute(
      path: [
        from,
        for (final (index, walk) in walks.indexed)
          ...(index == 0 ? walk.points : walk.points.skip(1)),
        to,
      ],
      distanceKm: walks.fold(0, (total, walk) => total + walk.km),
      steps: [
        for (final (index, walk) in walks.indexed)
          index == 0
              ? RouteStep(
                  maneuver: RouteManeuver.start,
                  distanceKm: walk.km,
                  streetName: walk.street,
                  heading: _headingFor(_startBearing(walk)),
                )
              : RouteStep(
                  maneuver: _turnBetween(
                    _endBearing(walks[index - 1]),
                    _startBearing(walk),
                  ),
                  distanceKm: walk.km,
                  streetName: walk.street,
                ),
        const RouteStep.arrive(),
      ],
    );
  }

  _Snap _nearestOnStreet(GeoPoint point) {
    _Snap? nearest;
    var nearestKm = double.infinity;
    for (var a = 0; a < _edges.length; a++) {
      for (final edge in _edges[a]) {
        if (edge.to <= a) continue;
        final onEdge = _closestPoint(point, _nodes[a], _nodes[edge.to]);
        final km = point.distanceKmTo(onEdge);
        if (km < nearestKm) {
          nearestKm = km;
          nearest = _Snap(onEdge, a, edge.to, edge.street);
        }
      }
    }
    if (nearest == null) throw const RouteNotFoundException();
    return nearest;
  }

  /// Finds the shortest path with Dijkstra's algorithm, and groups it by street.
  List<_Walk> _walkBetween(_Snap start, _Snap end) {
    final startNode = _nodes.length;
    final endNode = _nodes.length + 1;
    final points = [..._nodes, start.point, end.point];

    // Joins the start and end into the network for this search only.
    final temporaryEdges = <int, List<_Edge>>{};
    void link(int a, int b, String street) {
      final km = points[a].distanceKmTo(points[b]);
      (temporaryEdges[a] ??= []).add(_Edge(b, km, street));
      (temporaryEdges[b] ??= []).add(_Edge(a, km, street));
    }

    link(startNode, start.nodeA, start.street);
    link(startNode, start.nodeB, start.street);
    link(endNode, end.nodeA, end.street);
    link(endNode, end.nodeB, end.street);
    if (start.isOnSameEdgeAs(end)) link(startNode, endNode, start.street);

    final shortest = List.filled(points.length, double.infinity);
    final settled = List.filled(points.length, false);
    final arrivedFrom = List<(int, _Edge)?>.filled(points.length, null);
    shortest[startNode] = 0;

    while (true) {
      var current = -1;
      for (var i = 0; i < points.length; i++) {
        if (settled[i] || shortest[i].isInfinite) continue;
        if (current < 0 || shortest[i] < shortest[current]) current = i;
      }
      if (current < 0) throw const RouteNotFoundException();
      if (current == endNode) break;
      settled[current] = true;

      final edges = [
        if (current < _edges.length) ..._edges[current],
        ...?temporaryEdges[current],
      ];
      for (final edge in edges) {
        final distance = shortest[current] + edge.km;
        if (distance < shortest[edge.to]) {
          shortest[edge.to] = distance;
          arrivedFrom[edge.to] = (current, edge);
        }
      }
    }

    final legs = <(int, String)>[];
    for (var node = endNode; node != startNode;) {
      final (previous, edge) = arrivedFrom[node]!;
      legs.add((node, edge.street));
      node = previous;
    }

    final walks = <_Walk>[];
    var position = start.point;
    for (final (node, street) in legs.reversed) {
      if (walks.isEmpty || walks.last.street != street) {
        walks.add(_Walk(street, position));
      }
      walks.last.add(points[node]);
      position = points[node];
    }
    return walks;
  }

  /// Folds tiny stretches into their neighbours, so the instructions don't say
  /// to turn onto a street for only a few metres.
  void _mergeShortWalks(List<_Walk> walks) {
    var i = 0;
    while (i < walks.length && walks.length > 1) {
      if (walks[i].km >= _shortestStepKm) {
        i++;
      } else if (i == 0) {
        walks[1].prepend(walks[0]);
        walks.removeAt(0);
      } else {
        walks[i - 1].append(walks[i]);
        walks.removeAt(i);
        if (i < walks.length && walks[i].street == walks[i - 1].street) {
          walks[i - 1].append(walks[i]);
          walks.removeAt(i);
        }
      }
    }
  }

  double _startBearing(_Walk walk) {
    final first = walk.points.first;
    for (final point in walk.points.skip(1)) {
      if (first.distanceKmTo(point) >= _bearingSampleKm) {
        return _bearing(first, point);
      }
    }
    return _bearing(first, walk.points.last);
  }

  double _endBearing(_Walk walk) {
    final last = walk.points.last;
    for (final point in walk.points.reversed.skip(1)) {
      if (point.distanceKmTo(last) >= _bearingSampleKm) {
        return _bearing(point, last);
      }
    }
    return _bearing(walk.points.first, last);
  }

  RouteManeuver _turnBetween(double incoming, double outgoing) {
    final change = (outgoing - incoming + 540) % 360 - 180;
    if (change.abs() <= _straightAheadDegrees) {
      return RouteManeuver.continueStraight;
    }
    return change < 0 ? RouteManeuver.turnLeft : RouteManeuver.turnRight;
  }

  CompassHeading _headingFor(double bearing) {
    return CompassHeading.values[((bearing + 22.5) / 45).floor() % 8];
  }

  /// Degrees clockwise from north, from 0 up to 360.
  static double _bearing(GeoPoint a, GeoPoint b) {
    final east =
        (b.longitude - a.longitude) * math.cos(a.latitude * math.pi / 180);
    final north = b.latitude - a.latitude;
    return (math.atan2(east, north) * 180 / math.pi + 360) % 360;
  }

  static GeoPoint _between(GeoPoint a, GeoPoint b, double t) {
    return GeoPoint(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  static GeoPoint _closestPoint(GeoPoint point, GeoPoint a, GeoPoint b) {
    final scale = math.cos(point.latitude * math.pi / 180);
    final dx = (b.longitude - a.longitude) * scale;
    final dy = b.latitude - a.latitude;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) return a;
    final t =
        (((point.longitude - a.longitude) * scale * dx +
                    (point.latitude - a.latitude) * dy) /
                lengthSquared)
            .clamp(0.0, 1.0);
    return _between(a, b, t);
  }

  /// Where segment a-b meets segment c-d, as a fraction along each, or null.
  static (double, double)? _crossing(
    GeoPoint a,
    GeoPoint b,
    GeoPoint c,
    GeoPoint d,
  ) {
    final abX = b.longitude - a.longitude;
    final abY = b.latitude - a.latitude;
    final cdX = d.longitude - c.longitude;
    final cdY = d.latitude - c.latitude;
    final denominator = abX * cdY - abY * cdX;
    if (denominator == 0) return null;

    final acX = c.longitude - a.longitude;
    final acY = c.latitude - a.latitude;
    final alongAb = (acX * cdY - acY * cdX) / denominator;
    final alongCd = (acX * abY - acY * abX) / denominator;
    if (alongAb < 0 || alongAb > 1 || alongCd < 0 || alongCd > 1) return null;
    return (alongAb, alongCd);
  }
}
