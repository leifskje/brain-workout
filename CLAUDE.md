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
- **Picture Logic is the exception to reverse-solve generation: it *proves*
  solvability with a solver.** Clues are derived from a filled grid, so whether
  they are deducible is emergent and cannot be constructed. `solveNonogram`
  applies one rule — a cell that can be filled but cannot be empty is forced —
  to every row and column until nothing changes. If that completes the grid the
  puzzle needs no guessing *and* its solution is unique, because every step was
  forced, so uniqueness costs nothing extra. Candidates it can't finish are
  thrown away. Don't try to reverse-solve it. The uniqueness claim is checked
  against an independent exhaustive counter in the tests rather than assumed.
- **A knob you assume is a tradeoff might be free — measure before designing
  around it.** The nonogram clue-gutter cap was planned as a
  difficulty-vs-legibility tradeoff. Caps of 4, 5, 6 and 7 turn out to admit an
  identical candidate pool with identical branching, because a symmetric blob
  almost never puts five runs in a line. The narrow gutter was free, which is
  what lets a 12-wide grid fit a phone. Conversely, density there runs *opposite*
  to intuition — branching peaks near 0.38 and falls above it, so the first
  version's rising density curve was quietly making late levels easier.
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
- **A motion that carries information must opt out of "reduce animations."** A
  tester reported that Arrow Maze "should have an animation when you click the
  arrows", for one that had been there all along. The cause is not the device and
  not the frame rate: with the platform's reduce-animations setting on, an
  `AnimationController` with the default `AnimationBehavior.normal` runs at **5%
  of its duration** — the framework's own comment is that this limits it "to a
  single frame". 520ms becomes 26ms, i.e. nothing. Pass
  `animationBehavior: AnimationBehavior.preserve` wherever the movement *is* the
  feedback (which arrow left, and in which direction), and leave the default on
  decorative motion whose end state is visible anyway — a Wordle tile colour, a
  Simon flash, a card flip. Those are what the setting is for.
  - **Implicit animations cannot be told this.** `ImplicitlyAnimatedWidgetState`
    builds its controller without an `animationBehavior`, so `AnimatedPositioned`,
    `AnimatedOpacity`, `AnimatedContainer` and `TweenAnimationBuilder` all
    collapse and there is no parameter to stop them. That is why Arrow Escape's
    pieces are driven by an explicit controller in `_PieceView` instead — its
    arrow teleported off the board while the win dialog still waited a full
    `_moveDuration`, which is worse than a missing animation.
  - Both cases are covered by tests that set `debugSemanticsDisableAnimations` and
    assert the controller is still ticking 120ms in. Verify such a test by
    breaking the fix and watching it fail: the first version asserted on a
    locally generated `SnakeBoard`, not the screen's, so it passed either way.
- **Animate at a fixed *speed*, not a fixed duration, whenever the distance
  depends on the screen.** Separate from the above, and a smaller effect: both
  arrow games slid a piece a distance derived from cell size — which scales with
  the device — over a hard-coded duration, so the *speed* varied, around
  ~1850 dp/s on a large phone. `lib/theme/motion.dart` holds
  `slideDuration(distanceDp)`; clamped so small boards aren't twitchy and big ones
  aren't slow. This is *not* a refresh-rate issue either — Flutter animates from
  wall-clock time, so a 120Hz screen renders the same animation more smoothly,
  never faster. Frame rate was never the variable.
- **A modal bottom sheet needs `isScrollControlled` *and* a real constraint on
  the route.** Picture Logic's Norwegian help text overflowed the how-to-play
  sheet by 38px on a device: without `isScrollControlled` a sheet is capped at
  9/16 of the screen and simply overflows. Pass the cap via
  `showModalBottomSheet(constraints:)` measured from the *calling* context, put
  only the body in a `SingleChildScrollView`, and leave the dismiss button
  outside it — for this audience an unreachable "Got it!" is worse than clipped
  text. Note the nastier half: if the content ends up laid out *unbounded*,
  `Flexible` never shrinks, the button lands below the fold, and **no overflow
  error is reported at all**. Assert `finder.hitTestable()`, not just
  `findsOneWidget`, or the test will pass on a silently unreachable button.
- **Never set text scale in a test with `MediaQuery(data: MediaQueryData(textScaler: …))`.**
  That constructor replaces *all* of `MediaQueryData`, so `size` becomes
  `Size.zero` and the widget under test is laid out on a zero-height screen —
  the assertions still run, they just aren't testing a phone. Use
  `tester.platformDispatcher.textScaleFactorTestValue` (with a
  `clearTextScaleFactorTestValue` tear-down). The home-screen text-scale test
  carried this flaw for a while and read as protective while measuring nothing;
  an ancestor `MediaQuery` does override the one `MaterialApp` installs, so the
  scale took effect while the size silently did not.
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

### Branching — `main` is the release branch

Since the app is on the Play Store, `main` is what ships. Nothing lands on it
directly any more.

- **Every fix and feature goes on a branch**, named `les/<short-topic>` (or
  `les/<issue>/<short-topic>` once there are tickets) — `les` is the standing
  prefix across all my repos.
- **Merge to `main` via pull request.** Agents create and push the branch; they do
  **not** open the PR — I do that, same standing rule as commits and pushes.
- The pre-commit hook runs `flutter analyze` on every commit regardless of branch,
  so a branch is no excuse for a red tree. `/test` should be green before the PR.
- **Releases only ever happen from `main`**, and only when I ask — see the release
  section above. A branch is never published.
- `gh` on this machine holds two accounts; the work one (`LoffenHent`) is active by
  default. Use `gh auth switch --user leifskje` before any `gh` work on this repo,
  or the PR is attributed to the wrong identity.

## Releasing to Google Play — never without being asked

**`gradlew publishBundle` ships to real testers immediately.** `releaseStatus` is
`COMPLETED`, so there is no draft to approve in the Console: the build goes
straight out. Treat it like `git push --force` — only ever on an explicit request
for a release, never as the natural end of a piece of work, and never to "verify"
something.

What is always fine: `flutter build appbundle --release`, `tool/build_release.ps1`,
and `tool/play_listing_status.py` (which opens a draft edit, reads, and discards).

What needs asking first: `publishBundle`, `publishListing`,
`ensure_play_listings.py` — all three write to the live Play account.

Never run `bootstrapListing`: it deletes the local listing under
`android/app/src/main/play/`. See [play-store.md](docs/plans/play-store.md).

Bump `version:` in `pubspec.yaml` before any upload — Play rejects a repeated
`+N` versionCode. And note the Play *release name* is a free-text label, not the
app's version; don't infer what a build contains from it.
