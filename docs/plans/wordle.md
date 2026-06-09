# Word game (Wordle-style)

Guess a hidden 5-letter word in 6 tries; each guess colours letters
**green** (right letter, right spot), **yellow** (in the word, wrong spot),
**grey** (not in the word). Built for the app's audience, multi-language.

## Decisions

- **Languages:** English + Norwegian (bokmål) first, on an **extensible**
  language system so Swedish/Danish/etc. drop in later. Norwegian is the
  priority user. Each language: display name, word list asset, keyboard rows
  (Norwegian adds æ ø å).
- **Mode:** unlimited random words (play anytime), *not* one-per-day. Completing
  one word counts toward the daily workout (`registerPlay('wordle')`).
- **Not level-based.** Uses a **direct entry screen** (see architecture note in
  [backlog.md](backlog.md)) — needs the `GameDefinition.screenBuilder` addition.
  A small Wordle home offers Play + a language toggle.
- **Stars:** by guesses used — ≤3 → 3★, ≤4 → 2★, ≤6 → 1★ (recorded as best).

## Build steps

1. **Word lists (assets/words/<lang>.txt)** — 5-letter words, UPPERCASE, one per
   line. English: filtered from dwyl/english-words (public domain). Norwegian:
   ⚠️ still need a vetted, openly-licensed nb list (candidate: hunspell nb_NO
   expanded, or an open Scrabble/ordliste). Two roles: *answers* (common subset,
   ideally) and *allowed guesses* (full list). v1 may use one list for both.
2. **Engine (`wordle_models.dart`, pure Dart):** `LetterState`, and
   `scoreGuess(guess, target)` with correct **duplicate-letter** handling
   (count remaining occurrences after greens). ← unit-tested.
3. **Word repository (`word_repository.dart`):** loads a language's asset into a
   `Set` (validate guesses) + picks random answers. Uses `rootBundle`.
4. **Language config + selection:** `WordleLanguage` list; persist the chosen
   language in `ProgressStore` (`wordle_lang`).
5. **UI:** 6×5 guess grid with flip/colour reveal, on-screen keyboard with
   per-letter state colours (æ/ø/å for Norwegian), backspace/enter, invalid-word
   shake, win/lose, "New word". Themed accent (green).
6. **Integrate:** GameDefinition `screenBuilder`; home routing; daily-workout +
   stars.

## Status

- 🔨 Foundation: English word list + engine + tests.
- 📝 Norwegian word list (source + vet).
- 📝 UI + language toggle + integration.
