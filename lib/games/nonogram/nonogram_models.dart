import 'dart:math';

/// Picture Logic (a nonogram / Picross). Number clues along the top and left
/// give the runs of filled cells in each line; deduce the grid.
///
/// **This generator works differently from every other one in the app.** The
/// others build boards in reverse-solve order, so solvability is true by
/// construction. That is impossible here: clues are *derived* from a filled
/// grid, and whether they are deducible is an emergent property of the grid. So
/// solvability is **proven by a solver** instead — [solveNonogram] — and any
/// candidate it cannot finish is thrown away. Don't try to reverse-solve it.
///
/// The property that makes the mechanic worth building: if the iterated line
/// solver completes the grid, then the puzzle needs **no guessing** *and* its
/// solution is **unique**, because every single deduction along the way was
/// forced. Uniqueness comes free instead of needing a second exhaustive solver.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

/// What the player has put in a cell. The solution itself is a plain bool grid;
/// [crossed] is player bookkeeping and never affects the win check.
enum NonogramMark { blank, filled, crossed }

// Cell states used by the solver. Deliberately ints rather than an enum: the
// line solver is the hot path of generation and runs millions of times.
const int _unknown = 0;
const int _fill = 1;
const int _empty = 2;

/// Runs of consecutive filled cells in [line], in order.
///
/// An all-empty line yields an empty list, which the UI renders as "0".
List<int> cluesFor(List<bool> line) {
  final runs = <int>[];
  var run = 0;
  for (final on in line) {
    if (on) {
      run++;
    } else if (run > 0) {
      runs.add(run);
      run = 0;
    }
  }
  if (run > 0) runs.add(run);
  return runs;
}

/// What one line's clues still allow, given what is already known about it.
class LineDeduction {
  LineDeduction(this.canFill, this.canEmpty, this.placements);

  /// Whether some valid placement fills cell i.
  final List<bool> canFill;

  /// Whether some valid placement leaves cell i empty.
  final List<bool> canEmpty;

  /// How many placements of the runs are still consistent with [states].
  /// This is the raw material of the difficulty metric — see
  /// [NonogramSolveResult.branching].
  final int placements;
}

/// Everything [runs] still permits for a line in state [states].
///
/// Returns null if the clues and the known cells contradict each other, which
/// is how a wrong candidate grid gets rejected.
///
/// A cell that *can* be filled but cannot be empty is forced filled, and vice
/// versa; that is the only inference rule the solver needs, and applying it to
/// every row and column until nothing changes is a complete "no guessing"
/// solver for the puzzles this game ships.
LineDeduction? deduceLine(List<int> runs, List<int> states) {
  final n = states.length;
  final r = runs.length;

  // canAllBeEmpty[i]: cells i..n-1 could all be empty.
  final canAllBeEmpty = List<bool>.filled(n + 1, true);
  for (var i = n - 1; i >= 0; i--) {
    canAllBeEmpty[i] = states[i] != _fill && canAllBeEmpty[i + 1];
  }

  // count[j][i]: number of ways to place runs[j..] within cells[i..].
  // ok[j][i] is just count > 0, kept separately for readability.
  final count = List.generate(r + 1, (_) => List<int>.filled(n + 1, 0));
  final ok = List.generate(r + 1, (_) => List<bool>.filled(n + 1, false));
  for (var i = 0; i <= n; i++) {
    ok[r][i] = canAllBeEmpty[i];
    count[r][i] = ok[r][i] ? 1 : 0;
  }

  bool runFits(int i, int len) {
    if (i + len > n) return false;
    for (var k = i; k < i + len; k++) {
      if (states[k] == _empty) return false;
    }
    return true;
  }

  for (var j = r - 1; j >= 0; j--) {
    final len = runs[j];
    for (var i = n; i >= 0; i--) {
      var c = 0;
      // Leave cell i empty and carry on.
      if (i < n && states[i] != _fill && ok[j][i + 1]) c += count[j][i + 1];
      // Or start run j at cell i, which needs a gap after it.
      if (runFits(i, len)) {
        final after = i + len;
        if (after == n) {
          if (ok[j + 1][after]) c += count[j + 1][after];
        } else if (states[after] != _fill && ok[j + 1][after + 1]) {
          c += count[j + 1][after + 1];
        }
      }
      count[j][i] = c;
      ok[j][i] = c > 0;
    }
  }

  if (!ok[0][0]) return null; // clues contradict the known cells

  // Walk forward over states reachable from (0,0), marking what each surviving
  // choice implies. Both transitions increase i, so a single ascending sweep
  // over i visits every state after the states that can reach it.
  final canFill = List<bool>.filled(n, false);
  final canEmpty = List<bool>.filled(n, false);
  final reach = List.generate(r + 1, (_) => List<bool>.filled(n + 1, false));
  reach[0][0] = true;

  for (var i = 0; i <= n; i++) {
    for (var j = 0; j <= r; j++) {
      if (!reach[j][i]) continue;
      if (j == r) {
        for (var k = i; k < n; k++) {
          canEmpty[k] = true;
        }
        continue;
      }
      if (i < n && states[i] != _fill && ok[j][i + 1]) {
        canEmpty[i] = true;
        reach[j][i + 1] = true;
      }
      final len = runs[j];
      if (runFits(i, len)) {
        final after = i + len;
        if (after == n) {
          if (ok[j + 1][after]) {
            for (var k = i; k < after; k++) {
              canFill[k] = true;
            }
            reach[j + 1][after] = true;
          }
        } else if (states[after] != _fill && ok[j + 1][after + 1]) {
          for (var k = i; k < after; k++) {
            canFill[k] = true;
          }
          canEmpty[after] = true;
          reach[j + 1][after + 1] = true;
        }
      }
    }
  }

  return LineDeduction(canFill, canEmpty, count[0][0]);
}

