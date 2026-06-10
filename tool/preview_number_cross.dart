// Temporary visual-verification entrypoint: launches straight into the
// Number Cross screen. Run: flutter run -d windows -t tool/preview_number_cross.dart
import 'package:flutter/material.dart';

import 'package:brain_workout/games/number_cross/number_cross_screen.dart';
import 'package:brain_workout/services/progress_store.dart';
import 'package:brain_workout/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.init();
  const level = int.fromEnvironment('LEVEL', defaultValue: 1);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.1,
      maxScaleFactor: 1.3,
      child: child!,
    ),
    home: const NumberCrossScreen(startLevel: level),
  ));
}
