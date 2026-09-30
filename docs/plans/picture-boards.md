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

**Built (29 Sep): colour on the finished picture only.** The owner found a brown
tint during play "strange" and asked for the intended colours instead. Colour
never appears while arrows remain — the catch below still holds — but when the
last arrow leaves, the picture fades in (900ms) in its real colours and sits for
a moment before the dialog names it. During play long-arrow levels show only a
6% neutral outline; short-arrow levels show nothing. Masks use palette letters
(`arrow_pictures_palette.dart`, 15 colours) in place of `#`; any non-`.` cell is
inside, so colouring cannot move a board — fingerprinted over all 82 levels
before and after. A test fails on a stray `#` or a non-palette letter.


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

## Decided (29 Sep 2026, owner)

Superseded the "milestone levels" design below after the owner played 55/65/75.

- **A separate game, "Arrow Pictures" / "Pilbilder"** — every board a picture.
  The owner liked them enough to want all of them, but players already in Arrow
  Escape may prefer full boards, and a setting is invisible to this audience and
  would change a board a player is midway through. Arrow Escape goes back to full
  boards only; the 55/65/75 wiring never shipped, so nobody loses anything.
- **Both arrow kinds in the one game**, the shape choosing: short arrows are pixel
  art (detail, thin lines), long arrows are brush strokes (thick, rounded — a
  snake is ≥5 cells and bends). Ships with short arrows only; long-arrow pictures
  come later. Whether switching kinds level to level confuses is a device question.
- **Levels are an authored, append-only list.** New pictures only ever go on the
  end, so adding long-arrow levels later never changes a level someone has played.
  Past the end of the list the game cycles through the long-arrow pictures only
  (cycling the whole list sent level 83 back to the 42-arrow key); those cycled
  levels *may* change when
  pictures are added, which is acceptable because the autosave's arrow-count guard
  drops a mismatched save and the prefetch version covers the list length.
- **30+ pictures, not only generic.** Nordic, seasonal, animals, objects,
  landmarks are all fine. Not fine: characters, logos, brands, real people.
- Order of work: generalise `BoardPrefetch` → the game with short-arrow pictures
  → long-arrow pictures → colour.

## Design (original — see *Decided* above)

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
- ~~Does the win dialog acknowledge it?~~ **Yes (owner, 29 Sep)** — "You
  cleared level 76. It was a seahorse!" One ARB `select` per language
  (`pictureName`) holds all names with their articles; a test fails if a picture
  lacks one. Both arrow kinds also tint the picture behind the arrows, so every
  level ends on the revealed picture rather than an empty grid.

## Long arrows on pictures — measured (29 Sep)

`SnakeBoard.generateShaped` exists (not wired to levels). The `inShape` mask is kept
separate from `occupied`, as the trap above requires; with no mask the levelled
boards are byte-identical (fingerprinted over levels 1–60 before and after).

It overturns the "short = pixel art, long = brush strokes" split above. Long
snakes bend along thin strokes, so they cover *any* picture well, and they fix
the thing short arrows are worst at:

| picture | short arrows, hardest | long arrows, min 4 | long fill |
|---|---|---|---|
| windmill 32x42 | 19.95 branching | 3.79 | 92% |
| tall ship 24x29 | 4.43 | 2.85 | 94% |
| grandfather clock 20x28 | 6.60 | 2.36 | 96% |
| cat 13x13 | 5.41 | 2.92 | 98% |
| fish 11x7 | 3.47 | 1.83 (6 snakes) | 96% |

Generation ≤ 0.6s at 32x42. The limit is at the *small* end: a picture under
~100 cells holds only 6–15 snakes, a very short puzzle. Uncovered cells (4–8%)
are scattered singles, not pooled holes; whether they read as texture or as
damage is a device question. `dart run tool/dump_snake_shape.dart <name> [min]`.

Decided: the big ones (see *Status*). A second lap in the other kind would
reuse all the art and is still open.

## Status

🔨 **In progress**, branch `les/picture-boards` (pushed; not merged).

**30 Sep: 215 pictures, list pinned, mirrored replays built.** Every new picture
passed a blind silhouette audit (see the recipe). Awaiting the owner's spot-check
on the emulator.

Built (29 Sep): **Arrow Pictures** as its own game — 102 pictures by end of day
(`arrow_pictures_shapes.dart`, sorted by cell count, 42 → 1485; tiers in the
recipe below), Arrow Escape's
screen reused through `ArrowGameSpec`, boards prefetched via the now-generic
`BoardPrefetch<B>`, strings in en + nb. Arrow Escape is back to full boards.

