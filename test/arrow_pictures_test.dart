// Arrow Pictures: Arrow Escape's rules on picture boards, with boards built
// ahead of time in a background isolate.
//
// The isolate test is a plain `test()` on purpose: `testWidgets`' fake async
// never lets a real isolate finish (see CLAUDE.md).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_palette.dart';
import 'package:brain_workout/games/arrow_escape/arrow_escape_screen.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_screen.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_shapes.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/main.dart';
import 'package:brain_workout/services/board_prefetch.dart';
import 'package:brain_workout/services/progress_store.dart';
import 'package:brain_workout/widgets/picture_layer.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_screen.dart';

Widget localizedApp(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

String fingerprint(ArrowBoard b) =>
    b.pieces.map((p) => '${p.row},${p.col},${p.dir.index}').join(';');

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
    for (final game in gamesCatalog) {
      ProgressStore.instance.markHelpSeen(game.id);
    }
    arrowPicturesPrefetch.reset();
    arrowPicturesLongPrefetch.reset();
  });
  tearDown(() {
    arrowPicturesPrefetch.reset();
    arrowPicturesLongPrefetch.reset();
  });

  test('Arrow Pictures: every picture is a well-formed mask', () {
    expect(pictureShapes.length, greaterThanOrEqualTo(30));
    final names = <String>{};
    for (final shape in pictureShapes) {
      expect(names.add(shape.name), isTrue,
          reason: '${shape.name} is listed twice');
      // A ragged row is invisible by eye and gives the board a broken edge.
      for (final row in shape.rows) {
        expect(row.length, shape.colCount,
            reason: '${shape.name}: every row must be ${shape.colCount} wide');
        for (final ch in row.split('')) {
          expect(ch == '.' || picturePalette.containsKey(ch), isTrue,
              reason: '${shape.name}: "$ch" is not a palette colour');
          // `#` is the unassigned placeholder: a shipped picture has none.
          expect(ch, isNot('#'),
              reason: '${shape.name} has cells with no colour yet');
        }
      }
      // Past 44 wide a cell is under ~8dp at fit: the picture still reads,
      // but only zoomed in is it playable — the deliberate exception in
      // docs/plans/picture-boards.md, and 44 is as far as it has been probed.
      expect(shape.colCount, lessThanOrEqualTo(44), reason: shape.name);
      expect(shape.rowCount, lessThanOrEqualTo(60), reason: shape.name);
      expect(shape.cellCount, greaterThan(20), reason: shape.name);
      expect(shape.cellCount, lessThan(shape.rowCount * shape.colCount),
          reason: '${shape.name} must leave some air, or it is not a picture');
    }
  });

  test('Arrow Pictures: short arrows below the high-res tier, long from it',
      () {
    expect(pictureArrowsForLevel(pictureFirstLongPosition - 1),
        PictureArrows.short);
    expect(pictureArrowsForLevel(pictureFirstLongPosition), PictureArrows.long);
    expect(pictureArrowsForLevel(pictureShapes.length), PictureArrows.long);
    // Past the end it stays on the big pictures rather than restarting.
    expect(pictureArrowsForLevel(pictureShapes.length + 1), PictureArrows.long);
    // The tier boundary really is where the resolution jumps.
    expect(pictureShapes[pictureFirstLongPosition - 1].colCount,
        greaterThan(16));
    expect(pictureShapes[pictureFirstLongPosition - 2].colCount,
        lessThanOrEqualTo(16));
  });

  test('Arrow Pictures: every level is solvable, on its picture, and stable',
      () {
    // One full pass through the list plus the start of the cycle.
    for (var level = 1; level <= pictureShapes.length + 2; level++) {
      if (pictureArrowsForLevel(level) == PictureArrows.long) {
        checkLongLevel(level);
        continue;
      }
      final shape = pictureShapeForLevel(level);
      final cfg = pictureConfigForLevel(level);
      final board = generatePictureBoard(level);
      final why = 'level $level (${shape.name})';

      // The config must agree with the board, or the screen shows a heart
      // count the board cannot justify.
      expect(board.pieces.length, cfg.arrowCount, reason: why);
      expect((board.rows, board.cols), (cfg.rows, cfg.cols), reason: why);

      final occupied = {for (final p in board.pieces) (p.row, p.col)};
      expect(occupied.length, board.pieces.length, reason: why);
      for (var r = 0; r < shape.rowCount; r++) {
        for (var c = 0; c < shape.colCount; c++) {
          expect(occupied.contains((r, c)), shape.filled(r, c),
              reason: '$why: cell ($r,$c) does not match the picture');
        }
      }

      // Exact, not a heuristic: the game is monotone.
      expect(board.measureDifficulty().solvableGreedily, isTrue, reason: why);
      expect(fingerprint(generatePictureBoard(level)), fingerprint(board),
          reason: '$why must be retry-stable');
    }
  });

  test('Arrow Pictures: the shipped list is pinned, append-only', () {
    // Level N is picture N, and players keep progress: once shipped, a picture
    // may never move or disappear. New ones go on the end — extend this list
    // rather than edit it.
    const pinned = [
      'key', 'lightning_bolt', 'musical_note', 'fish', 'banana', 'mushroom',
      'carrot', 'mug', 'christmas_tree', 'house', 'crescent_moon', 'cherries',
      'bell', 'heart', 'hammer', 'tulip', 'fish_skeleton', 'bird', 'anchor',
      'candle', 'sailboat', 'scissors', 'whale', 'balloon', 'clothes_iron',
      'palm_tree', 'spectacles', 'umbrella', 'crown', 'sun', 'snail',
      'magnifying_glass', 'teapot', 'easter_egg', 'pear', 'rocket', 'pumpkin',
      'bottle', 'dog_bone', 'saturn', 'horse', 'bow_tie', 'kite',
      'hot_air_balloon', 'lighthouse', 'diamond', 'bathtub', 'frying_pan',
      'fishing_boat', 'diamond_ring', 'watermelon_slice', 'lemon', 'horseshoe',
      'boot', 'viking_ship', 'rain_cloud', 'table_lamp', 'cat', 'acorn',
      'mitten', 'star', 'tractor', 'pretzel', 'igloo', 'cactus', 'jellyfish',
      'moose', 'ice_cream_cone', 'owl', 'duck', 'snowflake', 'die', 'trophy',
      'bucket', 'rabbit', 'butterfly', 'light_bulb', 'spade_suit', 'strawberry',
      'flag', 'paw_print', 'padlock', 'club_suit', 'pineapple',
      'christmas_stocking', 'kransekake', 'stave_church', 'troll',
      'cooking_pot', 'tooth', 'four_leaf_clover', 'alarm_clock', 'chess_knight',
      'pine_cone', 'teddy_bear', 'elephant', 'gift_box', 'apple', 'toaster',
      'mountain_cabin', 'cheese_wedge', 'steam_locomotive', 'ladybird',
      'bicycle', 'roe_deer', 'grand_piano', 'pram', 'sheep', 'watering_can',
      'mailbox', 'goat', 'crab', 'anvil', 'hourglass', 'hedgehog',
      'fire_hydrant', 'wheelbarrow', 'saxophone', 'guitar', 'tortoise', 'fox',
      'rocking_chair', 'banjo', 'bird_house', 'seal', 'sewing_machine',
      'rooster', 'oil_lantern', 'puffin', 'scorpion', 'frog', 'gramophone',
      'barn', 'typewriter', 'penguin', 'chess_rook', 'tall_ship',
      'grandfather_clock', 'birdcage', 'snowman', 'squirrel', 'excavator',
      'swan', 'fire_engine', 'wolf', 'cello', 'steam_tug',
      'leaning_tower_of_pisa', 'helicopter', 'eiffel_tower', 'bryggen',
      'rocking_horse', 'peacock', 'giraffe', 'big_ben', 'lobster', 'eagle',
      'statue_of_liberty', 'tower_bridge', 'octopus', 'oak_tree',
      'pyramids_and_sphinx', 'colosseum', 'seahorse', 'pagoda', 'lion',
      'windmill', 'dragon', 'sunflower_in_pot', 'lusekofte',
      'onion_dome_church', 'armchair', 'empire_state_building', 'red_deer_stag',
      'sydney_opera_house', 'biplane', 'camel', 'vintage_car', 'motorcycle',
      'kangaroo', 'humpback_whale', 'ferris_wheel', 'submarine',
      'double_decker_bus', 'spinning_wheel', 'kremlin_spasskaya_tower',
      'walrus', 'tram', 'paddle_steamer', 'golden_gate_bridge', 'tiger',
      'stabbur', 'harp', 'arc_de_triomphe', 'movie_camera', 'stagecoach',
      'fjord_with_rowboat', 'hen_and_chicks', 'mont_saint_michel',
      'coastal_express_ship', 'nidaros_cathedral', 'reindeer', 'stonehenge',
      'angkor_wat', 'notre_dame', 'petronas_towers', 'hagia_sophia',
      'polar_bear', 'brandenburg_gate', 'cuckoo_clock', 'fairytale_castle',
      'parthenon', 'taj_mahal', 'carousel', 'st_pauls_cathedral',
    ];
    expect(pictureShapes.length, greaterThanOrEqualTo(pinned.length));
    expect([for (final s in pictureShapes.take(pinned.length)) s.name], pinned);
  });

  test('Arrow Pictures: the list is ordered by arrow count', () {
    // The tap count is the ramp; a big picture early would be a wall.
    for (var i = 1; i < pictureShapes.length; i++) {
      expect(pictureShapes[i].cellCount,
          greaterThanOrEqualTo(pictureShapes[i - 1].cellCount),
          reason: '${pictureShapes[i].name} is out of order');
    }
  });

  test('Arrow Pictures: past the end it cycles the big pictures, as new boards',
      () {
    // Cycling the whole list sent level 83 back to the 42-arrow key.
    final n = pictureShapes.length;
    expect(pictureShapeForLevel(n + 1).name,
        pictureShapes[pictureFirstLongPosition - 1].name);
    for (var level = n + 1; level <= 3 * n; level++) {
      expect(pictureArrowsForLevel(level), PictureArrows.long,
          reason: 'level $level fell back to a small picture');
      expect(picturePositionForLevel(level),
          greaterThanOrEqualTo(pictureFirstLongPosition));
    }
    // Every big picture comes round once per lap.
    final lap = n - pictureFirstLongPosition + 1;
    expect({for (var l = n + 1; l <= n + lap; l++) pictureShapeForLevel(l).name},
        hasLength(lap));
    // Same picture, different board.
    expect(
        snakeFingerprint(generateLongPictureBoard(n + 1)),
        isNot(snakeFingerprint(
            generateLongPictureBoard(pictureFirstLongPosition))),
        reason: 'a second lap should not replay the identical board');
  });

  test('Arrow Pictures: the first replay lap is mirrored, the next is not', () {
    final n = pictureShapes.length;
    final lap = n - pictureFirstLongPosition + 1;
    expect(pictureMirroredForLevel(n), isFalse);
    final original = pictureShapes[pictureFirstLongPosition - 1];
    final mirrored = pictureShapeForLevel(n + 1);
    // Same picture, so the win dialog still names it.
    expect(mirrored.name, original.name);
    for (var r = 0; r < original.rowCount; r++) {
      expect(mirrored.rows[r], original.rows[r].split('').reversed.join());
    }
    // The board is built on the mirrored mask, and the reveal paints it.
    final board = generateLongPictureBoard(n + 1);
    for (final a in board.arrows) {
      for (final c in a.cells) {
        expect(mirrored.filled(c.row, c.col), isTrue);
      }
    }
    expect(pictureMaskForLevel(n + 1)[0],
        [for (final ch in mirrored.rows[0].split('')) ch != '.']);
    expect(board.measureDifficulty().solvableGreedily, isTrue);
    // Lap two is the right way round again.
    expect(pictureShapeForLevel(n + lap + 1).rows, original.rows);
  });

  test('Arrow Pictures: appending a picture retires cached boards', () {
    // Cycled levels change meaning when the list grows, so the version stamped
    // on a prefetched board has to change with it.
    expect(pictureGeneratorVersion % 10000, pictureShapes.length);
  });

  test('ArrowBoard: JSON round-trips the board but never the play state', () {
    final board = generatePictureBoard(3);
    board.pieces[0].escaped = true;
    board.pieces[5].escaped = true;

    final back = ArrowBoard.fromJson(board.toJson())!;
    expect(fingerprint(back), fingerprint(board));
    expect((back.rows, back.cols), (board.rows, board.cols));
    // Caching the board being played must never bring it back half-cleared.
    expect(back.hasProgress, isFalse);

    // A cache must degrade to regenerating, never throw.
    final good = board.toJson();
    for (final bad in <Map<String, dynamic>>[
      {},
      {...good, 'rows': 0},
      {...good, 'cols': 'x'},
      {...good, 'pieces': [0, 0]},
      {...good, 'pieces': []},
      {...good, 'pieces': [0, 0, 9]},
      {...good, 'pieces': [0, 0, 0, 0, 0, 1]}, // two arrows, one cell
      {...good, 'pieces': [board.rows, 0, 0]},
    ]) {
      expect(ArrowBoard.fromJson(bad), isNull, reason: '$bad');
    }
  });

  test('Arrow Pictures: the background board is identical to a local one',
      () async {
    const level = 4;
    arrowPicturesPrefetch.warm(level);
    await arrowPicturesPrefetch.pending;
    expect(arrowPicturesPrefetch.has(level), isTrue,
        reason: 'the isolate should have produced a board');
    expect(fingerprint(arrowPicturesPrefetch.take(level)!),
        fingerprint(generatePictureBoard(level)));
    // And it was stored, so a restart does not rebuild it.
    expect(
        ProgressStore.instance.hasPrefetchedBoard(
            'arrow_pictures', level, pictureGeneratorVersion),
        isTrue);
  });

  testWidgets('Home screen lists Arrow Pictures', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BrainWorkoutApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Arrow Pictures'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Arrow Pictures'), findsOneWidget);
  });

  testWidgets('Arrow Pictures: a board loads, guards the retry tap, and plays',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    const level = 2;
    await tester
        .pumpWidget(localizedApp(const ArrowPicturesScreen(startLevel: level)));
    // Nothing warmed: the first frame says so instead of freezing.
    expect(find.byKey(const ValueKey('arrow_pictures_loading')), findsOneWidget);
    // obtain() yields one timer turn so the spinner can paint, then builds.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    final boardFinder = find.byKey(const ValueKey('arrow_pictures_board'));
    expect(boardFinder, findsOneWidget);

    final board = generatePictureBoard(level);
    final rect = tester.getRect(boardFinder);
    final cell = rect.width / board.cols;
    expect(rect.height / board.rows, closeTo(cell, 0.01),
        reason: 'cells must stay square on a non-square board');
    Offset centre(ArrowPiece p) =>
        rect.topLeft + Offset((p.col + 0.5) * cell, (p.row + 0.5) * cell);
    final hearts = pictureConfigForLevel(level).hearts;

    // A tap the instant the board lands is swallowed -- aim at a blocked arrow,
    // which is what would cost a heart.
    final blocked = board.pieces.firstWhere((p) => !board.isPathClear(p));
    await tester.tapAt(centre(blocked));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(hearts),
        reason: 'a tap during the settle guard must not cost a heart');

    await tester.pump(const Duration(milliseconds: 450));
    // The guard's tail starts warming the next level.
    expect(arrowPicturesPrefetch.warmingLevel, level + 1);

    final clear = board.pieces.firstWhere(board.isPathClear);
    await tester.tapAt(centre(clear));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(hearts));

    // Read back which arrow left through the autosave, not the screen.
    await tester.pumpWidget(const SizedBox());
    final saved = ProgressStore.instance.loadBoard('arrow_pictures', level)!;
    expect(saved['escaped'], [clear.id]);
  });

  testWidgets('Arrow Pictures: the biggest picture fits a phone',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    // The biggest of each kind: most hearts on the short side, widest grid on
    // the long side.
    for (final level in [pictureFirstLongPosition - 1, pictureShapes.length]) {
      await tester
          .pumpWidget(localizedApp(ArrowPicturesScreen(startLevel: level)));
      // obtain() yields one timer turn so the spinner can paint, then builds.
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.takeException(), isNull,
          reason: 'level $level: the layout overflowed');
      final hearts = pictureArrowsForLevel(level) == PictureArrows.long
          ? pictureLongHearts
          : pictureConfigForLevel(level).hearts;
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(hearts),
          reason: 'level $level');
      final rect =
          tester.getRect(find.byKey(const ValueKey('arrow_pictures_board')));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(rect.left, greaterThanOrEqualTo(0), reason: 'level $level');
      expect(rect.right, lessThanOrEqualTo(screen.width),
          reason: 'level $level');
      expect(rect.bottom, lessThanOrEqualTo(screen.height),
          reason: 'level $level');
      // A fresh State per level; initState is where the level loads.
      await tester.pumpWidget(const SizedBox());
    }
  });

  test('Long-arrow pictures: snakes stay on the picture and the board solves',
      () {
    // The trap the plan warns about: masking by marking outside cells occupied
    // makes every ray that crosses the background look blocked, so almost no
    // head is placeable. It would still solve -- the real board has fewer
    // blockers, not more -- so it is the fill assertion that catches it.
    for (final name in ['christmas_tree', 'cat', 'mountain_cabin']) {
      final shape = pictureShapes.firstWhere((s) => s.name == name);
      final mask = [
        for (final r in shape.rows) [for (final ch in r.split('')) ch != '.']
      ];
      final board =
          SnakeBoard.generateShaped(shape.rows, seed: 2, minLength: 4);
      final seen = <(int, int)>{};
      for (final a in board.arrows) {
        expect(a.cells.length, greaterThanOrEqualTo(4), reason: name);
        for (final c in a.cells) {
          expect(shape.filled(c.row, c.col), isTrue,
              reason: '$name: a snake left the picture at (${c.row},${c.col})');
          expect(seen.add((c.row, c.col)), isTrue, reason: '$name: overlap');
        }
      }
      expect(board.measureDifficulty().solvableGreedily, isTrue, reason: name);
      // An uncovered patch inside a picture reads as a broken picture.
      expect(board.fillWithin(mask), greaterThan(0.9), reason: name);
      expect(board.largestEmptyFractionWithin(mask), lessThan(0.05),
          reason: name);

      String fp(SnakeBoard b) => b.arrows
          .map((a) => a.cells.map((c) => '${c.row},${c.col}').join(' '))
          .join('|');
      expect(fp(SnakeBoard.generateShaped(shape.rows, seed: 2, minLength: 4)),
          fp(board),
          reason: '$name must be retry-stable');
    }
  });

  test('Arrow Pictures: the next level is warmed in the right kind of board',
      () async {
    // Level 39 warming a *short* board for level 40 would waste the whole
    // prefetch and leave the long level generating behind a spinner.
    warmPictureLevel(pictureFirstLongPosition);
    expect(arrowPicturesLongPrefetch.warmingLevel, pictureFirstLongPosition);
    expect(arrowPicturesPrefetch.warmingLevel, isNull);
    await arrowPicturesLongPrefetch.pending;

    // And the background board is the one the level generates locally.
    final warmed = arrowPicturesLongPrefetch.take(pictureFirstLongPosition)!;
    expect(snakeFingerprint(warmed),
        snakeFingerprint(generateLongPictureBoard(pictureFirstLongPosition)));
  });

  testWidgets('Arrow Pictures: crossing to long arrows swaps the screen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    const last = pictureFirstLongPosition - 1;
    await tester.pumpWidget(
        localizedApp(const ArrowPicturesScreen(startLevel: last)));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(ArrowEscapeScreen), findsOneWidget);

    final context = tester.element(find.byType(ArrowEscapeScreen));
    // Same kind: "Next level" loads in place, like every other game.
    expect(ArrowPicturesScreen.shortSpec.redirect!(context, last), isFalse);
    // Other kind: the screen is replaced.
    expect(ArrowPicturesScreen.shortSpec.redirect!(context, last + 1), isTrue);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ArrowEscapeScreen), findsNothing);
    expect(find.byType(SnakeArrowsScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('arrow_pictures_board')), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded),
        findsNWidgets(pictureLongHearts));
    await tester.pumpWidget(const SizedBox());
  });

  test('Arrow Pictures: every picture is named in both languages', () {
    // A picture missing from the ARB select falls back to "a picture", which
    // would read as a bug in the one place the game tells you what you made.
    final en = lookupAppLocalizations(const Locale('en'));
    final nb = lookupAppLocalizations(const Locale('nb'));
    for (final shape in pictureShapes) {
      expect(en.pictureName(shape.name), isNot('a picture'),
          reason: '${shape.name} has no English name');
      expect(nb.pictureName(shape.name), isNot('et bilde'),
          reason: '${shape.name} has no Norwegian name');
    }
    final seahorse =
        pictureShapes.indexWhere((s) => s.name == 'seahorse') + 1;
    expect(ArrowPicturesScreen.winMessage(en, seahorse),
        'You cleared level $seahorse. It was a seahorse!');
    expect(ArrowPicturesScreen.winMessage(nb, seahorse),
        'Du klarte nivå $seahorse. Det var en sjøhest!');
  });

  testWidgets('Arrow Pictures: an outline only where arrows are lines',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    PictureLayerPainter? layer() {
      final hits = find
          .byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is PictureLayerPainter)
          .evaluate();
      if (hits.isEmpty) return null;
      return (hits.first.widget as CustomPaint).painter as PictureLayerPainter;
    }

    // Short arrows are solid tiles: the picture is there, but not shown yet.
    await tester
        .pumpWidget(localizedApp(const ArrowPicturesScreen(startLevel: 3)));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(layer(), isNotNull);
    expect(layer()!.outline, isFalse);
    expect(layer()!.reveal, 0, reason: 'colour is withheld during play');

    // Arrow Escape is not a picture game at all.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(localizedApp(const ArrowEscapeScreen(startLevel: 3)));
    await tester.pump();
    expect(layer(), isNull);
    await tester.pumpWidget(const SizedBox());

    // Long arrows are thin lines; they get the faint outline.
    expect(ArrowPicturesScreen.longSpec.pictureOutline, isTrue);
    expect(ArrowPicturesScreen.shortSpec.pictureOutline, isFalse);
  });

  testWidgets('Arrow Pictures: a wide picture zooms into the whole board area',
      (tester) async {
    // A 16x7 picture fills only a strip of the portrait board area. Zoom used
    // to be confined to that strip, so zooming in barely helped.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final level = pictureShapes.indexWhere((s) => s.name == 'fish_skeleton') + 1;
    await tester
        .pumpWidget(localizedApp(ArrowPicturesScreen(startLevel: level)));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 450)); // past the tap guard

    final viewer = find.byKey(const ValueKey('arrow_pictures_viewer'));
    final boardFinder = find.byKey(const ValueKey('arrow_pictures_board'));
    final fit = tester.getRect(boardFinder);
    expect(tester.getRect(viewer).height, greaterThan(fit.height * 1.8),
        reason: 'the zoom area must be the board area, not the picture strip');

    await tester.tap(find.byKey(const ValueKey('arrow_pictures_zoom_in')));
    await tester.pump();
    final zoomed = tester.getRect(boardFinder);
    expect(zoomed.height, closeTo(fit.height * 1.5, 1));

    // A tap while zoomed still frees the arrow under it. Aim at a clear arrow
    // whose centre is on screen, using the painted (transformed) board rect.
    final board = generatePictureBoard(level);
    final cell = zoomed.width / board.cols;
    final area = tester.getRect(viewer);
    Offset centre(ArrowPiece p) =>
        zoomed.topLeft + Offset((p.col + 0.5) * cell, (p.row + 0.5) * cell);
    final target = board.pieces
        .firstWhere((p) => board.isPathClear(p) && area.contains(centre(p)));
    await tester.tapAt(centre(target));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    final saved = ProgressStore.instance.loadBoard('arrow_pictures', level)!;
    expect(saved['escaped'], [target.id]);
  });

  testWidgets('Arrow Pictures: long-arrow boards zoom into the whole area too',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final level =
        pictureShapes.indexWhere((s) => s.name == 'double_decker_bus') + 1;
    expect(pictureArrowsForLevel(level), PictureArrows.long);
    await tester
        .pumpWidget(localizedApp(ArrowPicturesScreen(startLevel: level)));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    final viewer = tester.getRect(find.byKey(const ValueKey('arrow_pictures_viewer')));
    final board = tester.getRect(find.byKey(const ValueKey('arrow_pictures_board')));
    expect(viewer.height, greaterThan(board.height * 1.3));
    expect(viewer.contains(board.center), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Arrow Pictures: the reveal returns to fit if zoomed in',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final level = pictureShapes.indexWhere((s) => s.name == 'fish_skeleton') + 1;
    await tester
        .pumpWidget(localizedApp(ArrowPicturesScreen(startLevel: level)));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 450));

    final boardFinder = find.byKey(const ValueKey('arrow_pictures_board'));
    final fit = tester.getRect(boardFinder);
    final board = generatePictureBoard(level);
    final fitCell = fit.width / board.cols;

    // Clear all but one arrow at fit.
    while (board.pieces.where((p) => !p.escaped).length > 1) {
      final p = board.pieces.firstWhere((p) => !p.escaped && board.isPathClear(p));
      await tester.tapAt(fit.topLeft +
          Offset((p.col + 0.5) * fitCell, (p.row + 0.5) * fitCell));
      p.escaped = true;
      await tester.pump(const Duration(milliseconds: 600));
    }
    // Zoom in centred on the last arrow, as a pinch there would.
    final last = board.pieces.firstWhere((p) => !p.escaped);
    final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const ValueKey('arrow_pictures_viewer')));
    final viewerRect =
        tester.getRect(find.byKey(const ValueKey('arrow_pictures_viewer')));
    final lastLocal = fit.topLeft - viewerRect.topLeft +
        Offset((last.col + 0.5) * fitCell, (last.row + 0.5) * fitCell);
    viewer.transformationController!.value = Matrix4.identity()
      ..translateByDouble(viewerRect.width / 2 - 2 * lastLocal.dx,
          viewerRect.height / 2 - 2 * lastLocal.dy, 0, 1)
      ..scaleByDouble(2, 2, 1, 1);
    await tester.pump();
    expect(tester.getRect(boardFinder).width, closeTo(fit.width * 2, 1));

    await tester.tapAt(viewerRect.center);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(viewer.transformationController!.value, Matrix4.identity(),
        reason: 'the finished picture must be seen whole');
    expect(tester.getRect(boardFinder), fit);

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Arrow Pictures: the finished picture is revealed before the dialog',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    const level = 1;
    await tester
        .pumpWidget(localizedApp(const ArrowPicturesScreen(startLevel: level)));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 450)); // past the tap guard

    final board = generatePictureBoard(level);
    final rect =
        tester.getRect(find.byKey(const ValueKey('arrow_pictures_board')));
    final cell = rect.width / board.cols;

    // Play the whole board: repeatedly fire an arrow whose path is clear.
    while (!board.isSolved) {
      final p = board.pieces.firstWhere((p) => !p.escaped && board.isPathClear(p));
      await tester.tapAt(
          rect.topLeft + Offset((p.col + 0.5) * cell, (p.row + 0.5) * cell));
      p.escaped = true; // mirror the screen's board
      await tester.pump(const Duration(milliseconds: 600));
    }
    // The reveal starts once the last arrow has finished sliding out.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));

    final painter = (find
            .byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is PictureLayerPainter)
            .evaluate()
            .first
            .widget as CustomPaint)
        .painter as PictureLayerPainter;
    expect(painter.reveal, greaterThan(0),
        reason: 'the picture should be fading in');
    expect(find.text('Well done!'), findsNothing,
        reason: 'the dialog must wait for the picture');

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('It was a key!'), findsOneWidget);
  });
}

String snakeFingerprint(SnakeBoard b) => b.arrows
    .map((a) =>
        '${a.cells.map((c) => '${c.row},${c.col}').join(' ')}>${a.exitDir.index}')
    .join('|');

void checkLongLevel(int level) {
  final shape = pictureShapeForLevel(level);
  final why = 'level $level (${shape.name}, long)';
  final mask = [
    for (final r in shape.rows) [for (final ch in r.split('')) ch != '.']
  ];
  final board = generateLongPictureBoard(level);
  expect((board.rows, board.cols), (shape.rowCount, shape.colCount),
      reason: why);
  for (final a in board.arrows) {
    expect(a.cells.length, greaterThanOrEqualTo(pictureLongMinLength),
        reason: why);
    for (final c in a.cells) {
      expect(shape.filled(c.row, c.col), isTrue,
          reason: '$why: a snake left the picture at (${c.row},${c.col})');
    }
  }
  expect(board.measureDifficulty().solvableGreedily, isTrue, reason: why);
  // A patchy picture reads as a broken one.
  expect(board.fillWithin(mask), greaterThan(0.85), reason: why);
}
