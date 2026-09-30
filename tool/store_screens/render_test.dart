// Renders real app screens to PNG for the Play Store screenshots, without
// capturing the device screen (see CLAUDE.md: screen capture is off-limits on
// this machine). Widget tests render offscreen; this one loads the real fonts so
// text is not drawn as test boxes, and writes each scene through the golden-file
// mechanism.
//
// Run: flutter test tool/store_screens/render_test.dart --update-goldens
// Then: python tool/frame_screenshots.py   (adds background, frame, caption)
//
// Not part of the normal test run: it lives under tool/, and `flutter test`
// with no path only picks up test/.
// It is a test in all but location, so test-only APIs are the right tool here.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_screen.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/games/nonogram/nonogram_screen.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_screen.dart';
import 'package:brain_workout/games/word_search/word_search_screen.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/screens/home_screen.dart';
import 'package:brain_workout/services/progress_store.dart';
import 'package:brain_workout/theme/app_theme.dart';

const _fontDir = r'C:\dev\flutter\bin\cache\artifacts\material_fonts';

Future<void> _loadFonts() async {
  Future<ByteData> read(String path) async =>
      ByteData.view(Uint8List.fromList(await File(path).readAsBytes()).buffer);
  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black']) {
    roboto.addFont(read('$_fontDir\\roboto-$w.ttf'));
  }
  await roboto.load();

  await (FontLoader('MaterialIcons')
        ..addFont(read('$_fontDir\\materialicons-regular.otf')))
      .load();
  // Emoji (the streak flame) — the Windows colour emoji font, if present.
  const emoji = r'C:\Windows\Fonts\seguiemj.ttf';
  if (File(emoji).existsSync()) {
    await (FontLoader('Segoe UI Emoji')..addFont(read(emoji))).load();
  }
}

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A believable returning player: a streak going, a few games under way.
Map<String, Object> _seed() {
  final today = _day(DateTime.now());
  return {
    'streak_current': 6,
    'streak_best': 11,
    'streak_lastDate': today,
    'daily_date': today,
    'daily_count': 1,
    'highest_level_arrow_pictures': 57,
    'highest_level_arrow_maze': 34,
    'highest_level_word_search': 12,
    'highest_level_arrow_escape': 41,
    'highest_level_nonogram': 18,
    'highest_level_mini_sudoku': 9,
    'last_opened_arrow_pictures': 3,
    'last_opened_word_search': 2,
    'last_opened_nonogram': 1,
    for (var i = 1; i <= 20; i++) 'stars_arrow_pictures_$i': 3,
  };
}

const _captureKey = ValueKey('store_capture');

/// Writes the app at the phone's real pixel density, not the 1x a golden gets.
Future<void> capture(WidgetTester tester, String path) async {
  // Tests draw shadows as hard outlines; store shots want the real soft
  // elevation. Restored before the test ends, which the binding checks.
  final saved = debugDisableShadows;
  debugDisableShadows = false;
  for (final e in find.byType(Material).evaluate()) {
    e.renderObject?.markNeedsPaint();
  }
  await tester.pump();
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.625);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('tool/store_screens/out/$path')
      ..parent.createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
  debugDisableShadows = saved;
  await tester.pump();
}

Widget _app(Locale locale, Widget home) => RepaintBoundary(
    key: _captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light().copyWith(
        textTheme: AppTheme.light().textTheme.apply(
            fontFamily: 'Roboto', fontFamilyFallback: ['Segoe UI Emoji']),
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.1, maxScaleFactor: 1.3, child: child!),
      home: home,
    ));

Future<void> _setUp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(_seed());
  await ProgressStore.init();
  for (final g in gamesCatalog) {
    ProgressStore.instance.markHelpSeen(g.id);
  }
}

/// Lets a board screen build its board (obtain() yields a timer turn first)
/// and get past the tap guard.
Future<void> _settleBoard(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 600));
}

/// Level of a named picture in the pinned list.
int _pictureLevel(String name) =>
    [for (var i = 0; i < 300; i++) i + 1]
        .firstWhere((l) => pictureShapeForLevel(l).name == name);

void main() {
  setUpAll(_loadFonts);

  for (final lang in ['en', 'nb']) {
    final locale = Locale(lang);

    testWidgets('home $lang', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_app(locale, const HomeScreen()));
      await tester.pumpAndSettle();
      await capture(tester, '$lang/01_home.png');
    });

    testWidgets('arrow pictures $lang', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_app(locale,
          ArrowPicturesScreen(startLevel: _pictureLevel('seahorse'))));
      await _settleBoard(tester);
      await capture(tester, '$lang/02_pictures.png');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('arrow pictures revealed $lang', (tester) async {
      await _setUp(tester);
      final level = _pictureLevel('teddy_bear');
      await tester.pumpWidget(
          _app(locale, ArrowPicturesScreen(startLevel: level)));
      await _settleBoard(tester);
      final board = generatePictureBoard(level);
      final rect =
          tester.getRect(find.byKey(const ValueKey('arrow_pictures_board')));
      final cell = rect.width / board.cols;
      while (!board.isSolved) {
        final ArrowPiece p =
            board.pieces.firstWhere((p) => !p.escaped && board.isPathClear(p));
        await tester.tapAt(
            rect.topLeft + Offset((p.col + 0.5) * cell, (p.row + 0.5) * cell));
        p.escaped = true;
        await tester.pump(const Duration(milliseconds: 600));
      }
      // Past the last slide and most of the fade-in, before the dialog.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await capture(tester, '$lang/03_revealed.png');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5)); // the win dialog's timer
    });

    testWidgets('arrow maze $lang', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_app(locale, const SnakeArrowsScreen(startLevel: 34)));
      await _settleBoard(tester);
      await capture(tester, '$lang/04_maze.png');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('picture logic $lang', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_app(locale, const NonogramScreen(startLevel: 18)));
      await _settleBoard(tester);
      await capture(tester, '$lang/05_nonogram.png');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('word search $lang', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_app(locale, const WordSearchScreen(startLevel: 12)));
      await _settleBoard(tester);
      await capture(tester, '$lang/06_word_search.png');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
