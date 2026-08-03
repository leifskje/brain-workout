# Picture Logic (Bildekryss)

A nonogram / Picross. Number clues along the top and left give the runs of
filled cells in each line; deduce the grid, and the filled cells make a picture.
Untimed, no penalty for a wrong fill — the player self-corrects, which is the
puzzle. Category: `logic`.

```
        2  4  4  4  2
  1 1   .  #  .  #  .
    5   #  #  #  #  #
    5   #  #  #  #  #
    3   .  #  #  #  .
    1   .  .  #  .  .
```

## Why this one is different from every other generator here

Every other game builds boards in **reverse-solve order**, so solvability is
true by construction. That is impossible for a nonogram: clues are *derived*
from a filled grid, and whether they're deducible is an emergent property. So
solvability must be **proven by a solver** instead of constructed. New pattern
for this repo — call it out in `CLAUDE.md` once it's built, or someone will try
to reverse-solve it.

## The solver (the core of the game, not a test helper)

**Line solver.** For one line, given its clues and the currently-known cells,
enumerate every placement of the runs consistent with what's known (memoized DP
over run index × cell index). Any cell filled in *all* placements is forced
filled; empty in all is forced empty.

**Iterate** line-solving over all rows then all columns until a pass changes
nothing.

- Grid complete → the puzzle is **line-solvable**: no guessing needed, and the
  solution is provably **unique**, because every deduction was forced. Fair.
- Stalled with unknowns left → needs search. Reject.

That single property — line-solvable implies unique and guess-free — is why this
mechanic is worth building. Uniqueness comes free instead of needing a second
exhaustive solver to confirm it.

## Difficulty

The branching-factor lesson from Arrow Maze transfers directly: **average number
of candidate placements per line at each deduction step**. A board where most
lines collapse to one placement immediately is trivial regardless of size; one
where every line stays ambiguous for many passes is hard. Secondary signals:
number of fixed-point passes required, and the largest number of unknown cells
remaining at the moment of the hardest single deduction.

Same loop as `snakeTargetBranchingForLevel`: seeded candidate pool → measure →
keep the one closest to the level's target. `tool/analyze_nonogram_difficulty.dart`
prints the achievable spread; keep targets inside it. Do **not** chase difficulty
with a bigger grid (see below).

Measured reachable bands (p50..max of the raw candidate pool):

| size | p50 | max |
|---|---|---|
| 5×5 | 0.35 | 1.29 |
| 8×8 | 0.90 | 1.90 |
| 10×10 | 1.15 | 2.63 |
| 12×12 | 1.50 | 2.74 |

The shipped ramp is `0.45 + 0.055·(level−1)`, clamped per size, so it only reaches
the ceiling around level 39 — the curve keeps climbing long after the grid stops
growing. The first attempt asked for 3.60 at level 40 against a real ceiling of
~2.4, which is not an error but silently degrades to "closest available" and
flattens levels 25+; the analyzer existed precisely to catch that, and did.

## Layout — the clue cap turned out to be free

This plan assumed the clue gutter was a difficulty-vs-legibility tradeoff.
Measured, it isn't a tradeoff at all: caps of 4, 5, 6 and 7 admit an **identical**
candidate pool with identical branching, because a symmetric blob almost never
puts more than four runs in one line. The narrow four-number gutter therefore
costs nothing, and it is what lets a 12-wide grid fit a small phone at this text
size.

- Grid 5×5 → 12×12. 12 is the ceiling, set by the ~22dp-per-cell legibility floor
  established by Arrow Maze.
- Clue cap 3 at 5×5, 4 above. Don't "unlock" it expecting harder boards — there
  aren't any up there.

## Generation

Random-density fill → derive clues → solve → grade → keep the best of a seeded
candidate pool of 800 (a whole board costs ~40ms, well inside the ~400ms other
generators spend).

Mirror-symmetric blobs, which shipped, and they carry the genre's payoff without
a picture library — the dumps read as trees, butterflies and faces. A hand-drawn
picture set for levels 1–10 is still the obvious next step if more charm is
wanted; it's content work, not a design change.

Two measured surprises, both recorded in the code:

- **Density runs opposite to intuition.** Branching peaks around 0.35–0.42 and
  *falls* above it, because a very full board is mostly solid lines and those are
  free. The first version ramped density up with level and was quietly making
  late levels easier.
- **5×5 needs a density floor for looks, not difficulty.** On a 5-wide board one
  empty line is 20% of the picture, so at 0.42 nearly every candidate had one,
  the looks score was dominated by it, and the same shape family kept winning —
  levels 1 and 3 came out near-identical.

## Interaction

Three states per cell: empty → filled → marked-empty (X) → empty. **Tap cycles**
— no long-press, no mode toggle, no hidden gesture. Marks are player bookkeeping
and don't affect the win check (win = filled cells match the solution exactly).

No drag-to-fill initially: it's the standard convenience in this genre but it's
the wrong bet for unsteady hands.

Optional **Check** button that highlights wrong fills, costing a star — consistent
with how hearts/stars work elsewhere.

## Animation

Nothing here carries information through motion: a cell's fill state is visible
in its end state. So the default `AnimationBehavior` is correct — do **not**
apply `AnimationBehavior.preserve` here. This is exactly the decorative case the
reduce-animations setting exists for. (See the motion section in `CLAUDE.md`;
the rule is easy to over-apply.)

## Status

✅ Built. `lib/games/nonogram/` (models + screen), catalog entry, l10n in both
languages, `tool/analyze_nonogram_difficulty.dart` and `tool/dump_nonogram.dart`.

Tested: line solver forced-cell and contradiction cases; levels 1–30 are
guess-free, clue-capped, deterministic and never the last-resort board;
difficulty on target for all 30 with late levels ≥0.8 above early ones; marks
cycle and crosses never block a win; plus two widget tests (cross-on-second-tap
with the Check button, and filling the picture to win).

**The uniqueness claim is checked, not asserted.** `countNonogramSolutions` in
the test file is an independent exhaustive row-by-row counter, and it confirms
exactly one solution for levels 1–8 — that is what turns "line-solvable implies
unique" from an argument into a fact. The solvability gate was also verified by
breaking it: with `if (!result.solved) continue` removed, level 22 fails
`should need no guessing`.

Possible next step: a hand-drawn picture set for levels 1–10, where
recognizability matters more than difficulty.
