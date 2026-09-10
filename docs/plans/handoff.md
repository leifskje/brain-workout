# State of play — handoff

Written to let a fresh agent pick up without re-deriving anything. Read `CLAUDE.md`
first; it holds the conventions and the hard-won lessons. This file is *where things
stand*, not how to work here.

Last published: **1.1.2 (versionCode 5)**, internal track, Sep 2026. `main` is
that release; the next one needs another `version:` bump.

Check what testers actually have with `python tool/play_track_status.py` rather
than reading `pubspec.yaml` — that file describes the *next* build, and a
versionCode in git is no evidence it was uploaded.

## Where the code is

`main` is the release branch and holds 15 games. Everything below is merged unless a
branch is named.

**Merged and live-ready:** Picture Logic (nonogram, game 15) · word of the day with
sharing · save & resume across six games · local personal bests · five un-capped
difficulty curves · Memory Match 15→21 pairs · the how-to-play sheet overflow fix ·
the daily-word share reachability fix.

**Shipped in 1.1.2**, and only partly seen on a device — the owner checked the stats
screen and played Arrow Maze to level 50; the rest is test-verified only: the colour
pattern fix · progress repair · Arrow Escape 14x14 + zoom · the golden arrow mid-board ·
Memory Match triples · Number Cross division · Simon's steeper curve · level times in six
games · the stats and settings screens · the Arrow Maze spinner and retry-tap guard.

**Shipped in 1.1.1:** the level-progression fix (clearing a level
now unlocks the next one whichever button you press — it previously only counted if you
pressed "Next level", in all thirteen level games) · Crack the Code clue counts · the
Memory Match picture-pool fix · What Comes Next visual-pattern tiers · the tester feedback button ·
the in-app update prompt · hints in the three word games. All of these came out of the
owner playing the app, not from tests — which is the argument for the feedback channel
in one line.

## Open work, ranked

0. **Chase the 1.1.1 feedback.** Testers must update *by hand* this once — the in-app
   prompt shipped in 1.1.1 and so cannot fire until 1.1.2. Tell them: Play Store → search
   the app → **Update**. The two questions worth asking are whether levels now advance,
   and whether the Send feedback button reaches an inbox at all — that button is the
   first thing in this app whose only real test is a person using it.
1. **Re-tune Arrow Maze branching targets.** The generator now reaches *lower*
   branching than the targets ask for, so the curve is not using the difficulty
   available. Cheapest real win left. Tune with
   `dart run tool/analyze_snake_difficulty.dart` and keep targets inside the printed
   spread — see the warnings in [arrow-maze-depth.md](arrow-maze-depth.md).
2. **Warm the level picker.** *Partly mitigated:* entering a level now shows
   "Setting up the next board…" instead of freezing, because `_loadLevel` routes
   through `BoardPrefetch.obtain` and yields a frame before generating. The work
   still happens on the UI isolate, so the pause is real — it just no longer
   reads as a hang. Actually prefetching for the picker is still open. `BoardPrefetch` covers only sequential play (win → next
   level). Entering from the picker, or the first level, still generates inline, so a
   slow board is felt there. **This is the gate on raising the Arrow Maze cap past 24
   columns.**
3. **Profile the generation cost cliff.** Cost per candidate jumps ~40× between an
   840-cell and a 988-cell board. An inferred fix (hoisting the per-attempt head scan)
   made it *slower* and was reverted — use the DevTools CPU profiler on
   `SnakeBoard.generate(60)` vs `generate(43)` rather than reasoning about it.
4. **Longest dependency chain as a difficulty axis.** Borrowed from the Rush Hour
   heuristic literature: the blocking relation is a DAG and its longest chain is the
   forced-move spine. Mean branching cannot distinguish a long spine from many short
   chains, and the spine is what feels hard.
5. **Eagle eye** — reward spotting a hard-to-see legal move. Never built; needs a
   non-arbitrary definition of "hard to spot".
6. **Memory Match triples.** 21 pairs is the structural ceiling (all layouts are 6
   columns, so card size is width-bound at ~45dp). Matching three of a kind is the next
   axis and is a mechanic change.
7. **Number Cross division** — the last untried knob; blanks and decoys are spent.

## Blocked, not forgotten

- **Compound Words** ⛔ — the shipped word lists cannot support it: full-form and
  capped at 8 letters, leaving 9 usable bridge words in Norwegian. Needs an uncapped
  *lemma* list re-derived from Ordbank, or a hand-authored bank. Numbers in
  [compound-words.md](compound-words.md).
- **Norwegian offensive-word filter** — pre-existing gap affecting every `nb` word
  game. A native speaker has to write it; guessing at one is worse than not having it.

## Unverified on a device

Everything below passes tests but has never run on real hardware. Widget tests and
board dumps are the agent's only channels here (see `CLAUDE.md`), so these need the
owner:

- The **feedback button** — `mailto:` is an intent like any other, so a device with no
  mail app falls back to the clipboard. Both paths need trying once.
- The **in-app update prompt**, which by construction cannot fire until a build *after*
  1.1.1 is on the internal track. Until then testers must update by hand.
- **Hint legibility** — the amber hinted cell in Word Search against the pink accent, and
  whether the lightbulb reads as "help" to a non-gamer.
- The **share sheet** after a *full rebuild* — `share_plus` is a native plugin and
  registration is generated at build time, so a hot reload after `pub add` throws
  `MissingPluginException`. There is a clipboard fallback either way.
- **24-column legibility at fit-to-screen** (~15dp per cell) before zooming.
- **Bonus cascade pacing** — up to four arrows at ≤820ms each, so ~2–3s.

## Feedback from testers — built, not yet proven

Shipped as option (1) below: an in-app **Send feedback** button on the home screen opening
a pre-filled `mailto:` with app version, locale and OS already in the body, plus a
clipboard fallback when no mail app answers. The home screen also now *shows the running
version*, which it never did — before this a report could not be tied to a build at all.

Deliberately **not** an in-app crash/analytics SDK: nothing about this app sends data
anywhere, and that is a property worth keeping, not an oversight (see the personal-bests
note in `CLAUDE.md`). A test asserts the mail body carries no identifiers.

Still open:

- **Which inbox.** `feedbackEmail` in `lib/services/app_info.dart` is the author's personal
  gmail. A Google Form is the alternative if replies should land in a sheet instead.
- **Whether testers find it.** The button is in the quiet footer under the games. If
  nothing arrives, the next cheapest step is a line in the how-to-play sheet.

## Releasing

Read the release section of `CLAUDE.md` and [play-store.md](play-store.md) before
touching anything. The short version:

- Releases only ever happen from `main`, and only when the owner explicitly asks.
- `gradlew publishBundle` goes **straight to real internal testers** —
  `releaseStatus` is `COMPLETED`, so there is no draft to approve. Treat it like
  `git push --force`.
- Bump `version:` in `pubspec.yaml` first; Play rejects a repeated `versionCode`.
- There is **no MCP or API integration** for the Play Console. Publishing is the
  Gradle Play Publisher plugin (`gradlew publishBundle`), with
  `tool/play_listing_status.py` for a safe read-only look.
- Production is gated behind 12 closed testers for 14 consecutive days; internal
  testing does not count toward it.
