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

  /// No description provided for @gameWordSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Search'**
  String get gameWordSearchTitle;

  /// No description provided for @gameWordSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the hidden words'**
  String get gameWordSearchSubtitle;

  /// No description provided for @gameMiniSudokuTitle.
  ///
  /// In en, this message translates to:
  /// **'Mini Sudoku'**
  String get gameMiniSudokuTitle;

  /// No description provided for @gameMiniSudokuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill the grid, no repeats'**
  String get gameMiniSudokuSubtitle;

  /// No description provided for @gameSimonTitle.
  ///
  /// In en, this message translates to:
  /// **'Simon'**
  String get gameSimonTitle;

  /// No description provided for @gameSimonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat the light sequence'**
  String get gameSimonSubtitle;

  /// No description provided for @gameWordScrambleTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Scramble'**
  String get gameWordScrambleTitle;

  /// No description provided for @gameWordScrambleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unscramble the letters'**
  String get gameWordScrambleSubtitle;

  /// No description provided for @gameCrackCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Crack the Code'**
  String get gameCrackCodeTitle;

  /// No description provided for @gameCrackCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guess the secret code'**
  String get gameCrackCodeSubtitle;

  /// No description provided for @gameTrailTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow the Trail'**
  String get gameTrailTitle;

  /// No description provided for @gameTrailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the circles in order'**
  String get gameTrailSubtitle;

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

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @helpArrowEscape.
  ///
  /// In en, this message translates to:
  /// **'Every arrow wants to fly off the board in the direction it points. Tap an arrow to send it away — but its path must be clear. Send off all the arrows to win.'**
  String get helpArrowEscape;

  /// No description provided for @helpArrowMaze.
  ///
  /// In en, this message translates to:
  /// **'The long arrows slide off the board head-first. Tap one to send it out — the path in front of its head must be clear. Clear the whole board to win.'**
  String get helpArrowMaze;

  /// No description provided for @helpWord.
  ///
  /// In en, this message translates to:
  /// **'Guess the hidden five-letter word in six tries. Green means the right letter in the right spot, yellow means the letter is somewhere else in the word, grey means it is not in the word.'**
  String get helpWord;

  /// No description provided for @helpNumberCross.
  ///
  /// In en, this message translates to:
  /// **'Place the numbers from the tray into the empty squares so every equation is correct — across and down. Tap a number and then a square, or drag it in. Tap a placed number to take it back.'**
  String get helpNumberCross;

  /// No description provided for @helpWordSearch.
  ///
  /// In en, this message translates to:
  /// **'All the words below the grid are hidden among the letters. Drag your finger across a word to mark it — forwards or backwards. Find them all to win.'**
  String get helpWordSearch;

  /// No description provided for @helpMiniSudoku.
  ///
  /// In en, this message translates to:
  /// **'Fill the empty squares so every row, column and box contains each number exactly once. Tap a square, then tap a number. Clashing numbers turn red so you can fix them.'**
  String get helpMiniSudoku;

  /// No description provided for @helpMemoryMatch.
  ///
  /// In en, this message translates to:
  /// **'All the cards lie face down, and every picture has a twin. Flip two cards at a time and remember what you see. Find all the pairs to win.'**
  String get helpMemoryMatch;

  /// No description provided for @helpSimon.
  ///
  /// In en, this message translates to:
  /// **'Watch the buttons light up, one after another. Then tap the same buttons in the same order. The sequence grows one step each round — keep up to the end!'**
  String get helpSimon;

  /// No description provided for @helpWhatNext.
  ///
  /// In en, this message translates to:
  /// **'Look at the row of numbers and figure out the pattern. Then pick the number that comes next. A wrong pick costs a heart.'**
  String get helpWhatNext;

  /// No description provided for @helpWordScramble.
  ///
  /// In en, this message translates to:
  /// **'The letters of a familiar word have been shuffled. Tap them in the right order to spell the word. Tap a letter in your answer to put it back.'**
  String get helpWordScramble;

  /// No description provided for @helpCrackCode.
  ///
  /// In en, this message translates to:
  /// **'Find the secret code! After each guess you get clues: a green dot means a correct digit in the correct spot, a yellow dot means a correct digit in the wrong spot. Crack the code before your guesses run out.'**
  String get helpCrackCode;

  /// No description provided for @helpTrail.
  ///
  /// In en, this message translates to:
  /// **'Tap the circles in order: 1, 2, 3 … On higher levels you alternate numbers and letters: 1, A, 2, B. A wrong tap costs a heart.'**
  String get helpTrail;

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

  /// No description provided for @wordSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Drag across the letters to mark a word.'**
  String get wordSearchHint;

  /// No description provided for @wordsFound.
  ///
  /// In en, this message translates to:
  /// **'Found {found} of {total}'**
  String wordsFound(int found, int total);

  /// No description provided for @miniSudokuHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a square, then a number. Each number fits once per row, column and box.'**
  String get miniSudokuHint;

  /// No description provided for @simonHint.
  ///
  /// In en, this message translates to:
  /// **'Watch the buttons light up, then tap them in the same order.'**
  String get simonHint;

  /// No description provided for @simonWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch closely…'**
  String get simonWatch;

  /// No description provided for @simonYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn!'**
  String get simonYourTurn;

  /// No description provided for @simonRound.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String simonRound(int current, int total);

  /// No description provided for @wordScrambleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the letters in order. Tap a letter in the answer to put it back.'**
  String get wordScrambleHint;

  /// No description provided for @wordOf.
  ///
  /// In en, this message translates to:
  /// **'Word {current} of {total}'**
  String wordOf(int current, int total);

  /// No description provided for @crackCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Green dot: right digit, right spot. Yellow dot: right digit, wrong spot.'**
  String get crackCodeHint;

  /// No description provided for @crackGuessOf.
  ///
  /// In en, this message translates to:
  /// **'Guess {current} of {total}'**
  String crackGuessOf(int current, int total);

  /// No description provided for @crackCodeWas.
  ///
  /// In en, this message translates to:
  /// **'The code was {code}.'**
  String crackCodeWas(String code);

  /// No description provided for @trailHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the circles in order. The line follows your progress.'**
  String get trailHint;

  /// No description provided for @trailNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {label}'**
  String trailNext(String label);

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
