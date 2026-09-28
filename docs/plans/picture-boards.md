# Picture boards — arrows arranged into a silhouette

Milestone levels whose arrows occupy a *shape* — a heart, a star, a house —
instead of the whole grid. Same game, same rules, in a silhouette.

Came from the owner's mother, who plays a commercial arrow puzzle that does this
and liked it. Design our own shapes: generic objects only, never a recognisable
character, logo or anything else someone else owns.

## It already works — this is the important part

**No new algorithm is needed for Arrow Escape.** The dense generator's
termination proof never used the fact that the grid was full:

> a non-empty board always has a topmost live cell, which can always be pointed up

That holds for *any* set of live cells. A cell outside the shape simply holds no
arrow, and a ray passes through it freely. So the existing forward construction —
take a live cell with a clear ray, give it that direction, remove it — runs
unchanged on an arbitrary mask, and the removal order is still a solution by
construction.

Prototyped and measured on 14x14 (longest-clear-ray choice, as `_buildDense`
uses):

| shape | cells | solvable | opening moves | mean branching |
|---|---|---|---|---|
| heart | 100 | yes | 10 | 3.88 |
| letter A | 86 | yes | 11 | 5.37 |
| smiley | 156 | yes | 6 | 2.65 |

Those land inside the band levels 41–100 already occupy (3.3–6.6), so a picture
board is a normal board, not a novelty with the difficulty knocked out of it.

## Arrow Maze too, but it is a bigger job

The owner's original reference has the *long* arrows worked into silhouettes, so
this wants doing for Arrow Maze as well. The reverse-solve argument survives
masking for the same reason — restricting *where* a snake may go cannot stop a
placed snake from having had a clear ray — but four things in `_build` need
changing, and one is a trap:

- **Add a separate `inShape` grid. Do not reuse `occupied`.** Marking
  out-of-shape cells as occupied is the obvious move and it is wrong: `rayClear`
  would then treat empty space outside the shape as a blocker, when a ray should
  pass through it freely. `occupied` must keep meaning "a snake is here".
- Gate `enumerateHeads` and body growth on `inShape`.
- `fillTarget` must be relative to the mask's cell count, not `rows * cols`.
- `emptyNear`'s summed-area table must count only in-shape empty cells, or cells
  near the silhouette's edge read as falsely roomy and heads get placed where
  nothing can grow.
- `largestEmptyFraction` must be mask-aware, or it scores the shape's own
  negative space as a defect and rejects every candidate.

**The real constraint is stroke width.** `minLength` is 5 from level 45, and a
snake is a contiguous path, so a shape needs strokes at least that long to hold
one — but it may *bend*, so a thick curve is fine and fine detail is not. Arrow
Escape does pixel art; Arrow Maze does brush strokes. Expect to lower `minLength`
on picture levels.

## Prior art, and a licence warning

Two open-source arrow-puzzle projects are worth knowing about. One of them has
already built this feature, and it is the one we must **not** copy from.