Measured, and it changed the design: **an absolute branching curve does not fit
pictures.** The shape sets the achievable range — troll cannot go below 7.9,
fish reaches 2.2 — so a single curve put 15 of 39 levels outside their own
spread. Levels now pick a percentile *within their picture's pool*
(`generateShapedAtHardness`): median at level 1, hardest by the end of the list.
Generation is ≤66ms at these sizes, so prefetch is headroom for bigger grids, not
yet a necessity. Tune with `dart run tool/analyze_arrow_pictures.dart`.

**High resolution makes short-arrow boards looser, not harder.** Levels 1–39
play at 3–6 arrows free per step, 62–82 at 7–10 (the windmill at 20). The
drawing agents traced it: an arrow facing open canvas out to the board edge is
free from the start, so tall or airy pictures play themselves, while enclosed
holes cost nothing. Keeping hardest-board branching ≤ 9 forced compromises —
front views instead of profiles, Big Ben without its palace, lamp posts added
beside the Eiffel Tower purely to block rays. Long arrows do not have this
problem (see above), and CLAUDE.md says branching is not what players feel in a
monotone game anyway. **Decided (owner): the big pictures use long arrows.**

**Wired (29 Sep).** Positions 40+ in the list (`pictureFirstLongPosition`) play
on Arrow Maze's screen, which now takes a `SnakeGameSpec` as Arrow Escape's takes
an `ArrowGameSpec`; `ArrowPicturesScreen` picks the screen by level, and "Next
level" across the boundary replaces it (`redirect`). Each kind has its own
prefetch cache, and `warmPictureLevel` warms the *next* level's kind — level 39
must warm a long board for 40. Long levels measure 2–6.5 branching, 85–97% of
the picture covered, ≤0.42s on desktop with a 48-candidate pool (96 covered no
more). Hearts fixed at 4. No bonus arrows on pictures.

**Redrawn dense (29 Sep), after the owner played level 82** — the seahorse —
and could not tell what it was: "the long arrow images can be much denser, they
felt empty". Two causes: the picture filled only 38% of its board, and long
arrows are thin lines, so a sparse picture reads as scattered strokes. Fixes:
the picture's cells are now tinted behind the snakes (`SnakeGameSpec.picture`),
which also turns clearing into a reveal; and all 43 long pictures were redrawn
as solid silhouettes, no 1-cell strokes, no filler scenery, natural poses back
(400–760 cells, 38–80 snakes, 90–96% covered, 2–7 branching, ≤0.32s). Tall
subjects (giraffe, towers, deer) stay near 50% of their box — filling more would
make them blobs.


**Huge tier (29 Sep), levels 83–102** — the owner asked for bigger, denser
pictures now that zoom exists. 20 pictures at 40–44 x 48–57, 1384–1500 cells,
78–114 snakes, coloured as drawn. Two knobs apply only above
`pictureHugeCells` (900), so every earlier board is unchanged: snakes up to 28
long (capped at 14, a 40x56 picture measured 81% covered; 30 reached 94%), and
Arrow Maze's screen zooms to `cols / 6` rather than 4x (≈7x at 44 wide). A 24-
candidate pool dropped three pictures to 88–89% at their level's seed; 48 holds
91–96% (polar bear 89%) at 0.4–0.8s on desktop, prefetched.


**A picture must read from its silhouette alone** — the rule every future
picture is drawn under. During play there is no colour: the player sees one flat
shape filled with snake lines. The first huge tier was drawn leaning on colour,
and the owner could name neither Holmenkollen ("a big triangle" — the hill
swallowed the jump) nor the polar bear on its ice floe ("a blob"); the carousel
and the redrawn seahorse, whose outlines alone say what they are, both landed.
An audit by silhouette failed or weakened 14 of the other 17. So: no large
grounds or backgrounds merging with the subject (≤ 3 rows of ground), iconic
features stick out of the outline or are cut in as holes, profiles over front
views, and judge a drawing from a one-colour rendering, never the coloured one.
Holmenkollen was replaced by a reindeer.

The owner checked the reworked huge tier on the emulator on 29 Sep: "they look
ok now".

## Adding pictures — the recipe

What today's rounds converged on. Drawing is agent work in parallel batches;
the code needs nothing — a picture is a mask in `arrow_pictures_shapes.dart`
plus one entry per language in the `pictureName` select in both ARB files, and
the tests pick it up (a missing name fails `every picture is named in both
languages`).

