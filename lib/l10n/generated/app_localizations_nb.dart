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
  String get gameSimonTitle => 'Simon';

  @override
  String get gameSimonSubtitle => 'Gjenta lysrekkefølgen';

  @override
  String get gameWordScrambleTitle => 'Bokstavsalat';

  @override
  String get gameWordScrambleSubtitle => 'Sett bokstavene i riktig rekkefølge';

  @override
  String get gameCrackCodeTitle => 'Knekk koden';

  @override
  String get gameCrackCodeSubtitle => 'Gjett den hemmelige koden';

  @override
  String get gameTrailTitle => 'Følg sporet';

  @override
  String get gameTrailSubtitle => 'Trykk på sirklene i rekkefølge';

  @override
  String get gameMergeTitle => '2048';

  @override
  String get gameMergeSubtitle => 'Slå sammen brikker til målet';

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
  String get howToPlay => 'Slik spiller du';

  @override
  String get gotIt => 'Skjønner!';

  @override
  String get helpArrowEscape =>
      'Hver pil vil fly ut av brettet i retningen den peker. Trykk på en pil for å sende den av gårde — men banen må være fri. Send ut alle pilene for å vinne.';

  @override
  String get helpArrowMaze =>
      'De lange pilene glir ut av brettet med hodet først. Trykk på en for å sende den ut — banen foran hodet må være fri. Tøm hele brettet for å vinne.';

  @override
  String get helpWord =>
      'Gjett det skjulte ordet på fem bokstaver på seks forsøk. Grønn betyr riktig bokstav på riktig plass, gul betyr at bokstaven finnes et annet sted i ordet, grå betyr at den ikke er med.';

  @override
  String get helpNumberCross =>
      'Plasser tallene fra brettet i de tomme rutene slik at alle regnestykkene stemmer — både bortover og nedover. Trykk på et tall og så en rute, eller dra det inn. Trykk på et plassert tall for å ta det tilbake.';

  @override
  String get helpWordSearch =>
      'Alle ordene under rutenettet er gjemt blant bokstavene. Dra fingeren over et ord for å markere det — forlengs eller baklengs. Finn alle for å vinne.';

  @override
  String get helpMiniSudoku =>
      'Fyll de tomme rutene slik at hver rad, kolonne og boks inneholder hvert tall nøyaktig én gang. Trykk på en rute, og så på et tall. Tall som krasjer blir røde, så du kan rette dem.';

  @override
  String get helpMemoryMatch =>
      'Alle kortene ligger med bildesiden ned, og hvert bilde har en tvilling. Snu to kort om gangen og husk hva du ser. Finn alle parene for å vinne.';

  @override
  String get helpSimon =>
      'Se på knappene som lyser opp, én etter én. Trykk så på de samme knappene i samme rekkefølge. Rekken blir ett trinn lengre for hver runde — heng med til slutten!';

  @override
  String get helpWhatNext =>
      'Se på tallrekken og finn mønsteret. Velg så tallet som kommer etterpå. Feil svar koster et hjerte.';

  @override
  String get helpWordScramble =>
      'Bokstavene i et kjent ord er stokket om. Trykk på dem i riktig rekkefølge for å stave ordet. Trykk på en bokstav i svaret for å legge den tilbake.';

  @override
  String get helpCrackCode =>
      'Finn den hemmelige koden! Etter hvert forsøk får du hint: en grønn prikk betyr riktig tall på riktig plass, en gul prikk betyr riktig tall på feil plass. Knekk koden før forsøkene er brukt opp.';

  @override
  String get helpTrail =>
      'Trykk på sirklene i rekkefølge: 1, 2, 3 … På høyere nivåer veksler du mellom tall og bokstaver: 1, A, 2, B. Feil trykk koster et hjerte.';

  @override
  String get helpMerge =>
      'Sveip på brettet (eller bruk pilene) for å skyve alle brikkene én vei. Når to brikker med samme tall møtes, slås de sammen til én med dobbelt verdi. Nå målbrikken for å vinne.';

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
  String get simonHint =>
      'Se på knappene som lyser opp, og trykk dem i samme rekkefølge.';

  @override
  String get simonWatch => 'Se nøye etter…';

  @override
  String get simonYourTurn => 'Din tur!';

  @override
  String simonRound(int current, int total) {
    return 'Runde $current av $total';
  }

  @override
  String get wordScrambleHint =>
      'Trykk på bokstavene i riktig rekkefølge. Trykk på en bokstav i svaret for å legge den tilbake.';

  @override
  String wordOf(int current, int total) {
    return 'Ord $current av $total';
  }

  @override
  String get crackCodeHint =>
      'Grønn prikk: riktig tall på riktig plass. Gul prikk: riktig tall på feil plass.';

  @override
  String crackGuessOf(int current, int total) {
    return 'Forsøk $current av $total';
  }

  @override
  String crackCodeWas(String code) {
    return 'Koden var $code.';
  }

  @override
  String get trailHint =>
      'Trykk på sirklene i rekkefølge. Linjen følger fremgangen din.';

  @override
  String trailNext(String label) {
    return 'Neste: $label';
  }

  @override
  String get mergeHint =>
      'Trykk på en pil for å skyve alle brikkene den veien. Like tall slås sammen.';

  @override
  String get mergeGoalLabel => 'Lag:';

  @override
  String mergeTarget(int value) {
    return 'Mål: $value';
  }

  @override
  String mergeScore(int value) {
    return 'Poeng: $value';
  }

  @override
  String get noMoves => 'Ingen flere trekk';

  @override
  String get noMovesBody => 'Brettet er fullt. Vil du prøve nivået på nytt?';

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