- **[robmat/arrows_game](https://github.com/robmat/arrows_game)** ("Skein") —
  Kotlin/Compose Android, the same snake/arrow-path mechanic as Arrow Maze. It
  generates boards with a *frontier-based* algorithm (the same characterisation
  `_Frontier` encodes here, arrived at independently), and it has
  `BoardShapeProvider` plus a `BoardImageProcessor` that derives **custom board
  shapes from image pixel data** — i.e. exactly this document's feature, shipped.
  It also carries an `:ads` module with Google Mobile Ads and GDPR consent, which
  is corroboration that the ad-gated continue is this genre's norm rather than one
  game's quirk, and a reminder of why we are not doing it.

  **It is GPL-3.0. Do not copy code from it, in any amount.** Brain Workout ships
  closed on Play; taking GPL-3 code would oblige us to release the whole app under
  GPL-3. Reading it to understand an approach is fine and ideas are not
  copyrightable — lifting lines is not. If in doubt, do not open it: our own
  generator already solves this in a single forward pass, so there is nothing we
  actually need from it.

- **[crudeGithub/Arrow-Escape-Game-Source-Code](https://github.com/crudeGithub/Arrow-Escape-Game-Source-Code)**
  — MIT, so legally usable, but technically not: Unity/C#, levels hand-authored
  through a ScriptableObject editor, and no shaped boards. A permissive licence on
  something we have no use for.

One idea worth taking from Skein, because it is obvious rather than novel:
**masks could be decoded from small image files instead of hand-authored in
source.** Not clearly better at this size — a 14x14 ASCII mask is reviewable in a
diff and needs no asset pipeline or decoder — but it scales better if shapes ever
get detailed or numerous. Start with ASCII; revisit if authoring becomes the
bottleneck.

## Resolution, fill and cost — measured

Grid size buys picture quality; **fill fraction** buys tap count; they are
independent. A solid heart and the same heart hollowed to an outline, generated
with the longest-clear-ray rule:

| grid | shape | arrows | dp/cell at fit | 320-candidate cost (extrapolated) |
|---|---|---|---|---|
| 14x14 | solid | 126 | ~26 | ~0.3s |
| 20x20 | solid | 254 | ~18 | ~0.7s |
| 20x20 | outline | 132 | ~18 | ~0.2s |
| 28x28 | solid | 500 | ~13 | ~2.0s |
| 28x28 | outline | 276 | ~13 | ~1.0s |

Single-candidate branching across all of those ran 3.2–5.8, i.e. inside the band
levels 41–100 already occupy. (The prototype timed the work correctly but did not
actually *keep* the best candidate, so what pool selection buys here is still
unmeasured — do that before setting a target.)

Two things follow:

- **An outline at high resolution beats a solid at low resolution on both axes.**
  A 20x20 outline heart is 132 arrows — *fewer* than today's level 100 — and a far
  better picture than the 126-arrow 14x14 solid.
- **Cost is the real constraint, not taps.** The owner is explicitly unworried
  about tap count ("if the board is interesting, clicking lots of times or coming
  back to it is fine"), and save/resume is already wired for Arrow Escape. But
  Arrow Escape has **no prefetch** — generation is inline on the UI isolate — so a
  ~2s board would freeze the app.

**So picture levels want Arrow Escape to get the prefetch Arrow Maze already has.**
That code is written, shipped and proven (`lib/services/board_prefetch.dart`), and
picture levels are *predictable* — if they are every tenth level, level 50 can be
warmed from level 41. Generalising `BoardPrefetch` beyond one game is the enabling
work; do it first or keep the grids small.

## Colour

Colour is an unused channel in Arrow Escape — direction carries every bit of game
information, so decorative colour costs nothing mechanically and colour-blind
players lose nothing. Two catches:

- **This audience reads colour as a rule.** Memory Match's lesson was that a new
  mechanic must be visible before first use; the mirror failure is a decorative
  difference that *looks* mechanical. Players will ask whether the red ones go first.
- **Colour is already spoken for.** Arrow Maze marks its bonus arrow gold, and a
  bonus arrow is the one real depth lever Arrow Escape is missing. If picture levels
  colour arrows decoratively, the bonus marker has to become a *shape* — a ring or
  glow — or picture levels carry no bonus. The latter is simpler and fits them being
  milestones.

Ship **single colour first**, but keep the format forward-compatible: masks are
already ASCII, so other letters can mean colour regions later. Costs nothing now,
and lets a monochrome silhouette be judged on a device before colour's ambiguity is
taken on.

## Zoom, and a deliberate exception

`CLAUDE.md` says zoom is an aid and never a requirement — scale 1 must show every
arrow tappable. A picture level is genuinely different: **seeing the shape and
tapping an arrow are two activities at two zoom levels**, so fit-to-screen only has
to be *viewable*. That justifies going under the ~23dp floor here in a way a normal
board cannot. It is still an exception to a written rule, so record it as one and
have the owner confirm "viewable" on a device — it is his call, not a measurable.

## Design

- **Milestone levels, not the default** — every tenth, say. A silhouette is a
  landmark and a reward; a run of them is a gimmick, and the shape constrains the
  generator enough that difficulty would drift.
- Shapes are hand-authored ASCII masks in the models file, like the prototype's,
  so they are reviewable in a diff and need no assets.
- Say nothing in the UI. Let the player notice. If it needs a label it has failed.
- The shape must be legible at fit-to-screen, which on a 14x14 is ~24dp a cell —
  so chunky outlines, no single-cell details.

## Open questions

- Does a picture board want a *lower* difficulty target? The shape is the reward;
  fighting a 2.6-branching smiley may bury it.
- Does the win dialog acknowledge it, or is that spoiling the joke?

## Status

🔨 **In progress**, branch `les/picture-boards` (not pushed). Built: `ArrowShape`
with three geometric masks, `ArrowBoard.generateShaped`, levels 55/65/75… via
`arrowShapeForLevel`, `configForLevel` following the shape, and
`tool/dump_arrow_shape.dart`. Seen on the emulator and liked.

Delivered shapes: heart (126 arrows, branching 2.96, chain 26), diamond (112,
4.55, 27), star (96, 5.33, 17).

**Open, and the owner's call: every tenth level, or every late board?** The
"milestone" argument above was written before three shapes existed to look at, and
the measured branching spread suggests "always" may cost nothing in difficulty.
He can judge it from the emulator faster than anyone can argue it.

Not started: prefetch generalisation (the gate on bigger grids), outline shapes,
colour, and anything at all for Arrow Maze.
