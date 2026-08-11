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

## Axis 1 — bigger boards: the generator was the blocker, and it is fixed

The first measurement here concluded that a bigger board makes the game *easier*
(branching floor 1.9 → 3.2 at 20×29, fill 88% → 68%). That was true, but the
conclusion drawn from it — "a bigger board is not a difficulty lever" — was wrong.
The board was never the problem; the **placement order** was.

### Why fill collapsed

An arrow is only placeable if the ray from its head to the edge is clear *at that
moment*, so the chance a candidate head is legal is roughly
`(1 - density) ^ rayLength`. On a 14-wide board most cells sit a few steps from an
edge, so rays are short and placements succeed. On a 28-wide board the interior is far
from every edge: usable head positions scale with the **perimeter**, not the area, and
once density rises no interior cell can host a head at all.

Head selection preferred the emptiest neighbourhood and ignored ray length entirely,
so it spent the empty early board on easy edge placements and then found nothing legal
inland.

### The fix: place interior heads first

Order candidate heads by **ray length descending**, emptiest neighbourhood as the
tiebreak. That pairs the hard long-ray placements with a low-density board, which is
the only time they can succeed.

| | 14×20 before | 14×20 now | 28×41 now |
|---|---|---|---|
| arrows | 23 | 24 | **97** |
| fill | 87% | **94%** | 92% |
| largest hole | 6% | **3%** | 2% |
| clear at start | 22% | **13%** | **4%** |
| miss vs target | 0.26 | **0.13** | 0.30 |
| generation | 393ms | **1ms** | 9.6s |

It improves the size we already ship on every axis — denser, fewer holes, far fewer
free opening moves, closer to target, and ~400× faster because placements now succeed
instead of failing thousands of times against the retry ceiling. And 28×41, four times
today's area with 97 arrows, fills to 92% with only 4% of arrows ready at the start.

**Small boards must keep the old ordering.** Below about 9 columns there is no interior
to fix, and the ray tiebreak narrows the candidate set enough to cost level 1 two points
of fill — enough to trip the 0.65 fill floor in the tests. Gated on `cfg.cols >= 9`.

### Zoom shipped, and the cap moved to 24

`InteractiveViewer` around the board, plus explicit zoom in / out / fit buttons — pinch
is genuinely awkward for this audience, so it must not be the only way in. The buttons
appear only when the board is wider than 14 columns; the narrow early boards look
exactly as they did, and would only lose vertical space to a control row they do not
need.

**The nesting is load-bearing.** The `InteractiveViewer` wraps the `GestureDetector`,
not the other way round. Hit testing passes down through the transform, so the detector
always receives board-space coordinates and the cell arithmetic needs no knowledge of
the zoom. Inverted, every tap mis-targets the moment the player zooms — and nothing
else in the suite notices.

Zoom is an **aid, never a requirement**: scale 1 shows the whole board with every arrow
tappable, `boundaryMargin` is zero so the board can never be panned off screen and
lost, and loading or restarting a level always returns to fit.

The board cap is now **24 columns (24×35, 3× the old area, ~70 arrows)**, up from 14.
Not higher because generation cost is superlinear in area — the retry ceiling grows with
it too — so 24×35 lands ~50–240ms while 26×38 took ~1.8s and 28×41 ~9.6s. A board
nobody waits for is worth more than two extra columns. Growth is gradual past level 30
rather than a jump.

Curve at the new sizes, all inside tolerance:

| level | board | arrows | fill | hole | clear@start | vs target | time |
|---|---|---|---|---|---|---|---|
| 17 | 14×20 | 29 | 92% | 2% | 10% | −0.08 | 11ms |
| 25 | 18×26 | 48 | 90% | 6% | 8% | +0.05 | 10ms |
| 40 | 22×32 | 67 | 88% | 4% | 6% | +0.12 | 240ms |
| 60 | 24×35 | 70 | 93% | 2% | **4%** | +0.07 | 50ms |

`clear@start` falling from 22% to 4% is the difficulty win: almost nothing is ready to
fire at the start, so every board opens with a search rather than a free move.

### What is still open

- **Re-tune the branching targets.** The generator can now reach lower branching than
  the current targets ask for, so the curve is not using all the difficulty available.
