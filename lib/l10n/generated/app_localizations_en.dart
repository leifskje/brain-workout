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
  String get gameSimonTitle => 'Simon';

  @override
  String get gameSimonSubtitle => 'Repeat the light sequence';

  @override
  String get gameWordScrambleTitle => 'Word Scramble';

  @override
  String get gameWordScrambleSubtitle => 'Unscramble the letters';

  @override
  String get gameCrackCodeTitle => 'Crack the Code';

  @override
  String get gameCrackCodeSubtitle => 'Guess the secret code';

  @override
  String get gameTrailTitle => 'Follow the Trail';

  @override
  String get gameTrailSubtitle => 'Tap the circles in order';

  @override
  String get gameMergeTitle => '2048';

  @override
  String get gameMergeSubtitle => 'Merge tiles to the target';

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
  String get howToPlay => 'How to play';

  @override
  String get gotIt => 'Got it!';

  @override
  String get helpArrowEscape =>
      'Every arrow wants to fly off the board in the direction it points. Tap an arrow to send it away — but its path must be clear. Send off all the arrows to win.';

  @override
  String get helpArrowMaze =>
      'The long arrows slide off the board head-first. Tap one to send it out — the path in front of its head must be clear. Clear the whole board to win.';

  @override
  String get helpWord =>
      'Guess the hidden five-letter word in six tries. Green means the right letter in the right spot, yellow means the letter is somewhere else in the word, grey means it is not in the word.';

  @override
  String get helpNumberCross =>
      'Place the numbers from the tray into the empty squares so every equation is correct — across and down. Tap a number and then a square, or drag it in. Tap a placed number to take it back.';

  @override
  String get helpWordSearch =>
      'All the words below the grid are hidden among the letters. Drag your finger across a word to mark it — forwards or backwards. Find them all to win.';

  @override
  String get helpMiniSudoku =>
      'Fill the empty squares so every row, column and box contains each number exactly once. Tap a square, then tap a number. Clashing numbers turn red so you can fix them.';

  @override
  String get helpMemoryMatch =>
      'All the cards lie face down, and every picture has a twin. Flip two cards at a time and remember what you see. Find all the pairs to win.';

  @override
  String get helpSimon =>
      'Watch the buttons light up, one after another. Then tap the same buttons in the same order. The sequence grows one step each round — keep up to the end!';

  @override
  String get helpWhatNext =>
      'Look at the row of numbers and figure out the pattern. Then pick the number that comes next. A wrong pick costs a heart.';

  @override
  String get helpWordScramble =>
      'The letters of a familiar word have been shuffled. Tap them in the right order to spell the word. Tap a letter in your answer to put it back. The category above the letters tells you what kind of word to look for. If the letters also spell a different real word, saying that one costs you nothing — just try again.';

  @override
  String get helpCrackCode =>
      'Find the secret code! After each guess you get clues: a green dot means a correct digit in the correct spot, a yellow dot means a correct digit in the wrong spot. Crack the code before your guesses run out.';

  @override
  String get helpTrail =>
      'Tap the circles in order: 1, 2, 3 … On higher levels you alternate numbers and letters: 1, A, 2, B. A wrong tap costs a heart.';

  @override
  String get helpMerge =>
      'Swipe the board (or use the arrows) to slide all the tiles one way. When two tiles with the same number touch, they merge into one with double the value. Reach the target tile to win.';

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
  String get simonHint =>
      'Watch the buttons light up, then tap them in the same order.';

  @override
  String get simonWatch => 'Watch closely…';

  @override
  String get simonYourTurn => 'Your turn!';

  @override
  String simonRound(int current, int total) {
    return 'Round $current of $total';
  }

  @override
  String get wordScrambleHint =>
      'Tap the letters in order. Tap a letter in the answer to put it back.';

  @override
  String wordOf(int current, int total) {
    return 'Word $current of $total';
  }

  @override
  String get crackCodeHint =>
      'Green dot: right digit, right spot. Yellow dot: right digit, wrong spot.';

  @override
  String crackGuessOf(int current, int total) {
    return 'Guess $current of $total';
  }

  @override
  String crackCodeWas(String code) {
    return 'The code was $code.';
  }

  @override
  String get trailHint =>
      'Tap the circles in order. The line follows your progress.';

  @override
  String trailNext(String label) {
    return 'Next: $label';
  }

  @override
  String get mergeHint =>
      'Tap an arrow to push every tile that way. Matching numbers merge.';

  @override
  String get mergeGoalLabel => 'Make:';

  @override
  String mergeTarget(int value) {
    return 'Target: $value';
  }

  @override
  String mergeScore(int value) {
    return 'Score: $value';
  }

  @override
  String get noMoves => 'No more moves';

  @override
  String get noMovesBody => 'The board is full. Want to try this level again?';

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

  @override
  String get categoryFood => 'Food and drink';

  @override
  String get categoryAnimals => 'Animals';

  @override
  String get categoryHome => 'In the home';

  @override
  String get categoryNature => 'Nature and weather';

  @override
  String get categoryClothing => 'Clothes';

  @override
  String get categoryBody => 'The body';

  @override
  String get categoryTravel => 'Places and travel';

  @override
  String get categoryPeople => 'People';

  @override
  String scrambleNearMiss(String word) {
    return '\"$word\" is a word — but not this one. Try again.';
  }

  @override
  String get credits => 'About and credits';

  @override
  String get creditsIntro =>
      'The word games use these openly licensed word lists.';

  @override
  String get creditsWordListsTitle => 'Word lists';

  @override
  String get creditsOrdbankName => 'Norsk ordbank (Norwegian)';

  @override
  String get creditsOrdbankBody =>
      '© Språkrådet and the University of Bergen, via the National Library\'s Språkbanken. Used under the Creative Commons Attribution 4.0 licence.';

  @override
  String get creditsOrdbankChanges =>
      'Adapted for this app: filtered to words of 3–8 letters, proper nouns removed, and split into base forms and full forms.';

  @override
  String get creditsDwylName => 'english-words (English)';

  @override
  String get creditsDwylBody =>
      'From the dwyl/english-words list, released into the public domain.';

  @override
  String get creditsDwylChanges =>
      'Adapted for this app: filtered to words of 3–8 letters.';

  @override
  String get creditsLicenceLink => 'Read the CC BY 4.0 licence';

  @override
  String get creditsShareAlikeLink => 'Read the CC BY-SA 4.0 licence';

  @override
  String get creditsScowlName => 'SCOWL (English word difficulty)';

  @override
  String get creditsScowlBody =>
      'Word difficulty tiers come from SCOWL, the Spell Checker Oriented Word List, which may be used, copied, modified and distributed for any purpose.';

  @override
  String get creditsScowlChanges =>
      'Adapted for this app: each word tagged with the smallest SCOWL size containing it, as a measure of how common it is.';

  @override
  String get creditsFreqName => 'Norwegian word frequencies';

  @override
  String get creditsFreqBody =>
      'Norwegian word difficulty comes from the FrequencyWords lists (Hermit Dave, built from OpenSubtitles data), used under the Creative Commons Attribution-ShareAlike 4.0 licence. Because of the share-alike term, the Norwegian word list this app ships is itself available under CC BY-SA 4.0.';

  @override
  String get creditsFreqChanges =>
      'Adapted for this app: frequency ranks reduced to four difficulty tiers and matched against the Norsk ordbank word list.';
}
