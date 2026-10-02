# New games — quick plans and build order (30 Sep 2026)

Short plans for six ideas, plus the order to build everything planned so far.
The fuller plans are [freecell.md](freecell.md), [sokoban.md](sokoban.md),
[mahjong-solitaire.md](mahjong-solitaire.md), [minesweeper.md](minesweeper.md)
and [odd-one-out.md](odd-one-out.md).

**The test for any new game:** is there a decision you can get wrong? That is
the lesson from Arrow Escape (see the monotonicity note in `CLAUDE.md`).

**Audience:** most players are around 40, some younger, some older (owner, 30
Sep). Keep the elderly-friendly interface as the floor, but pick games for
casual adults in general, not for one player.

## Chess puzzles

Find the winning move: mate in 1, 2 or 3, winning a piece, and so on.

- **Content is solved and free:** the Lichess puzzle database has about 6M
  puzzles under **CC0** (commercial use allowed, no attribution needed). Each
  has a position (FEN), its moves, a rating and theme tags. Ship a curated slice
  of a few thousand, sorted by rating. The rating *is* the difficulty curve, so
  there is nothing to tune.
- **No engine needed:** the solution is in the data. We only need legal-move
  generation. Use a Dart chess package with a permissive licence (check it).
  **No GPL code, and not Stockfish**, for the same reason as the Skein warning
  in [handoff.md](handoff.md).
- **Interface:** tap a piece, then tap a square. The opponent's reply plays
  itself. A wrong move shows what goes wrong, lets you try again, and costs a
  star, not the puzzle. The board must fill the screen width, and an 8×8 board
  on a phone is fine.
- **Risk:** the size of the data. Ship a pre-filtered CSV in the assets, not the
  800 MB dump.

## Letter hive (NYT's "Spelling Bee" is a trademark; name ours) — built 2 Oct as "Letter Hive" / "Bikuben", not yet released

Seven letters in a honeycomb, one of them in the centre. Make words of four or
more letters that always use the centre letter. A word using all seven scores a
bonus.

- **Uses the word lists we already ship**, in both languages. The generator picks
  seven letters that include at least one word using all seven, then counts how
  many valid words the puzzle has. A puzzle is accepted only within a
  word-count band per level.
- **Difficulty:** how many words there are, how rare they are, and the target
  (for example "find 60%" early, "find the pangram" later).
- **Interface:** tap letters, big Enter and Delete buttons, found words listed.
  No timer. It can have a date-seeded daily puzzle, like
  [word-of-the-day.md](word-of-the-day.md).
- **Offensive words in the Norwegian list:** not a risk any more. The owner
  decided on 2 Oct that the gap is fine; the players accept it.
- **As built:** the goal counts only common and ordinary words (SCOWL / corpus
  tiers 1–2) up to level 15, and adds the rare tier from 16, so early goals
  never need BEBEERU or MUUMUU. Any real word is *accepted*, rare and junk
  tiers included, as a bonus: a player who knows a rare word is never told it
  isn't one. Goal 25% of the points at level 1 → 55% from level 31; 2 and 3
  stars at 1.5× and 2× the goal. Reaching the goal offers "Keep going". English
  never uses S (plurals double the puzzle). The word lists stop at 8 letters,
  so pangrams are 7–8 long. Untimed. Look at puzzles with
  `dart run tool/analyze_letter_hive.dart [maxLevel] [en|nb] [--words]`.
- **Hint** (header lightbulb, unlimited): names an unfound counted word as
  "GU _ _ _ _ _", one more letter per tap until it is found. The first hint caps
  the level at 2 stars, as in Word Search and Word Scramble.
- **Show missed words:** offered only once the goal is met, after a confirm.
  Stars are frozen from then on, or it would be a list to copy.
- **Not built yet:** the daily puzzle.

## Bridges (Hashi) — built 2 Oct, on `les/bridges`, not yet released

Islands with numbers. Connect them with bridges (one or two, straight, never
crossing) so each island has its number of bridges and everything joins up.

- **Proven the same way as Picture Logic:** generate a solution, derive the
  numbers, and keep it only if a deduction solver finishes with no guesses.
  That makes the solution unique too.
- **Difficulty** by which techniques are needed, as for Mini Sudoku and
  Minesweeper. Grid size stays within 13×13 for legibility.
- **Interface:** tap two islands to add a bridge; tap the bridge to cycle 1 → 2
  → none. It is very visual and has little text.