- **Past 24 columns is blocked on generator *speed*, not on pool size.** Measured: at
  26×38 with the pool cut to 40 candidates, time comes down to 313ms — but fill falls
  to 79% with a 14% hole, against 93%/2% at 24×35. A wide pool is what buys a
  good-looking board, so cutting it just trades one flaw for another. Speed or fill,
  not both.

  The cost per candidate is what has to come down. It jumps ~40× for an 18% area
  increase (0.2ms at 840 cells, ~8ms at 988).

  **The obvious suspect is not the culprit — tried and reverted.** Head selection
  rescans every candidate head on each of up to `cells × 20` attempts, which looks
  like an O(area²) pass. Hoisting that out (rank all heads once per commit, then walk
  a cursor, with a random low-bit tiebreak so the ordering stays distributionally
  identical) made it **slower**: level 60 went 50ms → 866ms, level 42 156ms → 660ms,
  with quality unchanged. The per-commit sort costs more than every per-attempt scan
  it saves, because a pass commits ~70 snakes and each sort is O(h log h) over
  thousands of heads.

  So the cliff is somewhere else, and the next attempt should **profile rather than
  infer** — Dart DevTools' CPU profiler on a single `SnakeBoard.generate(60)` versus
  `generate(43)` would settle in minutes what an afternoon of reasoning did not.
  Candidates still worth suspecting: `enumerateHeads` rebuilding the whole list per
  commit, the `Set<Cell>` allocations in body growth (`Cell` has no cheap hash), and
  `refreshTables` being O(area) per commit.

### Prior art: there isn't any for this, and that is itself informative

Searched properly. The literature splits into two piles, neither of which is what we
need:

- **Solvers** for the adjacent genres — Rush Hour, Unblock Me, Parking Jam — which are
  BFS/DFS over a move tree. They answer "is this instance solvable and how hard", not
  "construct a large instance".
- **Constraint-based PCG** — ASP/SAT formulations of level generation (Smith & Mateas
  and successors). These *search* a space of boards under declared constraints.

That second pile is the tempting one and it is the wrong tool here. A solver's cost
grows with the space it searches, and our constraint is global (a removal order must
exist for the whole board). Reverse-solve construction never searches at all: it emits
a valid board in one pass, and solvability is true by construction. **For "as big as
possible", construction beats search**, so the algorithm class we already have is
right. The remaining work is constant factors, not a different paradigm.

### Prefetching beats optimising

The owner's idea, and it is worth more than every constant-factor attempt above:
generate the *next* board in the background while the win dialog is on screen.

The ~400ms budget that pinned the board cap was only a budget because generation sat on
the critical path between tapping "Next level" and seeing a board. Off that path it is
nearly free — the win dialog alone plays for ~1.1s before the player can even choose. So
the question stops being "how fast can we generate 28×41" and becomes "when do we
generate it".

`BoardPrefetch` (`lib/services/board_prefetch.dart`) warms level N+1 in a background
isolate as the win dialog opens, and `_loadLevel` takes it if it is ready. Two properties
make it safe:

- **Generation is deterministic in the level number**, so a prefetched board is
  *identical* to one made on the spot. Using it changes when the work happened, never
  what the player sees — asserted in the tests by comparing a prefetched board
  arrow-by-arrow against a locally generated one.
- **Every path degrades to generating on the spot.** A miss, wrong level, isolate
  failure or unusable payload all fall through to `SnakeBoard.generate`. Nothing here can
  stop a level opening.

It must run off the UI isolate: generation is synchronous CPU work, so doing it inline
would freeze the very celebration it hides behind. That means the board has to cross an
isolate boundary, hence `toJson`/`fromJson` in plain ints and lists, and hence the
isolate test is a plain `test()` — `testWidgets` runs its body in a fake-async zone where
a real isolate never completes.

**What this does *not* cover, before the cap is raised on the strength of it:** only the
sequential path. Entering from the level picker, or opening the first level, still
generates synchronously, so a two-second board would still be felt there. Raising the cap
past 24 wants either the picker warming the level under the cursor too, or an honest
loading state — that is the next piece, not another generator micro-optimisation.

### Why none of the Rush Hour work transfers: monotonicity

The Rush Hour material — the "how to avoid a huge search tree" question, the Medium
write-up, the various solver repos — is all about *search*: BFS, DFS, IDS, A*, IDA*,
blocking-car heuristics, state hashing, symmetry pruning. Rush Hour needs all of it
because the puzzle is **non-monotone**: cars *slide*, so a move can block as easily as
it unblocks, positions repeat, and the state space has cycles. That is why the game is
PSPACE-complete and why every implementation reaches for memoised search.

