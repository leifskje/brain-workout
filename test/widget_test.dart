import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/memory_match/memory_match_models.dart';
import 'package:brain_workout/games/number_cross/number_cross_models.dart';
import 'package:brain_workout/games/number_cross/number_cross_screen.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';
import 'package:brain_workout/games/what_next/what_next_models.dart';
import 'package:brain_workout/games/wordle/wordle_models.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/main.dart';
import 'package:brain_workout/screens/home_screen.dart';
import 'package:brain_workout/services/app_locale.dart';
import 'package:brain_workout/services/progress_store.dart';

/// Wraps [home] in a MaterialApp with the app's localizations (English in
/// tests), for pumping a single screen.
Widget localizedApp(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
  });

  testWidgets('Home screen shows the game catalog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BrainWorkoutApp());

    expect(find.text('Brain Workout'), findsOneWidget);
    expect(find.text('Arrow Escape'), findsOneWidget);
    // Category chips and the Play next suggestion are visible; the Continue
    // row is not (nothing has been played yet).
    expect(find.text('Logic'), findsWidgets);
    expect(find.text('Words'), findsOneWidget);
    expect(find.textContaining('Play next:'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('Language menu switches the app to Norwegian', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    addTearDown(() => appLocaleOverride.value = null);

    await tester.pumpWidget(const BrainWorkoutApp());
    expect(find.text('Brain Workout'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Norsk'));
    await tester.pumpAndSettle();

    expect(find.text('Hjernetrim'), findsOneWidget);
    expect(ProgressStore.instance.appLanguageId, 'nb');

    // The choice is persisted for the next launch.
    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Følg telefonens språk'));
    await tester.pumpAndSettle();
    expect(ProgressStore.instance.appLanguageId, isNull);
  });

  testWidgets('Home screen renders in Norwegian', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('nb'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ));

    expect(find.text('Hjernetrim'), findsOneWidget);
    expect(find.text('Tallkryss'), findsOneWidget);
    expect(find.text('Logikk'), findsWidgets);
    expect(find.textContaining('Spill neste:'), findsOneWidget);
  });

  testWidgets('Home screen shows Continue for the last opened game',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'last_opened_arrow_escape': 1,
      'last_opened_number_cross': 2, // most recent wins
    });
    await ProgressStore.init();
    await tester.pumpWidget(const BrainWorkoutApp());

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Number Cross — Level 1'), findsOneWidget);
  });

  test('totalStars sums the best result per level', () {
    final store = ProgressStore.instance;
    store.recordReached('g', 3);
    store.recordStars('g', 1, 2);
    store.recordStars('g', 1, 3); // best kept
    store.recordStars('g', 2, 1);
    expect(store.totalStars('g'), 4);
  });

  test('Generated levels are always solvable', () {
    // Replay the reverse-placement order forward: every level must be clearable.
    for (var level = 1; level <= 30; level++) {
      final board = ArrowBoard.generate(level);
      expect(board.pieces, isNotEmpty, reason: 'level $level produced no arrows');

      var removed = 0;
      // Removing in reverse placement order must always find a clear path.
      for (final piece in board.pieces.reversed) {
        expect(board.isPathClear(piece), isTrue,
            reason: 'level $level is not solvable at piece ${piece.id}');
        piece.escaped = true;
        removed++;
      }
      expect(removed, board.pieces.length);
      expect(board.isSolved, isTrue);
    }
  });

  test('Snake arrow levels are always solvable', () {
    for (var level = 1; level <= 30; level++) {
      final board = SnakeBoard.generate(level);
      expect(board.arrows, isNotEmpty, reason: 'level $level produced no arrows');

      for (final arrow in board.arrows.reversed) {
        expect(board.isPathClear(arrow), isTrue,
            reason: 'snake level $level not solvable at arrow ${arrow.id}');
        arrow.escaped = true;
      }
      expect(board.isSolved, isTrue);
    }
  });

  test('Snake boards fill the grid densely on higher levels', () {
    final board = SnakeBoard.generate(12);
    final filled =
        board.arrows.fold<int>(0, (sum, a) => sum + a.cells.length);
    expect(filled / (board.rows * board.cols), greaterThan(0.5),
        reason: 'maze should be dense, not sparse');
  });

  test('Memory boards are well-formed (every symbol appears exactly twice)', () {
    for (var level = 1; level <= 10; level++) {
      final board = MemoryBoard.generate(level);
      expect(board.cards.length, board.rows * board.cols);
      expect(board.cards.length.isEven, isTrue);
      expect(board.isSolved, isFalse);

      final counts = <String, int>{};
      for (final card in board.cards) {
        counts[card.symbol] = (counts[card.symbol] ?? 0) + 1;
      }
      expect(counts.values.every((n) => n == 2), isTrue,
          reason: 'memory level $level has a non-paired symbol');
    }
  });

  test('What Comes Next: questions are well-formed', () {
    for (var level = 1; level <= 20; level++) {
      final questions = WhatNextRound.generate(level);
      expect(questions, isNotEmpty, reason: 'level $level produced no questions');
      for (final q in questions) {
        expect(q.options.length, 4, reason: 'level $level: not 4 options');
        expect(q.options.toSet().length, 4, reason: 'level $level: duplicate options');
        expect(q.options, contains(q.answer),
            reason: 'level $level: answer missing from options');
        if (q.kind == QuestionKind.number) {
          expect(q.answer > 0, isTrue, reason: 'level $level: non-positive answer');
          expect(q.options.every((o) => o > 0), isTrue,
              reason: 'level $level: non-positive option');
        }
      }
    }
  });

  test('Wordle scoring handles greens, yellows, and duplicates', () {
    // All correct.
    expect(scoreGuess('APPLE', 'APPLE'),
        everyElement(LetterState.correct));

    // No overlap at all.
    expect(scoreGuess('FUZZY', 'GRIPE'),
        everyElement(LetterState.absent));

    // PAPER vs APPLE: one green P, the rest present/absent with duplicate care.
    expect(scoreGuess('PAPER', 'APPLE'), [
      LetterState.present, // P (in word, wrong spot)
      LetterState.present, // A
      LetterState.correct, // P matches position 2
      LetterState.present, // E
      LetterState.absent, // R not in APPLE
    ]);

    // A duplicate guessed letter beyond the target's count is grey.
    // target ABCDE has one A; guess AAXYZ → first A green, second A absent.
    expect(scoreGuess('AAXYZ', 'ABCDE'), [
      LetterState.correct,
      LetterState.absent,
      LetterState.absent,
      LetterState.absent,
      LetterState.absent,
    ]);
  });

  test('Wordle stars by guess count', () {
    expect(wordleStars(1), 3);
    expect(wordleStars(3), 3);
    expect(wordleStars(4), 2);
    expect(wordleStars(6), 1);
  });

  test('Stars: recordStars keeps the best result', () {
    final store = ProgressStore.instance;
    expect(store.stars('arrow_escape', 1), 0);
    store.recordStars('arrow_escape', 1, 2);
    expect(store.stars('arrow_escape', 1), 2);
    store.recordStars('arrow_escape', 1, 1); // lower → ignored
    expect(store.stars('arrow_escape', 1), 2);
    store.recordStars('arrow_escape', 1, 3);
    expect(store.stars('arrow_escape', 1), 3);
  });

  test('Streak & daily: first play starts a streak and counts toward the goal',
      () {
    final store = ProgressStore.instance;
    expect(store.currentStreak, 0);
    expect(store.dailyCount, 0);

    store.registerPlay('memory_match');
    expect(store.currentStreak, 1);
    expect(store.dailyCount, 1);

    // A second play the same day increments the count but not the streak.
    store.registerPlay('arrow_escape');
    expect(store.currentStreak, 1);
    expect(store.dailyCount, 2);
  });

  test('Number Cross puzzles are consistent and solvable', () {
    for (var level = 1; level <= 30; level++) {
      // The constructor scans the grid for equations and throws on any
      // malformed segment, so generate() itself asserts the layout shape.
      final board = NumberCrossBoard.generate(level);
      expect(board.runs.length, greaterThanOrEqualTo(3),
          reason: 'level $level should have at least 3 equations');

      // The correct values satisfy every equation, and every number cell
      // belongs to at least one equation.
      final inRuns = <NcCell>{};
      for (final run in board.runs) {
        final a = board.cellOf(run, 0);
        final b = board.cellOf(run, 2);
        final res = board.cellOf(run, 4);
        inRuns.addAll([a, b, res]);
        expect(applyOp(board.cellOf(run, 1).op!, a.value!, b.value!),
            res.value!,
            reason: 'level $level run at (${run.r},${run.c})');
      }
      for (final row in board.cells) {
        for (final cell in row) {
          if (cell.kind == NcKind.number) {
            expect(inRuns.contains(cell), isTrue,
                reason: 'level $level has an orphan number cell');
          }
        }
      }

      expect(board.blankCount, greaterThan(0));
      expect(board.isSolved, isFalse, reason: 'level $level starts unsolved');

      // Each blank's correct value is available in the pool.
      final pool = [...board.pool];
      for (final row in board.cells) {
        for (final cell in row) {
          if (cell.kind == NcKind.number && !cell.fixed) {
            expect(pool.remove(cell.value), isTrue,
                reason: 'level $level pool missing ${cell.value}');
          }
        }
      }

      // Placing the correct values solves it.
      for (final row in board.cells) {
        for (final cell in row) {
          if (cell.kind == NcKind.number && !cell.fixed) {
            cell.placed = cell.value;
          }
        }
      }
      expect(board.isSolved, isTrue, reason: 'level $level should be solvable');
    }
  });

  testWidgets('Number Cross screen renders small and large layouts',
      (tester) async {
    // Phone-ish portrait surface; overflows would fail the test.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    for (final level in [1, 10, 30]) {
      await tester.pumpWidget(localizedApp(
          NumberCrossScreen(key: ValueKey(level), startLevel: level)));
      expect(find.text('Level $level'), findsOneWidget);
      // The pool has chips to place.
      final board = NumberCrossBoard.generate(level);
      expect(board.pool, isNotEmpty);
    }
  });

  testWidgets('Number Cross: tap-to-place and tap-to-return', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        localizedApp(const NumberCrossScreen(startLevel: 1)));
    final board = NumberCrossBoard.generate(1); // same seed as the screen's
    final poolSize = board.pool.length;
    final value = board.pool.first;

    Finder chips() => find.byType(Draggable<int>);
    expect(chips(), findsNWidgets(poolSize));

    // Tap the first pool chip (last matching text — the pool sits below the
    // grid), then an empty cell: the number moves from pool to cell.
    await tester.tap(find.text('$value').last);
    await tester.pump();
    await tester.tap(find.byType(DragTarget<int>).first);
    await tester.pump();
    expect(chips(), findsNWidgets(poolSize - 1));

    // Tapping the placed cell returns the number to the pool.
    await tester.tap(find.byType(DragTarget<int>).first);
    await tester.pump();
    expect(chips(), findsNWidgets(poolSize));
  });
}
