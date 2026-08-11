# State of play — handoff

Written to let a fresh agent pick up without re-deriving anything. Read `CLAUDE.md`
first; it holds the conventions and the hard-won lessons. This file is *where things
stand*, not how to work here.

Last updated after the Arrow Maze depth work (Aug 2026).

## Where the code is

`main` is the release branch and holds 15 games. Everything below is merged unless a
branch is named.

**Merged and live-ready:** Picture Logic (nonogram, game 15) · word of the day with
sharing · save & resume across six games · local personal bests · five un-capped
difficulty curves · Memory Match 15→21 pairs · the how-to-play sheet overflow fix ·
the daily-word share reachability fix.

## Open work, ranked

1. **Re-tune Arrow Maze branching targets.** The generator now reaches *lower*
   branching than the targets ask for, so the curve is not using the difficulty
   available. Cheapest real win left. Tune with
   `dart run tool/analyze_snake_difficulty.dart` and keep targets inside the printed
   spread — see the warnings in [arrow-maze-depth.md](arrow-maze-depth.md).
2. **Warm the level picker.** `BoardPrefetch` covers only sequential play (win → next
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

- The **share sheet** after a *full rebuild* — `share_plus` is a native plugin and
  registration is generated at build time, so a hot reload after `pub add` throws
  `MissingPluginException`. There is a clipboard fallback either way.
- **24-column legibility at fit-to-screen** (~15dp per cell) before zooming.
- **Bonus cascade pacing** — up to four arrows at ≤820ms each, so ~2–3s.

## Feedback from testers — not built, and worth thinking about

Testers are non-developers. GitHub issues are too high a barrier: an account, a repo, a
form written for programmers. Options, cheapest first:

1. **In-app "Send feedback" that opens a pre-filled email** — `mailto:` with the app
   version, level, device and locale already in the body, so a one-line reply is still
   useful. No dependency beyond `url_launcher`, which is already present transitively.
2. **A Google Form** opened in a browser. Slightly more friction, but replies land in a
   sheet rather than an inbox, and it survives a tester who cannot compose email.
3. **Play Console tester feedback** — free and already there, but only reachable through
   the Play Store listing and easy for a tester to never find.

Recommendation: (1) plus a note in the how-to-play sheet. Deliberately *not* an
in-app crash/analytics SDK — nothing about this app sends data anywhere, and that is a
deliberate property, not an oversight (see the personal-bests note in `CLAUDE.md`).

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
