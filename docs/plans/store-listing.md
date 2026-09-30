# Play Store listing copy

Paste-ready text for Play Console → *Store presence → Main store listing*.
Norwegian is the default language; add English as an extra translation.

Play's limits: **app name 30**, **short description 80**, **full description
4000** characters. Counts below are checked by
`dart run tool/check_store_listing.dart`, which fails if any field is over.

Everything here is truthful about the app as built: no ads, no accounts, no data
collection, works offline. Keep it that way — the Data safety form has to match.

---

## Norwegian (nb) — default

### App name
```
Hjernetrim
```

### Short description
```
15 hjernetrim-spill som faktisk blir vanskeligere. Ingen reklame, ingen konto.
```

### Full description
```
Hjernetrim er femten små spill for hodet: piler, ord, tall, logikk og hukommelse. Enkle å komme i gang med, og de blir faktisk vanskeligere jo lenger du kommer.

Alt er bygget rundt én idé: grensesnittet skal være enkelt, ikke oppgavene. Stor, tydelig tekst, store knapper og rolige overganger. Ingen klokke med mindre du vil ha en, ingen mas og ingen reklame. Du bestemmer tempoet selv.

SPILLENE

Logikk
• Pilbilder — hvert brett er et bilde, og den siste pilen avslører hva det var
• Pillabyrint — nøst opp lange, buktende piler og send dem ut av brettet
• Pilflukt — send hver pil ut i retningen den peker
• Bildekryss — bruk talltipsene til å finne det skjulte bildet
• Knekk koden — finn den hemmelige koden
• Følg sporet — trykk på sirklene i rekkefølge
• Hva kommer etterpå? — finn mønsteret

Ord
• Ord — gjett det skjulte ordet på fem bokstaver
• Ordleting — finn de skjulte ordene i bokstavrutenettet
• Bokstavsalat — sett bokstavene i riktig rekkefølge

Tall
• Tallkryss — fyll ut kryssordet med regnestykker
• Mini-sudoku — fyll rutenettet uten gjentakelser
• 2048 — slå sammen brikker til målet

Hukommelse
• Memory — finn parene
• Simon — gjenta lysrekkefølgen

VANSKELIGHETSGRAD SOM FAKTISK ØKER

Hvert spill har nivåer som blir vanskeligere etter hvert — ikke bare større brett, men oppgaver som krever mer planlegging. Pilbilder alene har over 200 bilder. Ordspillene henter fra store ordlister og går fra vanlige ord til sjeldnere ord jo lenger du kommer.

DAGENS ØKT

Et lite daglig mål holder oversikt over hvor mange dager på rad du har spilt, og appen foreslår hva du kan spille neste. Spillene du spilte sist, ligger øverst. Ingen påminnelser du ikke har bedt om.

PERSONVERN

Appen samler ikke inn noe som helst. Ingen konto, ingen innlogging, ingen sporing, ingen reklame. All fremgang lagres bare på telefonen din, og appen fungerer helt uten nett.

SPRÅK

Norsk (bokmål) og engelsk. Appen følger telefonens språk, og du kan velge selv inne i appen.
```

---

## English (en-GB)

### App name
```
Brain Workout
```

### Short description
```
15 brain-training games that genuinely get harder. No ads, no account.
```

### Full description
```
Brain Workout is fifteen small games for your brain: arrows, words, numbers, logic and memory. Easy to pick up, and they genuinely get harder the further you go.

It is built around one idea: the interface should be simple, not the puzzles. Large, clear text, big buttons and calm transitions. No clock unless you want one, no nagging, no adverts. You set the pace.

THE GAMES

Logic
• Arrow Pictures — every board is a picture, and the last arrow reveals what it was
• Arrow Maze — untangle long snaking arrows and slide them off the board
• Arrow Escape — send every arrow off in the direction it points
• Picture Logic — use the number clues to reveal the hidden picture
• Crack the Code — work out the secret code
• Follow the Trail — tap the circles in order
• What Comes Next? — spot the pattern

Words
• Word — guess the hidden five-letter word
• Word Search — find the hidden words in the letter grid
• Word Scramble — put the letters back in the right order

Numbers
• Number Cross — fill in the crossword made of sums
• Mini Sudoku — fill the grid with no repeats
• 2048 — merge tiles up to the target

Memory
• Memory Match — find the pairs
• Simon — repeat the sequence of lights

DIFFICULTY THAT ACTUALLY CLIMBS

Every game has levels that keep getting harder — not just bigger boards, but puzzles that need more planning. Arrow Pictures alone has more than 200 pictures. The word games draw on large dictionaries and move from everyday words to rarer ones as you progress.

TODAY'S WORKOUT

A small daily goal keeps track of how many days in a row you have played, and suggests what to play next. The games you played last sit at the top. No reminders you did not ask for.

PRIVACY

The app collects nothing at all. No account, no sign-in, no tracking, no adverts. Progress is stored only on your phone, and everything works offline.

LANGUAGES

Norwegian (Bokmål) and English. The app follows your phone's language, and you can also choose inside the app.
```

---

## Graphics

All generated, none hand-made, so they stay in step with the app:

- **Icon and feature graphic:** `python tool/build_store_graphics.py`. The
  feature graphic is per language (`store/feature_1024x500_<lang>.png`), with the
  app name and tagline.
- **Screenshots:** `flutter test tool/store_screens/render_test.dart` renders
  real app screens offscreen (no screen capture, see `CLAUDE.md`), then
  `python tool/frame_screenshots.py` adds the background, caption and frame. The
  captions are in that script. There are six per language: Arrow Pictures in
  play, a revealed picture, home, Arrow Maze, Picture Logic, Word Search.
- Then `python tool/sync_play_listing.py` copies everything into GPP's tree.
  Publishing the listing (`publishListing`) writes to the live account, so it
  only happens when the owner asks.
## Content form answers (must match the app)

| Form | Answer |
|---|---|
| Privacy policy | URL of the published `PRIVACY.md` |
| Ads | No ads |
| App access | All functionality available, no restrictions |
| Content rating | Answer honestly → comes out rated for everyone |
| Target audience | 13+ / adults. **Do not tick under-13** — that opts into the far stricter Families policy |
| Data safety | No data collected, no data shared |
| Government / news / COVID app | No |
