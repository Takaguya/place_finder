import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/walking_route.dart';
import 'package:place_finder/features/places/domain/usecases/get_walking_route.dart';
import 'package:place_finder/features/places/domain/usecases/open_in_maps_app.dart';
import 'package:place_finder/features/places/presentation/bloc/directions_bloc.dart';

import '../../../helpers/fakes.dart';

void main() {
  final destination = northOfCentre(1);
  final request = DirectionsRequested(from: testCentre, to: destination);

  DirectionsBloc blocWith(
    Result<WalkingRoute> route, {
    FakeMapsAppRepository? mapsApp,
  }) {
    return DirectionsBloc(
      getWalkingRoute: GetWalkingRoute(FakeRouteRepository(route)),
      openInMapsApp: OpenInMapsApp(mapsApp ?? FakeMapsAppRepository()),
    );
  }

  test('begins by loading, with no route yet', () {
    final bloc = blocWith(Success(testRoute));
    addTearDown(bloc.close);

    expect(bloc.state.status, DirectionsStatus.loading);
    expect(bloc.state.route, isNull);
  });

  blocTest<DirectionsBloc, DirectionsState>(
    'publishes the route when one is found',
    build: () => blocWith(Success(testRoute)),
    act: (bloc) => bloc.add(request),
    verify: (bloc) {
      expect(bloc.state.status, DirectionsStatus.ready);
      expect(bloc.state.route, testRoute);
      expect(bloc.state.errorMessage, isNull);
    },
  );

  blocTest<DirectionsBloc, DirectionsState>(
    'publishes the message when no route is found',
    build: () => blocWith(const Failed(Failure('No route today.'))),
    act: (bloc) => bloc.add(request),
    verify: (bloc) {
      expect(bloc.state.status, DirectionsStatus.failure);
      expect(bloc.state.errorMessage, 'No route today.');
      expect(bloc.state.route, isNull);
    },
  );

  group('opening a maps app', () {
    test('asks for the destination, and publishes nothing on success', () async {
      final mapsApp = FakeMapsAppRepository();
      final bloc = blocWith(Success(testRoute), mapsApp: mapsApp);
      addTearDown(bloc.close);
      final states = <DirectionsState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);

      bloc.add(OpenInMapsAppRequested(to: destination));
      await Future<void>.delayed(Duration.zero);

      expect(mapsApp.opened, [destination]);
      expect(states, isEmpty);
    });

    blocTest<DirectionsBloc, DirectionsState>(
      'shows a failure once and clears it, so it can show again',
      build: () => blocWith(
        Success(testRoute),
        mapsApp: FakeMapsAppRepository(
          result: const Failed<void>(Failure('No maps app.')),
        ),
      ),
      act: (bloc) => bloc.add(OpenInMapsAppRequested(to: destination)),
      expect: () => const [
        DirectionsState(mapsAppError: 'No maps app.'),
        DirectionsState(),
      ],
    );

    blocTest<DirectionsBloc, DirectionsState>(
      'keeps the route on screen when a maps app fails to open',
      build: () => blocWith(
        Success(testRoute),
        mapsApp: FakeMapsAppRepository(
          result: const Failed<void>(Failure('No maps app.')),
        ),
      ),
      act: (bloc) async {
        bloc.add(request);
        await Future<void>.delayed(Duration.zero);
        bloc.add(OpenInMapsAppRequested(to: destination));
      },
      verify: (bloc) => expect(bloc.state.route, testRoute),
    );
  });
}
