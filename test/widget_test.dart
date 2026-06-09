import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/memory_match/memory_match_models.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';
import 'package:brain_workout/games/what_next/what_next_models.dart';
import 'package:brain_workout/games/wordle/wordle_models.dart';
import 'package:brain_workout/main.dart';
import 'package:brain_workout/services/progress_store.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
  });

  testWidgets('Home screen shows the game catalog', (tester) async {
    await tester.pumpWidget(const BrainWorkoutApp());

    expect(find.text('Brain Workout'), findsOneWidget);
    expect(find.text('Arrow Escape'), findsOneWidget);
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
}
