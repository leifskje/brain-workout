// Visual-verification entrypoint: launch one game directly.
// flutter run -d windows -t tool/preview_game.dart \
//   --dart-define=GAME=word_search --dart-define=LEVEL=3 --dart-define=LANG=en
import 'package:flutter/material.dart';

import 'package:brain_workout/games/mini_sudoku/mini_sudoku_screen.dart';
import 'package:brain_workout/games/word_search/word_search_screen.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/services/progress_store.dart';
import 'package:brain_workout/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.init();
  const game = String.fromEnvironment('GAME', defaultValue: 'word_search');
  const level = int.fromEnvironment('LEVEL', defaultValue: 1);
  const lang = String.fromEnvironment('LANG', defaultValue: 'en');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    locale: const Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.1,
      maxScaleFactor: 1.3,
      child: child!,
    ),
    home: switch (game) {
      'mini_sudoku' => const MiniSudokuScreen(startLevel: level),
      _ => const WordSearchScreen(startLevel: level),
    },
  ));
}
