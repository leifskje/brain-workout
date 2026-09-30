# State of play — handoff

Written to let a fresh agent pick up without re-deriving anything. Read `CLAUDE.md`
first; it holds the conventions and the hard-won lessons. This file is *where things
stand*, not how to work here.

Last published: **1.1.3 (versionCode 6)**, internal track, Sep 2026. `main` is that
release; the next one needs another `version:` bump. Arrow Pictures is not in
any release yet.

Check what testers actually have with `python tool/play_track_status.py` rather than
reading `pubspec.yaml` — that file describes the *next* build, and a versionCode in
git is no evidence it was uploaded.

## What to do first (written 29 Sep, for 30 Sep)

**Arrow Pictures** — a new game, built in one day on branch
`les/picture-boards`. Everything since the 28 Sep handoff commit is
**uncommitted**: the owner reviews and commits. Gates were green at hand-over
(`flutter analyze` clean, `flutter test` 181 passing). Nothing is pushed, nothing
near `main`, nothing released.

1. **Grow the picture list from 102 to at least 200** before any release — the
   owner's ask for tomorrow. The how, including tier sizes, the silhouette rule,
   coverage checks and the agent process that worked, is the *Adding pictures —
   the recipe* section of [picture-boards.md](picture-boards.md); its *Next*
   list has the rest (pin the list, mirrored replays, heart/diamond/star,
   Norwegian names check).
2. **Fix F5 wiping the emulator's app data** (see *Dev environment* below) —
   it cost several rounds today and will cost more during picture testing.
3. Then back to the ranked list: difficulty choice is next.

## Arrow Pictures — what exists (29 Sep)

- Every board a picture; its own card on the home screen ("Arrow Pictures" /
  "Pilbilder"), progress id `arrow_pictures`.
- **Levels 1–39 use short arrows** (Arrow Escape's screen), **40+ use long
  arrows** (Arrow Maze's screen); both screens now take a spec
  (`ArrowGameSpec`, `SnakeGameSpec`) and `ArrowPicturesScreen` picks one per
  level, swapping screens when "Next level" crosses the boundary.
- **Colour only on the finished picture**: during play long-arrow levels show a
  faint grey outline, short ones nothing; the last arrow fades the picture in
  (15-colour palette), then the win dialog names it ("It was a seahorse!" /
  "Det var en sjøhest!").
- Boards prefetched in a background isolate, one cache per arrow kind;
  `BoardPrefetch<B>` is generic now (Arrow Maze uses `arrowMazePrefetch`).
- Past level 102 the game cycles the long-arrow pictures with new boards — it
  used to restart at the 42-arrow key.
- Arrow Escape is back to full boards only; the 55/65/75 picture levels never
  shipped.
- Tools: `dart run tool/analyze_arrow_pictures.dart` (per-level coverage,
  branching, ms), `tool/dump_arrow_shape.dart`, `tool/dump_snake_shape.dart`.
- The owner checked on the emulator and signed off on how they look. The one
  lesson to carry: **a picture must read from its silhouette alone** — colour is
  hidden during play.

## Dev environment — open problems

- **F5 reinstalls the app from scratch**, wiping the emulator's app data (every
  game back to level 1). `dumpsys package` showed `firstInstallTime` = the F5
  time each time. `flutter run` only uninstalls when `adb install -r` fails, so
  something makes the in-place update fail. Next step: have the owner paste the
  Debug Console's first lines from an F5 ("Uninstalling old version…" /
  `INSTALL_FAILED_…`). Workaround today: after F5, `pwsh -File
  tool/set_level.ps1 -Level 103 -Game arrow_pictures`, then open the app from its
  icon.
- **A cold F5 starts the emulator twice**: the `Boot Android emulator`
  preLaunchTask boots `pixel_api35`, then the extension's `emulatorId` tries
  too, and the second exits with code 1 ("device 'emulator-5554' not found").
  Harmless once the first is up. Fix: drop one of the two starters in
  `.vscode/launch.json` / `tool/boot_emulator.ps1` (owner agreed in principle,
  not done).
- **Force-killing the emulator corrupts the quick-boot snapshot** → black app
  screen. `pwsh -File tool/boot_emulator.ps1 -Cold` fixes it. The emulator also
  crashed once on its own today; stale `multiinstance.lock` files and a second
  adb server were found and cleared.
- **Hot reload after adding an `AnimationController` in `initState`** throws on
  the running screen (initState does not re-run). Full restart instead.
- `set_level.ps1` must run while the app is *not* starting up — the app writes
  prefs from memory and will overwrite the change (seen once today).

