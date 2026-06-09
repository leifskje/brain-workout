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

## Architecture notes (do before/with the next non-level games)

- `GameDefinition` assumes **numbered levels** (`levelBuilder` → `LevelSelectScreen`).
  Games that don't fit levels (Wordle; maybe Number Cross) need a **direct-entry**
  option: add an optional `screenBuilder` to `GameDefinition`; the home card routes
  to it instead of the level picker. (`available` = has either builder.)
- When games-per-domain grows, add a `domain`/`category` field to `GameDefinition`
  and group the home screen by domain.
