# State of play — handoff

Written to let a fresh agent pick up without re-deriving anything. Read `CLAUDE.md`
first; it holds the conventions and the hard-won lessons. This file is *where things
stand*, not how to work here.

Last published: **1.2.0 (versionCode 7)**, internal track, 30 Sep 2026: Arrow
Pictures (215 pictures), the grouped home screen, the Larger text setting, and
a refreshed store listing (published with it). `main` is that release (PR #2);
the next upload needs another `version:` bump.

Check what testers actually have with `python tool/play_track_status.py` rather than
reading `pubspec.yaml` — that file describes the *next* build, and a versionCode in
git is no evidence it was uploaded.

## What to do first (written 1 Oct)

**Branch `les/picture-zoom`, uncommitted:** an Arrow Pictures zoom fix the owner
reported. The owner checked both halves on the emulator (2 Oct). Left: commit,
PR, and maybe a 1.2.1.

- **Zoom was confined to the picture's own box,** so a short, wide picture (fish
  skeleton, level 17) zoomed inside a thin strip and arrows got *harder* to hit.
  The viewer's child is now the whole board area with the board centred in it,
  in both `arrow_escape_screen.dart` and `snake_arrows_screen.dart`. The boards
  themselves are unchanged (padding the masks would change every board players
  have progress on).
- **Finishing while zoomed in revealed only part of the picture.** It now resets
  to fit before the reveal. The reset is instant; animate it if it feels abrupt.
- Tests: three new ones in `test/arrow_pictures_test.dart`, two of them checked
  by breaking the fix. Gates were green at hand-over: `flutter analyze` clean,
  `flutter test` 189 passing.

Then, in order:

1. **Owner spot-check of the new pictures** (still open from 30 Sep). First free
   the emulator's disk (see *Dev environment*), or F5 wipes progress again. The
   *Next* list of [picture-boards.md](picture-boards.md) has the weakest pictures
   and the short-arrow boundary question (now level 101). The Norwegian picture
   names were fixed 30 Sep; the owner may still want a look at "en spar" and
   "en kløver".
2. **Difficulty choice** ([difficulty-choice.md](difficulty-choice.md)): more
   pressing now that the audience is broad (see `CLAUDE.md`).
3. **New games** in the build order of [new-games.md](new-games.md). Challenge
   modes are thoughts, not decisions ([challenge-modes.md](challenge-modes.md)).

Store screenshots are generated, not captured: `flutter test
tool/store_screens/render_test.dart`, then `python tool/frame_screenshots.py`,
then `python tool/sync_play_listing.py`. Re-run after visible UI changes; see
[store-listing.md](store-listing.md).

## Arrow Pictures — what exists (29 Sep)

- Every board a picture; its own card on the home screen ("Arrow Pictures" /
  "Pilbilder"), progress id `arrow_pictures`.
- **Levels 1–101 use short arrows** (Arrow Escape's screen), **102+ use long
  arrows** (Arrow Maze's screen) — the boundary was 39/40 until 30 Sep; both screens now take a spec
  (`ArrowGameSpec`, `SnakeGameSpec`) and `ArrowPicturesScreen` picks one per
  level, swapping screens when "Next level" crosses the boundary.
- **Colour only on the finished picture**: during play long-arrow levels show a
  faint grey outline, short ones nothing; the last arrow fades the picture in
  (15-colour palette), then the win dialog names it ("It was a seahorse!" /
  "Det var en sjøhest!").
- Boards prefetched in a background isolate, one cache per arrow kind;
  `BoardPrefetch<B>` is generic now (Arrow Maze uses `arrowMazePrefetch`).
- Past level 215 the game cycles the long-arrow pictures with new boards,
  mirrored on alternate laps — it used to restart at the 42-arrow key.
- Arrow Escape is back to full boards only; the 55/65/75 picture levels never
  shipped.
- Tools: `dart run tool/analyze_arrow_pictures.dart` (per-level coverage,
  branching, ms), `tool/dump_arrow_shape.dart`, `tool/dump_snake_shape.dart`.
- The owner checked on the emulator and signed off on how they look. The one
  lesson to carry: **a picture must read from its silhouette alone** — colour is
  hidden during play.

## Dev environment — open problems

- **F5 reinstalls the app from scratch — cause found (30 Sep), fix is the
  owner's.** The emulator's 6 GB `/data` is full (433 MB free): Play has
  auto-updated 23 system apps into it. `adb install -r` of the ~200 MB debug APK
  fails with "Requested internal only, but not enough space", so `flutter run`
  uninstalls and reinstalls. An agent's attempt to revert those updates was
  blocked by the permission classifier (it deletes AVD data), so either:
  `adb shell pm uninstall-system-updates <pkg>` for the big unneeded apps
  (Chrome, YouTube, Maps, Photos…), or **Wipe Data** in Device Manager —
  `disk.dataPartition.size` is already raised to 16 GB in the AVD's
  `config.ini` (backup `config.ini.bak-20260930`), which only takes effect on a
  wipe. Afterwards `tool/set_level.ps1 -Level 103 -Game arrow_pictures`.
- **A cold F5 started the emulator twice — fixed (30 Sep).** `launch.json` now
  pins `deviceId: emulator-5554` and the preLaunchTask is the only starter.
  Not yet tried from a cold F5 by the owner.
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

1. **Arrow Pictures:** shipped in 1.2.0. Left: the zoom fix on `les/picture-zoom`,
   and the owner's spot-check. See *What to do first* and
   [picture-boards.md](picture-boards.md).
2. **Difficulty choice**, starting with the Word Search assist —
   [difficulty-choice.md](difficulty-choice.md).
3. **New games**, in the build order in [new-games.md](new-games.md): letter
   hive, chess puzzles, FreeCell, Bridges, Sokoban, word ladder, Odd One Out,
   Mahjong solitaire, cryptogram, Minesweeper. For Odd One Out
   ([odd-one-out.md](odd-one-out.md)), the plan was written earlier. The hard part is proving exactly one item is isolated; a set built to
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

- **Arrow Pictures, 101 → 102**: the swap from short to long arrows mid-game has
  not been played through deliberately; worth one pass for how it feels.
- **Arrow Pictures' 113 new pictures** (30 Sep) — audited blind by agents only.
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
