# Save & resume a board mid-game

Reported by the owner: *"I need to be able to be mid-game in 2048 and come back to
it later — if I close the app, or take a call."* Nothing was saved before this;
`ProgressStore` held levels, stars and streaks, but the board itself existed only
in widget state, so an interruption lost it.

## How it works

**One saved slot per game**, in `SharedPreferences` as JSON:
`ProgressStore.saveBoard / loadBoard / clearBoard`.

- **Keyed by game *and* level.** The level lives inside the slot and `loadBoard`
  refuses a save belonging to a different one — otherwise picking level 3 from the
  picker would resurrect your half-finished level 20.
- **One slot, not one per level.** The player is in the middle of exactly one
  board; keeping every abandoned attempt would grow without bound.
- **Versioned.** `_saveVersion` is checked on load, so a save written by an older
  shape is dropped rather than fed to a parser that no longer understands it.
- **Never throws.** Corrupt JSON, wrong shape, wrong version, wrong level all
  return null. A bad save must never be able to stop a game from opening.

**Only the player's own input is stored, never the puzzle.** Every generator here
is deterministic in the level number, so the board is regenerated and the saved
entries are replayed onto it. Storing the puzzle would duplicate the generator's
output and let a stale save contradict it.

**`BoardAutosave`** (`lib/services/board_autosave.dart`) is the shared hook. Mix it
into a game's `State` with `WidgetsBindingObserver` and implement three members.
It saves on two triggers:

- **`paused` / `hidden`** — the phone-call case, and the one that matters: once
  Android kills the process there is no later chance to write anything.
- **`dispose`** — pressing Back, so leaving and returning behaves like being
  interrupted.

`captureBoard()` returning null means "nothing worth keeping", which covers both an
untouched board and a finished one. **The finished case is load-bearing:** a win
clears the slot and *then* `dispose` runs, so a won board that still captured state
would immediately write itself back and the player would resume a level they had
already beaten.

Resuming is **silent** — no "continue?" prompt. The save is keyed to the level, so
the board on screen is the one the player left, and a prompt would only add a
decision for an audience that doesn't want one.

## Wired so far

| Game | Saves | Why it needed it |
|---|---|---|
| 2048 | grid, score, target, spawn mix | The one that was asked for |
| Picture Logic | marks (packed string) | Longest boards in the app — a 12×12 is a long sitting |
| Mini Sudoku | entries (packed string) | 9×9 with 58 blanks is not a five-minute board |
| Number Cross | placements; pool rebuilt from them | Same, and the tray state has to stay consistent |

Deliberately **not** wired, because a round is over in seconds and a saved
half-round would be more confusing than helpful: Simon, What Comes Next, Trail,
Crack the Code, Word Scramble, Memory Match, Wordle.

Arrow Maze and Arrow Escape are the open candidates — boards are long enough to be
worth keeping, and their state is just "which arrows have escaped", so it should be
a small addition.

## Notes for whoever extends this

- The RNG is deliberately not serialised in 2048. Only future spawn *positions*
  depend on it and the player cannot tell they differ; persisting a seed would
  imply a guarantee the game never made.
- Restores validate everything, because a saved board is untrusted input: 2048
  rejects ragged rows and any tile that isn't a power of two, Number Cross rejects
  a placement the pool cannot supply, and the packed-string games reject wrong
  lengths and stray characters. The cost of being wrong is a crash on opening a
  game, so each restore is all-or-nothing — a refusal leaves the board untouched
  rather than half-populated.
- Tests cover the round trip **through `jsonEncode`/`jsonDecode`**, not just the
  Dart map. That is where a lazy cast bites: decoding hands back `List<dynamic>`
  and `num`, not `List<int>` and `int`.
- The "corrupt data is refused" test seeds raw preference values, and it first
  asserts that a *valid* seeded value loads. Without that check every assertion
  expecting null would pass simply because nothing had been seeded.

## Status

✅ Shipped for 2048, Picture Logic, Mini Sudoku and Number Cross.
💡 Arrow Maze and Arrow Escape still to do.
