# Roadmap — games & home-screen improvements

From a review of our catalog vs brainplay.com (2026-06-10). Check items off as
they ship; add notes/links to per-game plan docs as they get designed.

## New games (priority order)

- [x] **Word Search** — shipped; see `docs/plans/word-search.md`. Curated
  en/nb word pools embedded in the model (Wordle lists were 5-letter-only
  dictionaries — wrong fit); word list follows the app language.
- [x] **Mini Sudoku** — shipped; see `docs/plans/mini-sudoku.md`. 4×4 → 6×6 →
  9×9 by level, unique-solution digging, conflict highlighting.
- [x] **Crack the Code** — shipped; see `docs/plans/crack-code.md`.
  Digit Mastermind, no repeated digits, dot clues.
- [x] **Simon** — shipped; see `docs/plans/simon.md`. Four huge buttons,
  grows 3→12 steps, hearts + replay-the-round on a miss.
- [x] **Word Scramble** (Bokstavsalat) — shipped; see
  `docs/plans/word-scramble.md`. Reuses the curated word pools.
- [x] **Follow the Trail** — shipped; see `docs/plans/trail.md`. Classic
  trail-making: tap 1, 2, 3 … / 1, A, 2, B in order.

- [x] **Merge / 2048** — shipped; see `docs/plans/merge.md`. Slide-and-merge
  to a per-level target tile; swipe + arrow pad; no art.

Lower priority / parked:

- [ ] Tower of Hanoi — simple but gets samey.
- [ ] Mahjong solitaire — very familiar to the demographic but needs tile art.
- [ ] Solitaire — extremely familiar but a big build.
- [ ] Tangram — drag-rotate is fiddly for elderly motor control.

## Home screen / UX — quick wins

- [x] **Category chips on game cards** (Words · Numbers · Memory · Logic) —
  helps scanning; no navigation change.
- [x] **"Continue" row** under the daily card — most recently opened game,
  tap goes straight into its current level. The catalog grid keeps a *fixed*
  order (elderly users build spatial memory; never reshuffle the grid).
- [x] **"Play next" button on the daily card** — suggests a game and launches
  it directly; removes choice paralysis. Suggestion rotates with each
  completed level for variety.
- [x] **Total stars on each game card** ("★ 24") — gentle collection feeling,
  data already in ProgressStore.
- [x] **Real Ko-fi URL** — `ko-fi.com/loffen` (account connected to Stripe).

## Bigger items

- [x] **Norwegian localization** — `intl`/ARB (`lib/l10n/app_en.arb` +
  `app_nb.arb`, generated into `lib/l10n/generated/`). Any Norwegian system
  locale (nb/nn/no) resolves to Bokmål; everything else falls back to English.
  Word (Wordle) defaults its word list to the app language until the player
  picks one. Game titles localized too (Pilflukt, Tallkryss, …). The Android
  launcher label is locale-aware (Hjernetrim on Norwegian phones).
- [x] **In-app language switcher** — globe menu on the home screen:
  follow phone / English / Norsk; persisted (`app_lang`) and applied live via
  `appLocaleOverride` (`lib/services/app_locale.dart`).
- [x] **First-time "how to play" overlay per game** — bottom sheet with large
  text shown once per game (flag in ProgressStore), reopenable via a "?"
  button in every game header. Simon pauses its playback under the sheet.
- [ ] **Section headers by category** — only when the catalog reaches ~9–10
  games. Single scroll list with headers; never tabs.
- [ ] **Smarter daily workout** — "one word, one number, one memory game"
  instead of any 3 levels, once categories exist.

## Explicitly rejected

- **Gems / leaderboards / XP levels** (brainplay-style) — competitive
  pressure and currency systems clash with the calm, self-paced design.
  Streak + stars is enough.
- **Reordering the game grid by recency** — hostile to spatial memory;
  the "Continue" row covers the need instead.
