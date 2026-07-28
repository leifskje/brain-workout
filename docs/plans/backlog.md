# Game & feature backlog

Status: ✅ shipped · 🔨 in progress · 📝 planned · 💡 idea

## Games by cognitive domain

We deliberately spread games across domains for a rounded "workout," and want
**multiple games per domain** over time.

| Domain | Games |
|---|---|
| Spatial / planning | ✅ Arrow Escape · ✅ Arrow Maze |
| Working memory | ✅ Memory Match |
| Logic / pattern | ✅ What Comes Next |
| Language | 🔨 Word game (Wordle-style) — see [wordle.md](wordle.md) |
| Numeracy | 📝 Number Cross (math crossword) — see [number-cross.md](number-cross.md) |
| Attention / speed | 💡 Odd One Out · 💡 Tap-in-order (Schulte table) |
| Memory (other) | 💡 Simon / sequence-repeat |

## Engagement & polish

- ✅ Levels + persistence · level picker · stars · daily workout + streak
- ✅ Haptics · celebratory win dialog · per-game theming · app icon + name
- ✅ Donate link (⚠️ real Ko-fi/BMC URL still a placeholder in `home_screen.dart`)
- 💡 Daily reminder notification (local notifications)
- 💡 Sound effects · 💡 achievements/badges · 💡 stats screen
- 💡 Settings screen (language, text size, sound)

## Difficulty (audit with `dart run tool/analyze_level_curves.dart`)

Every game once plateaued early — 11 of 12 were identical from level 20 onward,
seven from level 12 — so level numbers above that were decorative. Six games have
been uncapped since. What's left:

- 💡 **Optional "harder" mode for Memory Match and 2048.** Both sit at a plateau
  of 7, and both are close to structural ceilings: 2048 *is* the 2048 tile, and
  Memory Match at 5×6 is 15 pairs, about the most that fits a phone. Rather than
  stretching them, offer the player a way to go beyond — e.g. a toggle for a 6×6
  Memory board, or a 4096 target. Deliberately deferred: the ceilings are honest,
  so this is a feature, not a bug fix.
- 📝 **What Comes Next** plateaus at 9 and needs new *pattern tiers*, which is
  content work rather than config — the existing three tiers run out.
- 📝 **Number Cross** plateaus at 12. Untried knobs: division, more decoys,
  bigger grids.

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
