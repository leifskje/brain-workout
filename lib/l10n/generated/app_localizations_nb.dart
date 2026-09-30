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
  String get hintAllWordsHinted =>
      'Alle ordene som er igjen har allerede fått hint.';

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

  @override
  String get buildingBoard => 'Gjør klart neste brett…';

  @override
  String get gameArrowPicturesTitle => 'Pilbilder';

  @override
  String get gameArrowPicturesSubtitle => 'Hvert brett er et bilde';

  @override
  String get helpArrowPictures =>
      'Hvert brett er et bilde laget av piler. Trykk på en pil for å sende den ut av brettet i retningen den peker — men banen må være fri. Send ut alle pilene for å vinne.';

  @override
  String pictureName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'key': 'en nøkkel',
      'fish': 'en fisk',
      'mushroom': 'en sopp',
      'mug': 'et krus',
      'christmas_tree': 'et juletre',
      'house': 'et hus',
      'bell': 'en bjelle',
      'bird': 'en fugl',
      'anchor': 'et anker',
      'candle': 'et lys',
      'sailboat': 'en seilbåt',
      'scissors': 'en saks',
      'whale': 'en hval',
      'umbrella': 'en paraply',
      'sun': 'solen',
      'snail': 'en snegle',
      'teapot': 'en tekanne',
      'easter_egg': 'et påskeegg',
      'rocket': 'en rakett',
      'pumpkin': 'et gresskar',
      'horse': 'en hest',
      'hot_air_balloon': 'en luftballong',
      'lighthouse': 'et fyrtårn',
      'fishing_boat': 'en fiskebåt',
      'boot': 'en støvel',
      'viking_ship': 'et vikingskip',
      'cat': 'en katt',
      'tractor': 'en traktor',
      'moose': 'en elg',
      'owl': 'en ugle',
      'snowflake': 'et snøfnugg',
      'rabbit': 'en kanin',
      'butterfly': 'en sommerfugl',
      'flag': 'et flagg',
      'kransekake': 'en kransekake',
      'stave_church': 'en stavkirke',
      'troll': 'et troll',
      'elephant': 'en elefant',
      'mountain_cabin': 'en fjellhytte',
      'steam_locomotive': 'et damplokomotiv',
      'bicycle': 'en sykkel',
      'roe_deer': 'et rådyr',
      'grand_piano': 'et flygel',
      'watering_can': 'en vannkanne',
      'hedgehog': 'et pinnsvin',
      'wheelbarrow': 'en trillebår',
      'tortoise': 'en skilpadde',
      'fox': 'en rev',
      'rocking_chair': 'en gyngestol',
      'seal': 'en sel',
      'sewing_machine': 'en symaskin',
      'rooster': 'en hane',
      'oil_lantern': 'en parafinlampe',
      'puffin': 'en lundefugl',
      'frog': 'en frosk',
      'gramophone': 'en grammofon',
      'typewriter': 'en skrivemaskin',
      'penguin': 'en pingvin',
      'tall_ship': 'en seilskute',
      'grandfather_clock': 'et gulvur',
      'squirrel': 'et ekorn',
      'swan': 'en svane',
      'leaning_tower_of_pisa': 'det skjeve tårnet i Pisa',
      'eiffel_tower': 'Eiffeltårnet',
      'bryggen': 'Bryggen i Bergen',
      'peacock': 'en påfugl',
      'giraffe': 'en sjiraff',
      'big_ben': 'Big Ben',
      'eagle': 'en ørn',
      'statue_of_liberty': 'Frihetsgudinnen',
      'tower_bridge': 'Tower Bridge',
      'octopus': 'en blekksprut',
      'oak_tree': 'en eik',
      'pyramids_and_sphinx': 'pyramidene og sfinksen',
      'colosseum': 'Colosseum',
      'seahorse': 'en sjøhest',
      'pagoda': 'en pagode',
      'lion': 'en løve',
      'windmill': 'en vindmølle',
      'dragon': 'en drage',
      'sunflower_in_pot': 'en solsikke',
      'onion_dome_church': 'en kirke med løkkupler',
      'nidaros_cathedral': 'Nidarosdomen',
      'coastal_express_ship': 'et hurtigruteskip',
      'reindeer': 'et reinsdyr',
      'fjord_with_rowboat': 'en fjord med robåt',
      'stabbur': 'et stabbur',
      'polar_bear': 'en isbjørn',
      'humpback_whale': 'en knølhval',
      'red_deer_stag': 'en kronhjort',
      'tiger': 'en tiger',
      'hen_and_chicks': 'en høne med kyllinger',
      'vintage_car': 'en veteranbil',
      'harp': 'en harpe',
      'spinning_wheel': 'en rokk',
      'cuckoo_clock': 'et gjøkur',
      'carousel': 'en karusell',
      'taj_mahal': 'Taj Mahal',
      'notre_dame': 'Notre-Dame',
      'fairytale_castle': 'et eventyrslott',
      'golden_gate_bridge': 'Golden Gate-broen',
      'parthenon': 'Parthenon',
      'heart': 'et hjerte',
      'diamond': 'en diamant',
      'star': 'en stjerne',
      'apple': 'et eple',
      'pear': 'ei pære',
      'cherries': 'kirsebær',
      'acorn': 'ei eikenøtt',
      'strawberry': 'et jordbær',
      'carrot': 'en gulrot',
      'crescent_moon': 'en månesigd',
      'mitten': 'en votte',
      'musical_note': 'en note',
      'duck': 'en and',
      'padlock': 'en hengelås',
      'light_bulb': 'ei lyspære',
      'walrus': 'en hvalross',
      'camel': 'en kamel',
      'kangaroo': 'en kenguru',
      'biplane': 'et dobbeltdekkerfly',
      'double_decker_bus': 'en dobbeltdekkerbuss',
      'pretzel': 'en kringle',
      'bow_tie': 'en tøysløyfe',
      'banana': 'en banan',
      'tulip': 'en tulipan',
      'bottle': 'ei flaske',
      'ice_cream_cone': 'en iskrem',
      'crown': 'en krone',
      'cactus': 'en kaktus',
      'christmas_stocking': 'en julestrømpe',
      'pine_cone': 'en kongle',
      'pineapple': 'en ananas',
      'teddy_bear': 'en teddybjørn',
      'sheep': 'en sau',
      'goat': 'ei geit',
      'crab': 'en krabbe',
      'guitar': 'en gitar',
      'snowman': 'en snømann',
      'ladybird': 'ei marihøne',
      'barn': 'ei låve',
      'arc_de_triomphe': 'Triumfbuen',
      'brandenburg_gate': 'Brandenburger Tor',
      'sydney_opera_house': 'operahuset i Sydney',
      'st_pauls_cathedral': 'St. Paul\'s Cathedral',
      'hagia_sophia': 'Hagia Sofia',
      'petronas_towers': 'Petronas-tårnene',
      'mont_saint_michel': 'Mont-Saint-Michel',
      'stagecoach': 'en diligence',
      'paddle_steamer': 'en hjuldamper',
      'lightning_bolt': 'et lyn',
      'balloon': 'en ballong',
      'kite': 'en drage',
      'rain_cloud': 'en regnsky',
      'watermelon_slice': 'en vannmelonbit',
      'lemon': 'en sitron',
      'table_lamp': 'en bordlampe',
      'die': 'en terning',
      'chess_knight': 'en springer',
      'trophy': 'en pokal',
      'four_leaf_clover': 'et firkløver',
      'alarm_clock': 'ei vekkerklokke',
      'gift_box': 'en gave',
      'steam_tug': 'en slepebåt',
      'lobster': 'en hummer',
      'cello': 'en cello',
      'fire_engine': 'en brannbil',
      'excavator': 'en gravemaskin',
      'wolf': 'en ulv',
      'stonehenge': 'Stonehenge',
      'empire_state_building': 'Empire State Building',
      'kremlin_spasskaya_tower': 'Spasskij-tårnet',
      'helicopter': 'et helikopter',
      'lusekofte': 'en lusekofte',
      'rocking_horse': 'en gyngehest',
      'armchair': 'en lenestol',
      'hammer': 'en hammer',
      'jellyfish': 'en manet',
      'bucket': 'ei bøtte',
      'bathtub': 'et badekar',
      'clothes_iron': 'et strykejern',
      'frying_pan': 'ei stekepanne',
      'cooking_pot': 'ei gryte',
      'toaster': 'en brødrister',
      'angkor_wat': 'Angkor Wat',
      'saxophone': 'en saksofon',
      'banjo': 'en banjo',
      'anvil': 'en ambolt',
      'scorpion': 'en skorpion',
      'pram': 'en barnevogn',
      'hourglass': 'et timeglass',
      'chess_rook': 'et sjakktårn',
      'fire_hydrant': 'en brannhydrant',
      'bird_house': 'en fuglekasse',
      'birdcage': 'et fuglebur',
      'mailbox': 'en postkasse',
      'diamond_ring': 'en diamantring',
      'spectacles': 'et par briller',
      'spade_suit': 'en spar',
      'club_suit': 'en kløver',
      'dog_bone': 'et hundebein',
      'fish_skeleton': 'et fiskebein',
      'magnifying_glass': 'et forstørrelsesglass',
      'horseshoe': 'en hestesko',
      'palm_tree': 'en palme',
      'igloo': 'en iglo',
      'saturn': 'Saturn',
      'paw_print': 'et poteavtrykk',
      'tooth': 'en tann',
      'cheese_wedge': 'et ostestykke',
      'ferris_wheel': 'et pariserhjul',
      'tram': 'en trikk',
      'submarine': 'en ubåt',
      'motorcycle': 'en motorsykkel',
      'movie_camera': 'et filmkamera',
      'other': 'et bilde',
    });
    return '$_temp0';
  }

  @override
  String pictureCleared(int level, String picture) {
    return 'Du klarte nivå $level. Det var $picture!';
  }
}
