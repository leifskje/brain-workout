# Mahjong solitaire

Tiles stacked in a layered layout; remove matching pairs of *free* tiles (nothing
on top, and open on the left or right). Clear the board.

Domain: attention and planning. It looks like visual search, and on an easy
board it is. But when three or four identical tiles are free at once, *which*
pair you take can decide whether the board is still winnable. That is the
decision that gives it depth.

## Generation — reverse-solve, with a twist

Randomly dealt layouts are often unwinnable. Build in reverse instead, the
convention both arrow games use. Start from the empty layout and place tiles pair
by pair, only into positions that would be free at that point of the removal. The
reverse of placement order is then a valid solution, seeded by level.

The twist, and it's why this game has depth: **solvable-by-construction does not
mean every legal move is safe.** Unlike the arrow games, this one is not
monotone. Taking the wrong one of two identical free tiles can bury its partner
for good. That is the point, so don't generate it away.

- **Solver:** DFS over removals, with memoisation on the set of removed tiles.
  Symmetric choices between identical tiles collapse. The biggest layout this
  app would use (≤ 72 tiles, see below) is well within reach.
- The solver drives the **"no winnable moves left"** notice and the hint, as in
  [freecell.md](freecell.md).

## Difficulty — measured

`tool/analyze_mahjong_difficulty.dart`, with targets set from its printed
spread:

1. **Trap rate:** the share of legal moves that turn a winnable board into a lost
   one. It's the direct measure of wrong-but-legal choices, and the primary knob.
   Raise it by generating so that identical tiles are free together more often.
2. **Height and overlap of the layout.** A taller board hides more, so you need
   to think further ahead.
3. **Tile count**, 24 → 72. It's the weakest axis, so stop there. 144 tiles
   (the classic "turtle") won't fit a phone.

## Interface

- **Tile faces are our own, not the classic Chinese set.** Characters, bamboos
  and circles are hard for this audience to tell apart at 40dp, and the point is
  thinking, not deciphering. Picture-book icons (fruit, animals, tools)
  that differ in **shape** and not only colour, for colour-blind players.
  Arrow Pictures' palette and style can be reused.
- **Depth has to be visible:** offset each layer, with a clear shadow, and dim
  tiles that aren't free. A tile that looks free but isn't is the classic
  frustration, and dimming removes it.
- **Tap two tiles.** A mismatch just clears the selection: no penalty, no lost
  heart. There's nothing to lose by looking.
- **Unlimited undo; no shuffle.** A shuffle is the usual way out of a dead board,
  but it teaches nothing. Undo back to the last winnable position teaches the
  mistake.
- **No timer.**

## Naming

**"Mahjong"** in both languages. It's the name players know, and a translation
would only hide the game (owner, 30 Sep: keep a familiar English name rather
than invent a Norwegian one). Avoid "Shanghai", which is a trademark.

## Build steps

1. Models: layout grid with layers, free-tile rule, reverse-solve generation,
   solver. Test: every level 1–30 solvable (like the arrow games), and the trap
   rate is reported, not assumed.
2. The analyser: set the targets.
3. Tile art: draft the icon set, then run the **blind audit**
   ([picture-boards.md](picture-boards.md)) at tile size. Every pair of faces
   must be told apart, not just named. This is the riskiest part.
4. Screen: layered rendering, free-tile dimming, pair selection, undo, and the
   dead-board notice. Save and resume.
5. l10n and the catalog entry under Logic.