/// The outcome of trying to solve a puzzle by forced deductions alone.
class NonogramSolveResult {
  const NonogramSolveResult({
    required this.solved,
    required this.passes,
    required this.branching,
  });

  /// True when forced deductions alone completed the grid. Implies the solution
  /// is unique and the player never has to guess.
  final bool solved;

  /// Fixed-point iterations needed. A secondary difficulty signal: a board that
  /// falls out in two passes is a different experience from one needing eight.
  final int passes;

  /// Mean log2 of the number of placements still open per unfinished line, over
  /// the whole solve.
  ///
  /// This is the [branching factor](../../snake_arrows/) idea from Arrow Maze in
  /// a new costume, and for the same reason: a board where every line instantly
  /// collapses to one placement is trivial no matter how big it is, and grid
  /// size is a poor proxy for difficulty. Log scale because raw placement
  /// counts run into the hundreds and the interesting range is the exponent.
  final double branching;
}

/// Solves by forced deductions only — never guesses, never searches.
///
/// [solved] false means the puzzle needs guesswork, which is the rejection
/// criterion during generation. It does *not* mean the puzzle is unsolvable.
NonogramSolveResult solveNonogram(
  List<List<int>> rowClues,
  List<List<int>> colClues, {
  int maxPasses = 40,
}) {
  final h = rowClues.length, w = colClues.length;
  final grid = List.generate(h, (_) => List<int>.filled(w, _unknown));

  var branchingSum = 0.0;
  var branchingCount = 0;
  var passes = 0;
  var contradiction = false;

  /// Applies one line's forced cells. Returns false on contradiction.
  bool runLine(List<int> runs, List<int> states, void Function(int, int) write) {
    if (!states.contains(_unknown)) return true;
    final d = deduceLine(runs, states);
    if (d == null) return false;
    branchingSum += log(max(1, d.placements)) / ln2;
    branchingCount++;
    for (var i = 0; i < states.length; i++) {
      if (states[i] != _unknown) continue;
      if (d.canFill[i] && !d.canEmpty[i]) {
        write(i, _fill);
      } else if (d.canEmpty[i] && !d.canFill[i]) {
        write(i, _empty);
      }
    }
    return true;
  }

  while (passes < maxPasses) {
    final before = _knownCount(grid);
    passes++;

    for (var r = 0; r < h && !contradiction; r++) {
      if (!runLine(rowClues[r], grid[r], (c, v) => grid[r][c] = v)) {
        contradiction = true;
      }
    }
    for (var c = 0; c < w && !contradiction; c++) {
      final col = [for (var r = 0; r < h; r++) grid[r][c]];
      if (!runLine(colClues[c], col, (r, v) => grid[r][c] = v)) {
        contradiction = true;
      }
    }
    if (contradiction) break;
    if (_knownCount(grid) == before) break; // fixed point
  }

  final solved = !contradiction && _knownCount(grid) == w * h;
  return NonogramSolveResult(
    solved: solved,
    passes: passes,
    branching: branchingCount == 0 ? 0 : branchingSum / branchingCount,
  );
}

