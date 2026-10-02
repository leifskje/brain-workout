// Bridges: puzzles are kept only if the solver finishes them without guessing,
// which also proves the solution unique. The uniqueness claim is checked
// against an independent exhaustive counter rather than assumed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/bridges/bridges_models.dart';
import 'package:brain_workout/games/bridges/bridges_screen.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/main.dart';
import 'package:brain_workout/services/progress_store.dart';

Widget localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

String fingerprint(BridgesBoard b) =>
    '${b.islands.map((s) => '${s.row},${s.col},${s.need}').join(';')}'
    '|${b.solution.join()}';

/// Checks [values] against the rules directly, not via the solver.
void expectValidSolution(BridgesBoard b, List<int> values, String why) {
  for (var i = 0; i < b.islands.length; i++) {
    var sum = 0;
    for (var e = 0; e < b.edges.length; e++) {
      if (b.edges[e].a == i || b.edges[e].b == i) sum += values[e];
    }
    expect(sum, b.islands[i].need, reason: '$why: island $i count');
  }
  for (var e = 0; e < b.edges.length; e++) {
    expect(values[e], inInclusiveRange(0, 2), reason: why);
    if (values[e] == 0) continue;
    for (final f in b.crossings[e]) {
      expect(values[f], 0, reason: '$why: edges $e and $f cross');
    }
  }
  expect(
    bridgesConnected(b.islands.length, b.edges, values),
    isTrue,
    reason: '$why: not connected',
  );
}

/// Where on screen a board cell's centre is, from the painted board's rect —
/// an observable outside the layout maths, so this is not the screen's own
/// arithmetic checking itself.
Offset cellCentre(WidgetTester tester, BridgesBoard b, int r, int c) {
  final rect = tester.getRect(find.byKey(const ValueKey('bridges_board')));
  final cell = rect.width / b.cols;
  return rect.topLeft + Offset((c + 0.5) * cell, (r + 0.5) * cell);
}

