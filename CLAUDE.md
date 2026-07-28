# Brain Workout — project guide

A Flutter app of small "brain training" mini-games aimed at elderly users (built
with my mother in mind). A home screen lists selectable games; each game is
self-contained. Cross-platform Flutter, primary target Android.

**"Elderly-friendly" means the interface, not the content.** Large text, big tap
targets, high contrast, calm flows, no timers — yes. Easy puzzles — no. The player
this was built for is a retired English teacher, widely read in Norwegian and
English, so watering the content down makes the games boring rather than
accessible. Judge every game on whether it is *entertaining* and *appropriately
hard for its level number*, not on whether one specific person could manage it.
Difficulty must keep climbing past the early levels; see the Arrow Maze notes
under *Conventions* for how to measure that rather than guess at it.

## Working in this repo (for AI agents)

- **Verify, don't claim.** "Done" means `/test` (or `flutter analyze` + `flutter
  test`) is green — quote the result, don't assert it. For anything visual:
  widget tests (phone-size render + gestures) and board text dumps
  (`tool/dump_*.dart`) are the agent's channels; do **not** launch the app or
  take screenshots (screen capture triggers a corporate IT alert) — the owner
  tests look & feel on the emulator via hot reload and reports back.
- **These bugs already bit us once — don't reintroduce them** (details under
  *Conventions* below):
  1. `AnimationController` built lazily as a `late final` field → crashes on Back
     ("deactivated widget's ancestor"). Create controllers in `initState`.
  2. Async/animation callback firing after navigation → same crash class. Guard with
     `if (mounted)`.
  3. A level generator that isn't guaranteed solvable → unwinnable boards. Generate
     in reverse-solve order and keep the solvability test green.
- **Useful commands:** `/new-game <name>` scaffolds a new game; `/test` runs the
  gates. The pre-commit hook runs `flutter analyze`.
- **Never commit or push automatically** (see *Git* below).

## Commands

Flutter is installed at `C:\dev\flutter` (VS Code only — no Android Studio). On a
fresh terminal `flutter` is on PATH. Android builds need a JDK 17; `JAVA_HOME`
is provided via `.claude/settings.local.json`.

- Run on the emulator: `flutter emulators --launch pixel_api35` then `flutter run`
- Quick desktop check (no emulator): `flutter run -d windows`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Build debug APK: `flutter build apk --debug`

The owner runs the app from VS Code's play button (F5), not the terminal:
`.vscode/launch.json` holds the debug configs (Android debug / Android profile /
pick-device — no desktop config on purpose, this is an Android app) and
`.vscode/tasks.json` wraps analyze / test / gen-l10n. All checked in; keep them in
sync with the command list above. Agents still use `flutter test` /
`flutter analyze` directly and do **not** launch the app (see the top section).

Two things about the launch configs that are easy to get wrong, and were:

- The AVD is pinned with **`emulatorId: pixel_api35`**, not `deviceId`.
  `"deviceId": "android"` reads sensibly but can never match — `deviceId` is
  compared against device ids and names, and a booted AVD is `emulator-5554` /
  `sdk gphone64 x86 64`. `emulatorId` also documents itself as overriding the
  status-bar device, which `deviceId` does not.
- **F5 runs the last-used config, not the first one in the file**, and VS Code
  persists that per workspace. Reordering `launch.json` does not change it; that
  is why F5 kept building a Windows app after Windows was demoted.

`tool/boot_emulator.ps1` still runs as a `preLaunchTask` because the extension
waits only for the emulator to connect, while the script waits for
`sys.boot_completed`. It no-ops in ~0.5s when a device is already attached.

A pre-commit hook (`.githooks/pre-commit`, enabled via `core.hooksPath`) runs
`flutter analyze` before each commit. Bypass with `git commit --no-verify`.

## Structure

- `lib/main.dart` — app entry + global text scaling
- `lib/theme/app_theme.dart` — elderly-friendly theme (large text/targets, calm colors)
- `lib/models/game_definition.dart` — describes one game card
- `lib/games/games_catalog.dart` — the list of games shown on the home screen
- `lib/screens/` — home + coming-soon screens
- `lib/games/<game>/` — one folder per game: `*_models.dart` (logic) + `*_screen.dart` (UI)

## Adding a game

1. Create `lib/games/<game>/` with a `*_models.dart` (pure Dart logic, no Flutter
   imports, so it stays unit-testable) and a `*_screen.dart` (the playable widget).
2. Add a `GameDefinition` with a `builder` to `games_catalog.dart`. Omit `builder`
   to render it as a "coming soon" card.
3. **All UI strings are localized** (English + Norwegian Bokmål). Add every
   user-facing string to *both* `lib/l10n/app_en.arb` and `app_nb.arb`, run
   `flutter gen-l10n`, and use `AppLocalizations.of(context)` — never hardcode
   UI text in widgets. `GameDefinition` titles/subtitles are
   `String Function(AppLocalizations)`.

## Conventions (learned the hard way)

- **Level generators must be guaranteed solvable.** Both arrow games build boards
  in reverse-solve order: place each piece so it has a clear exit given the pieces
  already placed; the reverse of placement order is then a valid solution. Levels
  are seeded by level number → deterministic and retry-stable. Tests assert
  solvability for levels 1–30 (`test/widget_test.dart`).
- **Solvable is not the same as hard, and board size is a poor difficulty proxy.**
  Arrow Maze once capped every knob by level 17, so level 42 was config-identical
  to level 17 and measured as the *easiest* board in the game: 14×20, but ~7.5
  arrows ready to fire at every step, so the player never had to plan. What
  matters is the **branching factor**. `SnakeBoard.generate` now builds several
  seeded candidates, measures each with `measureDifficulty()`, and keeps the one
  closest to `snakeTargetBranchingForLevel`. Tune with
  `dart run tool/analyze_snake_difficulty.dart` — it prints the achievable spread,
  so targets stay inside what the generator can actually produce, and **re-run it
  after any generator change**: improving how bodies fill also made every board
  denser and harder, which put the old easy end of the curve out of reach. Don't
  chase difficulty with a bigger grid: 14×20 is ~23dp per cell on a phone and is
  the legibility floor for this audience.
- **Fill the board by placing bodies well, not by back-filling.** Snake bodies
  grow into the *most constrained* free cell (Warnsdorff-style) so they consume
  dead ends instead of stranding pockets, and heads are placed in the *emptiest*
  neighbourhood first so no region gets walled off — an enclosed void can never
  be filled, because every ray out of it is blocked. Together these took late
  levels from ~72% to ~85% coverage while making them harder. Both back-fill
  approaches were tried and rejected, and `_build` documents why: extra snakes
  placed late are removed *first*, so each is a free opening move (fill bought
  with easiness), and growing existing tails is legal in almost no cell, because
  a snake may only grow where no later-firing snake's exit ray passes.
- **Coverage alone doesn't describe how a board looks** — 86% full read as broken
  when the missing 14% pooled into one corner. `largestEmptyFraction` scores the
  biggest contiguous gap and is weighted heavier than total coverage.
- **Generation only invalidates its lookup tables when a snake is committed.** A
  failed attempt leaves the board untouched, so rebuilding the ray tables and
  candidate list every attempt (most of which fail on a too-short body) cost ~50x
  for identical output. That headroom is what affords a 768-candidate pool, which
  is what lets a board hit difficulty *and* coverage instead of trading them.
  Generating a level takes ~400ms and that is a deliberate choice: it happens once
  per level and nobody notices, whereas a patchy or flat board is obvious.
- **Difficulty and coverage are a priority order, not a weighted blend.** Any board
  within `onTargetTolerance` of the branching target counts as equally correct, and
  coverage decides between them. Scored as one sum, a wide pool spent itself buying
  branching precision from 0.1 to 0.0 — imperceptible — while giving up visible
  coverage. Don't tighten the tolerance either: at 0.1 it rejected perfectly
  playable boards and the fallback was worse on every axis.
- **Create `AnimationController`s in `initState`, never as lazy `late final`
  fields.** A lazy controller can stay unconstructed during normal play and then
  get built inside `dispose()`, which performs a `TickerMode` ancestor lookup on a
  deactivated widget and crashes ("Looking up a deactivated widget's ancestor is
  unsafe").
- **Guard every async / animation callback with `if (mounted) ...`** — animation
  listeners, status listeners, `Future.delayed`, and anything calling `showDialog`
  / `Navigator` after an await.
- **Elderly-friendly UX:** large tap targets, enlarged text (global `textScaler`),
  high contrast, simple flows, generous hit areas (e.g. tapping any cell of a
  snake selects it).

## Git

- This repo's commit identity is the personal account (`leifskje@gmail.com`), set
  locally (global git identity is unchanged).
- Per my standing preference: do **not** commit or push automatically — leave
  commits for me to review at my own pace, and I push manually.
