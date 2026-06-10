// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brain Workout';

  @override
  String get homeTagline => 'Pick a game for today\'s workout';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get startStreakToday => 'Start your streak today!';

  @override
  String bestStreak(int count) {
    return 'Best: $count';
  }

  @override
  String get workoutComplete => 'Today\'s workout complete! 🎉';

  @override
  String workoutProgress(int count, int goal) {
    return 'Today\'s workout: $count of $goal';
  }

  @override
  String playNext(String game) {
    return 'Play next: $game';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String gameAtLevel(String game, int level) {
    return '$game — Level $level';
  }

  @override
  String levelN(int level) {
    return 'Level $level';
  }

  @override
  String get play => 'Play';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get supportDeveloper => 'Support the developer';

  @override
  String get supportPageError => 'Could not open the support page.';

  @override
  String get categoryWords => 'Words';

  @override
  String get categoryNumbers => 'Numbers';

  @override
  String get categoryMemory => 'Memory';

  @override
  String get categoryLogic => 'Logic';

  @override
  String get gameArrowEscapeTitle => 'Arrow Escape';

  @override
  String get gameArrowEscapeSubtitle => 'Send every arrow off the board';

  @override
  String get gameArrowMazeTitle => 'Arrow Maze';

  @override
  String get gameArrowMazeSubtitle => 'Untangle the long snaking arrows';

  @override
  String get gameWordTitle => 'Word';

  @override
  String get gameWordSubtitle => 'Guess the hidden word';

  @override
  String get gameNumberCrossTitle => 'Number Cross';

  @override
  String get gameNumberCrossSubtitle => 'Fill the math crossword';

  @override
  String get gameMemoryMatchTitle => 'Memory Match';

  @override
  String get gameMemoryMatchSubtitle => 'Remember the pairs';

  @override
  String get gameWhatNextTitle => 'What Comes Next?';

  @override
  String get gameWhatNextSubtitle => 'Spot the pattern';

  @override
  String get gameWordSearchTitle => 'Word Search';

  @override
  String get gameWordSearchSubtitle => 'Find the hidden words';

  @override
  String get gameMiniSudokuTitle => 'Mini Sudoku';

  @override
  String get gameMiniSudokuSubtitle => 'Fill the grid, no repeats';

  @override
  String comingSoonTitle(String game) {
    return '$game is coming soon!';
  }

  @override
  String get comingSoonBody =>
      'We are still building this game. Check back later.';

  @override
  String get backToGames => 'Back to games';

  @override
  String continueAtLevel(int level) {
    return 'Continue — Level $level';
  }

  @override
  String get replayLevel => 'Replay a level';

  @override
  String get wellDone => 'Well done!';

  @override
  String clearedLevel(int level) {
    return 'You cleared level $level.';
  }

  @override
  String get home => 'Home';

  @override
  String get nextLevel => 'Next level';

  @override
  String get levelComplete => 'Level complete';

  @override
  String get back => 'Back';

  @override
  String get restartLevel => 'Restart level';

  @override
  String get outOfHearts => 'Out of hearts';

  @override
  String get outOfHeartsBody => 'No hearts left. Want to try this level again?';

  @override
  String get tryAgain => 'Try again';

  @override
  String get arrowEscapeHint =>
      'Tap an arrow to send it off the board. It needs a clear path to the edge.';

  @override
  String get arrowMazeHint =>
      'Tap a long arrow to send it off, head-first. The path ahead of its head must be clear.';

  @override
  String get numberCrossHint =>
      'Tap a number then a cell, or drag it in. Every across and down equation must be correct.';

  @override
  String get memoryMatchHint => 'Tap two cards to find a matching pair.';

  @override
  String pairsFound(int matched, int total) {
    return 'Pairs found: $matched / $total';
  }

  @override
  String clearedLevelInMoves(int level, int moves) {
    return 'You cleared level $level in $moves moves.';
  }

  @override
  String questionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get whichComesNext => 'Which comes next?';

  @override
  String get wordSearchHint => 'Drag across the letters to mark a word.';

  @override
  String wordsFound(int found, int total) {
    return 'Found $found of $total';
  }

  @override
  String get miniSudokuHint =>
      'Tap a square, then a number. Each number fits once per row, column and box.';

  @override
  String get notEnoughLetters => 'Not enough letters';

  @override
  String get notInWordList => 'Not in word list';

  @override
  String solvedInGuesses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Solved in $count guesses!',
      one: 'Solved in 1 guess!',
    );
    return '$_temp0';
  }

  @override
  String get newWord => 'New word';

  @override
  String get outOfGuesses => 'Out of guesses';

  @override
  String theWordWas(String word) {
    return 'The word was \"$word\".';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow phone language';
}
