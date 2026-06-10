// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Hjernetrim';

  @override
  String get homeTagline => 'Velg et spill til dagens økt';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dager på rad',
      one: '1 dag på rad',
    );
    return '$_temp0';
  }

  @override
  String get startStreakToday => 'Kom i gang i dag!';

  @override
  String bestStreak(int count) {
    return 'Beste: $count';
  }

  @override
  String get workoutComplete => 'Dagens økt er fullført! 🎉';

  @override
  String workoutProgress(int count, int goal) {
    return 'Dagens økt: $count av $goal';
  }

  @override
  String playNext(String game) {
    return 'Spill neste: $game';
  }

  @override
  String get continueLabel => 'Fortsett';

  @override
  String gameAtLevel(String game, int level) {
    return '$game — nivå $level';
  }

  @override
  String levelN(int level) {
    return 'Nivå $level';
  }

  @override
  String get play => 'Spill';

  @override
  String get comingSoon => 'Kommer snart';

  @override
  String get supportDeveloper => 'Støtt utvikleren';

  @override
  String get supportPageError => 'Kunne ikke åpne støttesiden.';

  @override
  String get categoryWords => 'Ord';

  @override
  String get categoryNumbers => 'Tall';

  @override
  String get categoryMemory => 'Hukommelse';

  @override
  String get categoryLogic => 'Logikk';

  @override
  String get gameArrowEscapeTitle => 'Pilflukt';

  @override
  String get gameArrowEscapeSubtitle => 'Send alle pilene ut av brettet';

  @override
  String get gameArrowMazeTitle => 'Pillabyrint';

  @override
  String get gameArrowMazeSubtitle => 'Nøst opp de lange, buktende pilene';

  @override
  String get gameWordTitle => 'Ord';

  @override
  String get gameWordSubtitle => 'Gjett det skjulte ordet';

  @override
  String get gameNumberCrossTitle => 'Tallkryss';

  @override
  String get gameNumberCrossSubtitle => 'Fyll ut tallkryssordet';

  @override
  String get gameMemoryMatchTitle => 'Memory';

  @override
  String get gameMemoryMatchSubtitle => 'Husk hvor parene er';

  @override
  String get gameWhatNextTitle => 'Hva kommer etterpå?';

  @override
  String get gameWhatNextSubtitle => 'Finn mønsteret';

  @override
  String get gameWordSearchTitle => 'Ordleting';

  @override
  String get gameWordSearchSubtitle => 'Finn de skjulte ordene';

  @override
  String get gameMiniSudokuTitle => 'Mini-sudoku';

  @override
  String get gameMiniSudokuSubtitle => 'Fyll rutenettet uten gjentakelser';

  @override
  String comingSoonTitle(String game) {
    return '$game kommer snart!';
  }

  @override
  String get comingSoonBody =>
      'Vi jobber fortsatt med dette spillet. Kom tilbake senere.';

  @override
  String get backToGames => 'Tilbake til spillene';

  @override
  String continueAtLevel(int level) {
    return 'Fortsett — nivå $level';
  }

  @override
  String get replayLevel => 'Spill et nivå om igjen';

  @override
  String get wellDone => 'Godt jobbet!';

  @override
  String clearedLevel(int level) {
    return 'Du klarte nivå $level.';
  }

  @override
  String get home => 'Hjem';

  @override
  String get nextLevel => 'Neste nivå';

  @override
  String get levelComplete => 'Nivå fullført';

  @override
  String get back => 'Tilbake';

  @override
  String get restartLevel => 'Start nivået på nytt';

  @override
  String get outOfHearts => 'Tomt for hjerter';

  @override
  String get outOfHeartsBody =>
      'Ingen hjerter igjen. Vil du prøve nivået på nytt?';

  @override
  String get tryAgain => 'Prøv igjen';

  @override
  String get arrowEscapeHint =>
      'Trykk på en pil for å sende den ut av brettet. Den må ha fri bane til kanten.';

  @override
  String get arrowMazeHint =>
      'Trykk på en lang pil for å sende den ut, hodet først. Banen foran hodet må være fri.';

  @override
  String get numberCrossHint =>
      'Trykk på et tall og så en rute, eller dra det inn. Alle regnestykkene må stemme, både bortover og nedover.';

  @override
  String get memoryMatchHint => 'Trykk på to kort for å finne et par.';

  @override
  String pairsFound(int matched, int total) {
    return 'Par funnet: $matched / $total';
  }

  @override
  String clearedLevelInMoves(int level, int moves) {
    return 'Du klarte nivå $level på $moves trekk.';
  }

  @override
  String questionOf(int current, int total) {
    return 'Spørsmål $current av $total';
  }

  @override
  String get whichComesNext => 'Hva kommer etterpå?';

  @override
  String get wordSearchHint => 'Dra over bokstavene for å markere et ord.';

  @override
  String wordsFound(int found, int total) {
    return 'Funnet $found av $total';
  }

  @override
  String get miniSudokuHint =>
      'Trykk på en rute og så et tall. Hvert tall passer bare én gang i hver rad, kolonne og boks.';

  @override
  String get notEnoughLetters => 'For få bokstaver';

  @override
  String get notInWordList => 'Ordet er ikke i ordlisten';

  @override
  String solvedInGuesses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Løst på $count forsøk!',
      one: 'Løst på 1 forsøk!',
    );
    return '$_temp0';
  }

  @override
  String get newWord => 'Nytt ord';

  @override
  String get outOfGuesses => 'Tomt for forsøk';

  @override
  String theWordWas(String word) {
    return 'Ordet var «$word».';
  }

  @override
  String get language => 'Språk';

  @override
  String get languageSystem => 'Følg telefonens språk';
}
