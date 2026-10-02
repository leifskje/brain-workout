// Letter hive: every puzzle is built around a pangram, answers always use the
// centre letter, and any real word is accepted, rare ones as a bonus.
//
// The dictionaries are warmed in setUpAll: an asset read inside testWidgets'
// fake-async zone never finishes (see CLAUDE.md).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/data/dictionary.dart';
import 'package:brain_workout/data/word_tier.dart';
import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/games/letter_hive/letter_hive_models.dart';
import 'package:brain_workout/games/letter_hive/letter_hive_screen.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/main.dart';
import 'package:brain_workout/services/progress_store.dart';

Widget localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

final Map<String, HiveIndex> indexes = {};

HiveIndex indexFor(String language) => indexes[language] ??= () {
  final d = Dictionary.loaded(language)!;
  return HiveIndex(language, [for (final w in d.words) (w, d.tierOf(w)!)]);
}();

Future<void> spell(WidgetTester tester, String word) async {
  for (final ch in word.split('')) {
    await tester.tap(find.byKey(ValueKey('hive_letter_$ch')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const ValueKey('hive_ok')));
  await tester.pump();
}

/// Lets the feedback message's clear-timer run out, so no timer is left
/// pending when the test ends.
Future<void> drainMessages(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 2));

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

  test('Levels 1-40 have a pangram, use the centre letter, and are stable', () {
    for (final language in ['en', 'nb']) {
      final index = indexFor(language);
      for (var level = 1; level <= 40; level++) {
        final p = LetterHivePuzzle.generate(level, index);
        final why = '$language level $level (${p.letters})';
        final cfg = letterHiveConfigForLevel(level);
        expect(p.letters.split('').toSet().length, 7, reason: why);
        expect(p.pangrams, isNotEmpty, reason: '$why has no pangram');
        expect(
          p.answers.length,
          inInclusiveRange(cfg.minAnswers, cfg.maxAnswers),
          reason: '$why fell outside the answer band',
        );
        for (final w in p.answers) {
          expect(w.contains(p.centre), isTrue, reason: '$why: $w');
          expect(w.length, greaterThanOrEqualTo(minWordLength), reason: why);
          expect(
            cfg.tiers,
            contains(Dictionary.loaded(language)!.tierOf(w)),
            reason: '$why: $w is not a tier the goal counts',
          );
          expect(p.check(w, const {}), HiveVerdict.ok, reason: '$why: $w');
        }
        if (language == 'en') {
          expect(p.letters.contains('S'), isFalse, reason: why);
        }
        expect(
          LetterHivePuzzle.generate(level, index).letters,
          p.letters,
          reason: '$why is not retry-stable',
        );
      }
    }
  });

  test('No letter set repeats until every one has been used', () {
    // Version 1 seeded each level with Random(level * k + c), and nearby
    // seeds drew alike: 29 of the first 120 Norwegian levels repeated one.
    for (final language in ['en', 'nb']) {
      final index = indexFor(language);
      final seen = <String, int>{};
      final distinct = index.letterSets.length;
      for (var level = 1; level <= 200 && level <= distinct; level++) {
        final p = LetterHivePuzzle.generate(level, index);
        final key = (p.letters.split('')..sort()).join();
        expect(
          seen[key],
          isNull,
          reason: '$language level $level repeats level ${seen[key]}',
        );
        seen[key] = level;
      }
    }
    // Far past the end of the sets, a level still opens.
    final far = LetterHivePuzzle.generate(1500, indexFor('nb'));
    expect(far.pangrams, isNotEmpty);
  });

  test('Words are checked fairly and scored the usual way', () {
    final index = indexFor('en');
    final p = LetterHivePuzzle.generate(1, index);
    final word = p.answers.firstWhere((w) => !p.isPangram(w));
    final pangram = p.pangrams.first;

    expect(p.check(word.substring(0, 3), const {}), HiveVerdict.tooShort);
    final noCentre = p.letters.substring(1, 5);
    expect(p.check(noCentre, const {}), HiveVerdict.missingCentre);
    expect(p.check(word, {word}), HiveVerdict.alreadyFound);
    expect(
      p.check(p.centre * 4 + p.letters[1] * 3, const {}),
      HiveVerdict.notAWord,
    );

    expect(p.pointsFor(pangram), pangram.length + 7);
    final four = p.answers.where((w) => w.length == 4 && !p.isPangram(w));
    if (four.isNotEmpty) expect(p.pointsFor(four.first), 1);

    // A real word the goal doesn't count is still accepted.
    final dictionary = Dictionary.loaded('en')!;
    final full = index.maskOf(p.letters)!;
    final centre = index.maskOf(p.centre)!;
    final rare = index
        .answersFor(full, centre, const {WordTier.lessCommon})
        .where((w) => !p.answers.contains(w));
    for (final w in rare.take(3)) {
      expect(dictionary.tierOf(w), WordTier.lessCommon);
      expect(p.check(w, const {}), HiveVerdict.ok, reason: w);
    }
  });

  test('Goals climb with the level and stars are in order', () {
    for (final language in ['en', 'nb']) {
      final index = indexFor(language);
      for (var level = 1; level <= 40; level++) {
        final p = LetterHivePuzzle.generate(level, index);
        final [one, two, three] = p.starPoints;
        expect(one, greaterThan(0));
        expect(
          one <= two && two <= three && three <= p.totalPoints,
          isTrue,
          reason: '$language level $level: ${p.starPoints}',
        );
      }
    }
    expect(
      letterHiveConfigForLevel(31).goal,
      greaterThan(letterHiveConfigForLevel(1).goal + 0.25),
    );
  });

  testWidgets('Letter Hive is on the home screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BrainWorkoutApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Letter Hive'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Letter Hive'), findsOneWidget);
  });

  testWidgets('Fits a small phone at the largest text scale', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0; // 360x640 logical
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(localizedApp(const LetterHiveScreen()));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    final p = LetterHivePuzzle.generate(1, indexFor('en'));
    for (final ch in p.letters.split('')) {
      expect(
        find.byKey(ValueKey('hive_letter_$ch')).hitTestable(),
        findsOneWidget,
        reason: '$ch is not tappable',
      );
    }
    expect(
      find.byKey(const ValueKey('hive_shuffle')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('Spelling words scores them, and reaching the goal clears it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const LetterHiveScreen()));
    await tester.pump();
    await tester.pump();

    final p = LetterHivePuzzle.generate(1, indexFor('en'));

    // A miss first: no centre letter.
    final outer = p.letters.substring(1);
    await spell(tester, outer.substring(0, 4));
    expect(find.textContaining('centre letter'), findsOneWidget);

    // Longest first, so the goal comes quickly; the pangram is among them.
    final words = List.of(p.answers)
      ..sort((a, b) => p.pointsFor(b) - p.pointsFor(a));
    var score = 0;
    for (final w in words) {
      await spell(tester, w);
      score += p.pointsFor(w);
      if (score >= p.starPoints.first) break;
      expect(find.text('Well done!'), findsNothing);
    }
    await tester.pumpAndSettle();
    expect(find.text('Well done!'), findsOneWidget);
    expect(ProgressStore.instance.stars('letter_hive', 1), greaterThan(0));

    // "Keep going" stays on the level, and moving on is still one tap away.
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hive_next')), findsOneWidget);
    expect(find.textContaining('Score $score'), findsOneWidget);
    await drainMessages(tester);
  });

  testWidgets('Found words come back after leaving the level', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final p = LetterHivePuzzle.generate(2, indexFor('en'));
    await tester.pumpWidget(
      localizedApp(const LetterHiveScreen(startLevel: 2)),
    );
    await tester.pump();
    await tester.pump();
    final word = p.answers.first;
    await spell(tester, word);
    await drainMessages(tester);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      localizedApp(const LetterHiveScreen(startLevel: 2)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(word), findsOneWidget);
    expect(find.text('1 word found'), findsOneWidget);
  });

  testWidgets('A hint names a word, grows a letter at a time, and caps stars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const LetterHiveScreen()));
    await tester.pump();
    await tester.pump();
    final p = LetterHivePuzzle.generate(1, indexFor('en'));

    String hintText() =>
        tester.widget<Text>(find.byKey(const ValueKey('hive_hint'))).data!;
    String prefix() => hintText().split(' ')[1];

    await tester.tap(find.byKey(const ValueKey('game_hint_button')));
    await tester.pump();
    expect(prefix().length, 2);
    await tester.tap(find.byKey(const ValueKey('game_hint_button')));
    await tester.pump();
    final shown = prefix();
    expect(shown.length, 3, reason: 'a second hint shows one more letter');
    final length = int.parse(
      RegExp(r'\((\d+)').firstMatch(hintText())!.group(1)!,
    );
    // The hint picks at random, and two answers can share a start and a
    // length (BULGING, BULLING), so spell each until the hint clears.
    final candidates = p.answers
        .where((w) => w.startsWith(shown) && w.length == length)
        .toList();
    // Underscores for the rest, so the length is visible at a glance.
    expect(hintText(), contains(' _' * (length - 3)));

    final spelled = <String>{};
    for (final w in candidates) {
      if (find.byKey(const ValueKey('hive_hint')).evaluate().isEmpty) break;
      await spell(tester, w);
      spelled.add(w);
    }
    expect(
      find.byKey(const ValueKey('hive_hint')),
      findsNothing,
      reason: 'a found word is no longer hinted',
    );

    // Every word: enough for three stars, but the hint holds it to two.
    for (final w in p.answers.where((w) => !spelled.contains(w))) {
      await spell(tester, w);
      if (find.text('Keep going').evaluate().isNotEmpty) {
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keep going'));
        await tester.pumpAndSettle();
      }
    }
    expect(ProgressStore.instance.stars('letter_hive', 1), 2);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Missed words show only after the goal, and only on request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedApp(const LetterHiveScreen()));
    await tester.pump();
    await tester.pump();
    final p = LetterHivePuzzle.generate(1, indexFor('en'));
    expect(find.byKey(const ValueKey('hive_reveal')), findsNothing);

    final words = List.of(p.answers)
      ..sort((a, b) => p.pointsFor(b) - p.pointsFor(a));
    final found = <String>{};
    var score = 0;
    for (final w in words) {
      await spell(tester, w);
      found.add(w);
      score += p.pointsFor(w);
      if (score >= p.starPoints.first) break;
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();

    final missed = p.answers.where((w) => !found.contains(w)).toList();
    expect(find.text(missed.first), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hive_reveal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hive_reveal_confirm')));
    await tester.pumpAndSettle();
    expect(find.text('${missed.length} words you missed'), findsOneWidget);
    expect(find.text(missed.first), findsOneWidget);
    expect(find.byKey(const ValueKey('hive_reveal')), findsNothing);

    // Typing a revealed word scores, but the stars stay where they were.
    final before = ProgressStore.instance.stars('letter_hive', 1);
    for (final w in missed) {
      await spell(tester, w);
    }
    expect(ProgressStore.instance.stars('letter_hive', 1), before);
    await drainMessages(tester);
  });
}
