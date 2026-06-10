# Mini Sudoku (Mini-sudoku)

Classic sudoku scaled down for a gentle start: 4×4 (2×2 boxes) on levels 1–3,
6×6 (2×3 boxes) on 4–9, full 9×9 from level 10. Tap a square, then a number
from the pad; conflicts tint red so they're easy to spot and fix. No lose
state — stars reflect wrong numbers placed (0 → 3★, ≤2 → 2★).

## Approach (guaranteed unique solution)

1. **Fill** a complete valid grid by seeded backtracking with shuffled
   candidates.
2. **Dig** cells in random order, keeping each removal only if the solver
   still counts exactly one solution (early exit at 2). Stops at the level's
   blank target or when nothing more can be removed → every puzzle has
   exactly one solution and is solvable by construction.
3. Seeded by level → deterministic and retry-stable.

## Status

✅ Shipped. Tested: levels 1–30 — solution validity (rows/cols/boxes are
permutations), no given conflicts, starts unsolved, entering the solution
solves it (`test/widget_test.dart`). Generation incl. 9×9 uniqueness checks
runs in ~1s for all 30 levels.