| tier | positions | size | cells | arrows |
|---|---|---|---|---|
| tier | positions (30 Sep) | size | cells | arrows |
|---|---|---|---|---|
| small | 1–101 | ≤ 16 wide | 40–170 | short |
| mid | 102–141 | 20–26 wide, ≤ 36 tall | 400–550 | long, max 14 |
| large | 142–172 | 28–32 wide, ≤ 42 tall | 600–850 | long, max 14 |
| huge | 173–215 | 40–44 wide, ≤ 60 tall | 1100–1500 | long, max 28 (> `pictureHugeCells`) |

The list is sorted by cell count, and **the kind of arrow is by position**
(`pictureFirstLongPosition` = 102), so the smallest must stay the short-arrow
ones. **Once shipped the list is append-only** (pinned by a test), so from then
on new pictures can only go on the end — the huge tier. Before release, adding
small pictures moves the boundary: keep the count of pictures ≤ 16 wide equal to
`pictureFirstLongPosition - 1`, or move the constant.

Every drawing:
- **Reads from its silhouette alone** (see above). Judge it rendered in one
  colour. Profiles, iconic parts sticking out or cut in as holes, ground ≤ 3 rows.
- **Long-arrow tiers: solid.** No 1-cell strokes — every inside cell in some
  inside 2×2 block — and ≥ 55–60% of its bounding box, or it reads as scattered
  lines. Short-arrow pictures may have 1-cell detail; they are tiles.
- **Coloured from `arrow_pictures_palette.dart` only**, never `#` (a test fails
  on it). Picture-book colours, coherent regions, no stray single cells.
- **Covered** by the long-arrow generator ≥ 92% at seed 1 *and* at its final
  level's seed (seed = level number, and coverage swings a few points by seed).
  Check with `dart run tool/analyze_arrow_pictures.dart` after merging.
- **Named** in English and Bokmål *with its article* ("a seahorse" / "en
  sjøhest", "the Eiffel Tower" / "Eiffeltårnet").
- No characters, logos, brands, real people or artworks.

Process that worked (30 Sep, 102 → 210): drawing agents in parallel, each
writing its own `tool/_draft_<batch>.dart` that runs `tool/picture_check.dart`
on itself (palette, 1-wide strokes, coverage at seeds 1/120/200, short-arrow
branching). Then a **blind audit**: an agent that sees only the draft's
silhouettes, shuffled and numbered, with no names, and names each one. The
drawer's own judgement is worthless here, and the audit is not: drawers
reported "reads clearly" on pictures the audit called "blob". Keep what it
names first; send the rest back once with its exact misreading, then drop.
Merge by name, re-sort, move `pictureFirstLongPosition`, re-run the analyzer.

Pass rates, first audit → after one redraw: small ~60% → ~80%, mid ~50% →
~65%, large and huge ~20% → ~45%. **Four-legged mammals fail at every size**
("four-legged animal, species unknown"; a bison read as an elephant, a llama
as a giraffe). What passes is anything with one unique outline — symbols,
tools, vehicles with separate wheels and window holes, landmarks with one
signature feature. Also watch for readings as a subject already in the list
(grapes → strawberry, Hagia Sophia → Taj Mahal): that is a fail, not a pass.

## Next

Done 30 Sep: grown to 215 (heart, diamond and star among them), list pinned
(`the shipped list is pinned, append-only`), mirrored replays (every other lap
past the end shows the pictures flipped left-to-right; `pictureMirroredForLevel`).

1. **Owner spot-check of the new pictures** on the emulator. Weakest by the audit:
   club suit, Mont-Saint-Michel, St Paul's, scorpion, Stonehenge.
2. **Short arrows now run to level 101** (was 39), because the list is sorted by
   size and half the new pictures were small ones — the small tier passes the
   audit best. Check the long-arrow switch still comes at a good point, or move
   `pictureFirstLongPosition` down (a small picture on long arrows is ~10 snakes,
   too short a puzzle — measured 29 Sep).
3. Norwegian picture names were chosen by agents; a native eye on `app_nb.arb`'s
   `pictureName` is worth ten minutes now that there are 215 (e.g. "ei/en",
   "et hundebein", "en spar"/"en kløver" for card suits, "St. Paul's Cathedral").
4. Coverage at the real level seed: all ≥ 92% except `steam_tug` at 89% (the
   test floor is 85%). Only matters if it reads patchy.
