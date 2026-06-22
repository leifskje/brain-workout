# Merge / 2048

The classic 2048: slide the whole board one way; equal numbers that collide
merge into their sum (2+2→4, 4+4→8 …). Reach the level's target tile to win;
the board filling with no possible merges is a loss. Adapted to the app's
level framework by making each level target a higher tile.

## Design

- **Model (pure Dart, tested):** grid of ints (0 = empty). The move reduces
  to a single line-collapse — `collapseLine` drops gaps then merges equal
  neighbours once each — applied to extracted rows/columns per direction and
  written back. After any change a new tile (2, or 4 at 10%) spawns. Seeded
  per level so the opening tiles are retry-stable.
- **Difficulty:** 4×4 board; target doubles per level from 32 (level 1) up to
  2048, then holds. Stars by empty cells at the win (efficient board → 3★).
- **Input:** a four-arrow pad is the clear primary control (large buttons,
  with the hint right above it); swipe also works as the nostalgia path. Both
  feed one `_move(direction)`.
- **Feedback (added after first playtest — controls read as opaque):**
  - Tiles **visibly slide** from old cell to new and merges converge, driven
    by `planSlides` (pure, tested) + one `AnimationController` (created in
    `initState`); merged tiles and the newly spawned tile **pop** in on
    settle. This is what makes the move legible — "everything shoves that
    way" is now obvious.
  - The goal is shown as an actual **target tile** ("Make: [64]") so the
    objective (combine up to that tile) is concrete, not just a number.
- **UI:** classic 2048 tile palette, taupe board, fixed Stack geometry; tiles
  use `FittedBox` so big numbers always fit.

## Status

✅ Shipped. Tested: `collapseLine` cases; generation/determinism/opening-tile
invariants for levels 1–30; a crafted win, a no-op move, and a stuck (full,
no equal neighbours) board; plus a screen render + arrow-pad widget test.
