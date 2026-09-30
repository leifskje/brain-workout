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

## Letter hive (NYT's "Spelling Bee" is a trademark; name ours)

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
- **Risk:** offensive words in the Norwegian list. That gap already exists in
  the backlog, and this game shows found words back to the player, so it makes
  the gap more visible.

## Bridges (Hashi)

Islands with numbers. Connect them with bridges (one or two, straight, never
crossing) so each island has its number of bridges and everything joins up.

- **Proven the same way as Picture Logic:** generate a solution, derive the
  numbers, and keep it only if a deduction solver finishes with no guesses.
  That makes the solution unique too.
- **Difficulty** by which techniques are needed, as for Mini Sudoku and
  Minesweeper. Grid size stays within 13×13 for legibility.
- **Interface:** tap two islands to add a bridge; tap the bridge to cycle 1 → 2
  → none. It is very visual and has little text.

## Word ladder

Turn COLD into WARM one letter at a time, with every step a real word.

- **Generation:** a graph of the word list (same length, one letter apart), BFS
  from the start word. Pick pairs whose shortest path fits the level's target.
  It is solvable by construction.
- **Depth:** dead ends are real, since a valid word can lead nowhere. Difficulty
  comes from path length and how many tempting dead ends lie near the path.
- **Interface:** change one letter per step, with undo. The shortest possible
  length is shown as a target, never a limit.
- **Risk:** Norwegian inflected forms make the graph noisy. Use lemmas only (the
  same issue as [compound-words.md](compound-words.md)).

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
| 1 | **Letter hive** | Reuses the word lists and the daily-puzzle machinery | S | Low (the nb offensive-word gap) |
| 2 | **Chess puzzles** | CC0 data brings its own difficulty curve | M | None |
| 3 | **FreeCell** | The most-played casual game; pure skill | M | None |
| 4 | **Bridges** | New kind of logic; the Picture Logic proof method carries over | M | None |
| 5 | **Sokoban** | Planning where a wrong move loses | M–L | None (levels generated) |
| 6 | **Word ladder** | Words with real dead ends | S–M | Low (lemmas) |
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
