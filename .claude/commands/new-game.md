# Scaffold a new mini-game

Create a new brain-training game end-to-end, following this repo's structure and
conventions (see [CLAUDE.md](../../CLAUDE.md)).

Arguments: `$ARGUMENTS` — the game name. Accept a human title ("Number Match") or a
snake_case id ("number_match"); derive both. The folder/id is snake_case; the
display title is Title Case.

## Steps

1. **Derive names.** `id` = snake_case (e.g. `number_match`), `Title` = Title Case
   (e.g. `Number Match`), `ClassPrefix` = PascalCase (e.g. `NumberMatch`).

2. **Create `lib/games/<id>/<id>_models.dart`** — pure Dart logic, **no Flutter
   imports** (so it stays unit-testable):
   - The game's data model + rules.
   - A `configFor Level(int level)` returning per-level difficulty.
   - A deterministic, **seeded** generator (`Random(level * <prime> + <salt>)`) so a
     level is identical on every retry.
   - If the game has a "solved by clearing pieces in some order" shape, generate in
     **reverse-solve order** so solvability is guaranteed (see the arrow games).

3. **Create `lib/games/<id>/<id>_screen.dart`** — the playable `StatefulWidget`:
   - **Create any `AnimationController` in `initState`**, never as a lazy
     `late final` field (a lazy controller can be first built inside `dispose()`
     and crash on a `TickerMode` ancestor lookup).
   - **Guard every async / animation callback with `if (mounted) ...`** — listeners,
     status listeners, `Future.delayed`, and anything calling `showDialog`/`Navigator`
     after an await.
   - Header with Back + `Level N` + restart; hearts row; win/lose dialogs ("Next
     level" / "Try again" / "Home"), matching the existing games.
   - **Elderly-friendly UX:** large tap targets, high contrast, generous hit areas.

4. **Register it** in [lib/games/games_catalog.dart](../../lib/games/games_catalog.dart):
   add a `GameDefinition` with `id`, `title`, a one-line `subtitle`, an `icon`, a
   distinct `color`, and `builder: (_) => const <ClassPrefix>Screen()`.

5. **Add a test** in [test/widget_test.dart](../../test/widget_test.dart): assert the
   home screen shows the new `title`, and — if the generator is solvability-based —
   add a "levels 1–30 are solvable" test mirroring the arrow-game tests.

6. **Verify:** run `/test` (analyze + tests). Both must be clean.

## Rules

- Match the look/flow of the existing games so the app feels unified.
- Keep logic in `*_models.dart` and UI in `*_screen.dart`.
- Do not commit — per the user's policy, leave commits for them to review.
- Report the files created + the catalog entry, then tell the user to hot-restart.
