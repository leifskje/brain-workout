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
  String get gameNonogramTitle => 'Bildekryss';

  @override
  String get gameNonogramSubtitle => 'Finn det skjulte bildet';

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
      'De lange pilene glir ut av brettet med hodet først. Trykk på en for å sende den ut — banen foran hodet må være fri. Tøm hele brettet for å vinne. Fra nivå 12 er én pil gyllen. Den står i veien for flere andre, så når den endelig kommer seg ut, kan de følge rett etter — verdt å sikte på.';

  @override
  String get helpWord =>
      'Gjett det skjulte ordet på fem bokstaver på seks forsøk. Grønn betyr riktig bokstav på riktig plass, gul betyr at bokstaven finnes et annet sted i ordet, grå betyr at den ikke er med.';

  @override
  String get helpNumberCross =>
      'Plasser tallene fra brettet i de tomme rutene slik at alle regnestykkene stemmer — både bortover og nedover. Trykk på et tall og så en rute, eller dra det inn. Trykk på et plassert tall for å ta det tilbake.';

  @override
  String get helpWordSearch =>
      'Alle ordene under rutenettet er gjemt blant bokstavene. Dra fingeren over et ord for å markere det — forlengs eller baklengs. Finn alle for å vinne. Fra nivå 10 hører alle ordene til samme kategori, og på de vanskeligste nivåene er listen skjult: du får bare kategorien og hvor mange ord du skal finne.';

  @override
  String get helpMiniSudoku =>
      'Fyll de tomme rutene slik at hver rad, kolonne og boks inneholder hvert tall nøyaktig én gang. Trykk på en rute, og så på et tall. Tall som krasjer blir røde, så du kan rette dem.';

  @override
  String get helpMemoryMatch =>
      'Alle kortene ligger med bildesiden ned, og hvert bilde har en tvilling. Snu to kort om gangen og husk hva du ser. Finn alle parene for å vinne.\n\nFra nivå 10 kommer bildene i tre og tre i stedet for to og to: du snur tre kort om gangen, og alle tre må være like. Brettet sier «Finn 3 like» når det er i den modusen.';

  @override
  String get helpSimon =>
      'Se på knappene som lyser opp, én etter én. Trykk så på de samme knappene i samme rekkefølge. Rekken blir ett trinn lengre for hver runde — heng med til slutten!';

  @override
  String get helpWhatNext =>
      'Se på rekken og finn mønsteret — det kan være tall, prikker, farger eller piler. Velg så det som kommer etterpå. Feil svar koster et hjerte.';

  @override
  String get helpWordScramble =>
      'Bokstavene i et kjent ord er stokket om. Trykk på dem i riktig rekkefølge for å stave ordet. Trykk på en bokstav i svaret for å legge den tilbake. Kategorien over bokstavene sier hva slags ord du skal se etter. Hvis bokstavene også danner et annet ekte ord, koster det deg ingenting — bare prøv igjen.';

  @override
  String get helpCrackCode =>
      'Finn den hemmelige koden! Etter hvert forsøk får du to tall: det grønne viser hvor mange som er riktige og står på riktig plass, det gule hvor mange som er riktige, men står på feil plass.\n\nDu får bare antallet — aldri hvilke. Det er nettopp det du skal regne ut. Knekk koden før forsøkene er brukt opp.';

  @override
  String get helpTrail =>
      'Trykk på sirklene i rekkefølge: 1, 2, 3 … På høyere nivåer veksler du mellom tall og bokstaver: 1, A, 2, B. Feil trykk koster et hjerte.';

  @override
  String get helpMerge =>
      'Sveip på brettet (eller bruk pilene) for å skyve alle brikkene én vei. Når to brikker med samme tall møtes, slås de sammen til én med dobbelt verdi. Nå målbrikken for å vinne.';

  @override
  String get helpNonogram =>
      'Tallene øverst og til venstre forteller hvor mange ruter på rad som er fylt, i rekkefølge. En linje merket 4 2 har fire fylte ruter, minst ett opphold, og så to til. En linje merket 0 er tom. Trykk på en rute for å fylle den, trykk igjen for å sette et kryss der du er sikker på at den skal være tom, og en gang til for å tømme den. Fyll alle de riktige rutene for å avsløre bildet. Ingenting er på tid, og en feil rute koster deg ingenting — bare rett den opp.';

  @override
  String get newRecord => 'Ny personlig rekord!';

  @override
  String bestMoves(int count) {
    return 'Din beste: $count trekk';
  }

  @override
  String bestScore(int value) {
    return 'Din beste poengsum: $value';
  }

  @override
  String bestMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Din beste: $count feil',
      one: 'Din beste: 1 feil',
      zero: 'Din beste: ingen feil',
    );
    return '$_temp0';
  }

  @override
  String bestGuesses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Din beste: $count gjett',
      one: 'Din beste: 1 gjett',
    );
    return '$_temp0';
  }

  @override
  String bonusArrowFreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Den gylne pilen frigjorde $count til!',
      one: 'Den gylne pilen frigjorde 1 til!',
    );
    return '$_temp0';
  }

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
  String get arrowMazeHintZoom =>
      'Trykk på en lang pil for å sende den ut, hodet først. Knip eller bruk knappene for å zoome inn.';

  @override
  String get zoomIn => 'Zoom inn';

  @override
  String get zoomOut => 'Zoom ut';

  @override
  String get zoomFit => 'Vis hele brettet';

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
  String wordSearchTheme(int count, String category) {
    return '$count skjulte ord å finne. Kategori: $category';
  }

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
      'Grønn: riktig tall på riktig plass. Gul: riktig tall på feil plass. Hvor mange — aldri hvilke.';

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
  String get nonogramHint =>
      'Trykk for å fylle, igjen for kryss, en gang til for å tømme.';

  @override
  String get nonogramCheck => 'Sjekk rutene mine';

  @override
  String get nonogramCheckClean => 'Ingen feil så langt!';

  @override
  String nonogramCheckFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fylte ruter er feil',
      one: '1 fylt rute er feil',
    );
    return '$_temp0';
  }

  @override
  String dailyShareTitle(int number) {
    return 'Hjernetrim — Ord $number';
  }

  @override
  String wordOfTheDay(int number) {
    return 'Dagens ord #$number';
  }

  @override
  String get dailyDoneTitle => 'Dagens ord er ferdig!';

  @override
  String get dailyDoneBody =>
      'Et nytt ord kommer hver dag — kom tilbake i morgen.';

  @override
  String get dailyNotSolved => 'Du klarte ikke dagens ord.';

  @override
  String get closeAction => 'Lukk';

  @override
  String get shareResult => 'Del';

  @override
  String get shareUnavailable =>
      'Deling er ikke tilgjengelig her — kopiert til utklippstavlen i stedet.';

  @override
  String get copyResult => 'Kopier';

  @override
  String get copiedToClipboard => 'Kopiert til utklippstavlen';

  @override
  String get practiceWord => 'Spill et nytt ord';

  @override
  String get practiceWordNote => 'Så mange du vil — disse er bare til øving.';

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

  @override
  String get categoryFood => 'Mat og drikke';

  @override
  String get categoryAnimals => 'Dyr';

  @override
  String get categoryHome => 'I hjemmet';

  @override
  String get categoryNature => 'Natur og vær';

  @override
  String get categoryClothing => 'Klær';

  @override
  String get categoryBody => 'Kroppen';

  @override
  String get categoryTravel => 'Steder og reise';

  @override
  String get categoryPeople => 'Mennesker';

  @override
  String scrambleNearMiss(String word) {
    return '«$word» er et ord — men ikke dette. Prøv igjen.';
  }

  @override
  String get credits => 'Om og takk til';

  @override
  String get creditsIntro =>
      'Ordspillene bruker disse åpent lisensierte ordlistene.';

  @override
  String get creditsWordListsTitle => 'Ordlister';

  @override
  String get creditsOrdbankName => 'Norsk ordbank (norsk)';

  @override
  String get creditsOrdbankBody =>
      '© Språkrådet og Universitetet i Bergen, via Språkbanken ved Nasjonalbiblioteket. Brukt under lisensen Creative Commons Navngivelse 4.0.';

  @override
  String get creditsOrdbankChanges =>
      'Tilpasset denne appen: filtrert til ord på 3–8 bokstaver, egennavn fjernet, og delt i grunnformer og fullformer.';

  @override
  String get creditsDwylName => 'english-words (engelsk)';

  @override
  String get creditsDwylBody =>
      'Fra listen dwyl/english-words, frigitt til offentlig eiendom.';

  @override
  String get creditsDwylChanges =>
      'Tilpasset denne appen: filtrert til ord på 3–8 bokstaver.';

  @override
  String get creditsLicenceLink => 'Les lisensen CC BY 4.0';

  @override
  String get creditsShareAlikeLink => 'Les lisensen CC BY-SA 4.0';

  @override
  String get creditsScowlName => 'SCOWL (engelsk ordvanskelighet)';

  @override
  String get creditsScowlBody =>
      'Vanskelighetsnivåene for engelske ord kommer fra SCOWL, Spell Checker Oriented Word List, som fritt kan brukes, kopieres, endres og distribueres til alle formål.';

  @override
  String get creditsScowlChanges =>
      'Tilpasset denne appen: hvert ord merket med den minste SCOWL-størrelsen det finnes i, som et mål på hvor vanlig det er.';

  @override
  String get creditsFreqName => 'Norske ordfrekvenser';

  @override
  String get creditsFreqBody =>
      'Vanskelighetsnivået for norske ord kommer fra FrequencyWords-listene (Hermit Dave, laget fra OpenSubtitles-data), brukt under lisensen Creative Commons Navngivelse-DelPåSammeVilkår 4.0. På grunn av del-på-samme-vilkår er den norske ordlisten denne appen bruker også tilgjengelig under CC BY-SA 4.0.';

  @override
  String get creditsFreqChanges =>
      'Tilpasset denne appen: frekvensrangeringer redusert til fire vanskelighetsnivåer og koblet mot ordlisten fra Norsk ordbank.';

  @override
  String get sendFeedback => 'Send tilbakemelding';

  @override
  String get feedbackSubject => 'Tilbakemelding om Hjernetrim';

  @override
  String get feedbackIntro =>
      'Hva skjedde, og hva forventet du? Alt er nyttig — selv én linje.';

  @override
  String get feedbackNoMailApp =>
      'Fant ingen e-postapp. Adressen og detaljene ble kopiert i stedet.';

  @override
  String appVersion(String version) {
    return 'Versjon $version';
  }

  @override
  String get updateAvailable => 'En ny versjon er klar';

  @override
  String get updateBody =>
      'Oppdater nå slik at du spiller den nyeste versjonen.';

  @override
  String get updateNow => 'Oppdater';

  @override
  String get updateLater => 'Ikke nå';

  @override
  String get updateFailed =>
      'Oppdateringen kunne ikke startes. Åpne Play Butikk og søk opp appen.';

  @override
  String get useHint => 'Hint';

  @override
  String get hintCost => 'Et hint betyr høyst 2 stjerner på dette nivået.';

  @override
  String get hintNoneLeft => 'Ingen flere hint til dette ordet.';

  @override
  String get arrowEscapeHintZoom =>
      'Trykk på en pil for å sende den ut av brettet. Den må ha fri bane til kanten. Knip eller bruk knappene for å zoome inn.';

  @override
  String triplesFound(int matched, int total) {
    return 'Tripler funnet: $matched / $total';
  }

  @override
  String get findThreeOfAKind => 'Finn 3 like';

  @override
  String get memoryMatchHintTriples =>
      'Trykk på tre kort for å finne en trippel.';

  @override
  String timeAndBest(String time, String best) {
    return 'Tid: $time · Beste: $best';
  }

  @override
  String timeTaken(String time) {
    return 'Tid: $time';
  }

  @override
  String get showTimer => 'Vis klokken mens du spiller';

  @override
  String get showTimerNote =>
      'Tiden din lagres alltid, så du kan slå den. Dette bestemmer bare om du ser den mens du spiller.';

  @override
  String get settings => 'Innstillinger';

  @override
  String get statistics => 'Din framgang';

  @override
  String get statsHeader => 'Dette har du gjort så langt';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dager spilt',
      one: '1 dag spilt',
    );
    return '$_temp0';
  }

  @override
  String statsStreakNow(int count) {
    return 'Rekke: $count';
  }

  @override
  String statsStars(int count) {
    return '$count stjerner';
  }

  @override
  String statsLevelsCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nivåer fullført',
      one: '1 nivå fullført',
    );
    return '$_temp0';
  }

  @override
  String statsFastest(int level, String time) {
    return 'Raskeste: nivå $level på $time';
  }

  @override
  String get statsNothingYet => 'Spill et nivå, så vises det her.';

  @override
  String statsTotalStars(int count) {
    return '$count stjerner i alt';
  }
}
