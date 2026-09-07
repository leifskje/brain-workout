# Game & feature backlog

Status: ✅ shipped · 🔨 in progress · 📝 planned · 💡 idea · ⛔ blocked

## Games by cognitive domain

We deliberately spread games across domains for a rounded "workout," and want
**multiple games per domain** over time.

| Domain | Games |
|---|---|
| Spatial / planning | ✅ Arrow Escape · ✅ Arrow Maze |
| Working memory | ✅ Memory Match |
| Logic / pattern | ✅ What Comes Next · ✅ Crack the Code — see [crack-code.md](crack-code.md) · ✅ Picture Logic (nonogram) — see [nonogram.md](nonogram.md) |
| Language | ✅ Word (Wordle-style) — see [wordle.md](wordle.md) · ✅ Word Search — see [word-search.md](word-search.md) · ✅ Word Scramble — see [word-scramble.md](word-scramble.md) · ⛔ Compound Words — see [compound-words.md](compound-words.md) |
| Numeracy | ✅ Number Cross — see [number-cross.md](number-cross.md) · ✅ Mini Sudoku — see [mini-sudoku.md](mini-sudoku.md) · ✅ 2048 — see [merge.md](merge.md) |
| Attention / speed | ✅ Follow the Trail — see [trail.md](trail.md) · 💡 Odd One Out |
| Memory (other) | ✅ Simon — see [simon.md](simon.md) |

## Engagement & polish

- ✅ Levels + persistence · level picker · stars · daily workout + streak
- ✅ **Clearing a level unlocks the next one.** It used not to: `recordReached` fires
  from each screen's level loader and nowhere else, so progress advanced *only* if the
  player pressed "Next level" on the win dialog. Anyone who pressed "Home" instead
  reopened the level they had just beaten, forever — which reads as "this game always
  gives me the same board", and was reported that way about Memory Match. It affected
  all thirteen level games. Win handlers now call `ProgressStore.recordCleared`, which
  records the stars *and* unlocks the next level; a source-level test fails if any game
  goes back to calling `recordStars` directly.
- ✅ Haptics · celebratory win dialog · per-game theming · app icon + name
- ✅ Donate link (⚠️ `https://ko-fi.com/loffen` in `home_screen.dart` has never been
  confirmed to resolve — one browser visit settles it, and testers can already tap it)
- ✅ Save & resume a board mid-game — see [save-resume.md](save-resume.md).
  Wired for 2048, Picture Logic, Mini Sudoku, Number Cross, Arrow Maze and Arrow
  Escape. Short-round games (Simon, Trail, What Comes Next, Crack the Code, Word
  Scramble, Memory Match, Wordle) are deliberately excluded.
- ✅ Word of the day + sharing — see [word-of-the-day.md](word-of-the-day.md).
  Date-seeded so there is no server; spoiler-free emoji grid; share sheet *and*
  copy-to-clipboard. Practice words stay available but are never shareable.
- ✅ **Tester feedback channel** — testers are non-developers, so GitHub issues are too
  high a barrier (account, repo, developer-shaped form). Cheapest workable option is an
  in-app "Send feedback" opening a pre-filled `mailto:` with version, level, device and
  locale already in the body, so a one-line reply is still actionable. A Google Form is
  the alternative if replies should land in a sheet. Deliberately *not* an analytics or
  crash SDK — nothing in this app sends data anywhere and that is a property worth
  keeping. See [handoff.md](handoff.md).
- ✅ **In-app update prompt** (`in_app_update`, wrapping Play Core). Play still
  auto-updates in the background, but it *defers* updates for apps the user rarely
  opens, and there is no prompt of our own — so a tester can sit on an old build for
  weeks while we wait for feedback on a new one. The "needs an update" dialog other apps
  show on launch is this API, not something Play does for free.

  Uses the **immediate** flow rather than flexible: a dismissible banner is exactly what
  this audience dismisses forever. Shipped in `lib/services/app_update.dart`, checked once
  after the home screen's first frame, with every failure path silent.

  Still awkward to verify, and worth knowing: the API only reports an update for a build
  actually installed *from Play*, so `flutter run` always reports none. Confirming it
  end to end needs a throwaway version bump on the internal track. Note also that the
  prompt only helps from the release *after* the one that introduces it — a tester on
  1.1.0 has to update by hand once (Play Store → search the app → **Update**) before it
  can ever fire.

- ✅ **Hints in the word games** — a lightbulb in the game header. Word Scramble places
  the next correct letter, Word Search marks where one unfound word starts (the direction
  is left to the player), and Wordle reveals one letter in place.

  **A hint costs a star, never a heart**, following the precedent Word Scramble's word-swap
  already set: the level stays finishable and simply cannot earn 3 stars. Costing a heart
  would push a player who needs the hint off the level entirely, which is the opposite of
  the point — this exists because a dyslexic player asked for it.

  **The daily word is excluded on purpose.** It is the same puzzle for everyone and its
  emoji grid is shareable, so a hinted daily result would misreport how it went to another
  person. Practice words get the button; the daily does not.
