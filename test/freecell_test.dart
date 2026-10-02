// FreeCell: every deal is proven winnable by the solver, and the tap tests
// play those proofs through the real screen.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show debugSemanticsDisableAnimations;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/freecell/freecell_models.dart';
import 'package:brain_workout/games/freecell/freecell_screen.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/main.dart';
import 'package:brain_workout/services/progress_store.dart';

Widget localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

const _c = 0, _d = 1, _h = 2, _s = 3;

Finder cardKey(int card) => find.byKey(ValueKey('fc_card_$card'));

/// A point inside the visible top strip of [card], from its rendered rect.
Offset cardPoint(WidgetTester tester, int card) {
  final r = tester.getRect(cardKey(card));
  return r.topCenter + Offset(0, r.height < 16 ? r.height / 2 : 8);
}

/// Lets slides and auto-moves finish, without pumpAndSettle (the win dialog
/// never settles).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.binding.hasScheduledFrame) break;
  }
}

/// Plays [m] by tapping: the moving card, then the destination.
Future<void> tapMove(
  WidgetTester tester,
  FreeCellPosition pos,
  FreeCellMove m,
) async {
  final card = pos.movingCard(m);
  await tester.tapAt(cardPoint(tester, card));
  await tester.pump();
  final Offset target;
  switch (m.toKind) {
    case PileKind.cell:
      target = tester.getCenter(find.byKey(ValueKey('fc_cell_${m.to}')));
    case PileKind.foundation:
      target = tester.getCenter(find.byKey(ValueKey('fc_found_${m.to}')));
    case PileKind.cascade:
      final dest = pos.cascades[m.to];
      target = dest.isEmpty
          ? tester
                    .getRect(find.byKey(ValueKey('fc_cascade_${m.to}')))
                    .topCenter +
                const Offset(0, 12)
          : cardPoint(tester, dest.last);
  }
  await tester.tapAt(target);
  await settle(tester);
  pos
    ..apply(m)
    ..autoPlay();
}

Map<int, Rect> cardRects(WidgetTester tester) => {
  for (var c = 0; c < 52; c++) c: tester.getRect(cardKey(c)),
};