int _knownCount(List<List<int>> grid) {
  var n = 0;
  for (final row in grid) {
    for (final v in row) {
      if (v != _unknown) n++;
    }
  }
  return n;
}

/// Per-level shape and difficulty target.
class NonogramConfig {
  const NonogramConfig({
    required this.width,
    required this.height,
    required this.density,
    required this.maxClues,
    required this.targetBranching,
  });

  final int width;
  final int height;

  /// Fraction of cells the candidate builder aims to fill.
  final double density;

  /// Hardest layout constraint in the game — see [maxCluesFor].
  final int maxClues;

  /// Wanted [NonogramSolveResult.branching]. Anything within
  /// [onTargetTolerance] counts as equally correct, and looks decide the rest.
  final double targetBranching;
}

/// Any board this close to the level's branching target is treated as equally
/// correct, exactly as Arrow Maze does it: difficulty and looks are a priority
/// order, not a weighted blend. Buying branching precision from 0.15 to 0.0 is
/// imperceptible; a board with an ugly empty band is not.
const double onTargetTolerance = 0.30;

/// Grid size is capped at 12 by the ~22dp legibility floor for this audience.
///
/// The clue gutter was *expected* to be the binding constraint here, and it
/// isn't: `tool/analyze_nonogram_difficulty.dart` shows caps of 4, 5, 6 and 7
/// admit an identical candidate pool with identical branching, because a
/// symmetric blob almost never puts more than four runs in one line. So the
/// narrow four-number gutter is free — it costs no difficulty and no variety,
/// and it is what lets a 12-wide grid fit a small phone at this text size.
/// Don't "unlock" it expecting harder boards; there aren't any up there.
int maxCluesFor(int size) => size <= 5 ? 3 : 4;

/// Highest branching the candidate builder can actually reach at each size,
/// from the measured pool (a little under the observed max, so the pool doesn't
/// have to get lucky). Asking for more than this is not an error — it silently
/// degrades to "closest available", which is how a curve flattens without
/// saying so, which is exactly what happened to Arrow Maze at level 17.
double _reachableCeiling(int size) => switch (size) {
      <= 5 => 1.10,
      <= 8 => 1.80,
      <= 10 => 2.20,
      _ => 2.45,
    };

NonogramConfig nonogramConfigForLevel(int level) {
  // Size grows to the legibility floor and then stops; difficulty past that
  // comes from the branching target, not from a bigger grid. The measured bands
  // per size overlap heavily, so the two knobs really are independent.
  final int size;
  if (level < 4) {
    size = 5;
  } else if (level < 9) {
    size = 8;
  } else if (level < 16) {
    size = 10;
  } else {
    size = 12;
  }

  // Density is a difficulty knob, and it runs the *opposite* way to intuition:
  // measured branching peaks around 0.35-0.42 and falls off above it, because a
  // very full board is mostly solid lines and those are free. An earlier version
  // ramped density up with level and was quietly making late levels easier.
  // The 5x5 floor is a *looks* fix, not a difficulty one: on a 5-wide board a
  // single empty line is 20% of the picture, so at 0.42 nearly every candidate
  // had one, the looks score was dominated by it, and the same shape family kept
  // winning — levels 1 and 3 came out near-identical. A fuller small board has
  // room to differ. Branching is barely affected at this size (measured max 1.29
  // at 0.42 vs 1.14 at 0.50).
  final ramp = 0.42 - 0.06 * min(1.0, level / 24);
  final density = size <= 5 ? max(0.50, ramp) : ramp;

  // Measured reachable bands (p50..max of the raw pool), from
  // tool/analyze_nonogram_difficulty.dart:
  //   5x5  0.35..1.29   8x8  0.90..1.90   10x10 1.15..2.63   12x12 1.50..2.74
  // This ramp stays inside them and only reaches the ceiling around level 39,
  // so the curve keeps climbing far past where the grid stops growing.
  // Re-run the analyzer after ANY change to candidate building — the bands move.
  final target = (0.45 + 0.055 * (level - 1)).clamp(0.45, _reachableCeiling(size));

  return NonogramConfig(
    width: size,
    height: size,
    density: density,
    maxClues: maxCluesFor(size),
    targetBranching: target.toDouble(),
  );
}

