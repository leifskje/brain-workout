# FreeCell

Classic solitaire with every card face up: eight columns, four free cells, four
foundations. Build each suit up from ace to king.

Domain: planning. It is the one casual game this audience already plays — the
kabal on the family PC — which is a reason to do it well, not a reason to do it
casually.

## Why FreeCell and not Klondike

Klondike hides most of the deck, so a large share of its difficulty is luck:
whether a buried card turns up in time. FreeCell is **full information**. Every
deal is a pure planning problem, and almost every deal can be won (one of the
first 32,000 classic deals cannot). That passes the test this app uses for
depth: there is a decision you can get wrong. Putting a card in the last free
cell too early is exactly the mistake that loses the game, and a player can
learn not to make it. Klondike can come later, reusing the card rendering.

## Generation — prove it, like Picture Logic

Deals are shuffled from a seed (seed = level), so a deal is deterministic and
retry-stable. Almost every deal is winnable, but "almost" is not the standard
here. **A solver checks every level; a deal it cannot solve is re-dealt.**

- A FreeCell solver is a well-trodden problem: best-first search over
  single-card moves, with the state canonicalised (free-cell order, and column
  order when a column is empty) and "safe" auto-moves to the foundations
  applied eagerly. Typical deals solve in milliseconds; the cap is a node limit,
  and a deal that hits it is thrown away rather than waited on.
- The solver is kept, not only used for generation. It powers the hint and the
  "can this still be won?" check (below).
- FreeCell is **not monotone**, unlike the arrow games: a move can make the deal
  unwinnable. So real search is needed here. The Arrow Maze note in `CLAUDE.md`
  warning against Rush Hour-style machinery does not apply. That note is about
  monotone games, and this one is the opposite case.

## Difficulty — measured, per the Arrow Maze lesson

Don't guess at difficulty; `tool/analyze_freecell_difficulty.dart` prints the
achievable spread per level, the same way the arrow analysers do.

1. **Free cells, 4 → 3 → 2.** The strongest knob by far. Four free cells make
   almost every deal easy; with two, many deals get genuinely hard. Early levels
   can also have five cells.
2. **Among the candidate deals, pick by the solver's measure**: the length of
   the shortest solution, and above all **how narrow the winning path is**. That
   is the share of legal moves at each step that still leave the deal winnable.
   It measures wrong-but-legal moves directly, which is the thing branching could
   not see in Arrow Escape.
3. **Buried aces and twos.** A cheap proxy early on, for building gentle first
   levels.

## Interface

- **Tap a card, then tap where it goes.** Also support dragging. Dragging alone
  is hard for this audience, and so is dropping precisely.
- **Auto-move to the foundations** only when it can never be wrong (the usual
  rule is that both opposite-colour cards one rank lower are already up). Tie the
  auto-move animation to the move-speed helper (`lib/theme/motion.dart`).
- **Unlimited undo, with no penalty.** Undoing is thinking, not failing. Stars
  count hints used, never undos and never time.
- **"This deal can no longer be won."** The solver runs after each move, in the
  background. When the position becomes lost, the game says so gently and
  offers to undo back to the last winnable position. This is kinder than the
  classic game, which lets you shuffle cards for ten minutes in a lost
  position, and it teaches the mistake.
- **Legibility is the main risk.** Eight columns across a 360dp portrait screen
  is about 42dp per card. Only the corner has to be readable: a large rank and
  suit, with the suit symbol doubled by colour *and* shape. Verify at 1.3x text
  scale in a widget test before any artwork is done. If it doesn't fit, landscape
  or zoom (the Arrow Maze precedent) is the fallback.
- **No timer and no move counter on screen.** The opt-in stopwatch rule in
  `CLAUDE.md` applies if one is ever wanted.

## Open questions for the owner

- **Rank letters in Norwegian:** A K Q J, or E K D Kn? Modern Norwegian decks
  mostly print A K Q J. Worth one question to the intended player.
- **Save and resume:** yes (see [save-resume.md](save-resume.md)). A deal is a
  long session, and this audience puts the phone down mid-game.

## Build steps

1. Models: card, deal-from-seed, legal moves, solver with node cap. Unit-test
   the solver on known deals, including the known unwinnable one.
2. `tool/analyze_freecell_difficulty.dart`: set the per-level targets from the
   printed spread.
3. Screen: layout test at 360dp and 1.3x text first, then tap-to-move, undo,
   auto-move and the lost-position notice.
4. Hint (the solver's next move) and save/resume.
5. l10n (en + nb) and the catalog entry under Logic.