void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
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

  test('Levels 1-40 are proven winnable, on target and deterministic', () {
    var onTarget = 0;
    for (var level = 1; level <= 40; level++) {
      final deal = FreeCellDeal.generate(level);
      final cfg = freeCellConfigForLevel(level);
      expect(deal.cells, cfg.cells);
      expect(deal.deck.toSet().length, 52);
      // Checked move by move against the rules, with the level's own cells.
      expect(
        replayWins(FreeCellPosition.deal(deal.deck, deal.cells), deal.solution),
        isTrue,
        reason: 'level $level: the proof does not replay',
      );
      expect(
        replayWins(FreeCellPosition.deal(deal.deck, deal.need), deal.solution),
        isTrue,
        reason: 'level $level: does not win with the cells it claims to need',
      );
      if (cfg.needAtMost
          ? deal.need <= cfg.targetNeed
          : deal.need == cfg.targetNeed) {
        onTarget++;
      }
      expect(
        FreeCellDeal.generate(level).deck,
        deal.deck,
        reason: 'level $level is not retry-stable',
      );
    }
    // A target outside the pool degrades silently to "closest found".
    expect(onTarget, greaterThanOrEqualTo(38));
  });

  test('Difficulty climbs: fewer cells and less room for error later on', () {
    final early = freeCellConfigForLevel(1);
    final late = freeCellConfigForLevel(80);
    expect(late.cells, lessThan(early.cells));
    var slack = 99, cells = 99;
    for (var level = 1; level <= 120; level++) {
      final cfg = freeCellConfigForLevel(level);
      expect(cfg.slack, lessThanOrEqualTo(slack), reason: 'level $level');
      expect(cfg.cells, lessThanOrEqualTo(cells), reason: 'level $level');
      slack = cfg.slack;
      cells = cfg.cells;
    }
    // A needs-every-cell deal really does fail with one cell fewer.
    final d = FreeCellDeal.generate(40);
    expect(d.need, d.cells);
    expect(
      solveFreeCell(
        FreeCellPosition.deal(d.deck, d.need - 1),
        maxNodes: needProbeNodes,
      ).solved,
      isFalse,
    );
  });

  test('Cascades build down in alternating colours', () {
    expect(stacksOn(cardOf(_h, 6), cardOf(_s, 7)), isTrue);
    expect(stacksOn(cardOf(_d, 6), cardOf(_c, 7)), isTrue);
    expect(
      stacksOn(cardOf(_h, 6), cardOf(_d, 7)),
      isFalse,
      reason: 'red on red',
    );
    expect(stacksOn(cardOf(_s, 6), cardOf(_c, 7)), isFalse);
    expect(stacksOn(cardOf(_h, 5), cardOf(_s, 7)), isFalse, reason: 'gap');

    final p = FreeCellPosition(
      [
        [cardOf(_s, 13), cardOf(_h, 6)],
        [cardOf(_c, 7)],
        [cardOf(_d, 7)],
        for (var i = 0; i < 5; i++) [cardOf(_c, 13 - i)],
      ],
      [-1, -1, -1, -1],
      [0, 0, 0, 0],
    );
    expect(
      p.canMove(const FreeCellMove(PileKind.cascade, 0, PileKind.cascade, 1)),
      isTrue,
    );
    expect(
      p.canMove(const FreeCellMove(PileKind.cascade, 0, PileKind.cascade, 2)),
      isFalse,
    );
    expect(
      p.canMove(const FreeCellMove(PileKind.cascade, 0, PileKind.cell, 3)),
      isTrue,
    );
    // The King underneath is not part of a run with the 6.
    expect(
      p.canMove(const FreeCellMove(PileKind.cascade, 0, PileKind.cell, 0, 2)),
      isFalse,
    );
  });

  test('The supermove limit is (free cells + 1) x 2^empty columns', () {
    // A run of 8: 9H down to 2S, alternating.
    final run = [for (var r = 9; r >= 2; r--) cardOf(r.isOdd ? _h : _s, r)];
    FreeCellPosition board({required int freeCells, required int empties}) {
      final cascades = <List<int>>[
        List.of(run),
        [cardOf(_c, 10)], // a black 10 for the red 9 to land on
      ];
      // Filler cards that no run card stacks on.
      var filler = 0;
      final fillers = [
        for (var r = 11; r <= 13; r++) ...[cardOf(_d, r), cardOf(_c, r)],
      ];
      while (cascades.length < 8 - empties) {
        cascades.add([fillers[filler++]]);
      }
      while (cascades.length < 8) {
        cascades.add([]);
      }
      return FreeCellPosition(
        cascades,
        [for (var i = 0; i < 4; i++) i < freeCells ? -1 : cardOf(_d, 2 + i)],
        [0, 0, 0, 0],
      );
    }

    expect(board(freeCells: 4, empties: 0).maxRun(toEmptyCascade: false), 5);
    expect(board(freeCells: 1, empties: 0).maxRun(toEmptyCascade: false), 2);
    expect(board(freeCells: 1, empties: 1).maxRun(toEmptyCascade: false), 4);
    expect(board(freeCells: 1, empties: 1).maxRun(toEmptyCascade: true), 2);
    expect(board(freeCells: 3, empties: 1).maxRun(toEmptyCascade: false), 8);

    const all8 = FreeCellMove(PileKind.cascade, 0, PileKind.cascade, 1, 8);
    expect(board(freeCells: 3, empties: 1).canMove(all8), isTrue);
    expect(
      board(freeCells: 2, empties: 1).canMove(all8),
      isFalse,
      reason: 'only 6 fit',
    );
    // Into an empty column, that column does not count as space.
    const toEmpty = FreeCellMove(PileKind.cascade, 0, PileKind.cascade, 7, 4);
    expect(board(freeCells: 1, empties: 2).canMove(toEmpty), isTrue);
    expect(board(freeCells: 1, empties: 1).canMove(toEmpty), isFalse);
  });

  test(
    'Foundations go up in order, and only safe cards go up by themselves',
    () {
      final p = FreeCellPosition(
        [
          [cardOf(_h, 2)],
          [cardOf(_h, 1)],
          [cardOf(_h, 3)],
          [cardOf(_c, 2)],
          [cardOf(_c, 1)],
          [cardOf(_s, 1)],
          [],
          [],
        ],
        [-1, -1, -1, -1],
        [0, 0, 0, 0],
      );
      expect(
        p.canMove(
          const FreeCellMove(PileKind.cascade, 0, PileKind.foundation, _h),
        ),
        isFalse,
        reason: '2 before the ace',
      );
      p.autoPlay();
      // Aces and twos always; the 3 of hearts waits for the black twos, and the
      // 2 of spades is not out yet.
      expect(p.foundations, [2, 0, 2, 1]);
      expect(p.cascades[2], [cardOf(_h, 3)]);
      expect(p.isSafeHome(cardOf(_h, 3)), isFalse);
      expect(
        p.canMove(
          const FreeCellMove(PileKind.cascade, 2, PileKind.foundation, _h),
        ),
        isTrue,
        reason: 'allowed by hand, just not automatically',
      );
    },
  );

  test('Moves survive encoding, and the solver line replays', () {
    for (final m in [
      const FreeCellMove(PileKind.cascade, 7, PileKind.cascade, 0, 13),
      const FreeCellMove(PileKind.cell, 3, PileKind.foundation, 2),
      const FreeCellMove(PileKind.cascade, 0, PileKind.cell, 1),
    ]) {
      expect(FreeCellMove.decode(m.encode()), m);
    }
    final d = FreeCellDeal.generate(3);
    final p = d.start();
    final r = solveFreeCell(p);
    expect(r.solved, isTrue);
    expect(replayWins(p, r.moves), isTrue);
  });

  testWidgets('FreeCell is on the home screen under Cards', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BrainWorkoutApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('FreeCell'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('FreeCell'), findsOneWidget);
    expect(find.text('Cards'), findsWidgets);
  });

  testWidgets('Playing the proof by tapping wins with three stars', (
    tester,
  ) async {
    usePhone(tester);
    const level = 2;
    await tester.pumpWidget(
      localizedApp(const FreeCellScreen(startLevel: level)),
    );
    await tester.pump();

    final deal = FreeCellDeal.generate(level);
    final pos = deal.start();
    for (final m in deal.solution) {
      await tapMove(tester, pos, m);
    }
    expect(pos.isWon, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Well done!'), findsOneWidget);
    expect(ProgressStore.instance.stars('freecell', level), 3);
    expect(
      ProgressStore.instance.bestResult('freecell', level),
      deal.solution.length,
    );
  });

  testWidgets('Undo puts every card back exactly', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(localizedApp(const FreeCellScreen(startLevel: 4)));
    await tester.pump();
    final deal = FreeCellDeal.generate(4);
    final pos = deal.start();
    final before = cardRects(tester);
    for (final m in deal.solution.take(3)) {
      await tapMove(tester, pos, m);
    }
    expect(cardRects(tester), isNot(equals(before)));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('freecell_undo')));
      await tester.pump();
    }
    expect(cardRects(tester), before);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('freecell_undo')))
          .onPressed,
      isNull,
      reason: 'nothing left to undo',
    );
  });

  testWidgets('An invalid destination just deselects', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(localizedApp(const FreeCellScreen(startLevel: 4)));
    await tester.pump();
    final pos = FreeCellDeal.generate(4).start();
    final before = cardRects(tester);
    // Find two cascade tops that do not stack.
    late int a, b;
    outer:
    for (a = 0; a < 8; a++) {
      for (b = 0; b < 8; b++) {
        if (a != b && !stacksOn(pos.cascades[a].last, pos.cascades[b].last)) {
          break outer;
        }
      }
    }
    await tester.tapAt(cardPoint(tester, pos.cascades[a].last));
    await tester.pump();
    await tester.tapAt(cardPoint(tester, pos.cascades[b].last));
    await settle(tester);
    expect(cardRects(tester), before);
    expect(find.text('0 moves'), findsOneWidget);
  });

  testWidgets('A hint shows the next move and costs a star', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(localizedApp(const FreeCellScreen(startLevel: 6)));
    await tester.pump();
    expect(find.byKey(const ValueKey('freecell_hint_target')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('game_hint_button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('freecell_hint_target')), findsOneWidget);
    expect(
      find.text('A hint means at most 2 stars for this level.'),
      findsOneWidget,
    );
    // Let the snack bar go, so it cannot sit over the lower cards.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Following hints all the way wins, with two stars at most.
    final pos = FreeCellDeal.generate(6).start();
    final line = FreeCellDeal.generate(6).solution;
    for (final m in line) {
      await tapMove(tester, pos, m);
    }
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Well done!'), findsOneWidget);
    expect(ProgressStore.instance.stars('freecell', 6), 2);
  });

  testWidgets('Off the known line, the hint comes from the solver', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(localizedApp(const FreeCellScreen(startLevel: 6)));
    await tester.pump();
    final deal = FreeCellDeal.generate(6);
    final pos = deal.start();
    // Any first move the proof does not start with.
    final off = pos.candidateMoves().firstWhere(
      (m) => m != deal.solution.first,
    );
    await tapMove(tester, pos, off);
    await tester.tap(find.byKey(const ValueKey('game_hint_button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('freecell_hint_target')), findsOneWidget);
    expect(solveFreeCell(pos, maxNodes: 40000).solved, isTrue);
  });

  testWidgets('Leaving mid-game resumes the same position, undo included', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(localizedApp(const FreeCellScreen(startLevel: 9)));
    await tester.pump();
    final deal = FreeCellDeal.generate(9);
    final pos = deal.start();
    final start = cardRects(tester);
    for (final m in deal.solution.take(6)) {
      await tapMove(tester, pos, m);
    }
    final mid = cardRects(tester);

    await tester.pumpWidget(const SizedBox());
    final saved = ProgressStore.instance.loadBoard('freecell', 9)!;
    expect(saved['moves'], hasLength(6));
    expect(saved['v'], FreeCellDeal.generatorVersion);

    await tester.pumpWidget(localizedApp(const FreeCellScreen(startLevel: 9)));
    await tester.pump();
    expect(cardRects(tester), mid);
    expect(find.text('6 moves'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const ValueKey('freecell_undo')));
      await tester.pump();
    }
    expect(cardRects(tester), start);
  });

  testWidgets('The slide survives the reduce-animations setting', (
    tester,
  ) async {
    usePhone(tester);
    debugSemanticsDisableAnimations = true;
    addTearDown(() => debugSemanticsDisableAnimations = null);
    await tester.pumpWidget(localizedApp(const FreeCellScreen(startLevel: 2)));
    await tester.pump();
    final deal = FreeCellDeal.generate(2);
    final pos = deal.start();
    final m = deal.solution.firstWhere((m) => m.toKind != PileKind.foundation);
    final card = pos.movingCard(m);
    final from = tester.getRect(cardKey(card));
    await tester.tapAt(cardPoint(tester, card));
    await tester.pump();
    await tester.tapAt(
      m.toKind == PileKind.cell
          ? tester.getCenter(find.byKey(ValueKey('fc_cell_${m.to}')))
          : pos.cascades[m.to].isEmpty
          ? tester
                    .getRect(find.byKey(ValueKey('fc_cascade_${m.to}')))
                    .topCenter +
                const Offset(0, 12)
          : cardPoint(tester, pos.cascades[m.to].last),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final mid = tester.getRect(cardKey(card));
    await settle(tester);
    final end = tester.getRect(cardKey(card));
    expect(end, isNot(from));
    expect(mid, isNot(end), reason: 'the slide collapsed to a single frame');
    expect(mid, isNot(from));
  });

  testWidgets('The board fits a small phone at the largest text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0; // 360x640 logical
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final level in [1, 60]) {
      await tester.pumpWidget(
        localizedApp(FreeCellScreen(startLevel: level, key: ValueKey(level))),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'level $level overflowed');
      final pos = FreeCellDeal.generate(level).start();
      for (final col in pos.cascades) {
        if (col.isEmpty) continue;
        expect(cardKey(col.last).hitTestable(), findsOneWidget);
        // Covered cards still show their corner: a comfortable strip each.
        if (col.length > 1) {
          final a = tester.getRect(cardKey(col[0]));
          final b = tester.getRect(cardKey(col[1]));
          expect(b.top - a.top, greaterThanOrEqualTo(14));
        }
      }
      final card = tester.getRect(cardKey(pos.cascades[0].last));
      expect(card.width, greaterThanOrEqualTo(36), reason: 'legibility');
      expect(
        find.byKey(const ValueKey('freecell_undo')).hitTestable(),
        findsOneWidget,
      );
    }
  });
}