## Shipped in 1.1.3 (Sep 2026)

Three fixes, all test-verified, and the owner checked them on the emulator:

- **Word Search hints.** Two stacked defects: the candidate filter keyed hinted
  *cells* rather than hinted *words*, so a word sharing a start cell with another
  could never be hinted (en level 26 has WEAVER and WOMAN both at (5,10) — the
  reported case); and `found` outranked `hinted` in the cell colouring, so a hint
  landing inside an already-found word was invisible. That second one was silently
  eating hints across en levels 20–40 and their nb equivalents.
- **Arrow Maze prefetch.** Warming moved from the win dialog (~1.1s) to the level
  load, and boards now persist across restarts. Generation is a median of 359ms but
  a p90 of 1290ms over levels 40–70, so the old budget was missed on a large
  minority of levels — and because cost is deterministic per level yet uneven
  between levels, it read to the player as random hangs.
- **Arrow Escape density.** Every level from 41 up was config-identical and level
  100 measured *easier* than level 20. New dense generator; level 100 goes branching
  11.3 → 3.4, fill 45% → 100%. Levels 1–40 frozen and pinned by fingerprint.

**Read the CLAUDE.md bullet on what those metrics could not see before touching
Arrow Escape difficulty again.** Filling the boards was the largest measured
difficulty change ever made in that game and the owner felt nothing, because the
game is monotone: any legal move is always correct, so density buys *harder to see*
and never *harder to work out*.

## Open work, ranked

1. **Arrow Pictures to ≥ 200 pictures**, then pin the list — see *What to do
   first* and [picture-boards.md](picture-boards.md). Before shipping it also
   needs a `version:` bump and probably the store listing/screenshots updated
   for a new game (ask; `publishListing` writes to the live account).
2. **Difficulty choice**, starting with the Word Search assist —
   [difficulty-choice.md](difficulty-choice.md).
3. **Odd One Out** ([odd-one-out.md](odd-one-out.md)) — the new game with a plan
   written. The hard part is proving exactly one item is isolated; a set built to
   isolate one item on colour can accidentally isolate another on size, and two
   defensible answers is worse than too hard.
4. **Sound + Simon's extra buttons**, as one piece. The stated blocker is "needs
   real audio assets", which is softer than it reads: the four tones are sine waves
   and can be generated by a script — no sourcing, no licence. The genuinely large
   part is that sound is *app-wide* infrastructure (mute toggle, silent-mode
   behaviour, which other games use it), so it belongs with new content, not in a
   patch. Keep it bundled with the extra buttons: a 5th colour without tones makes
   Simon harder purely on colour discrimination, the wrong axis for this audience.
5. **The next four plateaus.** `dart run tool/analyze_level_curves.dart` — Memory
   Match flattens at 13, Mini Sudoku 16, What Comes Next 17, 2048 at 18. The owner
   says Memory Match and Mini Sudoku do not *feel* easy, and he is right: a plateau
   means "stops changing", not "is easy". Lower priority than it looks, but he is a
   heavy player and will reach them. Mini Sudoku's remaining axis is not board size
   (9x9 is the ceiling, 58 of 81 blanks already) — it is which *solving technique* a
   puzzle requires, the same trick Picture Logic uses.
6. **Re-tune Arrow Maze branching targets.** The generator reaches lower branching
   than the targets ask for, so the curve is not using the difficulty available.
   `dart run tool/analyze_snake_difficulty.dart`, targets inside the printed spread.
7. **Profile the generation cost cliff.** Cost per candidate jumps ~40× between an
   840-cell and a 988-cell board. An inferred fix (hoisting the per-attempt head
   scan) made it *slower* and was reverted — use the DevTools CPU profiler on
   `SnakeBoard.generate(60)` vs `generate(43)` rather than reasoning about it.
8. **Eagle eye** — reward spotting a hard-to-see legal move. Never built; needs a
   non-arbitrary definition of "hard to spot".

## Closed since the last handoff

- *Every tenth level a picture, or every board?* — neither: a separate game,
  every board a picture (owner, 29 Sep). Both arrow kinds in one game, short on
  the small pictures, long on the big ones.
- *Warm the level picker* — done. `BoardPrefetch` now persists boards and warms
  during play. A picker jump to a never-warmed level still generates inline, but
  warms and stores itself on arrival, so a second visit is instant.
- *Longest dependency chain as a difficulty axis* — measured
  (`ArrowBoard.longestBlockingChain`, printed by the Arrow Escape analyzer). The
  result is a **warning, not a knob** — see the monotonicity bullet in `CLAUDE.md`.

