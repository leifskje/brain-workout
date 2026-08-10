# Arrow Maze — where the depth has to come from next

A tester reached level 50 and reported the board felt no harder than the twenties.
He was right, and the audit agreed: the branching target hit its 2.3 floor at
level 34, so **every level from 35 to 80 was config-identical**. The same plateau
bug as level 17 once was, just further out.

## What the retune bought (shipped)

| | level 35 | level 60 |
|---|---|---|
| branching (lower = harder) | 2.5 | 2.2 |
| forced steps | 26% | 32% |
| min arrow length | 4 | 5 |

Plateau moved **35 → 63**. That is real but small, and the ceiling is now
measured rather than guessed: `analyze_snake_difficulty` samples all 768 seeds at
14×20 and the lowest branching *any* of them reaches is ~2.1, so the ramp ends at
a reachable 2.15. An earlier attempt at 2.05 sat below the achievable floor and
silently degraded to "closest available" — the exact flattening the metric exists
to catch.

**Conclusion: 14×20 is essentially exhausted as a difficulty source.** Every
config knob is now at its limit. Anything further needs a new axis.

## Axis 1 — a bigger board, which means zoom

The board is pinned at 14×20 by legibility (~23dp per cell), not by the
generator. Pinch-zoom and pan would remove that constraint and reopen the whole
branching range, which is where the *large* remaining headroom is.

The honest risk: Arrow Maze is a game about scanning the whole board for an arrow
with a clear exit. If finding one requires panning, the game gets *tedious* rather
than harder, and that is a bad trade for this audience. Design accordingly:

- Default to fit-to-screen, always. Zoom is an **inspection aid**, never a
  requirement for play.
- Never let a tappable arrow be off-screen at the default zoom.
- Consider a "highlight all ready arrows" toggle so scanning stays possible at
  fit-to-screen even when arrowheads are small.

Verify with a real measurement, not a feel: generate at 20×30, run
`analyze_snake_difficulty`, and check the achievable branching floor actually
drops meaningfully below 2.1. If it doesn't, zoom buys nothing and shouldn't ship.

## Axis 2 — new mechanics (from a tester's own description)

Both of these add difficulty *without* more cells, which makes them strictly
better value than axis 1 if they work.

- ✅ **Bonus arrows — shipped.** One golden arrow per board from level 12 (three
  freed arrows, four from level 40). Both the bonus arrow *and* the arrows it frees
  are chosen from arrows that are **stuck at the start**: a tappable bonus arrow
  would be a free opening move, and freeing arrows that were never stuck would be
  no gift at all. Linked arrows are drawn in the same hue, lighter, so the
  connection is visible *before* the player commits to an order — which is the
  entire mechanic. Clearing the golden arrow last simply wastes it.

  Two things worth knowing. `measureDifficulty` simulates the cascade, because a
  metric that ignored it would be scoring a game nobody plays; the tuned curve
  survived that change with every level still inside tolerance, so no retuning was
  needed. And solvability is untouched for the same monotonicity reason as the
  autosave restores — a cascade only ever *removes* arrows, so it cannot strand
  anything, and the tests additionally assert every board is still solvable while
  ignoring the bonus entirely.
- **Eagle eye.** Reward spotting an arrow that threads a gap others block —
  i.e. a hard-to-see legal move. Adds a perception challenge on the same board.
  Needs a definition of "hard to spot" that isn't arbitrary; a candidate is an
  arrow whose exit ray passes within one cell of two or more other arrows.

## Do not copy code from the lookalike repos

Three were suggested. None is a usable code source:

| Repo | Stack | Licence | Verdict |
|---|---|---|---|
| SERAP-KEREM/Arrows | Unity / C# | MIT | Different mechanic (timing clicks to avoid collisions) |
| andrepucas/arrow-escape-2026 | Unity / C# | — | A ~5.5h technical-assessment vertical slice |
| sidhant947/ArrowEscape | Flutter | **GPL v3** | ⚠️ Copyleft — do not copy |

The closest one technically is the one to keep at arm's length: lifting code from
a GPL v3 project would oblige Brain Workout to be GPL v3 as well. Reading any of
them for *ideas* is fine; copying code is not.

## Status

✅ Retune shipped (plateau 35 → 63).
✅ Bonus arrows shipped — the first difficulty axis here that isn't a generator knob.
💡 Still open: **eagle eye**, and **axis 1 (zoom + a bigger board)**, which remains
the only route to the large remaining headroom. Verify zoom pays before building it:
generate at 20×30, run `analyze_snake_difficulty`, and check the achievable branching
floor actually drops meaningfully below 2.1. If it doesn't, zoom buys nothing.
