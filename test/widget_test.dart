import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show debugSemanticsDisableAnimations;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/data/dictionary.dart';
import 'package:brain_workout/data/word_pool.dart';
import 'package:brain_workout/data/word_tier.dart';
import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/arrow_escape/arrow_escape_screen.dart';
import 'package:brain_workout/games/crack_code/crack_code_models.dart';
import 'package:brain_workout/games/crack_code/crack_code_screen.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/games/memory_match/memory_match_models.dart';
import 'package:brain_workout/games/memory_match/memory_match_screen.dart';
import 'package:brain_workout/games/nonogram/nonogram_models.dart';
import 'package:brain_workout/games/nonogram/nonogram_screen.dart';
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
import 'package:brain_workout/games/wordle/word_repository.dart';
import 'package:brain_workout/games/wordle/wordle_screen.dart';
import 'package:brain_workout/services/app_locale.dart';
import 'package:brain_workout/widgets/how_to_play.dart';
import 'package:brain_workout/widgets/win_dialog.dart';
import 'package:brain_workout/services/progress_store.dart';
import 'package:brain_workout/theme/motion.dart';

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

  testWidgets('Home screen game cards survive the largest text scale',
      (tester) async {
    // The app enlarges text up to 1.3x. With a fixed card aspect ratio the cards
    // did not grow with it, so the two-line subtitle was clipped mid-word — and
    // it showed up in a Play Store screenshot. Existing tests missed it because
    // the platform scale in tests is 1.0, which the app clamps to its 1.1 floor,
    // never reaching the ceiling where it breaks.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    // Above the app's clamp ceiling, so the clamp itself is exercised. Set on
    // the platform rather than by wrapping in
    // `MediaQuery(data: MediaQueryData(textScaler: ...))`: that constructor
    // replaces all of MediaQueryData, so `size` became Size.zero and this test
    // spent a while checking the layout of a zero-height screen.
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const BrainWorkoutApp());
    await tester.pumpAndSettle();

    // A clipped subtitle or a too-wide row reports a RenderFlex overflow, which
    // fails the test.
    expect(tester.takeException(), isNull);
    expect(find.text('Arrow Escape'), findsOneWidget);

    // Taller cards mean the lower ones are off-screen and never built, so scroll
    // through the whole grid — the overflow could be on any card.
    final grid = find.byType(GridView);
    for (var i = 0; i < 6; i++) {
      await tester.drag(grid, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'a card overflowed after scrolling $i screens');
    }
    // Confirms the grid really scrolled, so the loop above did exercise cards
    // beyond the first screen rather than re-checking the same ones.
    expect(find.text('Arrow Escape'), findsNothing);
  });

  testWidgets('Game card level label is not ellipsised away', (tester) async {
    // Fixing the card overflow by making the label Flexible put it in
    // competition with a Spacer — both default to flex 1, so they split the free
    // space and "Level 46" rendered as "Niv…". find.text cannot catch that: the
    // widget's data is still the full string, only the *painting* is truncated.
    // Hence checking the render object.
    SharedPreferences.setMockInitialValues({
      'highest_level_arrow_escape': 46,
      'stars_arrow_escape_1': 3,
      'stars_arrow_escape_2': 3,
    });
    await ProgressStore.init();
    for (final game in gamesCatalog) {
      ProgressStore.instance.markHelpSeen(game.id);
    }

    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BrainWorkoutApp());
    await tester.pumpAndSettle();

    final label = find.text('Level 46');
    expect(label, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(label);
    expect(paragraph.didExceedMaxLines, isFalse,
        reason: 'the level label was truncated, so it paints as "Level 4…"');
  });

  testWidgets('Credits screen carries the CC BY attribution', (tester) async {
    // Norsk ordbank is CC BY 4.0, which obliges the app itself to name the
    // creator, identify the licence, and state that the data was changed. This
    // is a licence check, not a cosmetic one — if it fails, don't ship.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BrainWorkoutApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Språkrådet'), findsOneWidget,
        reason: 'CC BY requires naming the creator');
    expect(find.textContaining('University of Bergen'), findsOneWidget);
    expect(find.textContaining('Creative Commons'), findsOneWidget,
        reason: 'CC BY requires identifying the licence');
    // Specific to the Ordbank credit: both lists state their filtering, so a
    // looser match would find two.
    expect(find.textContaining('proper nouns removed'), findsOneWidget,
        reason: 'CC BY requires stating that the data was modified');
    // The public-domain English list is credited alongside it.
    expect(find.textContaining('dwyl'), findsOneWidget);

    // Share-alike is a stronger obligation than plain CC BY: the Norwegian list
    // we ship is itself CC BY-SA because it derives from that frequency data, and
    // the screen has to say so.
    await tester.scrollUntilVisible(find.textContaining('ShareAlike'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('ShareAlike'), findsOneWidget,
        reason: 'CC BY-SA requires identifying the share-alike licence');
    expect(find.textContaining('available under CC BY-SA'), findsOneWidget,
        reason: 'share-alike obliges us to pass the same licence on');
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

  test('Slide timing is derived from distance, not fixed', () {
    // A tester said Arrow Maze needed an animation when tapping an arrow — but
    // there was one. The duration was fixed at 520ms while the travel distance
    // scales with cell size, so on a bigger screen the arrow covered far more
    // pixels in the same time and read as a blur. Speed is now the constant.
    //
    // Not a refresh-rate problem: Flutter animates from wall-clock time, so a
    // 120Hz screen renders the same animation more smoothly, not faster.
    final near = slideDuration(300);
    final far = slideDuration(900);
    expect(far, greaterThan(near),
        reason: 'a longer slide must take longer, or speed is not constant');

    // Same distance always gives the same answer, whatever the device.
    expect(slideDuration(600), slideDuration(600));

    // Clamped at both ends: a tiny board should not feel twitchy, and a huge one
    // should not make the player wait.
    expect(slideDuration(1), const Duration(milliseconds: 340));
    expect(slideDuration(100000), const Duration(milliseconds: 820));
    // Degenerate inputs fall back rather than producing a zero-length animation.
    expect(slideDuration(0), const Duration(milliseconds: 340));
    expect(slideDuration(-5), const Duration(milliseconds: 340));
    expect(slideDuration(double.nan), const Duration(milliseconds: 340));

    // Within the clamps the speed really is what it claims: 900 dp/s.
    expect(slideDuration(450).inMilliseconds, closeTo(500, 2));
  });

  test('Difficulty keeps climbing past the early levels', () {
    // Every game used to plateau — 11 of 12 were identical from level 20 on, and
    // seven from level 12, which made every higher level number decorative.
    // These assert the curve still moves where it was uncapped; run
    // `dart run tool/analyze_level_curves.dart` to see all of them at once.
    expect(simonConfigForLevel(30).targetLength,
        greaterThan(simonConfigForLevel(20).targetLength));
    expect(trailConfigForLevel(40).count,
        greaterThan(trailConfigForLevel(20).count));
    expect(crackCodeConfigForLevel(30).length,
        greaterThan(crackCodeConfigForLevel(15).length));
    expect(miniSudokuConfigForLevel(16).blanks,
        greaterThan(miniSudokuConfigForLevel(13).blanks));
    expect(configForLevel(21).rows, greaterThan(configForLevel(13).rows));
    expect(configForLevel(21).arrowCount,
        greaterThan(configForLevel(13).arrowCount));

    // Uncapped after a tester reached level 50 in Arrow Maze and found it
    // identical to level 35. Lower branching is harder, hence lessThan.
    expect(snakeTargetBranchingForLevel(60),
        lessThan(snakeTargetBranchingForLevel(40)));
    expect(snakeConfigForLevel(50).minLength,
        greaterThan(snakeConfigForLevel(35).minLength));
    expect(memoryConfigForLevel(9).pairs,
        greaterThan(memoryConfigForLevel(7).pairs));
    // 2048's target tile is a structural ceiling, so the spawn mix carries the
    // curve past it — that is the knob that has to keep moving.
    expect(mergeConfigForLevel(18).fourChance,
        greaterThan(mergeConfigForLevel(8).fourChance));
    expect(numberCrossConfigForLevel(26).blanks,
        greaterThan(numberCrossConfigForLevel(12).blanks));
    expect(numberCrossConfigForLevel(26).decoys,
        greaterThan(numberCrossConfigForLevel(12).decoys));
    expect(whatNextConfigForLevel(17).tier,
        greaterThan(whatNextConfigForLevel(9).tier));
  });

  test('Arrow Escape stays solvable at the new high levels', () {
    // The grid now grows to 9x9 at 68% density instead of stopping at 7x7/60%,
    // so generation has to still succeed and stay clearable well past level 30.
    for (final level in [21, 30, 40, 60]) {
      final board = ArrowBoard.generate(level);
      expect(board.pieces, isNotEmpty, reason: 'level $level produced no arrows');
      for (final piece in board.pieces.reversed) {
        expect(board.isPathClear(piece), isTrue,
            reason: 'level $level not solvable at piece ${piece.id}');
        piece.escaped = true;
      }
      expect(board.isSolved, isTrue);
    }
  });

  test('Mini Sudoku stays uniquely solvable at the hardest levels', () {
    // blanks is only a target; the generator stops digging when uniqueness would
    // be lost. Assert it really does dig deeper now, and that what it produces is
    // still a valid puzzle.
    for (final level in [16, 30, 50]) {
      final board = MiniSudokuBoard.generate(level);
      final blanks = board.cells.expand((r) => r).where((c) => !c.given).length;
      expect(blanks, greaterThan(45),
          reason: 'level $level dug only $blanks blanks');
      expect(board.isSolved, isFalse);
    }
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
    // 1-30 plus a sample of the *high* levels. The high ones matter because the
    // level-45 minLength floor and the extended branching tail only take effect
    // up there, and a generator change that strands an arrow would otherwise be
    // invisible: this test used to stop at 30, i.e. before any of it.
    // Sampled rather than exhaustive because a 14x20 board costs ~400ms.
    for (final level in [
      for (var l = 1; l <= 30; l++) l,
      45,
      60,
      63,
      80,
    ]) {
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

  testWidgets('Arrow Maze animates even when the device disables animations',
      (tester) async {
    // A tester on an S23 Ultra reported that tapping an arrow produced no
    // animation, while the same build animated visibly on an S24. The cause was
    // not the device or the frame rate: with the platform's "reduce animations"
    // setting on, Flutter runs an AnimationController with the default
    // AnimationBehavior.normal at *5% duration* — the framework's own comment
    // says this limits it "to a single frame". 520ms became 26ms.
    //
    // This reproduces that setting and asserts the animation still takes real
    // time, which is what AnimationBehavior.preserve buys.
    debugSemanticsDisableAnimations = true;
    addTearDown(() => debugSemanticsDisableAnimations = null);

    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 1)));
    final board = SnakeBoard.generate(1); // same seed as the screen
    final rect = tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    final cell = rect.width / board.cols;
    final arrow = board.arrows.firstWhere(board.isPathClear);
    final target = arrow.cells.first;
    await tester.tapAt(rect.topLeft +
        Offset((target.col + 0.5) * cell, (target.row + 0.5) * cell));

    // The screen's own board is private, so measure the animation itself: a
    // running controller keeps a transient frame callback registered. The screen
    // has no idle animations, so this is 0 whenever nothing is moving.
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0),
        reason: 'tapping a clear arrow should start the escape animation');

    // 120ms in it must still be travelling. Under the default behaviour the whole
    // slide would already be over (780ms x 5% = 39ms) — that is exactly the
    // "there is no animation" the tester saw.
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.binding.transientCallbackCount, greaterThan(0),
        reason: 'the animation collapsed to a frame or two, as if not animating');

    // And it does finish, so nothing hangs waiting on it.
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('Arrow Escape animates even when the device disables animations',
      (tester) async {
    // Same defect as Arrow Maze above, but this screen had it through
    // AnimatedPositioned/AnimatedOpacity: ImplicitlyAnimatedWidgetState creates
    // its controller without an animationBehavior, so implicit animations collapse
    // to 5% too and cannot be told not to. Hence the explicit controller in
    // _PieceView. Worse here than a missing animation: the arrow teleported off
    // the board while the win dialog still waited a full _moveDuration.
    debugSemanticsDisableAnimations = true;
    addTearDown(() => debugSemanticsDisableAnimations = null);

    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(localizedApp(const ArrowEscapeScreen(startLevel: 1)));
    final board = ArrowBoard.generate(1); // same seed as the screen
    final rect =
        tester.getRect(find.byKey(const ValueKey('arrow_escape_board')));
    final cell = rect.height / board.rows;
    final piece = board.pieces.firstWhere(board.isPathClear);
    await tester.tapAt(rect.topLeft +
        Offset((piece.col + 0.5) * cell, (piece.row + 0.5) * cell));

    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0),
        reason: 'tapping a clear arrow should start the slide');
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.binding.transientCallbackCount, greaterThan(0),
        reason: 'the slide collapsed to a frame or two, as if not animating');

    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
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
      // The board grew to 21 pairs, so the symbol pool has to keep up. Without
      // this, too few symbols would quietly shrink the deck instead of failing.
      expect(counts.length, board.cards.length ~/ 2,
          reason: 'memory level $level ran short of distinct symbols');
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

  test('Word pool entries obey their own rules', () {
    // The pool's contract: 3-8 letters (Word Scramble's range), present in the
    // matching dictionary so a puzzle answer can never be a word the near-miss
    // check would reject, and in exactly one category — a word in two
    // categories would make the hint ambiguous, which defeats the point.
    for (final lang in categorisedWords.keys) {
      // Lines are WORD<TAB>tier.
      final dict = File('assets/words/${lang}_all.txt')
          .readAsLinesSync()
          .map((l) => l.split('	').first.trim().toUpperCase())
          .where((l) => l.isNotEmpty)
          .toSet();
      final categories = <String, Set<WordCategory>>{};

      for (final entry in categorisedWords[lang]!) {
        final w = entry.word;
        expect(w.length, inInclusiveRange(3, 8),
            reason: '$lang "$w" is outside the 3-8 letter range');
        expect(w, equals(w.toUpperCase()),
            reason: '$lang "$w" must be uppercase');
        expect(dict.contains(w), isTrue,
            reason: '$lang "$w" is missing from ${lang}_all.txt');
        categories.putIfAbsent(w, () => {}).add(entry.category);
      }
      for (final entry in categories.entries) {
        expect(entry.value.length, 1,
            reason: '$lang "${entry.key}" is in more than one category');
      }
    }
  });

  test('Word Search difficulty climbs past the early levels', () {
    // Was identical from level 10 on. Difficulty now comes from reverse
    // placement and from hiding the word list, not from an ever-bigger grid —
    // letters need more room than arrows and the app enlarges all text.
    final early = wordSearchConfigForLevel(5);
    final mid = wordSearchConfigForLevel(16);
    final late = wordSearchConfigForLevel(40);

    bool hasReverse(WordSearchConfig c) =>
        c.directions.any((d) => d.$2 < 0 || (d.$2 == 0 && d.$1 < 0));
    expect(hasReverse(early), isFalse,
        reason: 'early levels must read forwards only');
    expect(hasReverse(mid), isTrue);
    expect(late.words, greaterThan(early.words));
    expect(late.size, greaterThan(early.size));
    expect(late.size, lessThanOrEqualTo(11), reason: 'letters must stay legible');
    expect(early.showWordList, isTrue);
    expect(late.showWordList, isFalse,
        reason: 'the hardest levels give only the category');
  });

  test('Themed Word Search boards are single-category and complete', () {
    for (final lang in ['en', 'nb']) {
      for (final level in [12, 16, 20, 26, 40]) {
        final cfg = wordSearchConfigForLevel(level);
        final board = WordSearchBoard.generate(level, lang);

        expect(board.words.length, cfg.words,
            reason: '$lang level $level placed too few words');
        expect(board.category, isNotNull,
            reason: '$lang level $level is themed, so it needs a category');
        // Hiding the word list is only fair if the category really does describe
        // every word on the board.
        final inCategory =
            wordPoolByCategory(lang)[board.category!]!.toSet();
        for (final w in board.words) {
          expect(inCategory.contains(w.word), isTrue,
              reason: '$lang level $level: ${w.word} is not '
                  '${board.category!.name}');
        }
      }
    }
  });

  test('Word Scramble difficulty climbs into rarer, longer words', () {
    // Levels used to be identical from 10 onwards. Early levels draw the curated
    // pool so a category can be shown; later ones reach into the dictionary,
    // where having no category is itself part of the difficulty.
    final early = wordScrambleConfigForLevel(10);
    final mid = wordScrambleConfigForLevel(20);
    final late = wordScrambleConfigForLevel(40);

    expect(early.fromPool, isTrue);
    expect(mid.fromPool, isFalse,
        reason: 'the pool has only 11 English 8-letter words; it runs out');
    expect(late.minLen, greaterThan(mid.minLen));
    expect(late.words, greaterThan(mid.words));
    expect(late.tiers, contains(WordTier.lessCommon),
        reason: 'late levels should reach rarer vocabulary');

    // Junk is never a puzzle source, at any level.
    for (var level = 1; level <= 60; level++) {
      expect(wordScrambleConfigForLevel(level).tiers,
          isNot(contains(WordTier.junk)),
          reason: 'level $level would serve unfair words');
    }

    // Pool levels always carry a category; the fallback must not crash without a
    // dictionary, it just serves pool words instead.
    expect(generateScrambleRound(3, 'en').every((w) => w.category != null),
        isTrue);
    expect(generateScrambleRound(40, 'en'), isNotEmpty);
  });

  test('Offensive words can be checked but never set as puzzles', () {
    // The dictionary is exhaustive, so it contains crude words — CRAPPERS turned
    // up in a level-25 round. They must stay valid for the near-miss check while
    // being excluded from every puzzle tier.
    final tiers = <String, String>{};
    for (final line in File('assets/words/en_all.txt').readAsLinesSync()) {
      final parts = line.split('\t');
      if (parts.length == 2) tiers[parts[0]] = parts[1];
    }
    for (final word in ['CRAP', 'CRAPPERS', 'BULLSHIT', 'BUGGER', 'TURD']) {
      expect(tiers[word], isNotNull,
          reason: '$word should still be a recognised word');
      expect(tiers[word], '4',
          reason: '$word must not be available as a puzzle answer');
    }
  });

  test('Word Scramble deals words out instead of redrawing them', () {
    // Each level used to shuffle independently, with no idea what earlier levels
    // had served: Norwegian gave 188 puzzles from 44 distinct words, BILDE twelve
    // times. Words are now dealt from one per-language order.
    for (final lang in ['en', 'nb']) {
      final counts = <String, int>{};
      for (var level = 1; level <= 40; level++) {
        for (final sw in generateScrambleRound(level, lang)) {
          counts[sw.word] = (counts[sw.word] ?? 0) + 1;
        }
      }
      expect(counts.length, greaterThan(120),
          reason: '$lang served too few distinct words over 40 levels');
      expect(counts.values.reduce(math.max), lessThanOrEqualTo(3),
          reason: '$lang repeated one word too often');
    }
  });

  test('Word Scramble words carry the category that identifies them', () {
    final round = generateScrambleRound(12, 'nb');
    expect(round, isNotEmpty);
    for (final sw in round) {
      // The scramble must not simply be the answer, and the category has to
      // match the pool entry it came from.
      expect(sw.letters.join(), isNot(sw.word));
      expect(sw.letters.length, sw.word.length);
      final entry =
          categorisedWords['nb']!.firstWhere((e) => e.word == sw.word);
      expect(sw.category, entry.category);
    }
  });

  testWidgets('Word Scramble: a real-but-wrong word costs no heart',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    String signature(String w) => (w.split('')..sort()).join();

    // Index the dictionary by letter-signature once. Scanning all 148k words per
    // candidate level instead made this test take minutes.
    final bySignature = <String, List<String>>{};
    for (final line in File('assets/words/en_all.txt').readAsLinesSync()) {
      final w = line.split('	').first.trim().toUpperCase();
      if (w.isNotEmpty) {
        bySignature.putIfAbsent(signature(w), () => []).add(w);
      }
    }

    // Find a level whose *first* word has another real word in its letters —
    // the case the player complained about (spelling PANEL from PLANE).
    int? level;
    String? alternative;
    for (var candidate = 1; candidate <= 20 && level == null; candidate++) {
      final first = generateScrambleRound(candidate, 'en').first.word;
      final others = (bySignature[signature(first)] ?? const <String>[])
          .where((d) => d != first);
      if (others.isNotEmpty) {
        level = candidate;
        alternative = others.first;
      }
    }
    expect(level, isNotNull,
        reason: 'expected some early level to have an ambiguous first word');

    // Load the dictionary up front, via runAsync: rootBundle does real async
    // I/O, and awaiting that directly inside testWidgets deadlocks, because the
    // test body runs in a fake-async zone where real futures never complete.
    // The cache is static, so warming it here is what makes the screen see it
    // as loaded — pumping alone would never get there.
    final loaded =
        await tester.runAsync(() => Dictionary.forLanguage('en'));
    expect(loaded!.count, greaterThan(100000));

    await tester
        .pumpWidget(localizedApp(WordScrambleScreen(startLevel: level!)));
    await tester.pump();

    final word = generateScrambleRound(level, 'en').first;
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

    // Spell the *other* word by tapping tiles that hold its letters.
    final taken = List<bool>.filled(word.letters.length, false);
    for (final letter in alternative!.split('')) {
      final index = [
        for (var i = 0; i < word.letters.length; i++)
          if (!taken[i] && word.letters[i] == letter) i,
      ].first;
      taken[index] = true;
      await tester.tap(find.byKey(ValueKey('ws_tile_$index')));
      await tester.pump();
    }

    // It is a word, so: told so, and no heart taken.
    expect(find.textContaining('is a word'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing,
        reason: 'spelling a real word must not cost a heart');

    // The slots clear so they can try again, and the message stays up long
    // enough to read rather than vanishing with the letters.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.textContaining('is a word'), findsOneWidget);
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
      // Assert against the config rather than re-deriving the formula here: the
      // old copy of it silently became the only thing pinning 2048 as the
      // ceiling, and had to be edited to raise it.
      expect(game.target, cfg.target);
      expect(cfg.target, lessThanOrEqualTo(4096));
      expect(cfg.fourChance, inInclusiveRange(0.1, 0.3));
      if (level > 1) {
        final prev = mergeConfigForLevel(level - 1);
        expect(cfg.target, greaterThanOrEqualTo(prev.target));
        expect(cfg.fourChance, greaterThanOrEqualTo(prev.fourChance));
      }

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

  test('Nonogram: the line solver forces cells and spots contradictions', () {
    // A run filling the whole line forces every cell.
    final full = deduceLine([5], List.filled(5, 0))!;
    expect(full.canFill, everyElement(isTrue));
    expect(full.canEmpty, everyElement(isFalse));
    expect(full.placements, 1);

    // No runs at all forces every cell empty.
    final none = deduceLine([], List.filled(5, 0))!;
    expect(none.canEmpty, everyElement(isTrue));
    expect(none.canFill, everyElement(isFalse));

    // The classic overlap: a run of 3 in 5 cells always covers the middle.
    final overlap = deduceLine([3], List.filled(5, 0))!;
    expect(overlap.canFill[2] && !overlap.canEmpty[2], isTrue,
        reason: 'centre cell is forced');
    expect(overlap.canEmpty[0], isTrue, reason: 'the ends are still open');
    expect(overlap.placements, 3);

    // Two single cells in a line of five have six arrangements.
    expect(deduceLine([1, 1], List.filled(5, 0))!.placements, 6);

    // Contradiction: a run of 4 cannot fit when both ends are known empty.
    expect(deduceLine([4], [2, 0, 0, 0, 2]), isNull);
  });

  test('Nonogram: clue derivation, and a hand-built board that must solve', () {
    expect(cluesFor([true, true, false, true, false]), [2, 1]);
    expect(cluesFor([false, false, false]), isEmpty);
    expect(cluesFor([true, true, true]), [3]);

    // Alternating full and empty rows: every row clue forces its whole line at
    // once, so this has to fall out immediately.
    final rows = [
      [5],
      <int>[],
      [5],
      <int>[],
      [5],
    ];
    final cols = List.generate(5, (_) => [1, 1, 1]);
    expect(solveNonogram(rows, cols).solved, isTrue);
  });

  test('Nonogram levels are guess-free, unique, and fit their gutters', () {
    for (var level = 1; level <= 30; level++) {
      final cfg = nonogramConfigForLevel(level);
      final board = NonogramBoard.generate(level);

      expect(board.width, cfg.width, reason: 'level $level width');
      expect(board.height, cfg.height, reason: 'level $level height');

      // The clues really describe the solution.
      for (var r = 0; r < board.height; r++) {
        expect(board.rowClues[r], cluesFor(board.solution[r]),
            reason: 'level $level row $r clue');
      }
      for (var c = 0; c < board.width; c++) {
        final col = [
          for (var r = 0; r < board.height; r++) board.solution[r][c]
        ];
        expect(board.colClues[c], cluesFor(col), reason: 'level $level col $c');
      }

      // The layout gate: no line may need more clue numbers than the gutter can
      // draw, or the board stops being readable on a phone.
      for (final clue in [...board.rowClues, ...board.colClues]) {
        expect(clue.length, lessThanOrEqualTo(cfg.maxClues),
            reason: 'level $level clue $clue exceeds the gutter');
      }

      // Solvable by forced deductions alone — the player never has to guess.
      expect(solveNonogram(board.rowClues, board.colClues).solved, isTrue,
          reason: 'level $level should need no guessing');

      // Never the last-resort board (one full row, everything else empty).
      expect(board.rowClues.where((r) => r.isNotEmpty).length, greaterThan(1),
          reason: 'level $level fell back to the last-resort board');

      // Seeded: a retry gives the same puzzle.
      expect(NonogramBoard.generate(level).solution, board.solution,
          reason: 'level $level should be deterministic');
    }
  });

  test('Nonogram: line-solvable really does imply a unique solution', () {
    // The whole mechanic rests on this claim, so it is checked against an
    // independent exhaustive counter rather than assumed. Small grids only:
    // brute force is exponential, and the claim is about the deduction rule
    // rather than the grid size.
    for (var level = 1; level <= 8; level++) {
      final board = NonogramBoard.generate(level);
      expect(countNonogramSolutions(board.rowClues, board.colClues, limit: 2), 1,
          reason: 'level $level must have exactly one solution');
    }
  });

  test('Nonogram difficulty climbs past the early levels and stays on target',
      () {
    final branching = <int, double>{};
    for (var level = 1; level <= 30; level++) {
      final cfg = nonogramConfigForLevel(level);
      final board = NonogramBoard.generate(level);
      branching[level] = board.branching;
      expect((board.branching - cfg.targetBranching).abs(),
          lessThanOrEqualTo(onTargetTolerance),
          reason: 'level $level branching '
              '${board.branching.toStringAsFixed(2)} misses target '
              '${cfg.targetBranching.toStringAsFixed(2)}');
    }

    // The failure this guards against is a plateau: Arrow Maze once made level
    // 42 config-identical to level 17. Late levels must be measurably harder.
    final early =
        [for (var l = 1; l <= 5; l++) branching[l]!].reduce((a, b) => a + b) / 5;
    final late = [for (var l = 26; l <= 30; l++) branching[l]!]
            .reduce((a, b) => a + b) /
        5;
    expect(late, greaterThan(early + 0.8),
        reason: 'late levels ($late) must be clearly harder than early ($early)');
  });

  test('Nonogram: marks cycle, and crosses never block a win', () {
    final board = NonogramBoard.generate(1);
    expect(board.isSolved, isFalse);

    board.cycle(0, 0);
    expect(board.marks[0][0], NonogramMark.filled);
    board.cycle(0, 0);
    expect(board.marks[0][0], NonogramMark.crossed);
    board.cycle(0, 0);
    expect(board.marks[0][0], NonogramMark.blank);

    // Fill exactly the solution and cross off everything else: still a win,
    // because crosses are only the player's own notes.
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        board.marks[r][c] = board.solution[r][c]
            ? NonogramMark.filled
            : NonogramMark.crossed;
      }
    }
    expect(board.wrongFills, 0);
    expect(board.isSolved, isTrue);

    // One extra filled cell is a wrong fill and un-wins the board.
    final spare = [
      for (var r = 0; r < board.height; r++)
        for (var c = 0; c < board.width; c++)
          if (!board.solution[r][c]) (r, c)
    ].first;
    board.marks[spare.$1][spare.$2] = NonogramMark.filled;
    expect(board.isWrongFill(spare.$1, spare.$2), isTrue);
    expect(board.wrongFills, 1);
    expect(board.isSolved, isFalse);
  });

  testWidgets('Nonogram: a second tap crosses a cell, and Check reports a clean '
      'board', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const NonogramScreen(startLevel: 1)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close_rounded), findsNothing);
    await tester.tap(find.byKey(const ValueKey('nonogram-0-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nonogram-0-0')));
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget,
        reason: 'a second tap should mark a cross');

    // Nothing has been wrongly filled, so Check should say so.
    await tester.tap(find.text('Check my squares'));
    await tester.pump();
    expect(find.text('No mistakes so far!'), findsOneWidget);
  });

  testWidgets('Memory Match: the 21-pair board still fits a small phone',
      (tester) async {
    // Raising the ceiling from 15 to 21 pairs adds two rows, and the screen sizes
    // cards to fit rather than scrolling — so the failure mode is cards quietly
    // shrinking below what this audience can tap, not an overflow error.
    //
    // Measured card widths at 1.3x text scale, all layouts having 6 columns so
    // width is normally the binding constraint:
    //   411x868 -> 53dp   393x873 -> 50dp   360x800 -> 45dp   360x720 -> 45dp
    // The one exception is a 360x640 screen (roughly a 2015 phone), where 7 rows
    // becomes height-bound and cards drop to 36dp. Judged acceptable rather than
    // capping the game for every modern device; 360x720 is the conservative bar.
    tester.view.physicalSize = const Size(720, 1440);
    tester.view.devicePixelRatio = 2.0; // 360x720 logical
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(localizedApp(const MemoryMatchScreen(startLevel: 9)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final board = MemoryBoard.generate(9);
    expect(board.cards.length, 42, reason: '7x6 = 21 pairs');

    // Every card must be at least a 44dp tap target — the platform minimum, and
    // the reason the layout grows rows instead of columns past 5x6. Found by key
    // rather than by type: GestureDetector also matches the header's icon
    // buttons, which sit earlier in the tree and would make this assertion
    // measure a 48dp back button and pass regardless.
    for (final card in board.cards) {
      final finder = find.byKey(ValueKey('memory-card-${card.id}'));
      expect(finder.hitTestable(), findsOneWidget,
          reason: 'card ${card.id} is not tappable');
      final size = tester.getSize(finder);
      expect(size.shortestSide, greaterThanOrEqualTo(44.0),
          reason: 'card ${card.id} shrank to ${size.width}x${size.height}dp');
    }
  });

  testWidgets('Nonogram: the board fits a small phone at the largest text scale',
      (tester) async {
    // The clue gutters plus the Check button plus the hint line are the tight
    // part, and the biggest grid is the worst case — level 16 is the first 12x12.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0; // 360x640 logical
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final level in [1, 16]) {
      await tester.pumpWidget(localizedApp(NonogramScreen(startLevel: level)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'level $level overflowed on a small phone');
      // The board must still be reachable, not squeezed out by the chrome.
      expect(find.byKey(const ValueKey('nonogram-0-0')).hitTestable(),
          findsOneWidget,
          reason: 'level $level board is not tappable');
    }
  });

  testWidgets('Nonogram: filling in the picture wins the level', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const NonogramScreen(startLevel: 1)));
    await tester.pumpAndSettle();

    final board = NonogramBoard.generate(1); // same seed as the screen's
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        if (!board.solution[r][c]) continue;
        await tester.tap(find.byKey(ValueKey('nonogram-$r-$c')));
        await tester.pump();
      }
    }
    // The win is announced after a short delay, and a pending timer is not a
    // scheduled frame — pumpAndSettle alone would never advance the clock to it.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Well done!'), findsOneWidget);
  });
  testWidgets('How to play: the longest help text fits on a small phone',
      (tester) async {
    // Reported from the emulator: the sheet rendered "BOTTOM OVERFLOWED BY 38
    // PIXELS" on the first open of Picture Logic. The cause is not that game —
    // showModalBottomSheet caps a non-scroll-controlled sheet at 9/16 of the
    // screen, and the sheet's Column had no way to give, so *any* help text past
    // that height overflowed. Picture Logic's is simply the longest, and
    // Norwegian runs longer than English.
    tester.view.physicalSize = const Size(1080, 1920); // small phone
    tester.view.devicePixelRatio = 3.0; // 360x640 logical
    // Set at the platform level, NOT by wrapping in
    // `MediaQuery(data: MediaQueryData(textScaler: ...))` — that constructor
    // replaces the whole of MediaQueryData, so `size` becomes Size.zero and the
    // widget under test is handed a zero-height screen. The first version of
    // this test did exactly that and "failed" for that reason rather than the
    // real one.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3; // the app's ceiling
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final locale in [const Locale('en'), const Locale('nb')]) {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showHowToPlay(context,
                    body: AppLocalizations.of(context).helpNonogram,
                    accent: Colors.teal),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'the help sheet overflowed in ${locale.languageCode}');

      // However long the text is, the dismiss button must stay on screen and
      // tappable — scrolling the body must never push it out of reach.
      final gotIt = find.text(
          locale.languageCode == 'nb' ? 'Skjønner!' : 'Got it!');
      expect(gotIt, findsOneWidget);
      // hitTestable, not just present: the failure mode being guarded against is
      // a button pushed below the fold, which is still in the tree and still
      // "findable" while being completely unreachable to the player.
      expect(gotIt.hitTestable(), findsOneWidget,
          reason: 'the dismiss button is off screen in '
              '${locale.languageCode}');
      await tester.tap(gotIt);
      await tester.pumpAndSettle();
      expect(gotIt, findsNothing, reason: 'the sheet should have closed');
    }
  });
  test('Saved boards: round-trip, and every reason to refuse one', () {
    final store = ProgressStore.instance;
    expect(store.loadBoard('merge', 1), isNull, reason: 'nothing saved yet');
    expect(store.hasSavedBoard('merge', 1), isFalse);

    store.saveBoard('merge', 3, {'grid': 'x', 'n': 7});
    expect(store.loadBoard('merge', 3), {'grid': 'x', 'n': 7});
    expect(store.hasSavedBoard('merge', 3), isTrue);

    // Keyed to its level: picking a different level from the picker must not
    // resurrect a half-finished board from somewhere else.
    expect(store.loadBoard('merge', 4), isNull);
    expect(store.loadBoard('merge', 2), isNull);
    // ...and to its game.
    expect(store.loadBoard('nonogram', 3), isNull);

    store.clearBoard('merge');
    expect(store.loadBoard('merge', 3), isNull);

    // One slot per game: a second save replaces the first rather than
    // accumulating a board per level forever.
    store.saveBoard('merge', 5, {'a': 1});
    store.saveBoard('merge', 6, {'b': 2});
    expect(store.loadBoard('merge', 5), isNull);
    expect(store.loadBoard('merge', 6), {'b': 2});
  });

  test('Saved boards: corrupt or stale data is refused, never thrown', () async {
    Future<void> seedRaw(String value) async {
      SharedPreferences.setMockInitialValues({'flutter.board_merge': value});
      await ProgressStore.init();
    }

    // Prove the seeding mechanism works before relying on it: every assertion
    // below expects null, which is also what an un-seeded store returns, so
    // without this the whole test could pass while writing nothing at all.
    await seedRaw('{"v":1,"level":1,"state":{"ok":true}}');
    expect(ProgressStore.instance.loadBoard('merge', 1), {'ok': true},
        reason: 'raw seeding must actually reach the store');

    await seedRaw('not json {{');
    expect(ProgressStore.instance.loadBoard('merge', 1), isNull);

    await seedRaw('[1,2,3]'); // valid JSON, wrong shape
    expect(ProgressStore.instance.loadBoard('merge', 1), isNull);

    await seedRaw('{"v":999,"level":1,"state":{"a":1}}'); // other format version
    expect(ProgressStore.instance.loadBoard('merge', 1), isNull);

    await seedRaw('{"v":1,"level":1,"state":42}'); // payload not an object
    expect(ProgressStore.instance.loadBoard('merge', 1), isNull);
  });

  test('2048: a board survives a JSON round-trip', () {
    final game = MergeGame.generate(12);
    game.move(MergeDirection.left);
    final before = game.grid.toString();
    final score = game.score;

    // Through a real encode/decode, not just the Dart map: jsonDecode hands back
    // List<dynamic>/num rather than List<int>/int, which is where a lazy cast
    // would blow up on a real device but not in a unit test.
    final wire = jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;
    final restored = MergeGame.fromJson(wire)!;
    expect(restored.grid.toString(), before);
    expect(restored.score, score);
    expect(restored.target, game.target);
    // The restored game is playable, not just readable.
    expect(restored.hasMoves, isTrue);
  });

  test('2048: a malformed saved board is refused rather than half-loaded', () {
    expect(MergeGame.fromJson({}), isNull);
    expect(MergeGame.fromJson({'grid': 'nope', 'target': 32, 'score': 0}),
        isNull);
    // Ragged rows.
    expect(
        MergeGame.fromJson({
          'grid': [
            [0, 0],
            [0]
          ],
          'target': 32,
          'score': 0
        }),
        isNull);
    // A tile that isn't a power of two could never be produced by play, and
    // could never be merged away either.
    expect(
        MergeGame.fromJson({
          'grid': [
            [6, 0],
            [0, 0]
          ],
          'target': 32,
          'score': 0
        }),
        isNull);
    expect(
        MergeGame.fromJson({
          'grid': [
            [-2, 0],
            [0, 0]
          ],
          'target': 32,
          'score': 0
        }),
        isNull);
    // A valid 2x2 board is accepted, so the rejections above aren't vacuous.
    expect(
        MergeGame.fromJson({
          'grid': [
            [2, 4],
            [0, 8]
          ],
          'target': 32,
          'score': 12
        }),
        isNotNull);
  });

  test('Picture Logic: marks survive a round-trip and mismatches are refused',
      () {
    final board = NonogramBoard.generate(6);
    expect(board.hasProgress, isFalse);
    board.cycle(0, 0); // filled
    board.cycle(1, 1);
    board.cycle(1, 1); // crossed
    expect(board.hasProgress, isTrue);

    final json = board.marksJson();
    final fresh = NonogramBoard.generate(6);
    expect(fresh.applyMarksJson(json), isTrue);
    expect(fresh.marks[0][0], NonogramMark.filled);
    expect(fresh.marks[1][1], NonogramMark.crossed);
    expect(fresh.marks[2][2], NonogramMark.blank);

    // A save from a different-sized board is refused outright.
    final other = NonogramBoard.generate(1); // 5x5 vs level 6's 8x8
    expect(other.width == board.width, isFalse, reason: 'sizes must differ');
    expect(other.applyMarksJson(json), isFalse);
    expect(other.hasProgress, isFalse, reason: 'refusal must change nothing');

    // Garbage characters and wrong lengths are refused too.
    expect(fresh.applyMarksJson({'w': fresh.width, 'h': fresh.height, 'marks': 'zz'}),
        isFalse);
    final bad = 'q' * (fresh.width * fresh.height);
    expect(
        fresh.applyMarksJson(
            {'w': fresh.width, 'h': fresh.height, 'marks': bad}),
        isFalse);
  });

  testWidgets('Picture Logic: an interrupted board comes back on re-entry',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const NonogramScreen(startLevel: 4)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nonogram-0-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nonogram-2-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nonogram-2-3')));
    await tester.pump(); // now crossed

    // The phone rings: Android backgrounds the app. This is the moment the save
    // has to happen, because the process may never get another chance.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(ProgressStore.instance.hasSavedBoard('nonogram', 4), isTrue);

    // Tear the screen down and come back to the same level.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(localizedApp(const NonogramScreen(startLevel: 4)));
    await tester.pumpAndSettle();

    final board = NonogramBoard.generate(4);
    expect(board.applyMarksJson(ProgressStore.instance.loadBoard('nonogram', 4)!),
        isTrue);
    expect(board.marks[0][0], NonogramMark.filled);
    expect(board.marks[2][3], NonogramMark.crossed);

    // The cross is visible on the restored screen, which is what the player sees.
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('Picture Logic: restarting a level throws the save away',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const NonogramScreen(startLevel: 4)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nonogram-0-0')));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(ProgressStore.instance.hasSavedBoard('nonogram', 4), isTrue);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();
    expect(ProgressStore.instance.hasSavedBoard('nonogram', 4), isFalse,
        reason: 'restart must not leave the old board resumable');
  });

  testWidgets('2048: a played board is saved, and winning clears it',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const MergeScreen(startLevel: 1)));
    await tester.pumpAndSettle();

    // Play until something merges — captureBoard deliberately ignores a board
    // with no score yet, since a fresh one is a tap away from regenerating.
    for (final key in ['merge_left', 'merge_up', 'merge_right', 'merge_down']) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final saved = ProgressStore.instance.loadBoard('merge', 1);
    expect(saved, isNotNull,
        reason: 'four moves should have merged something and saved');
    final restored = MergeGame.fromJson(saved!);
    expect(restored, isNotNull);
    expect(restored!.score, greaterThan(0));
  });
  test('Mini Sudoku: entries round-trip, and givens are never overwritten', () {
    final board = MiniSudokuBoard.generate(5);
    expect(board.hasProgress, isFalse);

    // Enter the solution into the first two blanks.
    final blanks = [
      for (var r = 0; r < board.size; r++)
        for (var c = 0; c < board.size; c++)
          if (!board.cells[r][c].given) (r, c)
    ];
    expect(blanks.length, greaterThan(2));
    for (final (r, c) in blanks.take(2)) {
      board.cells[r][c].entered = board.cells[r][c].solution;
    }
    expect(board.hasProgress, isTrue);

    final wire =
        jsonDecode(jsonEncode(board.entriesJson())) as Map<String, dynamic>;
    final fresh = MiniSudokuBoard.generate(5);
    expect(fresh.applyEntriesJson(wire), isTrue);
    for (final (r, c) in blanks.take(2)) {
      expect(fresh.cells[r][c].entered, fresh.cells[r][c].solution,
          reason: 'entry at ($r,$c) should be restored');
    }
    // Untouched blanks stay empty.
    final (ur, uc) = blanks.last;
    expect(fresh.cells[ur][uc].entered, isNull);

    // A save from a differently-sized board is refused outright.
    final small = MiniSudokuBoard.generate(1); // 4x4 vs level 5's 6x6
    expect(small.size == board.size, isFalse, reason: 'sizes must differ');
    expect(small.applyEntriesJson(wire), isFalse);
    expect(small.hasProgress, isFalse, reason: 'refusal must change nothing');

    // A digit outside the board's range is refused rather than stored.
    final bad = '9' * (fresh.size * fresh.size);
    expect(fresh.applyEntriesJson({'size': fresh.size, 'entries': bad}), isFalse,
        reason: '9 is not a legal value on a 6x6 board');
  });

  test('Number Cross: placements round-trip and the pool is rebuilt', () {
    final board = NumberCrossBoard.generate(6);
    expect(board.hasProgress, isFalse);
    final poolBefore = [...board.pool];
    expect(poolBefore, isNotEmpty);

    // Place the first pool number into the first empty slot.
    final slot = [
      for (final row in board.cells)
        for (final cell in row)
          if (cell.kind == NcKind.number && !cell.fixed) cell
    ].first;
    final placedValue = poolBefore.first;
    slot.placed = placedValue;
    board.pool.remove(placedValue);
    expect(board.hasProgress, isTrue);

    final wire =
        jsonDecode(jsonEncode(board.placementsJson())) as Map<String, dynamic>;
    final fresh = NumberCrossBoard.generate(6);
    expect(fresh.pool.length, poolBefore.length, reason: 'fresh pool is full');
    expect(fresh.applyPlacementsJson(wire), isTrue);

    final freshSlot = [
      for (final row in fresh.cells)
        for (final cell in row)
          if (cell.kind == NcKind.number && !cell.fixed) cell
    ].first;
    expect(freshSlot.placed, placedValue);
    // The pool is derived from the placements rather than stored, so the two can
    // never disagree — placing one number must remove exactly one tile.
    expect(fresh.pool.length, poolBefore.length - 1);

    // A save claiming a number the pool doesn't hold is refused, or the player
    // would end up with more tiles than the puzzle has.
    final tooMany = {
      'rows': fresh.cells.length,
      'cols': fresh.cells.first.length,
      'placed': [
        for (var i = 0; i < (wire['placed'] as List).length; i++) 99999,
      ],
    };
    final other = NumberCrossBoard.generate(6);
    expect(other.applyPlacementsJson(tooMany), isFalse);
    expect(other.hasProgress, isFalse, reason: 'refusal must change nothing');

    // Wrong slot count is refused too.
    expect(
        other.applyPlacementsJson({
          'rows': other.cells.length,
          'cols': other.cells.first.length,
          'placed': [1],
        }),
        isFalse);
  });

  test('Every game that autosaves declines to save a finished board', () {
    // captureBoard() returning null on a won board is what stops a beaten level
    // being resumed: a win clears the slot and dispose() then runs, so a won
    // board that still captured state would write itself straight back.
    final sudoku = MiniSudokuBoard.generate(3);
    for (final row in sudoku.cells) {
      for (final cell in row) {
        if (!cell.given) cell.entered = cell.solution;
      }
    }
    expect(sudoku.isSolved, isTrue);

    final nono = NonogramBoard.generate(2);
    for (var r = 0; r < nono.height; r++) {
      for (var c = 0; c < nono.width; c++) {
        if (nono.solution[r][c]) nono.marks[r][c] = NonogramMark.filled;
      }
    }
    expect(nono.isSolved, isTrue);
    // Both report progress, so the screens' null-return has to come from the
    // isSolved check rather than from hasProgress being false by luck.
    expect(sudoku.hasProgress, isTrue);
    expect(nono.hasProgress, isTrue);
  });
  test('Arrow games: the escaped set round-trips, and junk is refused', () {
    final board = SnakeBoard.generate(8);
    expect(board.hasProgress, isFalse);

    // Clear the first two arrows that can legally go.
    final cleared = <int>[];
    for (final a in board.arrows) {
      if (cleared.length == 2) break;
      if (board.isPathClear(a)) {
        a.escaped = true;
        cleared.add(a.id);
      }
    }
    expect(cleared.length, 2, reason: 'level 8 should open with a legal move');
    expect(board.hasProgress, isTrue);

    final wire =
        jsonDecode(jsonEncode(board.escapedJson())) as Map<String, dynamic>;
    final fresh = SnakeBoard.generate(8);
    expect(fresh.applyEscapedJson(wire), isTrue);
    for (final a in fresh.arrows) {
      expect(a.escaped, cleared.contains(a.id), reason: 'arrow ${a.id}');
    }

    // Wrong arrow count (a save from another level with a different board).
    expect(
        SnakeBoard.generate(8)
            .applyEscapedJson({'count': 999, 'escaped': cleared}),
        isFalse);
    // An id that isn't on this board at all.
    expect(
        SnakeBoard.generate(8)
            .applyEscapedJson({'count': board.arrows.length, 'escaped': [99999]}),
        isFalse);
    // Not a list.
    expect(
        SnakeBoard.generate(8)
            .applyEscapedJson({'count': board.arrows.length, 'escaped': 3}),
        isFalse);

    // A refusal must leave the board untouched, not half-applied.
    final untouched = SnakeBoard.generate(8);
    expect(
        untouched.applyEscapedJson({
          'count': untouched.arrows.length,
          'escaped': [untouched.arrows.first.id, 99999]
        }),
        isFalse);
    expect(untouched.hasProgress, isFalse);
  });

  test('Arrow games: any partly-cleared board is still winnable', () {
    // This invariant is why `applyEscapedJson` does *not* verify winnability. If
    // a board is solvable, removing arrows only opens paths: take the original
    // solution order, skip the removed arrows, and each remaining arrow still
    // finds its path clear because the blockers present are a subset of those
    // present before. A runtime check could therefore never reject anything —
    // measured at 600 random subsets, zero rejections — so the guarantee is
    // asserted here rather than paid for on every resume.
    final rng = math.Random(20260810);
    for (final level in [1, 5, 12, 20, 35]) {
      final template = SnakeBoard.generate(level);
      final ids = [for (final a in template.arrows) a.id];
      for (var trial = 0; trial < 8; trial++) {
        final subset = [
          for (final id in ids)
            if (rng.nextBool()) id
        ];
        final board = SnakeBoard.generate(level);
        expect(
            board.applyEscapedJson({'count': ids.length, 'escaped': subset}),
            isTrue);

        // Greedily fire whatever can go; everything must eventually leave.
        var progress = true;
        while (progress) {
          progress = false;
          for (final a in board.arrows) {
            if (!a.escaped && board.isPathClear(a)) {
              a.escaped = true;
              progress = true;
            }
          }
        }
        expect(board.isSolved, isTrue,
            reason: 'level $level stranded an arrow after clearing $subset');
      }
    }
  });

  testWidgets('Arrow Maze: an interrupted board comes back, hearts and all',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 3)));
    await tester.pumpAndSettle();

    final board = SnakeBoard.generate(3); // same seed as the screen
    final rect = tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    final cellSize = rect.width / board.cols;
    // The board is painted, not built from widgets, so taps go by position.
    Future<void> tapCell(Cell c) async {
      await tester.tapAt(rect.topLeft +
          Offset((c.col + 0.5) * cellSize, (c.row + 0.5) * cellSize));
      await tester.pumpAndSettle();
    }

    // A blocked arrow costs a heart, so the saved hearts differ from full.
    final maxHearts = snakeConfigForLevel(3).hearts;
    final blocked = board.arrows.firstWhere((a) => !board.isPathClear(a));
    await tapCell(blocked.cells.first);
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets,
        reason: 'a blocked tap should cost a heart');

    // Then clear one that can legally go, so there is progress worth saving.
    final free = board.arrows.firstWhere(board.isPathClear);
    await tapCell(free.cells.first);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    final saved = ProgressStore.instance.loadBoard('arrow_maze', 3);
    expect(saved, isNotNull);
    expect(saved!['hearts'], maxHearts - 1,
        reason: 'the lost heart must survive the interruption too');
    expect(saved['escaped'], contains(free.id));

    // Re-entering restores both the cleared arrow and the missing heart.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 3)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets,
        reason: 'hearts should come back as they were, not reset to full');
  });
  test('Personal records: first finish sets a best, later ones can beat it', () {
    final store = ProgressStore.instance;
    expect(store.bestResult('memory_match', 4), isNull);

    // A first completion sets the best but is NOT a new record: there was nothing
    // to beat, and congratulating someone for merely finishing would make the
    // message meaningless the one time it matters.
    expect(store.recordBest('memory_match', 4, 20, lowerIsBetter: true), isFalse);
    expect(store.bestResult('memory_match', 4), 20);

    // Worse than the best: not a record, and the best is left alone.
    expect(store.recordBest('memory_match', 4, 25, lowerIsBetter: true), isFalse);
    expect(store.bestResult('memory_match', 4), 20);

    // Equal is not better either — "beat" has to mean beat.
    expect(store.recordBest('memory_match', 4, 20, lowerIsBetter: true), isFalse);

    // Fewer moves wins.
    expect(store.recordBest('memory_match', 4, 14, lowerIsBetter: true), isTrue);
    expect(store.bestResult('memory_match', 4), 14);

    // Higher-is-better runs the other way, for scores.
    expect(store.recordBest('merge', 2, 500, lowerIsBetter: false), isFalse);
    expect(store.recordBest('merge', 2, 400, lowerIsBetter: false), isFalse);
    expect(store.bestResult('merge', 2), 500);
    expect(store.recordBest('merge', 2, 900, lowerIsBetter: false), isTrue);
    expect(store.bestResult('merge', 2), 900);

    // Records are per level and per game — "fewest moves" only means something
    // against the same board.
    expect(store.bestResult('memory_match', 5), isNull);
    expect(store.bestResult('merge', 4), isNull);
  });

  testWidgets('Personal records: beating one shows the badge on the win dialog',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    // Pre-load a beatable best for Mini Sudoku level 1 (metric: mistakes).
    ProgressStore.instance
        .recordBest('mini_sudoku', 1, 5, lowerIsBetter: true);

    await tester.pumpWidget(localizedApp(const MiniSudokuScreen(startLevel: 1)));
    await tester.pumpAndSettle();

    // Solve it cleanly: 0 mistakes beats the stored 5.
    final board = MiniSudokuBoard.generate(1);
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        if (board.cells[r][c].given) continue;
        await tester.tap(find.byKey(ValueKey('sudoku_cell_${r}_$c')));
        await tester.pump();
        await tester.tap(find.byKey(
            ValueKey('sudoku_pad_${board.cells[r][c].solution}')));
        await tester.pump();
      }
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Well done!'), findsOneWidget);
    expect(find.text('New personal best!'), findsOneWidget);
    expect(find.text('Your best: no mistakes'), findsOneWidget);
    expect(ProgressStore.instance.bestResult('mini_sudoku', 1), 0);
  });
  test('Word of the day: same date gives the same word, no server needed',
      () async {
    final repo = await WordRepository.forLanguage(wordleLanguages.first);

    // Deterministic in the date, which is what lets two people compare grids.
    final a = repo.wordOfTheDay(DateTime(2026, 3, 14));
    final b = repo.wordOfTheDay(DateTime(2026, 3, 14, 23, 59));
    expect(a, b, reason: 'time of day must not change the word');
    expect(a.length, wordLength);
    expect(repo.isValid(a), isTrue, reason: 'the daily word must be guessable');

    // Consecutive days must not walk the list in order — that would hand out
    // alphabetically adjacent words (ABACK, ABASE, ABATE...).
    final week = [
      for (var d = 1; d <= 14; d++) repo.wordOfTheDay(DateTime(2026, 5, d))
    ];
    expect(week.toSet().length, greaterThan(10),
        reason: 'a fortnight should be mostly distinct words');
    // Walking the answer list in order would come out alphabetically sorted, which
    // is exactly the bug the index scramble exists to prevent. (An earlier version
    // of this check compared adjacent words with compareTo().abs() == 1, which is
    // true for *any* two different strings and so proved nothing.)
    final sorted = [...week]..sort();
    expect(week, isNot(sorted), reason: 'daily words are in alphabetical order');

    // Puzzle numbers advance by one per day and are what the share text quotes.
    expect(WordRepository.dailyPuzzleNumber(DateTime(2026, 3, 15)) -
        WordRepository.dailyPuzzleNumber(DateTime(2026, 3, 14)), 1);
    expect(WordRepository.dailyPuzzleNumber(DateTime(2026, 1, 1)), 1);

    // Each language has its own daily word.
    final nb = await WordRepository.forLanguage(wordleLanguages[1]);
    expect(nb.wordOfTheDay(DateTime(2026, 3, 14)),
        isNot(repo.wordOfTheDay(DateTime(2026, 3, 14))));
  });

  test('Word of the day: the shared grid never leaks the answer', () {
    final rows = [
      [
        LetterState.absent,
        LetterState.present,
        LetterState.absent,
        LetterState.absent,
        LetterState.correct,
      ],
      List.filled(wordLength, LetterState.correct),
    ];
    final text = dailyShareText(
        title: 'Brain Workout — Word 42', rows: rows, solved: true);

    expect(text, contains('Word 42'));
    expect(text, contains('2/$maxGuesses'));
    expect(text, contains('⬜🟨⬜⬜🟩'));
    expect(text, contains('🟩🟩🟩🟩🟩'));
    // The whole point of the format: colours only, so a friend who has not played
    // can see how it went without the word being spoiled.
    expect(RegExp(r'[A-Za-zÆØÅæøå]').allMatches(text.replaceAll('Brain Workout — Word', '')),
        isEmpty,
        reason: 'no letters may appear outside the title');

    // A failed day is marked X, not 6/6.
    final lost = dailyShareText(
        title: 'T', rows: List.filled(maxGuesses, rows.first), solved: false);
    expect(lost, contains('X/$maxGuesses'));
  });

  test('Word of the day: a finished day is remembered, and only that day', () {
    final store = ProgressStore.instance;
    expect(store.dailyWordResult('en', 42), isNull);

    store.recordDailyWord('en', 42, solved: true, rows: ['aapca', 'ccccc']);
    final got = store.dailyWordResult('en', 42);
    expect(got, isNotNull);
    expect(got!.solved, isTrue);
    expect(got.rows, ['aapca', 'ccccc']);

    // Yesterday's result must never read as today's.
    expect(store.dailyWordResult('en', 41), isNull);
    expect(store.dailyWordResult('en', 43), isNull);
    // Per language, since the words differ.
    expect(store.dailyWordResult('nb', 42), isNull);
  });

  testWidgets('Word of the day: finishing it offers share and copy',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    // Pre-file today's result so the screen opens straight onto the card.
    final puzzle = WordRepository.dailyPuzzleNumber(DateTime.now());
    ProgressStore.instance.recordDailyWord('en', puzzle,
        solved: true, rows: ['aapca', 'ccccc']);

    await tester.pumpWidget(localizedApp(const WordleScreen()));
    await tester.pumpAndSettle();

    expect(find.text("Today's word is done!"), findsOneWidget);
    expect(find.byKey(const ValueKey('wordle_share')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey('wordle_copy')).hitTestable(),
        findsOneWidget);

    // Copy puts the spoiler-free grid on the clipboard. The channel is mocked
    // rather than read back: the test binding does not carry a real clipboard, so
    // asserting via Clipboard.getData would be testing the harness, not the app.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.tap(find.byKey(const ValueKey('wordle_copy')));
    await tester.pumpAndSettle();
    expect(copied, isNotNull, reason: 'Copy should write to the clipboard');
    expect(copied, contains('🟩🟩🟩🟩🟩'));
    expect(copied, contains('2/$maxGuesses'));

    // A practice word is still available, and is not the daily.
    await tester.tap(find.byKey(const ValueKey('wordle_practice')));
    await tester.pumpAndSettle();
    expect(find.text("Today's word is done!"), findsNothing);
  });
  test('Arrow Maze bonus arrows: well-formed, stuck at the start, and fair', () {
    for (final level in [1, 8, 12, 20, 40, 60]) {
      final cfg = snakeConfigForLevel(level);
      final board = SnakeBoard.generate(level);
      final bonus = board.bonusArrow;

      if (cfg.bonusFrees == 0) {
        expect(bonus, isNull, reason: 'level $level should have no bonus arrow');
        continue;
      }
      // A board can legitimately lack a bonus if too few arrows start stuck, but
      // the dense late boards should always manage one.
      if (level >= 20) {
        expect(bonus, isNotNull, reason: 'level $level should have a bonus arrow');
      }
      if (bonus == null) continue;

      expect(bonus.frees.length, cfg.bonusFrees, reason: 'level $level link count');
      expect(bonus.frees, isNot(contains(bonus.id)),
          reason: 'a bonus arrow must not free itself');
      expect(bonus.frees.toSet().length, bonus.frees.length,
          reason: 'duplicate links');
      final ids = {for (final a in board.arrows) a.id};
      expect(bonus.frees.every(ids.contains), isTrue,
          reason: 'links must point at real arrows');

      // Both ends start blocked: a tappable bonus arrow would be a free opening
      // move, and freeing arrows that were never stuck would be no gift at all.
      expect(board.isPathClear(bonus), isFalse,
          reason: 'level $level bonus arrow is clear at the start');
      for (final id in bonus.frees) {
        final linked = board.arrows.firstWhere((a) => a.id == id);
        expect(board.isPathClear(linked), isFalse,
            reason: 'level $level frees arrow $id which was never stuck');
      }

      // Still winnable playing normally — the cascade only ever removes arrows,
      // so it cannot strand anything, but the board must be solvable *without*
      // relying on the bonus too.
      var progress = true;
      while (progress) {
        progress = false;
        for (final a in board.arrows) {
          if (!a.escaped && board.isPathClear(a)) {
            a.escaped = true;
            progress = true;
          }
        }
      }
      expect(board.isSolved, isTrue,
          reason: 'level $level must be solvable ignoring the bonus');
    }
  });

  test('Arrow Maze bonus arrows: the cascade fires once and skips the gone', () {
    final board = SnakeBoard.generate(25);
    final bonus = board.bonusArrow!;
    expect(board.bonusFreedBy(bonus).length, bonus.frees.length);

    // An already-escaped link is not freed twice.
    final first = board.arrows.firstWhere((a) => a.id == bonus.frees.first);
    first.escaped = true;
    expect(board.bonusFreedBy(bonus).length, bonus.frees.length - 1);
    expect(board.bonusFreedBy(bonus), isNot(contains(first)));

    // Clearing the bonus last wastes it entirely, which is the decision the
    // mechanic exists to create.
    for (final id in bonus.frees) {
      board.arrows.firstWhere((a) => a.id == id).escaped = true;
    }
    expect(board.bonusFreedBy(bonus), isEmpty);

    // A normal arrow frees nothing.
    final plain = board.arrows.firstWhere((a) => !a.isBonus);
    expect(board.bonusFreedBy(plain), isEmpty);
  });
  testWidgets('Win dialog: closeLabel dismisses without leaving the screen',
      (tester) async {
    // The reported bug: solving the daily word put the win dialog over the result
    // card, and its only non-Home button was "New word" — which replaced the
    // finished daily with a practice word, so the share buttons could never be
    // reached. The fix is this `closeLabel` route, which Wordle passes on a daily
    // win together with "Share" as the primary action.
    //
    // Tested at the dialog level. Driving a whole daily solve through the Wordle
    // screen hangs inside this file for reasons I could not pin down — the same
    // sequence completes in about a second in a standalone test file — so the
    // end-to-end path is verified by hand rather than here. See
    // docs/plans/word-of-the-day.md.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    WinAction? got;
    await tester.pumpWidget(localizedApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              got = await showWinDialog(context,
                  level: 3,
                  accent: Colors.green,
                  stars: 3,
                  nextLabel: 'Share',
                  closeLabel: 'Close');
            },
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // With closeLabel set, the secondary button is Close rather than Home — so
    // dismissing cannot navigate away from a screen that still has work to offer.
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Share'), findsOneWidget);

    await tester.tap(find.text('Close'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(got, WinAction.close,
        reason: 'Close must report itself distinctly from Home, or the caller '
            'cannot tell "stay here" from "leave"');
    // Still on the screen behind the dialog.
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Win dialog: without closeLabel the old Home button is unchanged',
      (tester) async {
    // Guards the other 14 games: adding WinAction.close must not change what any
    // existing caller sees, since they all treat "not next" as "go home".
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    WinAction? got;
    await tester.pumpWidget(localizedApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              got = await showWinDialog(context,
                  level: 1, accent: Colors.blue, stars: 2);
            },
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);

    await tester.tap(find.text('Home'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(got, WinAction.home);
  });

  test('Arrow Maze boards grow past the old 14-column ceiling', () {
    // The cap was 14 purely because a wider board is unreadable without zoom.
    // Zoom exists now, so late boards are ~3x the old area.
    expect(snakeConfigForLevel(17).cols, 14, reason: 'mid-game unchanged');
    expect(snakeConfigForLevel(60).cols, greaterThan(20),
        reason: 'late boards should be much wider now');
    expect(snakeConfigForLevel(60).cols, lessThanOrEqualTo(24),
        reason: 'past 24 columns generation gets too slow to wait for');
    // Monotonic: a later level never hands back a smaller board.
    for (var l = 2; l <= 80; l++) {
      expect(snakeConfigForLevel(l).cols,
          greaterThanOrEqualTo(snakeConfigForLevel(l - 1).cols),
          reason: 'level $l shrank the board');
    }
    // Early levels are untouched, so the tuned early curve still holds.
    for (var l = 1; l <= 17; l++) {
      expect(snakeConfigForLevel(l).cols, lessThanOrEqualTo(14));
    }
  });

  testWidgets('Arrow Maze: zoom controls appear only on boards that need them',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    // A narrow early board reads fine unaided, and the control row would only
    // steal vertical space from the board.
    await tester.pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 1)));
    await tester.pumpAndSettle();
    expect(snakeConfigForLevel(1).cols, lessThanOrEqualTo(14));
    expect(find.byKey(const ValueKey('arrow_maze_zoom_in')), findsNothing);

    // A wide late board gets them.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 60)));
    await tester.pumpAndSettle();
    expect(snakeConfigForLevel(60).cols, greaterThan(14));
    expect(find.byKey(const ValueKey('arrow_maze_zoom_in')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey('arrow_maze_zoom_out')), findsOneWidget);
    expect(find.byKey(const ValueKey('arrow_maze_zoom_fit')), findsOneWidget);
  });

  testWidgets('Arrow Maze: the whole board is visible and tappable at rest',
      (tester) async {
    // Zoom is an aid, never a requirement: at the default scale every arrow must
    // already be reachable, or a player who never zooms is stuck.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 60)));
    await tester.pumpAndSettle();

    final viewer = find.byKey(const ValueKey('arrow_maze_viewer'));
    final board = find.byKey(const ValueKey('arrow_maze_board'));
    final viewerRect = tester.getRect(viewer);
    final boardRect = tester.getRect(board);

    // The painted board fits inside the viewport — nothing is clipped away at
    // rest, so no arrow is unreachable without panning.
    expect(boardRect.width, lessThanOrEqualTo(viewerRect.width + 0.5));
    expect(boardRect.height, lessThanOrEqualTo(viewerRect.height + 0.5));

    // Zooming out is already at its limit, so its button is disabled; zooming in
    // is available.
    final outButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('arrow_maze_zoom_out')));
    expect(outButton.onPressed, isNull, reason: 'cannot zoom out below fit');
    final inButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('arrow_maze_zoom_in')));
    expect(inButton.onPressed, isNotNull);
  });

  testWidgets('Arrow Maze: taps still hit the right cell while zoomed in',
      (tester) async {
    // The real hazard of adding zoom: the InteractiveViewer sits *outside* the
    // GestureDetector so the detector keeps receiving board-space coordinates. Get
    // that backwards and every tap mis-targets once zoomed, while everything else
    // in the suite still passes.
    //
    // Two choices make this test actually sensitive. The screen position of a cell
    // is derived from `getRect` of the painted board, which already reflects the
    // transform — deriving it from the zoom matrix instead would just check the
    // maths against itself. And the assertion is on *which arrow escaped*, read
    // back from the autosave: an earlier version asserted "a heart was lost",
    // which passed even with the transform deliberately applied twice, because on
    // a 93%-full board a mis-aimed tap usually hits some other blocked arrow.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    const level = 60;
    await tester
        .pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: level)));
    await tester.pumpAndSettle();

    final board = SnakeBoard.generate(level); // same seed as the screen
    // A clear arrow near the middle of the board, so it stays on screen once
    // zoomed about the centre.
    double distanceToCentre(SnakeArrow a) {
      final cell = a.cells.first;
      final dr = cell.row - board.rows / 2;
      final dc = cell.col - board.cols / 2;
      return dr * dr + dc * dc;
    }

    final clear = board.arrows.where(board.isPathClear).toList()
      ..sort((a, b) => distanceToCentre(a).compareTo(distanceToCentre(b)));
    expect(clear, isNotEmpty, reason: 'level $level should open with a legal move');
    final target = clear.first;
    final targetCell = target.cells.first;

    await tester.tap(find.byKey(const ValueKey('arrow_maze_zoom_in')));
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    final viewer =
        tester.getRect(find.byKey(const ValueKey('arrow_maze_viewer')));
    expect(rect.width, greaterThan(viewer.width),
        reason: 'the board should be magnified beyond the viewport');

    final cellW = rect.width / board.cols;
    final cellH = rect.height / board.rows;
    final point = rect.topLeft +
        Offset((targetCell.col + 0.5) * cellW, (targetCell.row + 0.5) * cellH);
    expect(viewer.contains(point), isTrue,
        reason: 'the chosen arrow must still be on screen while zoomed');

    await tester.tapAt(point);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700)); // the slide out

    // Read back which arrow actually left.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final saved = ProgressStore.instance.loadBoard('arrow_maze', level);
    expect(saved, isNotNull, reason: 'an arrow should have escaped');
    expect(saved!['escaped'], contains(target.id),
        reason: 'the tap landed on a different arrow than the one aimed at');
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing,
        reason: 'a clear arrow costs no heart, so no other arrow was hit');
  });

  testWidgets('Arrow Maze: fit restores the whole board, and a new level resets',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 60)));
    await tester.pumpAndSettle();

    final boardAtRest =
        tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));

    await tester.tap(find.byKey(const ValueKey('arrow_maze_zoom_in')));
    await tester.pumpAndSettle();
    final zoomed =
        tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    expect(zoomed.width, greaterThan(boardAtRest.width + 1),
        reason: 'zoom in should actually magnify the board');

    await tester.tap(find.byKey(const ValueKey('arrow_maze_zoom_fit')));
    await tester.pumpAndSettle();
    final refit = tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    expect(refit.width, closeTo(boardAtRest.width, 0.5),
        reason: 'fit should return to showing the whole board');

    // Restarting must also drop back to fit — landing in a corner of a fresh
    // board would be disorienting.
    await tester.tap(find.byKey(const ValueKey('arrow_maze_zoom_in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();
    final afterRestart =
        tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    expect(afterRestart.width, closeTo(boardAtRest.width, 0.5),
        reason: 'a new board should start fit to the screen');
  });
  testWidgets('Arrow Maze: freed arrows fly out one by one, not all at once',
      (tester) async {
    // The owner's note: when the golden arrow gets out, the arrows it frees used to
    // blink out of existence. They should leave the way a tapped arrow does.
    //
    // Setting this up needs a path cleared to the golden arrow first, because it is
    // deliberately blocked at the start — so the test escapes everything it legally
    // can *except* the golden arrow and the ones it frees, saves that position, and
    // lets the screen restore it.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    int? chosen;
    SnakeBoard? prepared;
    for (final level in [35, 40, 42, 45, 50]) {
      final b = SnakeBoard.generate(level);
      final bonus = b.bonusArrow;
      if (bonus == null) continue;
      final protectedIds = {bonus.id, ...bonus.frees};
      var progress = true;
      while (progress && !b.isPathClear(bonus)) {
        progress = false;
        for (final a in b.arrows) {
          if (a.escaped || protectedIds.contains(a.id)) continue;
          if (b.isPathClear(a)) {
            a.escaped = true;
            progress = true;
          }
        }
      }
      // Needs the golden arrow reachable with at least two of its partners still
      // on the board, or there is no chain to observe.
      final remaining =
          bonus.frees.where((id) => !b.arrows.firstWhere((a) => a.id == id).escaped);
      if (b.isPathClear(bonus) && remaining.length >= 2) {
        chosen = level;
        prepared = b;
        break;
      }
    }
    expect(chosen, isNotNull,
        reason: 'no level offered a reachable golden arrow to test with');

    final level = chosen!;
    final board = prepared!;
    final bonus = board.bonusArrow!;
    final freedIds = bonus.frees
        .where((id) => !board.arrows.firstWhere((a) => a.id == id).escaped)
        .toList();

    ProgressStore.instance.saveBoard('arrow_maze', level, {
      ...board.escapedJson(),
      'hearts': snakeConfigForLevel(level).hearts,
    });

    await tester.pumpWidget(localizedApp(SnakeArrowsScreen(startLevel: level)));
    await tester.pumpAndSettle();

    // Tap the golden arrow via the painted board's own rect, so no transform maths
    // is duplicated here.
    final rect = tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    final cellW = rect.width / board.cols;
    final cellH = rect.height / board.rows;
    final head = bonus.cells.first;
    await tester.tapAt(rect.topLeft +
        Offset((head.col + 0.5) * cellW, (head.row + 0.5) * cellH));
    await tester.pump();

    /// The escaped set as the game currently sees it, read via the autosave.
    ///
    /// Resuming afterwards is essential, not tidiness: `paused` stops the
    /// scheduler producing frames, which freezes the very animation being
    /// measured. Without the resume the chain stalled after one arrow and the
    /// test blamed the app for what the test itself had done.
    Set<int> escapedNow() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final saved = ProgressStore.instance.loadBoard('arrow_maze', level);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final ids = saved?['escaped'];
      return ids is List ? {for (final v in ids) v as int} : <int>{};
    }

    // One slide's worth: the golden arrow is gone, but its partners cannot all be
    // gone yet — that is the difference between a chain and a vanishing act.
    // 900ms because slideDuration clamps a single slide at 820ms; 700 left the
    // golden arrow still in flight and nothing had escaped at all.
    await tester.pump(const Duration(milliseconds: 900));
    final midway = escapedNow();
    expect(midway, contains(bonus.id), reason: 'the golden arrow should have left');
    expect(freedIds.where(midway.contains).length, lessThan(freedIds.length),
        reason: 'the freed arrows vanished instantly instead of flying out');

    // Let the whole chain finish.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 900));
    }
    final after = escapedNow();
    for (final id in freedIds) {
      expect(after, contains(id), reason: 'freed arrow $id never left');
    }
    // No heart was spent: a cascade is a reward, not a mistake.
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });
  testWidgets('Arrow Maze: a two-finger pinch zooms the board', (tester) async {
    // Asked because pinch appeared not to work on the emulator. The Android
    // emulator needs Ctrl (Cmd on macOS) held while dragging to simulate a second
    // finger — the little circles that appear are its virtual fingertips — so a
    // real two-pointer gesture is worth asserting in code, independently of
    // whatever the emulator is doing with the mouse.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const SnakeArrowsScreen(startLevel: 60)));
    await tester.pumpAndSettle();

    Rect boardRect() =>
        tester.getRect(find.byKey(const ValueKey('arrow_maze_board')));
    final before = boardRect();

    // Two pointers moving apart: a pinch-out.
    final centre =
        tester.getCenter(find.byKey(const ValueKey('arrow_maze_viewer')));
    final finger1 = await tester.startGesture(centre - const Offset(24, 0));
    final finger2 = await tester.startGesture(centre + const Offset(24, 0));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await finger1.moveBy(const Offset(-14, 0));
      await finger2.moveBy(const Offset(14, 0));
      await tester.pump();
    }
    await finger1.up();
    await finger2.up();
    await tester.pumpAndSettle();

    final after = boardRect();
    expect(after.width, greaterThan(before.width + 1),
        reason: 'pinching out should magnify the board');

    // And pinching back in returns toward fit, so the gesture works both ways.
    final f3 = await tester.startGesture(centre - const Offset(90, 0));
    final f4 = await tester.startGesture(centre + const Offset(90, 0));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await f3.moveBy(const Offset(14, 0));
      await f4.moveBy(const Offset(-14, 0));
      await tester.pump();
    }
    await f3.up();
    await f4.up();
    await tester.pumpAndSettle();
    expect(boardRect().width, lessThan(after.width),
        reason: 'pinching in should shrink it again');
  });

}