**Arrow Maze is monotone.** Arrows are *removed*, never repositioned, and removing one
can only ever open paths — never close them. That single property is why:

- **Solving needs no search.** Repeatedly firing whatever is clear is not a heuristic
  here, it is exact, which is what lets `measureDifficulty` simulate a greedy solve and
  be *correct* rather than approximate. All the A*/IDA*/hashing machinery is the price
  Rush Hour pays for a property we do not have.
- **A partly-cleared board is always still winnable** — measured earlier at 600 random
  escaped-subsets with zero rejections, which is why `applyEscapedJson` needs no
  winnability check.

So the search literature is not a missed opportunity; it is answering a harder question
than ours. Do not import it.

One thing in that material *is* accidental confirmation. The Medium article does cover
generation, and its method is Monte Carlo — place vehicles at random, solve, discard the
unsolvable — and the author reports that "the deadlock was in the random puzzle
generation step" when placing vehicles on an already-full grid. That is precisely the
failure our reverse-solve construction avoids, and precisely the fill collapse we hit
when the placement *order* was wrong. Independent confirmation that construction beats
rejection sampling here.

### The one idea worth borrowing

Rush Hour's best-performing heuristic is a hybrid of *how many cars block the target*
and *how far it has to travel*. The analogue we do not currently measure is the **depth
of the blocking DAG**: each arrow must leave before those on its exit ray, so the board
is a partial order, and the longest chain in it is the minimum number of forced steps
before anything else can open up.

Mean branching (what we tune against) says how many moves are available *on average*. A
board with the same mean branching can have a long forced spine or many short chains,
and the long spine is the one that feels hard. Adding `longestDependencyChain` alongside
branching, and targeting it, is a cheap and well-motivated next difficulty axis —
cheap because the DAG is already implicit in `isPathClear`.

Worth knowing if the cap ever needs to jump by a lot rather than a little:
**divide-and-conquer** would scale linearly — generate independent sub-boards and
stitch them, since an arrow exiting left only interacts with cells to its left. That
trades some global difficulty coupling for near-unlimited size, and is the one
structural idea that would beat tuning constant factors.
- **Tap targets at fit-to-screen.** 24 columns is ~15dp per cell on a 360dp phone.
  Tapping any cell of an arrow selects it, so the effective target is the whole arrow
  rather than one cell, but this is the axis to watch if the cap ever rises again.

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

  **The freed arrows are a legal chain, not a gift.** The first version picked any
  stuck arrows and slid them out through their neighbours — the reward broke the one
  rule the game spends every level teaching, and the owner noticed. Now the golden
  arrow's chain is built so each arrow has a genuinely clear path *when its own turn
  comes*: the first is clear once the golden arrow leaves, the second once the first
  leaves, and so on.

  A chain rather than a set, because a set does not exist often enough. Requiring one
  arrow to single-handedly unblock two others found nothing on most boards — at ~90%
  fill, most exit rays cross more than one arrow — and the bonus vanished entirely.
  Measured over levels 12–60: chains of 2–4 (usually 3) on 10 of 11 boards, and the
  one miss simply gets no bonus. Finding them needs a generous candidate scan (96,
  i.e. effectively every blocked arrow); at 24 a third of boards came up empty.

  The freed arrows **fly out one at a time**, reusing the ordinary escape
  animation, so a bonus reads as a chain reaction rather than arrows blinking out
  of existence — the owner asked for this after seeing them vanish. Each one picks
  the next arrow whose path is *now* clear where possible, since the golden arrow
  leaving often opens a lane, so as many as possible look like a normal escape. The
  board stays locked until the chain drains.

  Restarting the animation must be deferred out of the controller's own status
  listener (a microtask), and the whole thing is easy to mis-test: reading state
  via `AppLifecycleState.paused` stops the scheduler producing frames, which
  freezes the animation under test. That made the chain look broken after one arrow
  when it was the test doing the freezing.

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
✅ Large-board packing fixed (interior-first head ordering).
✅ Zoom/pan shipped, and the board cap raised 14 → 24 (3× the area, ~70 arrows).
📝 Re-tune the branching targets — the generator can now go lower than they ask for.
📝 Past 24 columns needs the per-attempt head scan made incremental; a smaller pool
   alone trades fill for speed (measured: 79% fill with a 14% hole at 26×38).
💡 Still open: **eagle eye**, and making the bonus mechanic carry more weight.
