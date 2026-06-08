# Brain Workout — project guide

A Flutter app of small "brain training" mini-games aimed at elderly users (built
with my mother in mind). A home screen lists selectable games; each game is
self-contained. Cross-platform Flutter, primary target Android.

## Working in this repo (for AI agents)

- **Verify, don't claim.** "Done" means `/test` (or `flutter analyze` + `flutter
  test`) is green — quote the result, don't assert it. For anything visual, it also
  means it was actually run/seen, not just compiled.
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

## Conventions (learned the hard way)

- **Level generators must be guaranteed solvable.** Both arrow games build boards
  in reverse-solve order: place each piece so it has a clear exit given the pieces
  already placed; the reverse of placement order is then a valid solution. Levels
  are seeded by level number → deterministic and retry-stable. Tests assert
  solvability for levels 1–30 (`test/widget_test.dart`).
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
