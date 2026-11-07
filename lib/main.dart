import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The map and bottom sheet need a tall screen to fit together.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PlaceFinderApp());
}