- 💡 Daily reminder notification (local notifications)
- ✅ Personal records ("New personal best!") — local only, per game *and* per
  level. Wired for 2048 (score), Memory Match (moves), Mini Sudoku and Picture
  Logic (mistakes), Crack the Code (guesses). The arrow games and Trail are left
  out on purpose: their only metric is hearts lost, which the stars already say.
  A first completion sets the best but is never announced as a record.
- 💡 Sound effects · 💡 achievements/badges · 💡 stats screen
- 💡 Settings screen (language, text size, sound)

## Difficulty (audit with `dart run tool/analyze_level_curves.dart`)

Every game once plateaued early — 11 of 12 were identical from level 20 onward,
seven from level 12 — so level numbers above that were decorative.

A second round followed a tester reaching Arrow Maze level 50 and finding it
identical to the twenties. Plateaus after it:

| game | before | after | what moved |
|---|---|---|---|
| Arrow Maze | 35 | **63** | branching tail to a measured-reachable 2.15; `minLength` 5 at L45 |
| Number Cross | 12 | **26** | blanks 9→13, decoys 2→5 |
| What Comes Next | 9 | **17** | tiers 4–5: sum-of-previous-two, interleaved sequences |
| 2048 | 7 | **18** | target to 4096, then `fourChance` 0.1→0.3 |
| Memory Match | 7 | **9** | 15 → 21 pairs (7×6) |

What's left:

- ✅ **Arrow Maze depth, three ways** — bonus arrows (a golden arrow whose departure
  unlocks a *legal chain* of 2–4 others, from level 12); large-board packing fixed by
  placing interior heads first; and the board cap raised 14 → 24 columns behind zoom,
  taking level 60 from 24 arrows to ~70 with `clear@start` 22% → 4%. Next is re-tuning
  the branching targets, which the generator can now beat. See
  [arrow-maze-depth.md](arrow-maze-depth.md) and [handoff.md](handoff.md).
- 💡 **Memory Match needs *triples* to go further.** 21 pairs is the structural
  ceiling: all layouts are 6 columns wide, so card size is width-bound at ~45dp
  on a 360dp phone and rows are the only thing that can grow. Matching three of a
  kind rather than two is the next real axis, and it is a mechanic change.
- 💡 **Number Cross division.** Still untried, and now the main knob left; blanks
  and decoys are spent.
- ✅ **What Comes Next: the visual patterns never climbed.** `_shapeQuestion` was never
  passed the tier, so the ~40% of every round that is dots/colour/arrow was identical at
  level 1 and level 60 — dots always +1, arrows always a quarter clockwise, colour cycles
  2–4 long. The *number* tiers did climb, which is why `analyze_level_curves.dart` read
  healthy while nearly half the game was flat. Old-style shape questions now fall from
  88% of the pool at tier 1 to 25% at tier 5. Dot counts are capped at 12 (they are drawn
  as dots) and their distractors now straddle the answer — clamped to 1..9, a large answer
  got only bigger neighbours and was guessable as "the smallest option".
- ✅ **Memory Match showed the same 21 pictures from level 9 up.** The symbol pool held
  exactly 21 entries and level 9+ needs 21 pairs, so every level drew all of them.
  Positions still varied, which is why it looked correctly seeded. Pool is now 44. The
  lesson generalises: a pool sized *equal* to the largest draw is a pool with no variety.

### Word-game quality gaps

- 📝 **No offensive-word filter for Norwegian.** English puzzle words are screened
  using SCOWL's offensive/profane lists (plus a top-up, since SCOWL missed `TURD`),
  so crude words can still be *checked* by the near-miss rule but never *set* as an
  answer. Norwegian has no equivalent list and I'd only be guessing at one — a
  native speaker should write it. Until then a crude Norwegian word can appear as a
  puzzle. See the tier demotion in `assets/words/en_all.txt`.
- 📝 **Norwegian scramble words are inflected forms** (`MÅLET`, `ØYNENE`,
  `SIKLENDE`) because `nb_all.txt` holds full forms. Legitimate but less satisfying
  than headwords; fixing it means tiering the Ordbank *lemma* list separately.
- 📝 **English levels 32+ may be too obscure** — `GARBOARD`, `TRILLIUM`, `JOBBERY`
  are real and correctly tiered, but possibly past the fun line. One-line fix:
  restrict the top band to `WordTier.normal`.

## Architecture notes (do before/with the next non-level games)

- `GameDefinition` assumes **numbered levels** (`levelBuilder` → `LevelSelectScreen`).
  Games that don't fit levels (Wordle; maybe Number Cross) need a **direct-entry**
  option: add an optional `screenBuilder` to `GameDefinition`; the home card routes
  to it instead of the level picker. (`available` = has either builder.)
- When games-per-domain grows, add a `domain`/`category` field to `GameDefinition`
  and group the home screen by domain.
