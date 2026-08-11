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

## Axis 1 — a bigger board and zoom: ⛔ measured, and it does not work

This doc used to claim a bigger board was "the only route to the large remaining
headroom" and that zoom should be verified before building. It was verified. **The
answer is no**, and the direction is the opposite of what was assumed.

Measured by temporarily raising the column cap to 20 (so late levels build 20×29
instead of 14×20) and running `analyze_snake_difficulty`:

| | 14×20 (shipped) | 20×29 (tested) |
|---|---|---|
| branching min/med/max at L60 | **1.9** / 3.6 / 6.8 | **3.2** / 5.1 / 8.6 |
| board fill | 86–90% | 63–74% |
| largest empty gap | 3–9% | 12–33% |
| generation time | ~400ms | ~1200–1600ms |

Lower branching is harder, so a bigger board **raises the difficulty floor from 1.9
to 3.2** — it makes the game markedly *easier*. The shipped boards missed their
targets by +0.8 to +1.2 across every late level.

**The cause is the generator, not the geometry.** Fill collapses from ~88% to ~68%
and the largest contiguous hole grows to as much as a third of the board, because
the placement algorithm cannot pack a grid that big. Empty space is precisely what
gives arrows clear exits, so a sparse board is an easy board — the same finding that
made level 42 the easiest in the game back when every knob capped at level 17.

So the order of work is the reverse of what was assumed: **a bigger board is not a
difficulty lever until the generator can fill one.** Improving large-board packing is
a real project on its own, and only if it succeeds does zoom become worth building.
Zoom by itself would buy a board that is easier, patchier and 3–4× slower to
generate.

## Axis 2 — new mechanics (from a tester's own description)

Both of these add difficulty *without* more cells, which makes them strictly
better value than axis 1 if they work.

- ✅ **Bonus arrows — shipped.** One golden arrow per board from level 12 (three
  freed arrows, four from level 40). Both the bonus arrow *and* the arrows it frees
  are chosen from arrows that are **stuck at the start**: a tappable bonus arrow
  would be a free opening move, and freeing arrows that were never stuck would be
  no gift at all. The connection has to be visible *before* the player commits to an order — that
  is the entire mechanic — but it costs **one** colour, not two. Only the golden
  arrow is recoloured; the arrows it will free keep the normal colour and carry a
  small gold dot on the head. The first version painted them a second, lighter
  gold, which put four or five gold arrows on a board of ~22 and two new colours
  in front of the player; the tester's verdict was "a bit too much — there appears
  to be multiple colours". Clearing the golden arrow last still wastes it.

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
⛔ Bigger board + zoom: measured and rejected. It makes the game easier, not harder,
because the generator cannot fill a board that size. Would need better large-board
packing *first*, and only then is zoom worth revisiting.
💡 Still open: **eagle eye**, and making the bonus mechanic carry more weight.
