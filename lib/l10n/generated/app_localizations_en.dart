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
  String get gameNonogramTitle => 'Picture Logic';

  @override
  String get gameNonogramSubtitle => 'Reveal the hidden picture';

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
      'The long arrows slide off the board head-first. Tap one to send it out — the path in front of its head must be clear. Clear the whole board to win. From level 12 one arrow is golden. It is in the way of several others, so when it finally gets out they are free to follow it straight away — worth aiming for.';

  @override
  String get helpWord =>
      'Guess the hidden five-letter word in six tries. Green means the right letter in the right spot, yellow means the letter is somewhere else in the word, grey means it is not in the word.';

  @override
  String get helpNumberCross =>
      'Place the numbers from the tray into the empty squares so every equation is correct — across and down. Tap a number and then a square, or drag it in. Tap a placed number to take it back.';

  @override
  String get helpWordSearch =>
      'All the words below the grid are hidden among the letters. Drag your finger across a word to mark it — forwards or backwards. Find them all to win. From level 10 every word belongs to the same category, and on the hardest levels the list is hidden: you get only the category and how many words to find.';

  @override
  String get helpMiniSudoku =>
      'Fill the empty squares so every row, column and box contains each number exactly once. Tap a square, then tap a number. Clashing numbers turn red so you can fix them.';

  @override
  String get helpMemoryMatch =>
      'All the cards lie face down, and every picture has a twin. Flip two cards at a time and remember what you see. Find all the pairs to win.\n\nFrom level 10 the pictures come in threes instead of twos: you turn over three cards at a time and all three must match. The board says \"Find 3 of a kind\" when it is in that mode.';

  @override
  String get helpSimon =>
      'Watch the buttons light up, one after another. Then tap the same buttons in the same order. The sequence grows one step each round — keep up to the end!';

  @override
  String get helpWhatNext =>
      'Look at the row and work out the pattern — it may be numbers, dots, colours or arrows. Then pick what comes next. A wrong pick costs a heart.';

  @override
  String get helpWordScramble =>
      'The letters of a familiar word have been shuffled. Tap them in the right order to spell the word. Tap a letter in your answer to put it back. The category above the letters tells you what kind of word to look for. If the letters also spell a different real word, saying that one costs you nothing — just try again.';

  @override
  String get helpCrackCode =>
      'Find the secret code! After each guess you get two numbers: the green one is how many digits are correct and in the correct spot, the yellow one is how many are correct but in the wrong spot.\n\nThey are counts only. They never tell you which digit is which — working that out is the puzzle. Crack the code before your guesses run out.';

  @override
  String get helpTrail =>
      'Tap the circles in order: 1, 2, 3 … On higher levels you alternate numbers and letters: 1, A, 2, B. A wrong tap costs a heart.';

  @override
  String get helpMerge =>
      'Swipe the board (or use the arrows) to slide all the tiles one way. When two tiles with the same number touch, they merge into one with double the value. Reach the target tile to win.';

  @override
  String get helpNonogram =>
      'The numbers along the top and the left tell you how many squares in a row are filled, in order. A line marked 4 2 has four filled squares, at least one gap, then two more. A line marked 0 is empty. Tap a square to fill it, tap again to put a cross where you are sure it stays empty, and once more to clear it. Fill in every correct square to reveal the picture. Nothing is timed and a wrong square costs you nothing — just fix it.';

  @override
  String get newRecord => 'New personal best!';

  @override
  String bestMoves(int count) {
    return 'Your best: $count moves';
  }

  @override
  String bestScore(int value) {
    return 'Your best score: $value';
  }

  @override
  String bestMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your best: $count mistakes',
      one: 'Your best: 1 mistake',
      zero: 'Your best: no mistakes',
    );
    return '$_temp0';
  }

  @override
  String bestGuesses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your best: $count guesses',
      one: 'Your best: 1 guess',
    );
    return '$_temp0';
  }

  @override
  String bonusArrowFreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The golden arrow freed $count more!',
      one: 'The golden arrow freed 1 more!',
    );
    return '$_temp0';
  }

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
  String get arrowMazeHintZoom =>
      'Tap a long arrow to send it off, head-first. Pinch or use the buttons to zoom in for a closer look.';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomFit => 'Fit the whole board';

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
  String wordSearchTheme(int count, String category) {
    return '$count hidden words to find. Category: $category';
  }

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
      'Green: right digit, right spot. Yellow: right digit, wrong spot. How many — never which.';

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
  String get nonogramHint =>
      'Tap to fill, tap again for a cross, once more to clear.';

  @override
  String get nonogramCheck => 'Check my squares';

  @override
  String get nonogramCheckClean => 'No mistakes so far!';

  @override
  String nonogramCheckFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filled squares are wrong',
      one: '1 filled square is wrong',
    );
    return '$_temp0';
  }

  @override
  String dailyShareTitle(int number) {
    return 'Brain Workout — Word $number';
  }

  @override
  String wordOfTheDay(int number) {
    return 'Word of the day #$number';
  }

  @override
  String get dailyDoneTitle => 'Today\'s word is done!';

  @override
  String get dailyDoneBody =>
      'A new word appears every day — come back tomorrow.';

  @override
  String get dailyNotSolved => 'You didn\'t get today\'s word.';

  @override
  String get closeAction => 'Close';

  @override
  String get shareResult => 'Share';

  @override
  String get shareUnavailable =>
      'Sharing isn\'t available here — copied to the clipboard instead.';

  @override
  String get copyResult => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to the clipboard';

  @override
  String get practiceWord => 'Play another word';

  @override
  String get practiceWordNote =>
      'As many as you like — these are just for practice.';

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

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get feedbackSubject => 'Brain Workout feedback';

  @override
  String get feedbackIntro =>
      'What happened, and what did you expect? Anything at all is useful — even one line.';

  @override
  String get feedbackNoMailApp =>
      'No email app found. The address and details were copied instead.';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get updateAvailable => 'A new version is ready';

  @override
  String get updateBody => 'Update now so you are playing the latest version.';

  @override
  String get updateNow => 'Update';

  @override
  String get updateLater => 'Not now';

  @override
  String get updateFailed =>
      'The update could not be started. Open Play Store and search for the app.';

  @override
  String get useHint => 'Hint';

  @override
  String get hintCost => 'A hint means at most 2 stars for this level.';

  @override
  String get hintNoneLeft => 'No more hints for this word.';

  @override
  String get hintAllWordsHinted =>
      'Every word still to find already has its hint.';

  @override
  String get arrowEscapeHintZoom =>
      'Tap an arrow to send it off the board. It needs a clear path to the edge. Pinch or use the buttons to zoom in.';

  @override
  String triplesFound(int matched, int total) {
    return 'Triples found: $matched / $total';
  }

  @override
  String get findThreeOfAKind => 'Find 3 of a kind';

  @override
  String get memoryMatchHintTriples => 'Tap three cards to find a triple.';

  @override
  String timeAndBest(String time, String best) {
    return 'Time: $time · Best: $best';
  }

  @override
  String timeTaken(String time) {
    return 'Time: $time';
  }

  @override
  String get showTimer => 'Show the clock while playing';

  @override
  String get showTimerNote =>
      'Your time is always saved so you can beat it. This only decides whether you see it while you play.';

  @override
  String get settings => 'Settings';

  @override
  String get largerText => 'Larger text';

  @override
  String get largerTextNote =>
      'Makes all text a little bigger than your phone\'s setting. Turn it off to follow the phone.';

  @override
  String get statistics => 'Your progress';

  @override
  String get statsHeader => 'What you have done so far';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days played',
      one: '1 day played',
    );
    return '$_temp0';
  }

  @override
  String statsStreakNow(int count) {
    return 'Streak: $count';
  }

  @override
  String statsStars(int count) {
    return '$count stars';
  }

  @override
  String statsLevelsCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels cleared',
      one: '1 level cleared',
    );
    return '$_temp0';
  }

  @override
  String statsFastest(int level, String time) {
    return 'Fastest: level $level in $time';
  }

  @override
  String get statsNothingYet => 'Play a level and it will show up here.';

  @override
  String statsTotalStars(int count) {
    return '$count stars in all';
  }

  @override
  String get buildingBoard => 'Setting up the next board…';

  @override
  String get gameArrowPicturesTitle => 'Arrow Pictures';

  @override
  String get gameArrowPicturesSubtitle => 'Every board is a picture';

  @override
  String get helpArrowPictures =>
      'Every board is a picture made of arrows. Tap an arrow to send it off the board in the direction it points — but its path must be clear. Send off all the arrows to win.';

  @override
  String pictureName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'key': 'a key',
      'fish': 'a fish',
      'mushroom': 'a mushroom',
      'mug': 'a mug',
      'christmas_tree': 'a Christmas tree',
      'house': 'a house',
      'bell': 'a bell',
      'bird': 'a bird',
      'anchor': 'an anchor',
      'candle': 'a candle',
      'sailboat': 'a sailboat',
      'scissors': 'a pair of scissors',
      'whale': 'a whale',
      'umbrella': 'an umbrella',
      'sun': 'the sun',
      'snail': 'a snail',
      'teapot': 'a teapot',
      'easter_egg': 'an Easter egg',
      'rocket': 'a rocket',
      'pumpkin': 'a pumpkin',
      'horse': 'a horse',
      'hot_air_balloon': 'a hot-air balloon',
      'lighthouse': 'a lighthouse',
      'fishing_boat': 'a fishing boat',
      'boot': 'a boot',
      'viking_ship': 'a Viking ship',
      'cat': 'a cat',
      'tractor': 'a tractor',
      'moose': 'a moose',
      'owl': 'an owl',
      'snowflake': 'a snowflake',
      'rabbit': 'a rabbit',
      'butterfly': 'a butterfly',
      'flag': 'a flag',
      'kransekake': 'a kransekake',
      'stave_church': 'a stave church',
      'troll': 'a troll',
      'elephant': 'an elephant',
      'mountain_cabin': 'a mountain cabin',
      'steam_locomotive': 'a steam locomotive',
      'bicycle': 'a bicycle',
      'roe_deer': 'a roe deer',
      'grand_piano': 'a grand piano',
      'watering_can': 'a watering can',
      'hedgehog': 'a hedgehog',
      'wheelbarrow': 'a wheelbarrow',
      'tortoise': 'a tortoise',
      'fox': 'a fox',
      'rocking_chair': 'a rocking chair',
      'seal': 'a seal',
      'sewing_machine': 'a sewing machine',
      'rooster': 'a rooster',
      'oil_lantern': 'an oil lantern',
      'puffin': 'a puffin',
      'frog': 'a frog',
      'gramophone': 'a gramophone',
      'typewriter': 'a typewriter',
      'penguin': 'a penguin',
      'tall_ship': 'a tall ship',
      'grandfather_clock': 'a grandfather clock',
      'squirrel': 'a squirrel',
      'swan': 'a swan',
      'leaning_tower_of_pisa': 'the Leaning Tower of Pisa',
      'eiffel_tower': 'the Eiffel Tower',
      'bryggen': 'Bryggen in Bergen',
      'peacock': 'a peacock',
      'giraffe': 'a giraffe',
      'big_ben': 'Big Ben',
      'eagle': 'an eagle',
      'statue_of_liberty': 'the Statue of Liberty',
      'tower_bridge': 'Tower Bridge',
      'octopus': 'an octopus',
      'oak_tree': 'an oak tree',
      'pyramids_and_sphinx': 'the pyramids and the Sphinx',
      'colosseum': 'the Colosseum',
      'seahorse': 'a seahorse',
      'pagoda': 'a pagoda',
      'lion': 'a lion',
      'windmill': 'a windmill',
      'dragon': 'a dragon',
      'sunflower_in_pot': 'a sunflower',
      'onion_dome_church': 'an onion-domed church',
      'nidaros_cathedral': 'Nidaros Cathedral',
      'coastal_express_ship': 'a coastal express ship',
      'reindeer': 'a reindeer',
      'fjord_with_rowboat': 'a fjord with a rowing boat',
      'stabbur': 'a stabbur',
      'polar_bear': 'a polar bear',
      'humpback_whale': 'a humpback whale',
      'red_deer_stag': 'a red deer stag',
      'tiger': 'a tiger',
      'hen_and_chicks': 'a hen and her chicks',
      'vintage_car': 'a vintage car',
      'harp': 'a harp',
      'spinning_wheel': 'a spinning wheel',
      'cuckoo_clock': 'a cuckoo clock',
      'carousel': 'a carousel',
      'taj_mahal': 'the Taj Mahal',
      'notre_dame': 'Notre-Dame',
      'fairytale_castle': 'a fairytale castle',
      'golden_gate_bridge': 'the Golden Gate Bridge',
      'parthenon': 'the Parthenon',
      'heart': 'a heart',
      'diamond': 'a diamond',
      'star': 'a star',
      'apple': 'an apple',
      'pear': 'a pear',
      'cherries': 'cherries',
      'acorn': 'an acorn',
      'strawberry': 'a strawberry',
      'carrot': 'a carrot',
      'crescent_moon': 'a crescent moon',
      'mitten': 'a mitten',
      'musical_note': 'a musical note',
      'duck': 'a duck',
      'padlock': 'a padlock',
      'light_bulb': 'a light bulb',
      'walrus': 'a walrus',
      'camel': 'a camel',
      'kangaroo': 'a kangaroo',
      'biplane': 'a biplane',
      'double_decker_bus': 'a double-decker bus',
      'pretzel': 'a pretzel',
      'bow_tie': 'a bow tie',
      'banana': 'a banana',
      'tulip': 'a tulip',
      'bottle': 'a bottle',
      'ice_cream_cone': 'an ice cream cone',
      'crown': 'a crown',
      'cactus': 'a cactus',
      'christmas_stocking': 'a Christmas stocking',
      'pine_cone': 'a pine cone',
      'pineapple': 'a pineapple',
      'teddy_bear': 'a teddy bear',
      'sheep': 'a sheep',
      'goat': 'a goat',
      'crab': 'a crab',
      'guitar': 'a guitar',
      'snowman': 'a snowman',
      'ladybird': 'a ladybird',
      'barn': 'a barn',
      'arc_de_triomphe': 'the Arc de Triomphe',
      'brandenburg_gate': 'the Brandenburg Gate',
      'sydney_opera_house': 'the Sydney Opera House',
      'st_pauls_cathedral': 'St Paul\'s Cathedral',
      'hagia_sophia': 'the Hagia Sophia',
      'petronas_towers': 'the Petronas Towers',
      'mont_saint_michel': 'Mont-Saint-Michel',
      'stagecoach': 'a stagecoach',
      'paddle_steamer': 'a paddle steamer',
      'lightning_bolt': 'a lightning bolt',
      'balloon': 'a balloon',
      'kite': 'a kite',
      'rain_cloud': 'a rain cloud',
      'watermelon_slice': 'a slice of watermelon',
      'lemon': 'a lemon',
      'table_lamp': 'a table lamp',
      'die': 'a die',
      'chess_knight': 'a chess knight',
      'trophy': 'a trophy',
      'four_leaf_clover': 'a four-leaf clover',
      'alarm_clock': 'an alarm clock',
      'gift_box': 'a present',
      'steam_tug': 'a steam tug',
      'lobster': 'a lobster',
      'cello': 'a cello',
      'fire_engine': 'a fire engine',
      'excavator': 'an excavator',
      'wolf': 'a wolf',
      'stonehenge': 'Stonehenge',
      'empire_state_building': 'the Empire State Building',
      'kremlin_spasskaya_tower': 'the Spasskaya Tower',
      'helicopter': 'a helicopter',
      'lusekofte': 'a Norwegian sweater',
      'rocking_horse': 'a rocking horse',
      'armchair': 'an armchair',
      'hammer': 'a hammer',
      'jellyfish': 'a jellyfish',
      'bucket': 'a bucket',
      'bathtub': 'a bathtub',
      'clothes_iron': 'an iron',
      'frying_pan': 'a frying pan',
      'cooking_pot': 'a cooking pot',
      'toaster': 'a toaster',
      'angkor_wat': 'Angkor Wat',
      'saxophone': 'a saxophone',
      'banjo': 'a banjo',
      'anvil': 'an anvil',
      'scorpion': 'a scorpion',
      'pram': 'a pram',
      'hourglass': 'an hourglass',
      'chess_rook': 'a chess rook',
      'fire_hydrant': 'a fire hydrant',
      'bird_house': 'a birdhouse',
      'birdcage': 'a birdcage',
      'mailbox': 'a mailbox',
      'diamond_ring': 'a diamond ring',
      'spectacles': 'a pair of glasses',
      'spade_suit': 'a spade',
      'club_suit': 'a club',
      'dog_bone': 'a dog bone',
      'fish_skeleton': 'a fish skeleton',
      'magnifying_glass': 'a magnifying glass',
      'horseshoe': 'a horseshoe',
      'palm_tree': 'a palm tree',
      'igloo': 'an igloo',
      'saturn': 'Saturn',
      'paw_print': 'a paw print',
      'tooth': 'a tooth',
      'cheese_wedge': 'a wedge of cheese',
      'ferris_wheel': 'a Ferris wheel',
      'tram': 'a tram',
      'submarine': 'a submarine',
      'motorcycle': 'a motorcycle',
      'movie_camera': 'a movie camera',
      'other': 'a picture',
    });
    return '$_temp0';
  }

  @override
  String pictureCleared(int level, String picture) {
    return 'You cleared level $level. It was $picture!';
  }

  @override
  String get gameBridgesTitle => 'Bridges';

  @override
  String get gameBridgesSubtitle => 'Connect the islands';

  @override
  String get helpBridges =>
      'Each circle is an island, and its number says how many bridges it needs. Join islands with straight bridges along a row or column: one or two between the same pair, and bridges may never cross. When every island has its number and they are all joined into one group, the puzzle is solved. Tap an island and then a neighbour to build a bridge, or tap the water between them. Tap a bridge again to make it double, and once more to remove it. Nothing is timed and a wrong bridge costs you nothing — just fix it.';

  @override
  String get bridgesHint =>
      'Tap two islands, or the water between them. Again for a double bridge, once more to remove.';

  @override
  String get bridgesCheck => 'Check my bridges';

  @override
  String get bridgesCheckClean => 'No wrong bridges so far!';

  @override
  String bridgesCheckFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bridges are wrong',
      one: '1 bridge is wrong',
    );
    return '$_temp0';
  }

  @override
  String get bridgesNoCrossing => 'Bridges can\'t cross each other.';

  @override
  String get bridgesNotJoined =>
      'Every island is full, but they are not all joined into one group yet.';

  @override
  String get gameLetterHiveTitle => 'Letter Hive';

  @override
  String get gameLetterHiveSubtitle => 'Make words from seven letters';

  @override
  String get helpLetterHive =>
      'Make words of four or more letters from the seven in the hive. Every word must use the centre letter, and a letter can be used more than once. Longer words score more, and a word that uses all seven letters scores a bonus. Reach the goal to clear the level, then keep going for more stars if you like. Tap the letters to spell a word, then OK. Nothing is timed.';

  @override
  String get letterHiveOk => 'OK';

  @override
  String get letterHiveDelete => 'Delete';

  @override
  String get letterHiveShuffle => 'Shuffle';

  @override
  String get letterHiveTapLetters => 'Tap the letters to spell a word';

  @override
  String get letterHiveTooShort => 'Too short: at least 4 letters';

  @override
  String letterHiveMissingCentre(String letter) {
    return 'Every word must use the centre letter, $letter';
  }

  @override
  String get letterHiveNotAWord => 'Not in the word list';

  @override
  String get letterHiveAlreadyFound => 'Already found';

  @override
  String letterHivePoints(int points) {
    return 'Nice! +$points';
  }

  @override
  String letterHivePangram(int points) {
    return 'All seven letters! +$points';
  }

  @override
  String letterHiveBonus(int points) {
    return 'A rare one, a bonus! +$points';
  }

  @override
  String letterHiveScore(int score, int goal) {
    return 'Score $score · goal $goal';
  }

  @override
  String letterHiveFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words found',
      one: '1 word found',
      zero: 'No words yet',
    );
    return '$_temp0';
  }

  @override
  String get letterHiveKeepGoing => 'Keep going';

  @override
  String letterHiveGoalReached(int level) {
    return 'You reached the goal on level $level. Keep going for more stars, or move on.';
  }

  @override
  String letterHiveMoreStars(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Three stars!',
      two: 'Two stars!',
    );
    return '$_temp0';
  }

  @override
  String letterHiveHintLine(String pattern, int count) {
    return 'Hint: $pattern ($count letters)';
  }

  @override
  String get letterHiveNoHints => 'You have found every word the goal counts!';

  @override
  String get letterHiveShowMissed => 'Show missed words';

  @override
  String get letterHiveRevealTitle => 'Show every word?';

  @override
  String get letterHiveRevealBody =>
      'You keep the stars you have, but this level can\'t earn any more.';

  @override
  String get letterHiveRevealConfirm => 'Show them';

  @override
  String get letterHiveRevealCancel => 'Not yet';

  @override
  String letterHiveMissed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words you missed',
      one: '1 word you missed',
    );
    return '$_temp0';
  }

  @override
  String get categoryCards => 'Cards';

  @override
  String get gameFreecellTitle => 'FreeCell';

  @override
  String get gameFreecellSubtitle =>
      'The classic patience: plan every card home';

  @override
  String get helpFreecell =>
      'Move every card to the four piles at the top right, building each suit up from Ace to King. In the columns, a card can go on a card one higher of the other colour: a red 6 on a black 7. Each free cell at the top left holds any one card.\n\nTap a card to pick it up, then tap where it should go. Tap it again to send it home, or to a free cell. You can move several cards at once when there is room to do it one at a time, so empty free cells and columns let you move longer runs. Cards that are safe to send home go there by themselves.\n\nUndo is free and unlimited. On later levels some free cells are closed.';

  @override
  String get freecellUndo => 'Undo';

  @override
  String freecellMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String get freecellNoMoves => 'No moves left. Undo and try another way.';

  @override
  String get freecellHintStuck =>
      'I can\'t find a way to win from here. Try undoing a few moves.';

  @override
  String freecellTooMany(int max) {
    return 'Only $max cards can move at once right now. Empty a free cell or a column to move more.';
  }
}