/// A generated puzzle plus the player's marks.
class NonogramBoard {
  NonogramBoard({
    required this.solution,
    required this.rowClues,
    required this.colClues,
    required this.branching,
    required this.passes,
  }) : marks = List.generate(
          solution.length,
          (_) => List<NonogramMark>.filled(
              solution.first.length, NonogramMark.blank),
        );

  final List<List<bool>> solution;
  final List<List<int>> rowClues;
  final List<List<int>> colClues;
  final List<List<NonogramMark>> marks;

  /// Measured difficulty of this board, kept for the analyzer and for tests.
  final double branching;
  final int passes;

  int get height => solution.length;
  int get width => solution.first.length;

  /// Won when the filled cells match the solution exactly. Crosses are the
  /// player's own notes and are ignored, so a board covered in them still wins.
  bool get isSolved {
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        if ((marks[r][c] == NonogramMark.filled) != solution[r][c]) return false;
      }
    }
    return true;
  }

  /// Cells filled in that shouldn't be — what the Check button reveals.
  int get wrongFills {
    var n = 0;
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        if (marks[r][c] == NonogramMark.filled && !solution[r][c]) n++;
      }
    }
    return n;
  }

  bool isWrongFill(int r, int c) =>
      marks[r][c] == NonogramMark.filled && !solution[r][c];

  /// Tap cycles blank -> filled -> crossed -> blank. One gesture, no mode
  /// toggle and no long-press: nothing hidden for the player to discover.
  void cycle(int r, int c) {
    marks[r][c] = switch (marks[r][c]) {
      NonogramMark.blank => NonogramMark.filled,
      NonogramMark.filled => NonogramMark.crossed,
      NonogramMark.crossed => NonogramMark.blank,
    };
  }

  double get fillFraction {
    var n = 0;
    for (final row in solution) {
      for (final on in row) {
        if (on) n++;
      }
    }
    return n / (width * height);
  }

  /// Builds a board for [level], seeded so a retry gives the same puzzle.
  ///
  /// Generates a pool of candidates, keeps only those the line solver can
  /// finish (guess-free and therefore unique), and among those picks by the
  /// priority order: branching within [onTargetTolerance] of target first, then
  /// looks. See `docs/plans/nonogram.md`.
  /// [candidates] is deliberately generous: a whole board generates in ~10ms at
  /// 220, so a pool of 800 still costs ~40ms — far inside the ~400ms per-level
  /// budget the other generators already spend — and a wide pool is what lets a
  /// board hit its difficulty target *and* look right instead of trading them.
  static NonogramBoard generate(int level, {int candidates = 800}) {
    final cfg = nonogramConfigForLevel(level);
    final rng = Random(level * 7919 + 5011);

    NonogramBoard? best;
    var bestOnTarget = false;
    var bestScore = double.infinity;

    for (var attempt = 0; attempt < candidates; attempt++) {
      final grid = buildCandidateGrid(cfg, rng);
      final rowClues = [for (final row in grid) cluesFor(row)];
      final colClues = [
        for (var c = 0; c < cfg.width; c++)
          cluesFor([for (var r = 0; r < cfg.height; r++) grid[r][c]])
      ];

      // Layout gate before the expensive gate: a board that cannot be drawn is
      // worthless however nice it solves.
      if (rowClues.any((r) => r.length > cfg.maxClues)) continue;
      if (colClues.any((c) => c.length > cfg.maxClues)) continue;

      final result = solveNonogram(rowClues, colClues);
      if (!result.solved) continue; // needs guessing — reject

      final board = NonogramBoard(
        solution: grid,
        rowClues: rowClues,
        colClues: colClues,
        branching: result.branching,
        passes: result.passes,
      );

      final miss = (result.branching - cfg.targetBranching).abs();
      final onTarget = miss <= onTargetTolerance;
      final score = onTarget ? _looksScore(board, cfg) : miss;

      // Priority order, not a blend: an on-target board always beats an
      // off-target one, and looks only break ties among on-target boards.
      if (best == null ||
          (onTarget && !bestOnTarget) ||
          (onTarget == bestOnTarget && score < bestScore)) {
        best = board;
        bestOnTarget = onTarget;
        bestScore = score;
      }
    }

    return best ?? _lastResort(cfg);
  }

  /// How bad a board looks, lower is better. Only consulted between boards that
  /// already hit the difficulty target.
  static double _looksScore(NonogramBoard board, NonogramConfig cfg) {
    // A wholly empty row or column is a free gimme and reads as a mistake.
    var emptyLines = 0;
    for (final runs in board.rowClues) {
      if (runs.isEmpty) emptyLines++;
    }
    for (final runs in board.colClues) {
      if (runs.isEmpty) emptyLines++;
    }
    return emptyLines * 0.5 + (board.fillFraction - cfg.density).abs();
  }

  /// Deterministic escape hatch so [generate] is total: one full row, rest
  /// empty. Trivially line-solvable (every clue forces its whole line at once),
  /// so it is a real puzzle rather than a crash — just a dull one. Tests assert
  /// levels 1-30 never reach it.
  static NonogramBoard _lastResort(NonogramConfig cfg) {
    final grid = List.generate(
        cfg.height, (r) => List<bool>.filled(cfg.width, r == 0));
    final rowClues = [for (final row in grid) cluesFor(row)];
    final colClues = [
      for (var c = 0; c < cfg.width; c++)
        cluesFor([for (var r = 0; r < cfg.height; r++) grid[r][c]])
    ];
    final result = solveNonogram(rowClues, colClues);
    return NonogramBoard(
      solution: grid,
      rowClues: rowClues,
      colClues: colClues,
      branching: result.branching,
      passes: result.passes,
    );
  }
}

