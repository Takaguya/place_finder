import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/places/domain/usecases/get_walking_route.dart';
import 'features/places/domain/usecases/open_in_maps_app.dart';
import 'features/places/presentation/bloc/place_search_bloc.dart';
import 'features/places/presentation/place_routes.dart';
import 'injection.dart';

class PlaceFinderApp extends StatelessWidget {
  const PlaceFinderApp({super.key});

  /// Keeps a phone-sized layout on larger screens, such as tablets.
  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GetWalkingRoute>(
          create: (_) => createGetWalkingRoute(),
        ),
        RepositoryProvider<OpenInMapsApp>(create: (_) => createOpenInMapsApp()),
      ],
      child: BlocProvider(
        create: (_) => createPlaceSearchBloc()..add(const PlaceSearchStarted()),
        child: MaterialApp(
          title: 'Place Finder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: (context, child) => ColoredBox(
            color: AppColors.ink,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: child,
              ),
            ),
          ),
          initialRoute: PlaceRoutes.search,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
