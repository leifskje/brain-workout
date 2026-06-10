# Roadmap — games & home-screen improvements

From a review of our catalog vs brainplay.com (2026-06-10). Check items off as
they ship; add notes/links to per-game plan docs as they get designed.

## New games (priority order)

- [ ] **Word Search** — top pick. Most familiar puzzle for the elderly
  audience; trivially generatable (place words, fill random letters — solvable
  by construction); drag-to-select with generous hit areas. Reuse the Wordle
  word lists.
- [ ] **Mini Sudoku** — 4×4 → 6×6 → 9×9 by level. Familiar; unique-solution
  generators are well-trodden and fit the "guaranteed solvable" rule.
- [ ] **Crack the Code** (Mastermind with digits/colors) — deduction; tiny UI
  (big buttons); difficulty scales by code length + symbol count.
- [ ] **Simon** (repeat the light/sound sequence) — second *memory* game;
  simplest possible UI: four huge colored buttons.

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
- [ ] **Real Ko-fi URL** — `home_screen.dart` still has the placeholder
  (needs the actual account URL).

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
- [ ] **First-time "how to play" overlay per game** — one dismissible sheet
  with a picture, shown once (flag in ProgressStore).
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
