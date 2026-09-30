# Sokoban

Push every box onto a target. You can push but never pull, and one box at a time.

Domain: spatial planning. Of the four casual games planned here, it adds the
most depth. The arrow games can never punish a legal move (they are monotone:
see `CLAUDE.md`). In Sokoban, one push into a corner loses the level. It is
the planning game this app doesn't have yet.

## Levels — generated and proven, not borrowed

The classic hand-made level sets are the obvious source. Their licences are a
patchwork, though, and many never say anything. Treat them like the GPL
warning in [picture-boards.md](picture-boards.md): read them for ideas, don't
ship them. (If a set with an explicit free licence turns up, it can be
considered then. Check it first, don't assume.)

Generate instead, using **reverse play**, which is the well-known way to build
Sokoban levels:

1. Build a small room: a wall mask carved from templates, ≤ 10×10 inside.
2. Put the boxes on their targets, then play backwards. The player *pulls*
   boxes away from the targets for N steps. Every position reached this way can
   be pushed back, so the level is solvable by construction.
3. **Then prove and measure it with a forward solver.** BFS over (box
   positions, player region), with the state normalised to where the player can
   reach, plus simple deadlock pruning (boxes in corners or against walls, off
   target). Small rooms and ≤ 5 boxes keep this exact and fast.

This game is not monotone, and it is PSPACE-complete in general. So the search
machinery `CLAUDE.md` says the arrow games don't need is exactly what this one
does need. Keep boards small enough that the exact search stays cheap, rather
than reaching for heuristic solvers.

## Difficulty — measured

`tool/analyze_sokoban_difficulty.dart` prints the spread per level:

1. **Minimum pushes** of the optimal solution: the length of the plan.
2. **Dead-end rate:** the share of legal pushes that make the level
   unwinnable. It is the same wrong-move measure as FreeCell and Mahjong.
3. **Boxes, 1 → 5**, and room size. The weakest axes, and capped early for
   legibility: a 10×10 room is about 32dp per cell on a phone.

The ramp is the solver's measures, not the room size. Pick the best of several
reverse-played candidates per level, as `SnakeBoard.generate` does.

## Interface

- **Tap a floor cell to walk there** (the path is found automatically). **Tap a
  box next to you to push it.** Swiping is optional, never required. Reaching
  the square behind a box and pushing it is what the player should be thinking
  about, not the controls.
- **Unlimited undo, and restart.** No penalty for either.
- **Gentle deadlock notice.** When the solver finds the position is lost, say
  "This box can't reach a target any more" and highlight the box. Offer to undo,
  don't forbid the move. The mistake is the lesson.
- **No move counter as a score.** Stars can reward "within N pushes of optimal",
  but that bonus is optional and never a failure.
- **No timer.**

## Build steps

1. Models: room mask, state, legal moves, reverse-play generator, BFS solver with
   deadlock pruning. Test: levels 1–30 solvable, solutions verified by replaying
   them.
2. The analyser: set the targets and check the ramp for plateaus
   (`analyze_level_curves.dart`).
3. Screen: tap-to-walk, tap-to-push, undo and restart, the deadlock notice, and
   save and resume.
4. l10n and the catalog entry under Logic.
