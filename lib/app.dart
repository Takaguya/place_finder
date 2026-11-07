import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_router.dart';
import 'core/config/app_flavor.dart';
import 'core/theme/app_theme.dart';
import 'features/places/domain/usecases/get_walking_route.dart';
import 'features/places/domain/usecases/open_in_maps_app.dart';
import 'features/places/presentation/bloc/place_search_bloc.dart';
import 'injection.dart';

class PlaceFinderApp extends StatelessWidget {
  const PlaceFinderApp({super.key});

  /// Keeps a phone-sized layout on larger screens, such as tablets.
  static const double _maxWidth = 480;

  /// Kept outside build, so that a rebuild doesn't lose the user's place.
  static final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    final flavor = AppFlavor.current;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GetWalkingRoute>(
          create: (_) => createGetWalkingRoute(),
        ),
        RepositoryProvider<OpenInMapsApp>(create: (_) => createOpenInMapsApp()),
      ],
      child: BlocProvider(
        create: (_) => createPlaceSearchBloc()..add(const PlaceSearchStarted()),
        child: MaterialApp.router(
          title: flavor.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: _router,
          builder: (context, child) {
            final app = ColoredBox(
              color: AppColors.ink,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: child,
                ),
              ),
            );
            if (flavor.isProduction) return app;
            return Banner(
              message: flavor.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: app,
            );
          },
        ),
      ),
    );
  }
}
