# Number Cross (math crossword)

A crossword-style grid where the entries are little equations that **share
cells where they cross**. Some numbers and operators (+ − × =) are pre-printed;
the player places a given **pool of numbers** into the blanks so that **every**
across- and down-equation is valid. A number at a crossing belongs to both its
row and its column equation — the "grey cells" workout.

## Example

```
 8  −  ?  =  5        across:  8 − ? = 5   (? = 3)
 ×
 ?                    down:    8 × ? = 16  (? = 2)
 =
16
                     Pool: [ 2 , 3 ]
```
The `8` is shared by both equations (the crossing).

## Approach (guaranteed solvable — same trick as the arrow games)

1. **Reverse-generate:** pick a layout of intersecting across/down equations,
   then choose numbers that satisfy *all* of them in a fully-filled grid.
2. **Blank out** some number cells → those become the pool the player places.
3. Optionally add a few decoy/extra pool numbers for harder levels.
4. Validate: a solver confirms the intended placement satisfies every equation;
   aim for a unique solution where feasible (not strictly required for a casual
   game — note any non-uniqueness).

## Build notes

- **Model (pure Dart, tested):** grid of cells (`number-fixed`, `number-blank`,
  `operator`, `equals`, `empty`); across/down equation extraction; equation
  validation; a deterministic generator seeded by level.
- **Operators:** start with + and − (gentle), add × at higher levels; avoid ÷ to
  keep integers clean.
- **Difficulty by level:** grid size, number of blanks, pool size (+ decoys),
  operator set, value range.
- **UI:** grid + a number pool; tap-a-pool-number-then-a-blank (or drag) to
  place; tap a placed number to return it to the pool; highlight a row/column
  equation when it becomes valid; win when all equations hold.
- **Framework:** levels + stars + daily workout like the other games (this one
  *does* fit numbered levels). Themed accent (orange/brown).

## Status

✅ Shipped (v1). Realized as a **3×3 number lattice** (5×5 cell crossword): each
number sits in a row equation `a op b = c` *and* a column equation (the
crossing). Consistent generator (corner operators chosen to agree; addition-only
always consistent), reverse-blanked into a pool. Difficulty scales by operators
(+ → +− → +−×), blank count, and decoys. Win = every row & column valid (any
valid fill), so it's forgiving. Tested for consistency + solvability, levels 1–30.

## v2 — irregular crossword layout (planned)

Goal: look and feel like the brainplay math-crossword — equations of varying
positions/lengths placed across a larger grid, intersecting at shared number
cells, with empty cells giving the classic crossword shape (instead of our
packed 3×3 lattice).

Quick plan:
- **Layout engine:** on a larger grid, place across & down equations
  (`a op b = c`, 5 cells each) at chosen anchors so they cross at *number*
  cells; leave the rest empty. Start sparse (3–6 equations), grow with level.
- **Consistent generation (still reverse-construction):** assign numbers by
  backtracking — when two equations share a cell, that cell has one value
  satisfying both; choose the free operand/operator to fit. Or grow
  incrementally: place an equation, then attach a crossing one whose shared
  value is already fixed. Fall back / retry on dead ends. Keep seeded.
- **Blank + pool:** same as v1 — blank some number cells into a pool (+decoys).
- **Validation:** generalise `isSolved` to *scan* the grid for runs matching
  `[num][op][num][=][num]` (across & down) and check each — works for any
  layout. (v1's fixed row/col checks become a special case.)
- **Reuse:** `NcCell`/`NcOp`/`applyOp` and the **whole screen** (generic
  `cells[r][c]` render + pool + tap/drag) carry over; this is mostly a
  model/generator change. The grid is already variable-sized.
- **Risk:** intersection consistency across the network — prototype the
  generator + a solver/validator + tests before touching UI.
