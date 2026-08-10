// Wordle / word-of-the-day screen tests.
//
// These are in their own file mostly for tidiness. The thing that made earlier
// attempts appear to hang was not the file, and is worth reading before adding a
// test here:
//
//  - **A cold asset read cannot happen inside `testWidgets`.** `testWidgets` runs
//    the body in a fake-async zone, so the real file I/O behind
//    `rootBundle.loadString` never progresses and the test simply never finishes.
//    That is what made every earlier attempt "hang": the tests that appeared to
//    work were riding on a static cache warmed by an earlier plain `test()` in the
//    same run. `setUpAll` runs outside the fake-async zone, so the word list is
//    warmed there — after which in-test calls are cache hits.
//  - While the list loads the screen shows an *indeterminate*
//    CircularProgressIndicator, which schedules frames forever, so `pumpAndSettle`
//    never settles and dies by timeout. Use bounded pump loops.
//  - `debugPrint` is buffered per test and never flushed for a test that does not
//    complete, so prints are useless for diagnosing a hang here. Split a suspect
//    flow into several small tests and let the hang isolate itself.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_workout/games/games_catalog.dart';
import 'package:brain_workout/games/wordle/word_repository.dart';
import 'package:brain_workout/games/wordle/wordle_models.dart';
import 'package:brain_workout/games/wordle/wordle_screen.dart';
import 'package:brain_workout/l10n/generated/app_localizations.dart';
import 'package:brain_workout/services/progress_store.dart';

Widget localizedApp(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  // Outside the fake-async zone of testWidgets — see the file comment. Without
  // this, the first test to touch the asset never completes.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final language in wordleLanguages) {
      await WordRepository.forLanguage(language);
    }
  });

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
    for (final game in gamesCatalog) {
      ProgressStore.instance.markHelpSeen(game.id);
    }
  });

  /// Bounded pumping — see the file comment on why not `pumpAndSettle`.
  Future<void> settle(WidgetTester tester, [int steps = 12]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  testWidgets('Solving the daily word leads to the share, not past it',
      (tester) async {
    // Reported from the emulator: the win dialog covered the result card and its
    // only non-Home button was "New word", which replaced the finished daily with
    // a practice word — so the share buttons were unreachable by any route.
    phoneSize(tester);
    final repo = await WordRepository.forLanguage(wordleLanguages.first);
    final answer = repo.wordOfTheDay(DateTime.now());

    await tester.pumpWidget(localizedApp(const WordleScreen()));
    await settle(tester, 30);

    for (final ch in answer.split('')) {
      await tester.tap(find.byKey(ValueKey('wordle_key_$ch')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('wordle_key_ENTER')));
    await settle(tester, 20);

    // The celebration still happens...
    expect(find.text('Well done!'), findsOneWidget);
    // ...but it no longer offers to throw the finished daily away. This is the
    // assertion that fails before the fix.
    expect(find.text('New word'), findsNothing,
        reason: 'a daily win must not offer to replace itself with a practice word');
    // "Close" appears only in the dialog, so it is an unambiguous handle on it.
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await settle(tester);

    // Dismissing stays put rather than going home, and the share buttons are
    // genuinely reachable — hitTestable, not merely present.
    expect(find.text("Today's word is done!"), findsOneWidget);
    expect(find.byKey(const ValueKey('wordle_share')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey('wordle_copy')).hitTestable(),
        findsOneWidget);
  });

  testWidgets('Tapping Share never throws at the player', (tester) async {
    // Reported from a real device: MissingPluginException(No implementation found
    // for method share on channel dev.fluttercommunity.plus/share). The cause was
    // mundane — native plugin registration is generated at build time, so an app
    // hot-reloaded after `pub add` has the Dart half of share_plus and not the
    // native half — but the player got a stack trace instead of their score.
    //
    // **Limit of this test, stated honestly.** On this Windows test host share_plus
    // resolves to `SharePlusWindowsPlugin`, a Dart implementation backed by
    // url_launcher, so it never goes near a method channel and the Android
    // exception cannot be reproduced here. What is asserted is the guarantee that
    // actually matters and holds on every platform: tapping Share does not surface
    // an exception, and the screen survives it. The clipboard fallback itself is
    // verified on the device.
    phoneSize(tester);

    final puzzle = WordRepository.dailyPuzzleNumber(DateTime.now());
    ProgressStore.instance.recordDailyWord('en', puzzle,
        solved: true, rows: ['aapca', 'ccccc']);

    await tester.pumpWidget(localizedApp(const WordleScreen()));
    await settle(tester, 30);
    expect(find.byKey(const ValueKey('wordle_share')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wordle_share')));
    await settle(tester, 6);

    expect(tester.takeException(), isNull,
        reason: 'a failing share must never surface to the player');
    // The screen is still there and still usable afterwards.
    expect(find.text("Today's word is done!"), findsOneWidget);
    expect(find.byKey(const ValueKey('wordle_copy')).hitTestable(),
        findsOneWidget);
  });

  testWidgets('Copy always works, whatever the share sheet does', (tester) async {
    // The dependency-free route, and the reason both are offered: it needs no
    // plugin and no other app to cooperate.
    phoneSize(tester);

    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final puzzle = WordRepository.dailyPuzzleNumber(DateTime.now());
    ProgressStore.instance.recordDailyWord('en', puzzle,
        solved: true, rows: ['aapca', 'ccccc']);

    await tester.pumpWidget(localizedApp(const WordleScreen()));
    await settle(tester, 30);

    await tester.tap(find.byKey(const ValueKey('wordle_copy')));
    await settle(tester, 4);

    expect(copied, isNotNull, reason: 'Copy should write to the clipboard');
    expect(copied, contains('🟩🟩🟩🟩🟩'));
    expect(copied, contains('2/$maxGuesses'));
    // Colours only — a friend who has not played must not have it spoiled. The
    // first two lines are the title and a blank, so the grid starts at line 3.
    final grid = const LineSplitter().convert(copied!).skip(2).join();
    expect(RegExp(r'[A-Za-z]').allMatches(grid), isEmpty,
        reason: 'the shared grid must not leak letters');
  });
}
