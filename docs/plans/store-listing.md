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
Rolige hjernetrim-oppgaver med stor tekst og store knapper. Uten tidspress.
```

### Full description
```
Hjernetrim samler tolv små oppgaver som er laget for å være behagelige å bruke — og skikkelig morsomme å løse.

Alt er bygget rundt én idé: grensesnittet skal være enkelt, ikke oppgavene. Stor tekst, store trykkflater, tydelige farger og rolige overganger. Ingen klokke som teller ned, ingen mas, ingen reklame. Du bestemmer tempoet selv.

SPILLENE

• Pillabyrint — nøst opp lange, buktende piler og send dem ut av brettet
• Pilflukt — send hver pil ut i retningen den peker
• Bokstavsalat — sett bokstavene i riktig rekkefølge
• Ordleting — finn de skjulte ordene i bokstavrutenettet
• Ord — gjett det skjulte ordet på fem bokstaver
• Tallkryss — fyll ut kryssordet med regnestykker
• Mini-sudoku — fyll rutenettet uten gjentakelser
• Memory — finn parene
• Simon — gjenta lysrekkefølgen
• Hva kommer etterpå? — finn mønsteret
• Knekk koden — finn den hemmelige koden
• 2048 — slå sammen brikker til målet

VANSKELIGHETSGRAD SOM FAKTISK ØKER

Hvert spill har nivåer som blir vanskeligere etter hvert — ikke bare større brett, men oppgaver som krever mer planlegging. Ordspillene henter fra store ordlister og går fra vanlige ord til sjeldnere ord jo lenger du kommer.

DAGENS ØKT

En liten daglig utfordring holder oversikt over hvor mange dager på rad du har spilt. Ingen påminnelser du ikke har bedt om.

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
Calm brain-training puzzles with large text and big buttons. No timers.
```

### Full description
```
Brain Workout is twelve small puzzles built to be comfortable to use — and genuinely satisfying to solve.

It is built around one idea: the interface should be simple, not the puzzles. Large text, big tap targets, clear colours and calm transitions. No countdown clock, no nagging, no adverts. You set the pace.

THE GAMES

• Arrow Maze — untangle long snaking arrows and slide them off the board
• Arrow Escape — send every arrow off in the direction it points
• Word Scramble — put the letters back in the right order
• Word Search — find the hidden words in the letter grid
• Word — guess the hidden five-letter word
• Number Cross — fill in the crossword made of sums
• Mini Sudoku — fill the grid with no repeats
• Memory Match — find the pairs
• Simon — repeat the sequence of lights
• What Comes Next? — spot the pattern
• Crack the Code — work out the secret code
• 2048 — merge tiles up to the target

DIFFICULTY THAT ACTUALLY CLIMBS

Every game has levels that keep getting harder — not just bigger boards, but puzzles that need more planning. The word games draw on large dictionaries and move from everyday words to rarer ones as you progress.

TODAY'S WORKOUT

A small daily goal keeps track of how many days in a row you have played. No reminders you did not ask for.

PRIVACY

The app collects nothing at all. No account, no sign-in, no tracking, no adverts. Progress is stored only on your phone, and everything works offline.

LANGUAGES

Norwegian (Bokmål) and English. The app follows your phone's language, and you can also choose inside the app.
```

---

## Graphics still needed (owner)

Play will not let you publish without these:

- **App icon** 512×512 PNG, 32-bit, no transparency. Source:
  `assets/icon/app_icon.png` — check it is at least 512×512 and re-export flat.
- **Feature graphic** 1024×500 PNG or JPG, no transparency and no text near the
  edges (Play crops it on some surfaces).
- **Phone screenshots**, minimum 2, maximum 8. 16:9 or 9:16, at least 1080px on
  the long edge. Take them on the emulator: Arrow Maze mid-game, Word Scramble
  showing a category chip, the home screen with the daily card, and Mini Sudoku
  are the four that show the app off best.

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