/// A blobby, left-right symmetric candidate grid.
///
/// Symmetry is doing real work: a purely random grid reads as noise and throws
/// away the payoff of the genre, whereas a symmetric blob reads as *something*
/// without needing a hand-drawn picture library. Cells grow from seeds into
/// neighbours so shapes stay connected rather than speckled.
///
/// Public because `tool/analyze_nonogram_difficulty.dart` measures the raw
/// candidate pool, which is the number that decides whether a level's
/// difficulty target is reachable at all.
List<List<bool>> buildCandidateGrid(NonogramConfig cfg, Random rng) {
  final w = cfg.width, h = cfg.height;
  final halfW = (w + 1) ~/ 2;
  final grid = List.generate(h, (_) => List<bool>.filled(w, false));
  final target = (cfg.density * w * h / 2).round().clamp(1, halfW * h);

  final filled = <int>[]; // packed r * halfW + c, left half only
  void fill(int r, int c) {
    if (grid[r][c]) return;
    grid[r][c] = true;
    grid[r][w - 1 - c] = true; // mirror
    filled.add(r * halfW + c);
  }

  fill(rng.nextInt(h), rng.nextInt(halfW));
  var guard = 0;
  while (filled.length < target && guard++ < target * 60) {
    // Occasionally start a new blob so shapes don't become one big mass.
    if (rng.nextInt(12) == 0) {
      fill(rng.nextInt(h), rng.nextInt(halfW));
      continue;
    }
    final from = filled[rng.nextInt(filled.length)];
    final r = from ~/ halfW, c = from % halfW;
    final (dr, dc) = switch (rng.nextInt(4)) {
      0 => (-1, 0),
      1 => (1, 0),
      2 => (0, -1),
      _ => (0, 1),
    };
    final nr = r + dr, nc = c + dc;
    if (nr < 0 || nr >= h || nc < 0 || nc >= halfW) continue;
    fill(nr, nc);
  }
  return grid;
}
