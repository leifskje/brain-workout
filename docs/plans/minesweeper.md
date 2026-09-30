# Minesweeper, no guessing

Uncover every safe cell; each uncovered number says how many of its eight
neighbours hide a mine.

Domain: logic. Pure deduction, and the plan below makes it *fair*. The classic
game's flaw is the forced 50/50 guess, which punishes a player for luck, not
reasoning. Here, no level ever requires a guess.

## Generation — prove it, exactly like Picture Logic

Picture Logic's generator is the precedent (`CLAUDE.md`). The deducibility of
a random board can't be constructed, only proven, so:

1. Seed by level. Place the mines, keeping the first-tap region clear (it's
   revealed for the player, so there's no blind first tap).
2. **Run a deduction solver** from that opening:
   - single-cell rules (a number satisfied → the rest are safe; a number equal
     to its hidden neighbours → all mines);
   - subset rules between pairs of numbers;
   - exhaustive constraint enumeration over the frontier, only as a last step.
3. If the solver clears the board, accept it. Otherwise discard it and try the
   next seed. Every step is forced, so the solution is also unique.

## Difficulty — which rule is needed, not how many mines

The trick Mini Sudoku still needs (see [handoff.md](handoff.md)) applies here
too. `tool/analyze_minesweeper_difficulty.dart` records the **hardest rule the
solver needed** and how often:

1. Easy: single-cell rules only.
2. Middle: subset rules needed at least k times.
3. Hard: frontier enumeration needed.

Density and board size follow, but as the weaker knobs. For legibility, cap the
board at about 9×14 at 36dp on a phone, or use zoom (the Arrow Maze precedent)
for anything larger.

## Interface

- **Explicit dig/flag mode toggle**, as a big two-state button. Long-press to
  flag is hidden and fiddly for this audience. Don't require it; it can exist as
  a shortcut.
- **Hitting a mine costs a heart, not the game.** This follows the arrow games:
  three hearts, and the board stays as it was. A misstep in deduction should
  cost something, but not an hour's work.
- **Wrong flags are never punished**, and never revealed until the end.
- **Hint:** show one cell the solver can currently deduce, and the rule that
  deduces it, in words. That turns the hint into teaching.
- **No timer.** The classic game has one; this one doesn't.

## Overlap to watch

Picture Logic is also a grid-deduction game. They feel different — local counts
versus row/column runs. Still, of the four casual-game plans (FreeCell, Mahjong
solitaire, Sokoban, this), this one adds the least that is new, and it ranks last.

## Build steps

1. Models: board from seed, reveal, and the solver with rule levels. Test:
   levels 1–30 solve with no guess, checked against an independent brute-force
   counter on small boards (as Picture Logic's uniqueness is checked).
2. The analyser: set the rule-level ramp.
3. Screen: mode toggle, hearts, the hint with its rule text, zoom if needed, and
   save and resume.
4. l10n and the catalog entry under Logic.
