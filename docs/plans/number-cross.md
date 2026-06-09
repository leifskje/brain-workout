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

📝 Planned — build after the Word game. Generation correctness is the main risk;
prototype the model + solver + tests before the UI.