- **As built:** the difficulty metric is how many times counting runs dry and
  a connectivity argument ("this would seal a group off", "this is the only
  link left") is needed: 0 on levels 1–3, rising to 5 from level 31. Board
  width stops at 12. Tune with `dart run tool/analyze_bridges_difficulty.dart`;
  look at boards with `dart run tool/dump_bridges.dart <level>`.
- **Next, if it plays well:** decoys (bridges a pair could take but the
  solution doesn't) are what the player can get wrong, and the early boards
  have few, since 11 islands on 7×9 barely see each other. Level 1 has none.
  A difficulty axis past level 31 is also missing: the connectivity count
  stops at 5, the most the pool reliably reaches.

## Word ladder — built 2 Oct as "Word Ladder" / "Ordstigen", not yet released

Turn COLD into WARM one letter at a time, with every step a real word.

- **Generation:** a graph of the word list (same length, one letter apart), BFS
  from the start word. Pick pairs whose shortest path fits the level's target.
  It is solvable by construction.
- **Depth:** dead ends are real, since a valid word can lead nowhere. Difficulty
  comes from path length and how many tempting dead ends lie near the path.
- **Interface:** change one letter per step, with undo. The shortest possible
  length is shown as a target, never a limit.
- **Risk, as it turned out:** Norwegian inflected forms make the all-words graph
  dense, but the shortcut check below handles that; lemmas were not needed. The
  real limit is six letters, with only 70–190 Norwegian pairs per shape, so
  Norwegian stays at 4–5 letters.
- **As built:** any real word is accepted as a step, but the par and the hints
  use only the par tiers (en 1–2, nb 1–3; the tiers aren't comparable across
  languages). A pair is rejected if *any* word gives a shorter ladder, so
  "Shortest: N" is literally true. Difficulty is **detour**: the par minus the
  letters that differ. It rises from 0 (4 letters, 3 steps) to 4 (5 letters,
  9 steps). Hint = the next word on a shortest ladder from the current word.
  Stars: 3 at par with no hint, 2 within par + 2. Untimed. A few slurs
  (`LadderIndex.neverSet`) are never *set* as puzzle words, though still
  accepted if typed (owner, 2 Oct). Tune with
  `dart run tool/analyze_word_ladder.dart [N] [--spread] [--pairs] [--path]`.

## Cryptogram

A quote in which every letter has been swapped for another. Work out the
substitution.

- **Content:** needs a bank of quotes in the public domain. Old proverbs and
  Norwegian *ordtak* are safe; modern quotes are not. A few hundred per language
  is the whole job.
- **Proof:** only accept a puzzle whose substitution is unique given the quote,
  checked against the word list. Give the first letter or two away to set the
  difficulty.
- **Interface:** tap a letter, then choose its replacement. Every copy of that
  letter updates together.
- **Risk:** content work in two languages. Build it after the no-content games.

## Arrow-word crossword (pilkryss) — ⛔ blocked on content

The most-loved magazine puzzle in Norway. Building the grid is manageable
(fitting words is a known search problem). **Clues are the blocker**: we need
short definitions we are allowed to ship, in both languages. Plan it only once
a licensable source of definitions exists, or a hand-written clue bank is judged
worth the effort. Same class of blocker as Compound Words.

## A speed game — owner's decision (see also [challenge-modes.md](challenge-modes.md))

The strongest evidence in the field is the ACTIVE trial's speed-of-processing
training: effects still measurable after ten years. It flashes a scene briefly
and asks what was where, and the flash gets shorter as you improve. Answering
can be untimed, so you never lose for thinking slowly. But it is the closest
the app would come to the no-time-pressure rule, so it needs the owner's call
before any plan. With a broader, younger audience it is more defensible than
when the target was one elderly player.

## Build order

Ranked by value for the effort, content risk, and spread across skills. Nothing
here is released until the owner asks.

| # | Game | Why here | Effort | Content risk |
|---|---|---|---|---|
| 1 | **Letter hive** ✅ built | Reuses the word lists and the daily-puzzle machinery | S | None (owner accepts the nb gap) |
| 2 | **Chess puzzles** | CC0 data brings its own difficulty curve | M | None |
| 3 | **FreeCell** ✅ built | The most-played casual game; pure skill | M | None |
| 4 | **Bridges** ✅ built | New kind of logic; the Picture Logic proof method carries over | M | None |
| 5 | **Sokoban** | Planning where a wrong move loses | M–L | None (levels generated) |
| 6 | **Word ladder** ✅ built | Words with real dead ends | S–M | Low (lemmas) |
| 7 | **Odd One Out** | Attention; the plan exists | M | Low |
| 8 | **Mahjong solitaire** | Popular, but needs its own tile art (blind audit) | L | Art |
| 9 | **Cryptogram** | Needs a proverb bank in two languages | M | Content |
| 10 | **Minesweeper** | Fair, but overlaps with Picture Logic | M | None |
| — | Arrow-word crossword | Blocked on clues | L | ⛔ |
| — | Speed game | Needs the owner's decision | M | — |

Two cross-cutting things get more important with a broader audience:

- **Difficulty choice** ([difficulty-choice.md](difficulty-choice.md)): a
40-year-old regular and a first-time 75-year-old should not start on the same
level 1. Consider doing it before game #3.
- **The home screen** now groups games by category heading. Each new game needs
a `GameCategory`, and if chess, FreeCell and Mahjong arrive together a
"Cards & board" category may earn a heading of its own.

## FreeCell, as built (2 Oct, not yet released)

- New **Cards** category. Tap to move, no dragging; safe cards go home by
  themselves; undo free and unlimited. Stars count hints only (3 with none, 2
  with one or two), because trying a line and undoing it *is* the thinking.
  The personal best is the move count of the winning line. Untimed.
- Deals are seeded shuffles kept only if the solver (best-first search,
  positions hashed ignoring column and cell order) wins them. Difficulty is
  the free cells given against the fewest the solver needs: 4 cells needing ≤2
  (levels 1–8), 4 needing 3 (9–24), 3 needing 2 (25–36), 3 needing 3 (37–54),
  2 needing 2 (55+). Solver effort (nodes) is far too noisy to be the knob.
  Tune with `dart run tool/analyze_freecell_difficulty.dart`.
- The hint is instant while you follow the deal's proof, and comes from the
  solver once you leave it. "Can't find a way" is not a proof there is none:
  the solver's move set is deliberately incomplete.
- The save stores the moves and replays them, so undo survives a resume.
