import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/crack_code/crack_code_models.dart';
import 'package:brain_workout/games/crack_code/crack_code_screen.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/games/memory_match/memory_match_models.dart';
import 'package:brain_workout/games/number_cross/number_cross_models.dart';
import 'package:brain_workout/games/number_cross/number_cross_screen.dart';
import 'package:brain_workout/games/simon/simon_models.dart';
import 'package:brain_workout/games/simon/simon_screen.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_screen.dart';
import 'package:brain_workout/games/trail/trail_models.dart';
import 'package:brain_workout/games/trail/trail_screen.dart';
import 'package:brain_workout/games/what_next/what_next_models.dart';
import 'package:brain_workout/games/merge/merge_models.dart';
import 'package:brain_workout/games/merge/merge_screen.dart';
import 'package:brain_workout/games/mini_sudoku/mini_sudoku_models.dart';
import 'package:brain_workout/games/mini_sudoku/mini_sudoku_screen.dart';
import 'package:brain_workout/games/word_scramble/word_scramble_models.dart';
import 'package:brain_workout/games/word_scramble/word_scramble_screen.dart';
import 'package:brain_workout/games/word_search/word_search_models.dart';
import 'package:brain_workout/games/word_search/word_search_screen.dart';
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
    // Keep the first-open "how to play" sheet out of unrelated tests.
    for (final game in gamesCatalog) {
      ProgressStore.instance.markHelpSeen(game.id);
    }
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

  test('Snake difficulty rises with level and stays on target', () {
    // Guards the generator's difficulty gate. Size and density are poor proxies
    // — level 42 once measured as the *easiest* board in the game, at 14x20 with
    // 7.5 arrows ready to fire at every step — so assert on branching factor,
    // which is what the gate targets.
    double branchingAt(int level) =>
        SnakeBoard.generate(level).measureDifficulty().meanBranching;

    // Compare distant levels: adjacent ones legitimately vary, and asserting on
    // a 0.1 gap would just be flaky.
    expect(branchingAt(4) - branchingAt(42), greaterThan(0.5),
        reason: 'late levels must force real planning, not just be big');
    expect(branchingAt(42), lessThan(3.0),
        reason: 'late levels should rarely offer an obvious move');

    // The target curve itself must keep descending.
    for (var level = 2; level <= 60; level++) {
      expect(snakeTargetBranchingForLevel(level),
          lessThanOrEqualTo(snakeTargetBranchingForLevel(level - 1)),
          reason: 'difficulty target must not ease off at level $level');
    }

    for (final level in [1, 10, 20, 30, 40]) {
      final board = SnakeBoard.generate(level);
      final d = board.measureDifficulty();
      expect(d.solvableGreedily, isTrue, reason: 'level $level got stuck');
      // The generator can't always hit the target; it must land near it.
      expect((d.meanBranching - snakeTargetBranchingForLevel(level)).abs(),
          lessThan(0.8),
          reason: 'level $level drifted off its difficulty target');
      // A patchy board reads as unfinished even when it plays well — and where
      // the gaps sit matters more than how many there are, so bound both.
      expect(board.fillFraction, greaterThan(0.65),
          reason: 'level $level left too much of the grid bare');
      expect(board.largestEmptyFraction, lessThan(0.2),
          reason: 'level $level pooled its empty cells into one visible void');
    }

    // Late levels also allow less margin for error and no trivial filler.
    expect(snakeConfigForLevel(42).hearts, lessThan(snakeConfigForLevel(1).hearts));
    expect(snakeConfigForLevel(42).minLength,
        greaterThan(snakeConfigForLevel(1).minLength));
  });

  testWidgets('Arrow Maze: tapping a clear arrow slithers it off the board',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 1)));
    final board = SnakeBoard.generate(1); // same seed as the screen
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

    // The painter taps by position, so aim at the centre of a body cell.
    final rect = tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    final cell = rect.width / board.cols;
    final arrow = board.arrows.firstWhere(board.isPathClear);
    final target = arrow.cells.first;
    await tester.tapAt(rect.topLeft +
        Offset((target.col + 0.5) * cell, (target.row + 0.5) * cell));

    // Pump mid-flight as well as after: the escape branch of the painter
    // samples the body along its rail and is a separate path from the resting
    // one, so both need to render without throwing.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // A clear path costs no heart — a blocked tap would have emptied one.
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
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

  test('Word Search boards contain every target word', () {
    for (final language in ['en', 'nb']) {
      for (var level = 1; level <= 30; level++) {
        final board = WordSearchBoard.generate(level, language);
        final cfg = wordSearchConfigForLevel(level);
        expect(board.words.length, cfg.words,
            reason: '$language level $level word count');
        expect(board.size, cfg.size);

        for (final w in board.words) {
          // The placement actually spells the word on the grid.
          final spelled =
              [for (final (r, c) in w.cells) board.grid[r][c]].join();
          expect(spelled, w.word,
              reason: '$language level $level word ${w.word}');
          // And selecting those cells finds it.
          expect(board.trySelect(w.cells)?.word, w.word);
        }
        expect(board.isSolved, isTrue);

        // Below the crossing threshold, words never share a cell — fully
        // separate words are much easier to spot.
        if (!cfg.allowCrossings) {
          final seen = <(int, int)>{};
          for (final w in board.words) {
            for (final cell in w.cells) {
              expect(seen.add(cell), isTrue,
                  reason:
                      '$language level $level: unexpected crossing at $cell');
            }
          }
        }

        // Deterministic: same level + language → same board.
        final again = WordSearchBoard.generate(level, language);
        expect(again.grid.toString(), board.grid.toString(),
            reason: '$language level $level should be retry-stable');
      }
    }
  });

  test('Mini Sudoku puzzles are valid with a unique solution', () {
    for (var level = 1; level <= 30; level++) {
      final board = MiniSudokuBoard.generate(level);
      final n = board.size;

      // The solution is a valid sudoku: each row/column/box holds 1..n once.
      final want = List.generate(n, (i) => i + 1);
      for (var r = 0; r < n; r++) {
        final row = [for (var c = 0; c < n; c++) board.cells[r][c].solution]
          ..sort();
        expect(row, want, reason: 'level $level row $r');
      }
      for (var c = 0; c < n; c++) {
        final col = [for (var r = 0; r < n; r++) board.cells[r][c].solution]
          ..sort();
        expect(col, want, reason: 'level $level col $c');
      }
      for (var br = 0; br < n; br += board.boxRows) {
        for (var bc = 0; bc < n; bc += board.boxCols) {
          final box = [
            for (var r = br; r < br + board.boxRows; r++)
              for (var c = bc; c < bc + board.boxCols; c++)
                board.cells[r][c].solution
          ]..sort();
          expect(box, want, reason: 'level $level box ($br,$bc)');
        }
      }

      expect(board.blankCount, greaterThan(0));
      expect(board.isSolved, isFalse, reason: 'level $level starts unsolved');

      // No given conflicts, and entering the solution solves it.
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          expect(board.hasConflict(r, c), isFalse);
          final cell = board.cells[r][c];
          if (!cell.given) cell.entered = cell.solution;
        }
      }
      expect(board.isSolved, isTrue, reason: 'level $level should solve');
    }
  });

  test('Simon sequences are well-formed and the tap flow works', () {
    for (var level = 1; level <= 30; level++) {
      final cfg = simonConfigForLevel(level);
      final game = SimonGame.generate(level);
      expect(game.sequence.length, cfg.targetLength,
          reason: 'level $level length');
      for (final b in game.sequence) {
        expect(b, inInclusiveRange(0, cfg.buttons - 1));
      }
      // Never the same button three times in a row.
      for (var i = 2; i < game.sequence.length; i++) {
        expect(
            game.sequence[i] == game.sequence[i - 1] &&
                game.sequence[i] == game.sequence[i - 2],
            isFalse,
            reason: 'level $level triple at $i');
      }
      // Deterministic.
      expect(SimonGame.generate(level).sequence, game.sequence);

      // Playing every round correctly wins the level.
      var taps = 0;
      while (true) {
        final result = game.tap(game.sequence[game.inputPos]);
        taps++;
        if (result == SimonTap.won) break;
        expect(taps, lessThan(1000)); // safety net
      }
      expect(game.round, game.sequence.length);
    }

    // A wrong tap resets the round's input.
    final game = SimonGame.generate(1);
    final wrong = (game.sequence[0] + 1) % 4;
    expect(game.tap(wrong), SimonTap.wrong);
    expect(game.inputPos, 0);
    expect(game.tap(game.sequence[0]),
        game.sequence.length == 1 ? SimonTap.won : anything);
  });

  testWidgets('Simon: watching a round then repeating it advances',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const SimonScreen(startLevel: 1)));
    final game = SimonGame.generate(1); // same seed as the screen's
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Round 1 of ${game.sequence.length}'), findsOneWidget);
    expect(find.text('Watch closely…'), findsOneWidget);

    // Let the lead-in + round-1 playback finish (700ms + flash + gap).
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your turn!'), findsOneWidget);

    // Repeat the one-button sequence → round 2 plays.
    await tester.tap(find.byKey(ValueKey('simon_btn_${game.sequence[0]}')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Round 2 of ${game.sequence.length}'), findsOneWidget);

    // Drain pending playback timers before the test ends.
    await tester.pump(const Duration(seconds: 5));
  });

  test('Word Scramble rounds are well-formed in both languages', () {
    for (final language in ['en', 'nb']) {
      for (var level = 1; level <= 30; level++) {
        final cfg = wordScrambleConfigForLevel(level);
        final round = generateScrambleRound(level, language);
        expect(round.length, cfg.words,
            reason: '$language level $level word count');
        for (final w in round) {
          expect(w.word.length, inInclusiveRange(cfg.minLen, cfg.maxLen));
          // The scramble is a permutation of the word, and never the word.
          expect([...w.letters]..sort(), [...w.word.split('')]..sort());
          expect(w.letters.join(), isNot(w.word));
        }
        // No duplicate words in a round; deterministic regeneration.
        expect({for (final w in round) w.word}.length, round.length);
        expect(
            [for (final w in generateScrambleRound(level, language)) w.word],
            [for (final w in round) w.word]);
      }
    }
  });

  test('Crack the Code: codes are valid and scoring is correct', () {
    for (var level = 1; level <= 30; level++) {
      final cfg = crackCodeConfigForLevel(level);
      final game = CrackCodeGame.generate(level);
      expect(game.code.length, cfg.length);
      expect(game.code.toSet().length, cfg.length, reason: 'distinct digits');
      for (final d in game.code) {
        expect(d, inInclusiveRange(1, cfg.symbols));
      }
      expect(CrackCodeGame.generate(level).code, game.code,
          reason: 'level $level deterministic');

      // Guessing the code itself wins with all-exact.
      final result = game.submit(game.code);
      expect(result.exact, cfg.length);
      expect(result.present, 0);
      expect(game.isWon, isTrue);
    }

    // Scoring: a rotation of the code is all-present, no exact.
    final game = CrackCodeGame.generate(5);
    final rotated = [...game.code.skip(1), game.code.first];
    final r = game.submit(rotated);
    expect(r.exact, 0);
    expect(r.present, game.code.length);
  });

  test('Trail boards are ordered, labelled, and spaced', () {
    for (var level = 1; level <= 30; level++) {
      final cfg = trailConfigForLevel(level);
      final board = TrailBoard.generate(level);
      expect(board.nodes.length, cfg.count);

      for (var i = 0; i < board.nodes.length; i++) {
        final n = board.nodes[i];
        expect(n.x, inInclusiveRange(0, 1));
        expect(n.y, inInclusiveRange(0, 1));
        final expected = !cfg.alternating
            ? '${i + 1}'
            : i.isEven
                ? '${i ~/ 2 + 1}'
                : String.fromCharCode('A'.codeUnitAt(0) + i ~/ 2);
        expect(n.label, expected, reason: 'level $level node $i');
        // Nodes never overlap.
        for (var j = 0; j < i; j++) {
          final dx = board.nodes[j].x - n.x, dy = board.nodes[j].y - n.y;
          expect(math.sqrt(dx * dx + dy * dy), greaterThan(0.08),
              reason: 'level $level nodes $i/$j too close');
        }
      }
      expect(TrailBoard.generate(level).nodes.first.x,
          board.nodes.first.x, reason: 'deterministic');
    }
  });

  testWidgets('Word Scramble: spelling the word advances to the next',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(localizedApp(const WordScrambleScreen(startLevel: 1)));
    final round = generateScrambleRound(1, 'en'); // same seed as the screen
    expect(find.text('Word 1 of ${round.length}'), findsOneWidget);

    // Tap the tiles in the order that spells the word.
    final word = round.first;
    final used = List<bool>.filled(word.letters.length, false);
    for (final ch in word.word.split('')) {
      final i = List.generate(word.letters.length, (i) => i)
          .firstWhere((i) => !used[i] && word.letters[i] == ch);
      used[i] = true;
      await tester.tap(find.byKey(ValueKey('ws_tile_$i')));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Word 2 of ${round.length}'), findsOneWidget);
  });

  testWidgets('Crack the Code: guessing the code wins', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(localizedApp(const CrackCodeScreen(startLevel: 1)));
    final game = CrackCodeGame.generate(1); // same seed as the screen
    expect(find.text('Guess 1 of ${game.maxGuesses}'), findsOneWidget);

    for (final d in game.code) {
      await tester.tap(find.byKey(ValueKey('cc_pad_$d')));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Well done!'), findsOneWidget);
  });

  testWidgets('Trail: wrong tap costs a heart, ordered taps win',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const TrailScreen(startLevel: 1)));
    final board = TrailBoard.generate(1); // same seed as the screen
    expect(find.text('Next: 1'), findsOneWidget);

    // Wrong node first: a heart is lost.
    await tester.tap(find.byKey(const ValueKey('trail_node_2')));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));

    // Then tap everything in order — win dialog appears.
    for (var i = 0; i < board.nodes.length; i++) {
      await tester.tap(find.byKey(ValueKey('trail_node_$i')));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Well done!'), findsOneWidget);
  });

  test('Merge: collapseLine slides and merges once per move', () {
    expect(collapseLine([2, 2, 0, 0]).line, [4, 0, 0, 0]);
    expect(collapseLine([2, 2, 2, 0]).line, [4, 2, 0, 0]);
    expect(collapseLine([2, 2, 2, 2]).line, [4, 4, 0, 0]);
    expect(collapseLine([4, 0, 0, 0]).line, [4, 0, 0, 0]);
    expect(collapseLine([2, 4, 0, 0]).line, [2, 4, 0, 0]);
    expect(collapseLine([0, 0, 2, 2]).line, [4, 0, 0, 0]);
    expect(collapseLine([2, 2, 0, 0]).gained, 4);
    expect(collapseLine([2, 4, 0, 0]).gained, 0);
  });

  test('Merge: generation, moves, win and stuck detection', () {
    for (var level = 1; level <= 30; level++) {
      final cfg = mergeConfigForLevel(level);
      final game = MergeGame.generate(level);
      expect(game.size, cfg.size);
      expect(game.target, 1 << (5 + level - 1).clamp(5, 11));

      // Exactly two opening tiles, each a 2 or a 4.
      final tiles = [
        for (final row in game.grid)
          for (final v in row)
            if (v != 0) v
      ];
      expect(tiles.length, 2);
      for (final v in tiles) {
        expect(v == 2 || v == 4, isTrue);
      }
      expect(game.reachedTarget, isFalse);
      expect(game.hasMoves, isTrue);

      // Deterministic opening.
      expect(MergeGame.generate(level).grid.toString(), game.grid.toString());
    }

    // A real move merges, scores, spawns, and can reach the target.
    final g = MergeGame.fromGrid([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ], target: 4);
    expect(g.move(MergeDirection.left), isTrue);
    expect(g.grid[0][0], 4);
    expect(g.score, 4);
    expect(g.reachedTarget, isTrue);
    // The merge freed cells, so a tile spawned: 1 (merged) + 1 (spawn) = 2.
    final count = [
      for (final row in g.grid)
        for (final v in row)
          if (v != 0) v
    ].length;
    expect(count, 2);

    // A move that changes nothing is a no-op (no spawn).
    final noop = MergeGame.fromGrid([
      [2, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    expect(noop.move(MergeDirection.left), isFalse);
    expect(noop.grid[0][0], 2);

    // A full board with no equal neighbours has no moves.
    final stuck = MergeGame.fromGrid([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);
    expect(stuck.hasMoves, isFalse);
  });

  test('Merge: planSlides describes the tile motion', () {
    // Two 2s in a row slide to column 0; the second merges into the first.
    final slides = planSlides([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ], MergeDirection.left);
    final top = slides.where((s) => s.fromRow == 0).toList();
    expect(top.length, 2);
    expect(top.every((s) => s.toRow == 0 && s.toCol == 0), isTrue);
    expect(top.where((s) => s.merged).length, 1);

    // A board already settled to the left doesn't change.
    expect(
        willChange([
          [2, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ], MergeDirection.left),
        isFalse);
  });

  testWidgets('Merge screen renders and the arrow pad responds',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const MergeScreen(startLevel: 1)));
    // Goal shown as a mini target tile (32 only appears there at level 1).
    expect(find.text('32'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);

    // Tapping an arrow slides the board (animates) without error.
    await tester.tap(find.byKey(const ValueKey('merge_left')));
    await tester.pump(); // start the slide
    await tester.pump(const Duration(milliseconds: 200)); // finish it
    await tester.pumpAndSettle(); // settle pops
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('How to play: shown once on first open, reopenable via ?',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    // Fresh prefs — nothing marked seen.
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();

    await tester.pumpWidget(
        localizedApp(const NumberCrossScreen(key: ValueKey(1))));
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsOneWidget);

    await tester.tap(find.text('Got it!'));
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsNothing);

    // Second open: not shown again.
    await tester.pumpWidget(
        localizedApp(const NumberCrossScreen(key: ValueKey(2))));
    await tester.pump();
    expect(find.text('How to play'), findsNothing);

    // But the ? button brings it back.
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsOneWidget);
  });

  testWidgets('Word Search and Mini Sudoku screens render', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    for (final level in [1, 5, 12]) {
      await tester.pumpWidget(localizedApp(
          WordSearchScreen(key: ValueKey('ws$level'), startLevel: level)));
      expect(find.text('Level $level'), findsOneWidget);
      final board = WordSearchBoard.generate(level, 'en');
      expect(find.text('Found 0 of ${board.words.length}'), findsOneWidget);

      await tester.pumpWidget(localizedApp(
          MiniSudokuScreen(key: ValueKey('ms$level'), startLevel: level)));
      expect(find.text('Level $level'), findsOneWidget);
      // The number pad covers 1..size.
      final n = miniSudokuConfigForLevel(level).size;
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
      expect(find.widgetWithText(InkWell, '$n'), findsWidgets);
    }
  });

  testWidgets('Word Search: dragging across a word finds it', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(localizedApp(const WordSearchScreen(startLevel: 1)));
    final board = WordSearchBoard.generate(1, 'en'); // same seed as screen
    final word = board.words.first;

    // The grid is the screen's only pan-handling GestureDetector; cell
    // geometry mirrors the screen's LayoutBuilder math (8px panel padding).
    final grid = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onPanStart != null);
    expect(grid, findsOneWidget);
    final rect = tester.getRect(grid);
    const pad = 8.0;
    final cell = (math.min(rect.width, rect.height) - pad * 2) / board.size;
    Offset center(int r, int c) => rect.topLeft +
        Offset(pad + c * cell + cell / 2, pad + r * cell + cell / 2);

    final cells = word.cells;
    final (r0, c0) = cells.first;
    final (r1, c1) = cells.last;
    await tester.timedDragFrom(center(r0, c0),
        center(r1, c1) - center(r0, c0), const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Found 1 of ${board.words.length}'), findsOneWidget);
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
