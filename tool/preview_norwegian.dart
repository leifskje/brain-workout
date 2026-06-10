// Temporary visual-verification entrypoint: the full app forced to Norwegian.
// Run: flutter run -d windows -t tool/preview_norwegian.dart
import 'package:flutter/material.dart';

import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/screens/home_screen.dart';
import 'package:brain_workout/services/progress_store.dart';
import 'package:brain_workout/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.init();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    locale: const Locale('nb'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.1,
      maxScaleFactor: 1.3,
      child: child!,
    ),
    home: const HomeScreen(),
  ));
}