/// A point on the water under edge [e], nudged along the bridge: where two
/// possible bridges cross, the dead centre of the cell is a genuine tie.
Offset waterOf(WidgetTester tester, BridgesBoard b, int e) {
  final edge = b.edges[e];
  final (r, c) = edge.cells[edge.cells.length ~/ 2];
  final cell =
      tester.getRect(find.byKey(const ValueKey('bridges_board'))).width /
      b.cols;
  final nudge = edge.horizontal ? Offset(cell * 0.3, 0) : Offset(0, cell * 0.3);
  return cellCentre(tester, b, r, c) + nudge;
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
    for (final game in gamesCatalog) {
      ProgressStore.instance.markHelpSeen(game.id);
    }
  });

  test('The worked example from the plan solves by counting alone', () {
    // (4) . . . (3)
    //
    // (3) . . . (2)
    const islands = [
      Island(0, 0, 4),
      Island(0, 4, 3),
      Island(3, 0, 3),
      Island(3, 4, 2),
    ];
    final edges = visibleEdges(4, 5, islands);
    final result = solveBridges(islands, edges, crossingsFor(edges, islands));
    expect(result.solved, isTrue);
    expect(result.advancedSteps, 0);
    int value(int a, int b) =>
        result.values[edges.indexWhere((e) => e.a == a && e.b == b)];
    expect(value(0, 1), 2);
    expect(value(0, 2), 2);
    expect(value(2, 3), 1);
    expect(value(1, 3), 1);
  });

  test(
    'Two 1s side by side are never joined: the group would be sealed off',
    () {
      // (1) . (1)
      //
      // (2) . (2)
      // Counting allows a 1-1 bridge, but it would seal those two off from the
      // 2s, so each 1 must go down instead.
      const islands = [
        Island(0, 0, 1),
        Island(0, 2, 1),
        Island(2, 0, 2),
        Island(2, 2, 2),
      ];
      final edges = visibleEdges(3, 3, islands);
      final result = solveBridges(islands, edges, crossingsFor(edges, islands));
      expect(result.solved, isTrue);
      expect(
        result.advancedSteps,
        greaterThan(0),
        reason: 'needs the connectivity rule, not just counting',
      );
      expect(result.values[edges.indexWhere((e) => e.a == 0 && e.b == 1)], 0);
    },
  );

  test('Levels 1-40 are guess-free, valid and deterministic', () {
    for (var level = 1; level <= 40; level++) {
      final board = BridgesBoard.generate(level);
      final cfg = bridgesConfigForLevel(level);
      expect(board.rows, cfg.rows);
      expect(board.cols, cfg.cols);
      final result = solveBridges(board.islands, board.edges, board.crossings);
      expect(result.solved, isTrue, reason: 'level $level needs a guess');
      expect(
        result.values,
        board.solution,
        reason: 'level $level: solver found a different solution',
      );
      expectValidSolution(board, board.solution, 'level $level');
      expect(
        board.islands.length,
        greaterThanOrEqualTo(cfg.islands * 0.85),
        reason: 'level $level fell back to a tiny board',
      );
      expect(
        fingerprint(BridgesBoard.generate(level)),
        fingerprint(board),
        reason: 'level $level is not retry-stable',
      );
    }
  });

  test('Solver-solvable really does mean a unique solution', () {
    // Exhaustive search is only affordable on the small early boards.
    for (var level = 1; level <= 8; level++) {
      final b = BridgesBoard.generate(level);
      expect(
        countBridgesSolutions(b.islands, b.edges, b.crossings),
        1,
        reason: 'level $level has more than one solution',
      );
    }
  });

  test('Difficulty climbs past the early levels and stays on target', () {
    int steps(int level) {
      final b = BridgesBoard.generate(level);
      return solveBridges(b.islands, b.edges, b.crossings).advancedSteps;
    }

    var onTarget = 0;
    for (var level = 1; level <= 40; level++) {
      if (steps(level) == bridgesConfigForLevel(level).targetAdvanced) {
        onTarget++;
      }
    }
    // A target outside the pool degrades silently to "closest found"; this is
    // what catches a curve that has flattened that way.
    expect(onTarget, greaterThanOrEqualTo(36));
    final early = [for (var l = 1; l <= 5; l++) steps(l)];
    final late = [for (var l = 31; l <= 40; l++) steps(l)];
    expect(
      late.reduce((a, b) => a + b) / late.length,
      greaterThan(early.reduce((a, b) => a + b) / early.length + 3),
    );
  });

  test('Bridges cycle, refuse to cross, and save and restore', () {
    final board = BridgesBoard.generate(20);
    final e = Iterable<int>.generate(
      board.edges.length,
    ).firstWhere((e) => board.crossings[e].isNotEmpty);
    final f = board.crossings[e].first;
    expect(board.cycle(e), isTrue);
    expect(board.counts[e], 1);
    expect(board.cycle(f), isFalse, reason: 'f crosses a built bridge');
    expect(board.counts[f], 0);
    expect(board.cycle(e), isTrue);
    expect(board.counts[e], 2);

    final restored = BridgesBoard.generate(20)
      ..applyCountsJson(board.countsJson());
    expect(restored.counts, board.counts);
    expect(board.cycle(e), isTrue);
    expect(board.counts[e], 0);
    expect(board.cycle(f), isTrue, reason: 'nothing crosses it any more');

    final other = BridgesBoard.generate(1); // a different size
    expect(other.applyCountsJson(board.countsJson()), isFalse);
    expect(other.hasProgress, isFalse);
  });

  testWidgets('Bridges is on the home screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BrainWorkoutApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bridges'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bridges'), findsOneWidget);
  });

  testWidgets(
    'The biggest board fits a small phone at the largest text scale',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0; // 360x640 logical
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final level in [1, 21]) {
        await tester.pumpWidget(localizedApp(BridgesScreen(startLevel: level)));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'level $level overflowed on a small phone',
        );
        expect(
          find.byKey(const ValueKey('bridges_board')).hitTestable(),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('The biggest board stays legible on an ordinary phone', (
    tester,
  ) async {
    // Measured on a typical phone, not the small one above: the test font
    // draws every glyph a full em wide, so there the hint line wraps to eight
    // lines and squeezes the board far more than real text would.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625; // ~411x869 logical
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const BridgesScreen(startLevel: 21)));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(const ValueKey('bridges_board')));
    // Comfortably above the ~22dp legibility floor used across the app.
    expect(
      rect.width / bridgesConfigForLevel(21).cols,
      greaterThanOrEqualTo(28),
    );
  });

  testWidgets(
    'Tapping the water between islands builds the solution and wins',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(localizedApp(const BridgesScreen(startLevel: 5)));
      await tester.pumpAndSettle();

      final board = BridgesBoard.generate(5); // same seed as the screen's
      for (var e = 0; e < board.edges.length; e++) {
        for (var k = 0; k < board.solution[e]; k++) {
          await tester.tapAt(waterOf(tester, board, e));
          await tester.pump();
        }
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Well done!'), findsOneWidget);
      // Never a wrong bridge and never a check: three stars.
      expect(ProgressStore.instance.stars('bridges', 5), 3);
    },
  );

  testWidgets('Tapping island then neighbour builds bridges, and they resume', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const BridgesScreen(startLevel: 3)));
    await tester.pumpAndSettle();

    final board = BridgesBoard.generate(3);
    // Build every solution bridge but the last, island to island.
    final built = [
      for (var e = 0; e < board.edges.length; e++)
        if (board.solution[e] > 0) e,
    ];
    final skipped = built.removeLast();
    for (final e in built) {
      final a = board.islands[board.edges[e].a];
      final b = board.islands[board.edges[e].b];
      for (var k = 0; k < board.solution[e]; k++) {
        await tester.tapAt(cellCentre(tester, board, a.row, a.col));
        await tester.pump();
        await tester.tapAt(cellCentre(tester, board, b.row, b.col));
        await tester.pump();
      }
    }
    expect(find.text('Well done!'), findsNothing);

    // Leaving saves; coming back restores exactly those bridges.
    await tester.pumpWidget(const SizedBox());
    final saved = ProgressStore.instance.loadBoard('bridges', 3)!;
    final expected = List.of(board.solution)..[skipped] = 0;
    expect(saved['counts'], expected);

    await tester.pumpWidget(localizedApp(const BridgesScreen(startLevel: 3)));
    await tester.pumpAndSettle();
    for (var k = 0; k < board.solution[skipped]; k++) {
      await tester.tapAt(waterOf(tester, board, skipped));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Well done!'), findsOneWidget);
  });
}
