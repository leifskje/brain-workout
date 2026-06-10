import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nb.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nb'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Brain Workout'**
  String get appTitle;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Pick a game for today\'s workout'**
  String get homeTagline;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String streakDays(int count);

  /// No description provided for @startStreakToday.
  ///
  /// In en, this message translates to:
  /// **'Start your streak today!'**
  String get startStreakToday;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best: {count}'**
  String bestStreak(int count);

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Today\'s workout complete! 🎉'**
  String get workoutComplete;

  /// No description provided for @workoutProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s workout: {count} of {goal}'**
  String workoutProgress(int count, int goal);

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next: {game}'**
  String playNext(String game);

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @gameAtLevel.
  ///
  /// In en, this message translates to:
  /// **'{game} — Level {level}'**
  String gameAtLevel(String game, int level);

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelN(int level);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @supportDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Support the developer'**
  String get supportDeveloper;

  /// No description provided for @supportPageError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the support page.'**
  String get supportPageError;

  /// No description provided for @categoryWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get categoryWords;

  /// No description provided for @categoryNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get categoryNumbers;

  /// No description provided for @categoryMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get categoryMemory;

  /// No description provided for @categoryLogic.
  ///
  /// In en, this message translates to:
  /// **'Logic'**
  String get categoryLogic;

  /// No description provided for @gameArrowEscapeTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrow Escape'**
  String get gameArrowEscapeTitle;

  /// No description provided for @gameArrowEscapeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send every arrow off the board'**
  String get gameArrowEscapeSubtitle;

  /// No description provided for @gameArrowMazeTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrow Maze'**
  String get gameArrowMazeTitle;

  /// No description provided for @gameArrowMazeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Untangle the long snaking arrows'**
  String get gameArrowMazeSubtitle;

  /// No description provided for @gameWordTitle.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get gameWordTitle;

  /// No description provided for @gameWordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guess the hidden word'**
  String get gameWordSubtitle;

  /// No description provided for @gameNumberCrossTitle.
  ///
  /// In en, this message translates to:
  /// **'Number Cross'**
  String get gameNumberCrossTitle;

  /// No description provided for @gameNumberCrossSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill the math crossword'**
  String get gameNumberCrossSubtitle;

  /// No description provided for @gameMemoryMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory Match'**
  String get gameMemoryMatchTitle;

  /// No description provided for @gameMemoryMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remember the pairs'**
  String get gameMemoryMatchSubtitle;

  /// No description provided for @gameWhatNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What Comes Next?'**
  String get gameWhatNextTitle;

  /// No description provided for @gameWhatNextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spot the pattern'**
  String get gameWhatNextSubtitle;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'{game} is coming soon!'**
  String comingSoonTitle(String game);

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'We are still building this game. Check back later.'**
  String get comingSoonBody;

  /// No description provided for @backToGames.
  ///
  /// In en, this message translates to:
  /// **'Back to games'**
  String get backToGames;

  /// No description provided for @continueAtLevel.
  ///
  /// In en, this message translates to:
  /// **'Continue — Level {level}'**
  String continueAtLevel(int level);

  /// No description provided for @replayLevel.
  ///
  /// In en, this message translates to:
  /// **'Replay a level'**
  String get replayLevel;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get wellDone;

  /// No description provided for @clearedLevel.
  ///
  /// In en, this message translates to:
  /// **'You cleared level {level}.'**
  String clearedLevel(int level);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @levelComplete.
  ///
  /// In en, this message translates to:
  /// **'Level complete'**
  String get levelComplete;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @restartLevel.
  ///
  /// In en, this message translates to:
  /// **'Restart level'**
  String get restartLevel;

  /// No description provided for @outOfHearts.
  ///
  /// In en, this message translates to:
  /// **'Out of hearts'**
  String get outOfHearts;

  /// No description provided for @outOfHeartsBody.
  ///
  /// In en, this message translates to:
  /// **'No hearts left. Want to try this level again?'**
  String get outOfHeartsBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @arrowEscapeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow to send it off the board. It needs a clear path to the edge.'**
  String get arrowEscapeHint;

  /// No description provided for @arrowMazeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a long arrow to send it off, head-first. The path ahead of its head must be clear.'**
  String get arrowMazeHint;

  /// No description provided for @numberCrossHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a number then a cell, or drag it in. Every across and down equation must be correct.'**
  String get numberCrossHint;

  /// No description provided for @memoryMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Tap two cards to find a matching pair.'**
  String get memoryMatchHint;

  /// No description provided for @pairsFound.
  ///
  /// In en, this message translates to:
  /// **'Pairs found: {matched} / {total}'**
  String pairsFound(int matched, int total);

  /// No description provided for @clearedLevelInMoves.
  ///
  /// In en, this message translates to:
  /// **'You cleared level {level} in {moves} moves.'**
  String clearedLevelInMoves(int level, int moves);

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionOf(int current, int total);

  /// No description provided for @whichComesNext.
  ///
  /// In en, this message translates to:
  /// **'Which comes next?'**
  String get whichComesNext;

  /// No description provided for @notEnoughLetters.
  ///
  /// In en, this message translates to:
  /// **'Not enough letters'**
  String get notEnoughLetters;

  /// No description provided for @notInWordList.
  ///
  /// In en, this message translates to:
  /// **'Not in word list'**
  String get notInWordList;

  /// No description provided for @solvedInGuesses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Solved in 1 guess!} other{Solved in {count} guesses!}}'**
  String solvedInGuesses(int count);

  /// No description provided for @newWord.
  ///
  /// In en, this message translates to:
  /// **'New word'**
  String get newWord;

  /// No description provided for @outOfGuesses.
  ///
  /// In en, this message translates to:
  /// **'Out of guesses'**
  String get outOfGuesses;

  /// No description provided for @theWordWas.
  ///
  /// In en, this message translates to:
  /// **'The word was \"{word}\".'**
  String theWordWas(String word);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow phone language'**
  String get languageSystem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nb'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nb':
      return AppLocalizationsNb();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
