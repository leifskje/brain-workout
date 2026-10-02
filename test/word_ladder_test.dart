// Word Ladder: par is the true shortest ladder (no rare-word shortcut beats
// it), endpoints are everyday words, any real word is accepted as a step, and
// the hint always points along a shortest ladder.
//
// The dictionaries are warmed in setUpAll: an asset read inside testWidgets'
// fake-async zone never finishes (see CLAUDE.md).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/data/dictionary.dart';
import 'package:brain_workout/data/word_tier.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/games/word_ladder/word_ladder_models.dart';
import 'package:brain_workout/games/word_ladder/word_ladder_screen.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/services/progress_store.dart';

Widget localizedApp(Widget home, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

final Map<String, LadderIndex> indexes = {};

LadderIndex indexFor(String language) => indexes[language] ??= () {
  final d = Dictionary.loaded(language)!;
  return LadderIndex(language, [for (final w in d.words) (w, d.tierOf(w)!)]);
}();

/// Changes the current word into [word] by tapping its one differing position
/// and then that letter's key.
Future<void> stepTo(WidgetTester tester, String current, String word) async {
  final i = List.generate(
    word.length,
    (i) => i,
  ).firstWhere((i) => current[i] != word[i]);
  await tester.tap(find.byKey(ValueKey('ladder_pos_$i')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('ladder_key_${word[i]}')));
  await tester.pump();
}

Future<void> openLevel(WidgetTester tester, int level) async {
  await tester.pumpWidget(localizedApp(WordLadderScreen(startLevel: level)));
  await tester.pump();
  await tester.pump();
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Dictionary.forLanguage('en');
    await Dictionary.forLanguage('nb');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
    for (final game in gamesCatalog) {
      ProgressStore.instance.markHelpSeen(game.id);
    }
  });

  test('Levels 1-40: par is the true shortest ladder, endpoints are everyday '
      'words, and generation is retry-stable', () {
    for (final language in ['en', 'nb']) {
      final index = indexFor(language);
      final dictionary = Dictionary.loaded(language)!;
      for (var level = 1; level <= 40; level++) {
        final p = WordLadderPuzzle.generate(level, index);
        final why = '$language level $level (${p.start} > ${p.target})';
        final cfg = wordLadderConfigForLevel(level, language);
        expect(p.start.length, cfg.length, reason: why);
        expect(p.target.length, cfg.length, reason: why);
        for (final end in [p.start, p.target]) {
          expect(
            endpointTiersFor(language),
            contains(dictionary.tierOf(end)),
            reason: '$why: $end is not an everyday word',
          );
        }
        // Over the par tiers, and over every word: equal, so no rare word
        // makes "Shortest" a lie.
        final fair = index.distancesFrom(p.start, tiers: p.parTiers);
        final any = index.distancesFrom(p.start);
        expect(fair[p.target], p.par, reason: why);
        expect(any[p.target], p.par, reason: '$why has a rare shortcut');
        // Every target in the analyzer's spread is reachable, so a miss here
        // means the curve has silently flattened.
        expect(p.par, cfg.par, reason: '$why missed its par target');
        expect(p.detour, cfg.detour, reason: '$why missed its detour target');

        expect(p.solution.first, p.start, reason: why);
        expect(p.solution.last, p.target, reason: why);
        expect(p.solution.length, p.par + 1, reason: why);
        expect(
          p.solution.where(LadderIndex.neverSet.contains),
          isEmpty,
          reason: why,
        );
        for (var i = 1; i < p.solution.length; i++) {
          expect(hamming(p.solution[i - 1], p.solution[i]), 1, reason: why);
          expect(
            p.parTiers,
            contains(index.tierOf(p.solution[i])),
            reason: why,
          );
        }
        final again = WordLadderPuzzle.generate(level, index);
        expect(
          '${again.start}>${again.target}',
          '${p.start}>${p.target}',
          reason: '$why is not retry-stable',
        );
      }
    }
  });

  test('No puzzle comes round twice in the first 80 levels', () {
    // Nearby seeds once made Dart's Random land on the same pair again and
    // again (Norwegian level 38 was level 32) from pools of over 1000 pairs.
    for (final language in ['en', 'nb']) {
      final index = indexFor(language);
      final seen = <String, int>{};
      for (var level = 1; level <= 80; level++) {
        final p = WordLadderPuzzle.generate(level, index);
        final pair = ([p.start, p.target]..sort()).join('/');
        expect(
          seen[pair],
          isNull,
          reason: '$language level $level repeats level ${seen[pair]}',
        );
        seen[pair] = level;
      }
    }
  });

  test('Difficulty climbs: longer words, longer ladders, more detours', () {
    for (final language in ['en', 'nb']) {
      final index = indexFor(language);
      final early = WordLadderPuzzle.generate(2, index);
      final late = WordLadderPuzzle.generate(40, index);
      expect(late.length, greaterThan(early.length));
      expect(late.par, greaterThan(early.par + 3));
      expect(late.detour, greaterThan(early.detour + 1));
    }
  });

  test(
    'A step must change one letter into a real word, rare ones included',
    () {
      final index = indexFor('en');
      final p = WordLadderPuzzle.generate(1, index);
      final ladder = [p.start];
      final next = p.solution[1];
      expect(p.check(p.start, next, ladder), StepVerdict.ok);
      expect(p.check(p.start, p.start, ladder), StepVerdict.unchanged);
      expect(
        p.check(p.start, '${p.start.substring(0, 3)}Q', ladder),
        StepVerdict.notAWord,
      );
      // Two letters at once is not a step, even into a real word.
      final two = index
          .wordsOf(p.length, WordTier.values.toSet())
          .firstWhere((w) => hamming(w, p.start) == 2);
      expect(p.check(p.start, two, ladder), StepVerdict.notAWord);
      // Back onto a word already climbed is refused.
      expect(p.check(next, p.start, [p.start, next]), StepVerdict.alreadyUsed);

      // Junk-tier neighbours are real words and must be accepted.
      final dictionary = Dictionary.loaded('en')!;
      final rare = index
          .neighbours(p.start)
          .where((w) => dictionary.tierOf(w) == WordTier.junk)
          .toList();
      expect(
        rare,
        isNotEmpty,
        reason: 'no junk neighbour of ${p.start} to test',
      );
      for (final w in rare) {
        expect(p.check(p.start, w, ladder), StepVerdict.ok, reason: w);
      }
    },
  );

  test('A hint names the next word on a shortest ladder from anywhere', () {
    for (final language in ['en', 'nb']) {
      final index = indexFor(language);
      for (final level in [1, 12, 25, 40]) {
        final p = WordLadderPuzzle.generate(level, index);
        final back = index.distancesFrom(p.target, tiers: p.parTiers);
        // From the start, and from a word off the solution.
        final off = index
            .neighbours(p.start, p.parTiers)
            .firstWhere((w) => back[w] != null && back[w]! >= p.par);
        for (final from in [p.start, off]) {
          final h = p.hint(from)!;
          expect(hamming(from, h), 1, reason: '$language $level from $from');
          expect(
            back[h],
            back[from]! - 1,
            reason: '$language $level: $h is not a step closer',
          );
        }
        expect(p.hint(p.target), isNull);
      }
    }
  });

  test('Stars: 3 at par, 2 within two steps or with a hint, else 1', () {
    expect(WordLadderPuzzle.starsFor(5, 5, usedHint: false), 3);
    expect(WordLadderPuzzle.starsFor(7, 5, usedHint: false), 2);
    expect(WordLadderPuzzle.starsFor(8, 5, usedHint: false), 1);
    expect(WordLadderPuzzle.starsFor(5, 5, usedHint: true), 2);
    expect(WordLadderPuzzle.starsFor(9, 5, usedHint: true), 1);
  });

  testWidgets('Climbing the shortest ladder wins with three stars', (
    tester,
  ) async {
    phone(tester);
    await openLevel(tester, 4);
    final p = WordLadderPuzzle.generate(4, indexFor('en'));
    expect(find.text('Shortest: ${p.par} steps'), findsOneWidget);

    // A miss first: costs nothing and adds no rung.
    await tester.tap(find.byKey(const ValueKey('ladder_pos_0')));
    await tester.pump();
    final bad = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        .split('')
        .firstWhere((c) => !indexFor('en').isWord(c + p.start.substring(1)));
    await tester.tap(find.byKey(ValueKey('ladder_key_$bad')));
    await tester.pump();
    expect(find.textContaining('not in the word list'), findsOneWidget);
    expect(find.text('No steps yet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ladder_pos_0'))); // deselect
    await tester.pump();

    for (var i = 1; i < p.solution.length; i++) {
      expect(find.text('Well done!'), findsNothing);
      await stepTo(tester, p.solution[i - 1], p.solution[i]);
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Well done!'), findsOneWidget);
    expect(ProgressStore.instance.stars('word_ladder', 4), 3);
    expect(ProgressStore.instance.bestResult('word_ladder', 4), p.par);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Stepping back is free, and a hint caps the level at two stars', (
    tester,
  ) async {
    phone(tester);
    await openLevel(tester, 2);
    final p = WordLadderPuzzle.generate(2, indexFor('en'));

    await stepTo(tester, p.start, p.solution[1]);
    expect(find.text('You: 1 step'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ladder_undo')));
    await tester.pump();
    expect(find.text('No steps yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('game_hint_button')));
    await tester.pump();
    final hinted = p.hint(p.start)!;
    expect(find.text('Hint: try $hinted'), findsOneWidget);

    var current = p.start;
    while (current != p.target) {
      final next = p.hint(current)!;
      await stepTo(tester, current, next);
      current = next;
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Well done!'), findsOneWidget);
    expect(ProgressStore.instance.stars('word_ladder', 2), 2);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('The ladder comes back after leaving the level', (tester) async {
    phone(tester);
    final p = WordLadderPuzzle.generate(5, indexFor('en'));
    await openLevel(tester, 5);
    await stepTo(tester, p.solution[0], p.solution[1]);
    await stepTo(tester, p.solution[1], p.solution[2]);

    await tester.pumpWidget(const SizedBox());
    await openLevel(tester, 5);
    expect(find.text('You: 2 steps'), findsOneWidget);
    // The climbed rungs are listed, spaced out letter by letter.
    expect(find.text(p.solution[1].split('').join(' ')), findsOneWidget);
    for (var i = 0; i < p.length; i++) {
      final tile = find.descendant(
        of: find.byKey(ValueKey('ladder_pos_$i')),
        matching: find.text(p.solution[2][i]),
      );
      expect(tile, findsOneWidget);
    }
  });

  for (final (language, letters) in [
    ('en', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
    ('nb', 'ABCDEFGHIJKLMNOPQRSTUVWXYZÆØÅ'),
  ]) {
    testWidgets('Fits a small phone at the largest text scale ($language)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0; // 360x640 logical
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // A late level: the longest words and the longest ladder.
      final level = 39;
      final p = WordLadderPuzzle.generate(level, indexFor(language));
      await tester.pumpWidget(
        localizedApp(
          WordLadderScreen(startLevel: level),
          locale: Locale(language),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Climb most of the way, so the ladder list is full too.
      for (var i = 1; i < p.solution.length - 1; i++) {
        await stepTo(tester, p.solution[i - 1], p.solution[i]);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('ladder_pos_0')));
      await tester.pump();
      for (final ch in letters.split('')) {
        expect(
          find.byKey(ValueKey('ladder_key_$ch')).hitTestable(),
          findsOneWidget,
          reason: '$ch is not tappable',
        );
      }
      for (var i = 0; i < p.length; i++) {
        expect(
          find.byKey(ValueKey('ladder_pos_$i')).hitTestable(),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('ladder_target')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ladder_undo')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