## Blocked, not forgotten

- **Compound Words** ⛔ — the shipped word lists cannot support it: full-form and
  capped at 8 letters, leaving 9 usable bridge words in Norwegian. Needs an uncapped
  *lemma* list re-derived from Ordbank, or a hand-authored bank. Numbers in
  [compound-words.md](compound-words.md).
- **Norwegian offensive-word filter** — pre-existing gap affecting every `nb` word
  game. A native speaker has to write it; guessing at one is worse than not having it.

## Refused, with reasons — do not quietly build these

- **Ad-gated continues.** Described by the mother as something she enjoys in another
  game. The one-heart tension is worth taking; the advert is not. Nothing in this app
  sends data anywhere — a property [backlog.md](backlog.md) protects against even a
  crash SDK — and an ad SDK is a tracking SDK.
- **A "top 5% quickest" leaderboard.** Needs a server and therefore everyone's times
  leaving their phone. The local substitute is in
  [difficulty-choice.md](difficulty-choice.md).

## Licence hazard — read before looking at prior art

[robmat/arrows_game](https://github.com/robmat/arrows_game) ("Skein") is an Android
game with the same snake/arrow mechanic as Arrow Maze, generated with a
frontier-based algorithm, and it already ships shaped boards derived from image
pixel data. It is the most relevant thing that exists — and it is **GPL-3.0**.

Brain Workout ships closed on Play. Copying GPL-3 code into it, in any amount,
would oblige us to release the whole app under GPL-3. Ideas are not copyrightable
and reading for understanding is fine, but do not lift lines, and do not let a
"just check how they did it" turn into a paste. Our generator already solves this
in a single forward pass; there is nothing there we need. Details in
[picture-boards.md](picture-boards.md).

[crudeGithub/Arrow-Escape-Game-Source-Code](https://github.com/crudeGithub/Arrow-Escape-Game-Source-Code)
is MIT and therefore safe, but it is Unity/C# with hand-authored levels and no
shaped boards — nothing to take.

## Unverified on a device

Passes tests but has never run on real hardware. Widget tests and board dumps are the
agent's only channels (see `CLAUDE.md`), so these need the owner:

- **Arrow Pictures, 39 → 40**: the swap from short to long arrows mid-game has
  not been played through deliberately; worth one pass for how it feels.
- **Arrow Pictures on a real phone**: huge boards (44 wide, ~8dp cells at fit)
  and ~2s board generation after a level-picker jump have only been seen on the
  emulator.
- The **feedback button** — `mailto:` is an intent like any other, so a device with no
  mail app falls back to the clipboard. Both paths need trying once.
- The **in-app update prompt**. It shipped in 1.1.2, so 1.1.3 is the first build that
  can actually trigger it — but only for testers already on 1.1.2. Anyone older must
  update by hand once: Play Store → search the app → **Update**.
- The **share sheet** after a *full rebuild* — `share_plus` is a native plugin and
  registration is generated at build time, so a hot reload after `pub add` throws
  `MissingPluginException`. There is a clipboard fallback either way.
- **24-column Arrow Maze legibility at fit-to-screen** (~15dp per cell) before zooming.
- **Bonus cascade pacing** — up to four arrows at ≤820ms each, so ~2–3s.

## Testing on a device

`pwsh -File tool/set_level.ps1 -Level 100 [-Game arrow_escape]` unlocks levels on an
attached debug build, because the level picker only shows up to
`highest_level_<game>` and the emulator's progress is near zero exactly when a late
board is what needs looking at. `-Show` lists what is unlocked. It only ever touches
`highest_level_*`.

It **refuses to lower** a level without `-Force`, and that guard exists because an
earlier version knocked a real playthrough from 101 back to 75. Lowering is never
what you want anyway: the picker shows *every* level up to the highest, so an
earlier level is already reachable without touching anything.

## Releasing

Read the release section of `CLAUDE.md` and [play-store.md](play-store.md) before
touching anything. The short version:

- Releases only ever happen from `main`, and only when the owner explicitly asks.
- `gradlew publishBundle` goes **straight to real internal testers** —
  `releaseStatus` is `COMPLETED`, so there is no draft to approve. Treat it like
  `git push --force`.
- Bump `version:` in `pubspec.yaml` first; Play rejects a repeated `versionCode`.
- Publishing is the Gradle Play Publisher plugin; there is no MCP or API integration.
  `tool/play_track_status.py` and `tool/play_listing_status.py` are safe read-only looks.
- Production is gated behind 12 closed testers for 14 consecutive days; internal
  testing does not count toward it.