/// Counts solutions of a nonogram by row-wise backtracking, stopping at [limit].
///
/// Deliberately independent of `solveNonogram`: this is what turns "the line
/// solver finished, so the solution must be unique" from an argument into a
/// checked fact. Exponential, so tests only run it on small grids.
int countNonogramSolutions(
  List<List<int>> rowClues,
  List<List<int>> colClues, {
  int limit = 2,
}) {
  final h = rowClues.length, w = colClues.length;
  final options = [for (final clue in rowClues) _rowPlacements(clue, w)];
  final grid = List.generate(h, (_) => List<bool>.filled(w, false));
  var found = 0;

  /// Whether column [c] is still consistent after [rows] rows are laid down.
  bool columnOk(int c, int rows) {
    final runs = <int>[];
    var open = 0;
    for (var r = 0; r < rows; r++) {
      if (grid[r][c]) {
        open++;
      } else if (open > 0) {
        runs.add(open);
        open = 0;
      }
    }
    final clue = colClues[c];
    for (var i = 0; i < runs.length; i++) {
      if (i >= clue.length || runs[i] != clue[i]) return false;
    }
    if (open > 0) {
      if (runs.length >= clue.length || open > clue[runs.length]) return false;
    }
    if (rows == h) {
      if (open > 0) runs.add(open);
      if (runs.length != clue.length) return false;
      for (var i = 0; i < runs.length; i++) {
        if (runs[i] != clue[i]) return false;
      }
    }
    return true;
  }

  void search(int r) {
    if (found >= limit) return;
    if (r == h) {
      for (var c = 0; c < w; c++) {
        if (!columnOk(c, h)) return;
      }
      found++;
      return;
    }
    for (final placement in options[r]) {
      grid[r] = placement;
      var ok = true;
      for (var c = 0; c < w && ok; c++) {
        if (!columnOk(c, r + 1)) ok = false;
      }
      if (ok) search(r + 1);
      if (found >= limit) return;
    }
    grid[r] = List<bool>.filled(w, false);
  }

  search(0);
  return found;
}

/// Every arrangement of [clue] in a line of [n] cells.
List<List<bool>> _rowPlacements(List<int> clue, int n) {
  final out = <List<bool>>[];
  void place(int idx, int pos, List<bool> cur) {
    if (idx == clue.length) {
      out.add([...cur]);
      return;
    }
    // Every later run still needs its own length plus one separating gap.
    var rest = 0;
    for (var i = idx + 1; i < clue.length; i++) {
      rest += clue[i] + 1;
    }
    final len = clue[idx];
    for (var s = pos; s + len + rest <= n; s++) {
      final next = [...cur];
      for (var k = s; k < s + len; k++) {
        next[k] = true;
      }
      place(idx + 1, s + len + 1, next);
    }
  }

  place(0, 0, List<bool>.filled(n, false));
  return out;
}
