import 'dart:math';

/// A grid coordinate (row/column).
class Cell {
  const Cell(this.row, this.col);

  final int row;
  final int col;

  Cell step(Dir d) => Cell(row + d.dRow, col + d.dCol);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// A direction with its grid step.
enum Dir {
  up(-1, 0),
  down(1, 0),
  left(0, -1),
  right(0, 1);

  const Dir(this.dRow, this.dCol);

  final int dRow;
  final int dCol;
}

/// A long, possibly bent arrow made of connected cells.
///
/// [cells] runs from tail to head; [exitDir] is the direction the head points
/// (the way it leaves the board).
class SnakeArrow {
  SnakeArrow({required this.id, required this.cells, required this.exitDir});

  final int id;
  final List<Cell> cells;
  final Dir exitDir;
  bool escaped = false;

  /// Ids this arrow sweeps off the board with it when it escapes.
  ///
  /// A **bonus arrow** (non-empty [frees]) is the one mechanic here that rewards
  /// choosing an *order* rather than just finding any legal move: the arrows it
  /// frees are ones that are stuck at the start, so clearing the bonus early is
  /// worth far more than clearing it last. That is the property the difficulty
  /// metric has always been reaching for — see docs/plans/arrow-maze-depth.md.
  List<int> frees = const [];

  bool get isBonus => frees.isNotEmpty;

  Cell get head => cells.last;

  bool occupies(int r, int c) {
    for (final cell in cells) {
      if (cell.row == r && cell.col == c) return true;
    }
    return false;
  }
}

/// Per-level difficulty settings.
class SnakeLevelConfig {
  const SnakeLevelConfig({
    required this.rows,
    required this.cols,
    required this.minLength,
    required this.maxLength,
    required this.hearts,
    required this.fillTarget,
    this.bonusFrees = 0,
  });

  final int rows;
  final int cols;
  final int minLength;
  final int maxLength;
  final int hearts;

  /// Fraction of the grid to fill with arrows (denser = harder).
  final double fillTarget;

  /// How many stuck arrows the board's bonus arrow sweeps out with it. 0 = no
  /// bonus arrow on this level.
  final int bonusFrees;
}

SnakeLevelConfig snakeConfigForLevel(int level) {
  // Portrait board: width (cols) grows with level, height (rows) ~1.45x wider to
  // match a phone screen.
  //
  // The old 14-column ceiling was set by legibility — ~23dp per cell is the floor
  // for this audience, and a wider board goes under it. The screen now offers
  // zoom and pan, so the cap moved to 24 (24x35, 3x the old area, ~70 arrows).
  // Two things keep it at 24 rather than higher:
  //
  //  - **Generation cost**, which scales with area and is superlinear because the
  //    retry ceiling grows with it too: 24x35 lands a few hundred ms, 26x38 took
  //    ~1.8s and 28x41 ~9.6s. A board nobody waits for is worth more than two
  //    extra columns.
  //  - **Zoom is an aid, not a requirement.** Every arrow must still be tappable
  //    at fit-to-screen, which gets thin much past this.
  //
  // Growth is slower than the old one-column-per-two-levels so the jump to a very
  // large board is gradual rather than a shock at level 30.
  final cols = (6 + (level - 1) ~/ 2).clamp(6, 20) +
      (level > 30 ? ((level - 30) ~/ 4).clamp(0, 4) : 0);
  final rows = (cols * 1.45).round();
  final fill = (0.6 + level * 0.04).clamp(0.6, 0.92);
  // Longer snakes tangle more without needing a bigger grid, and raising the
  // floor removes trivial 2-cell filler that was padding late levels.
  final maxLen = (4 + level ~/ 2).clamp(4, 14);
  // Raising the floor again at 45 removes the last of the short filler arrows,
  // so every arrow on a late board is long enough to block several others. This
  // is the only *config* knob left at 14x20 that isn't already maxed out.
  final minLen = level >= 45 ? 5 : (level >= 30 ? 4 : (level >= 15 ? 3 : 2));
  // Less margin for error once the boards genuinely require planning.
  final hearts = level >= 35 ? 3 : (level >= 20 ? 4 : 5);
  // Bonus arrows start at 12, once boards are dense enough that being stuck is a
  // real state rather than a rarity, and grow to four freed arrows late on. This
  // is the first difficulty axis in the game that isn't a knob on the generator —
  // see docs/plans/arrow-maze-depth.md.
  final bonusFrees = level < 12 ? 0 : (level < 40 ? 3 : 4);
  return SnakeLevelConfig(
    rows: rows,
    cols: cols,
    minLength: minLen,
    maxLength: maxLen,
    hearts: hearts,
    fillTarget: fill,
    bonusFrees: bonusFrees,
  );
}

/// How hard a generated board actually plays.
///
/// Board size and density turn out to be poor difficulty proxies: a 14x20 board
/// at 70% fill measured as the *easiest* in the game because a dozen arrows were
/// always ready to fire, so the player never had to plan. What matters is the
/// branching factor — how few legal moves exist at each step.
class SnakeDifficulty {
  const SnakeDifficulty({
    required this.clearAtStart,
    required this.meanBranching,
    required this.forcedSteps,
    required this.solvableGreedily,
  });

  /// Arrows with a clear shot before any move, as a fraction of all arrows.
  final double clearAtStart;

  /// Mean number of arrows that could legally fire, per step of a greedy solve.
  final double meanBranching;

  /// Fraction of steps with exactly one legal move — the moments the player has
  /// to find the right arrow rather than tap any obvious one.
  final double forcedSteps;

  /// Whether repeatedly firing the first available arrow clears the board.
  final bool solvableGreedily;
}

/// Mean branching factor a level's board should aim for — how many arrows are
/// typically ready to fire. Lower means the player has to search harder.
///
/// Generation picks the candidate board closest to this, rather than pass/fail
/// gating, for two reasons found by measuring (`tool/analyze_snake_difficulty.dart`):
/// a conjunctive gate on both branching and openness turned out unachievable at
/// some levels — the least-branching seed isn't the most-closed one — and
/// "accept the first board over the bar" picked mediocre early seeds, which made
/// level 17 easier than level 12. Aiming at a target uses the whole spread and
/// keeps the curve monotonic.
///
/// Range is calibrated to what the generator can actually produce — currently
/// about 1.8 to 4.8 with medians near 3.0, per the spread the tool prints. Re-run
/// it after any generator change: making bodies fill better also made every board
/// denser and harder, which put the old easy end (4.8) out of reach and quietly
/// made level 4 harder than level 1. A target outside the achievable range just
/// yields the nearest extreme, which is a safe failure mode but wastes the curve.
/// The 2.3 floor is the measured limit of what the generator reaches at high
/// levels, not a design preference: asking for 2.0 just made every late level
/// miss by 0.3-0.9 with nothing to show for it.
/// Wanted mean branching for [level] — *lower is harder*, because a low
/// branching factor is what forces the player to plan ahead.
///
/// Two segments, and the second exists because of a tester report: the old curve
/// hit its 2.3 floor at level 34, so a player at level 50 was handed a board
/// config-identical to level 35. The same plateau bug as before, just further out.
///
/// The tail is bounded by measurement, not taste. `analyze_snake_difficulty`
/// samples all 768 seeds at 14x20 and prints the achievable spread: with the
/// level-45 `minLength` floor the lowest branching *any* seed reaches is ~2.1, so
/// 2.15 is the honest end of the ramp. An earlier attempt at 2.05 sat below that
/// and simply degraded to "closest available" — the silent flattening this whole
/// metric exists to prevent.
///
/// The slope is deliberately gentle (0.005/level) so the remaining headroom is
/// spread over ~30 levels rather than spent in five.
///
/// **The real conclusion is that 14x20 is close to exhausted as a difficulty
/// source.** This retune buys roughly two notches (measured: branching 2.5 ->
/// 2.2, forced steps 26% -> 32% between levels 35 and 60). Genuine depth past
/// here needs a bigger board — which needs zoom — or a new mechanic, not more
/// tuning. See docs/plans/arrow-maze-depth.md.
double snakeTargetBranchingForLevel(int level) {
  if (level <= 34) return (4.0 - level * 0.05).clamp(2.3, 4.0);
  return (2.3 - (level - 34) * 0.005).clamp(2.15, 2.3);
}

/// The snake-arrow board: holds the arrows and the rules for clearing them.
class SnakeBoard {
  SnakeBoard({required this.rows, required this.cols, required this.arrows});

  final int rows;
  final int cols;
  final List<SnakeArrow> arrows;

  /// The non-escaped arrow occupying [r],[c], or null.
  SnakeArrow? arrowAt(int r, int c) {
    for (final a in arrows) {
      if (!a.escaped && a.occupies(r, c)) return a;
    }
    return null;
  }

  /// True when the straight line ahead of [a]'s head, up to the board edge, is
  /// clear of *other* arrows. An arrow never blocks itself (its body trails the
  /// head as it leaves).
  bool isPathClear(SnakeArrow a) {
    var r = a.head.row + a.exitDir.dRow;
    var c = a.head.col + a.exitDir.dCol;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      final occ = arrowAt(r, c);
      if (occ != null && occ.id != a.id) return false;
      r += a.exitDir.dRow;
      c += a.exitDir.dCol;
    }
    return true;
  }

  bool get isSolved => arrows.every((a) => a.escaped);

  /// Arrows freed as a side effect of [arrow] leaving. Empty for a normal arrow.
  ///
  /// Already-escaped links are skipped, so clearing a bonus arrow late simply
  /// wastes the bonus — which is exactly the decision the mechanic exists to
  /// create.
  List<SnakeArrow> bonusFreedBy(SnakeArrow arrow) => [
        for (final a in arrows)
          if (!a.escaped && a.id != arrow.id && arrow.frees.contains(a.id)) a
      ];

  /// The bonus arrow, if this board has one.
  SnakeArrow? get bonusArrow =>
      arrows.where((a) => a.isBonus).cast<SnakeArrow?>().firstWhere(
            (a) => true,
            orElse: () => null,
          );

  /// Assigns one bonus arrow and the arrows it frees, deterministically.
  ///
  /// Both ends are chosen from arrows that are **blocked at the start**: a bonus
  /// arrow that could be tapped immediately would be a free opening move, and
  /// freeing arrows that were never stuck would be no gift at all. Does nothing
  /// unless there are enough blocked arrows to make it meaningful, so an unusually
  /// open board simply has no bonus rather than a token one.
  void assignBonus(Random rng, {required int freeCount}) {
    if (freeCount <= 0) return;
    final blocked = [for (final a in arrows) if (!isPathClear(a)) a];
    // The bonus arrow itself plus the arrows it frees, all from the blocked set.
    if (blocked.length < freeCount + 1) return;

    final pool = [...blocked]..shuffle(rng);
    final bonus = pool.removeLast();
    bonus.frees = [for (final a in pool.take(freeCount)) a.id];
  }

  /// The whole board as plain lists, so it can cross an isolate boundary.
  ///
  /// Generation is pure CPU work and, on the biggest boards, slow enough to be felt.
  /// Running it in a background isolate keeps the UI responsive, and an isolate
  /// result has to be sendable — hence ints and lists rather than object graphs.
  Map<String, dynamic> toJson() => {
        'rows': rows,
        'cols': cols,
        'arrows': [
          for (final a in arrows)
            {
              'id': a.id,
              'dir': a.exitDir.index,
              // Flattened r,c pairs: half the objects of a list of lists.
              'cells': [
                for (final c in a.cells) ...[c.row, c.col]
              ],
              if (a.frees.isNotEmpty) 'frees': a.frees,
            }
        ],
      };

  /// Rebuilds a board from [toJson]. Returns null if the payload is unusable, so a
  /// bad precache degrades to generating on the spot rather than throwing.
  static SnakeBoard? fromJson(Map<String, dynamic> json) {
    final rows = json['rows'], cols = json['cols'], raw = json['arrows'];
    if (rows is! int || cols is! int || raw is! List) return null;
    if (rows <= 0 || cols <= 0) return null;

    final arrows = <SnakeArrow>[];
    for (final entry in raw) {
      if (entry is! Map) return null;
      final id = entry['id'], dir = entry['dir'], flat = entry['cells'];
      if (id is! int || dir is! int || flat is! List) return null;
      if (dir < 0 || dir >= Dir.values.length) return null;
      if (flat.isEmpty || flat.length.isOdd) return null;
      final cells = <Cell>[];
      for (var i = 0; i < flat.length; i += 2) {
        final r = flat[i], c = flat[i + 1];
        if (r is! int || c is! int) return null;
        if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
        cells.add(Cell(r, c));
      }
      final arrow =
          SnakeArrow(id: id, cells: cells, exitDir: Dir.values[dir]);
      final frees = entry['frees'];
      if (frees is List) {
        for (final f in frees) {
          if (f is! int) return null;
        }
        arrow.frees = [for (final f in frees) f as int];
      }
      arrows.add(arrow);
    }
    if (arrows.isEmpty) return null;
    return SnakeBoard(rows: rows, cols: cols, arrows: arrows);
  }

  /// Which arrows have already left, for resuming after an interruption.
  ///
  /// The board itself regenerates from the level number, so all that has to be
  /// saved is the set of ids that escaped.
  Map<String, dynamic> escapedJson() => {
        'count': arrows.length,
        'escaped': [
          for (final a in arrows)
            if (a.escaped) a.id
        ],
      };

  /// Restores an escaped set written by [escapedJson]. Returns false and changes
  /// nothing if the save doesn't describe this board.
  ///
  /// **No winnability check, deliberately.** An earlier version verified the
  /// remaining arrows could still all escape, on the theory that a corrupt save
  /// might strand them. It cannot: if a board is solvable, removing arrows only
  /// ever *opens* paths, so every subset is solvable too. (Take the original
  /// solution order and skip the removed arrows — when each remaining arrow
  /// fires, the blockers present are a subset of the ones present originally, and
  /// its path was clear then.) Measured before deleting it: 600 random subsets
  /// across both arrow games, zero rejections. The invariant is asserted in
  /// `test/widget_test.dart` instead, which is where it belongs.
  bool applyEscapedJson(Map<String, dynamic> json) {
    if (json['count'] != arrows.length) return false;
    final raw = json['escaped'];
    if (raw is! List) return false;

    final ids = <int>{};
    final valid = {for (final a in arrows) a.id};
    for (final v in raw) {
      if (v is! int || !valid.contains(v)) return false;
      ids.add(v);
    }
    for (final a in arrows) {
      a.escaped = ids.contains(a.id);
    }
    return true;
  }

  /// Whether the player has cleared anything yet.
  bool get hasProgress => arrows.any((a) => a.escaped);

  /// Fraction of the grid covered by arrow cells. A patchy board looks unfinished
  /// even when it plays well, so generation scores this alongside difficulty.
  double get fillFraction =>
      arrows.fold<int>(0, (sum, a) => sum + a.cells.length) / (rows * cols);

  /// Size of the largest contiguous (4-connected) run of empty cells, as a
  /// fraction of the grid.
  ///
  /// Coverage alone is not enough to judge how a board *looks*: 86% full reads as
  /// finished when the gaps are scattered between snakes, and as broken when the
  /// same 14% pools into one corner. Generation scores this so it prefers boards
  /// whose emptiness is distributed.
  double get largestEmptyFraction {
    final occupied =
        List.generate(rows, (_) => List<bool>.filled(cols, false));
    for (final a in arrows) {
      for (final cell in a.cells) {
        occupied[cell.row][cell.col] = true;
      }
    }

    final seen = List.generate(rows, (_) => List<bool>.filled(cols, false));
    var largest = 0;
    for (var r0 = 0; r0 < rows; r0++) {
      for (var c0 = 0; c0 < cols; c0++) {
        if (occupied[r0][c0] || seen[r0][c0]) continue;
        var size = 0;
        final stack = <Cell>[Cell(r0, c0)];
        seen[r0][c0] = true;
        while (stack.isNotEmpty) {
          final cell = stack.removeLast();
          size++;
          for (final d in Dir.values) {
            final n = cell.step(d);
            if (n.row < 0 || n.row >= rows || n.col < 0 || n.col >= cols) {
              continue;
            }
            if (occupied[n.row][n.col] || seen[n.row][n.col]) continue;
            seen[n.row][n.col] = true;
            stack.add(n);
          }
        }
        if (size > largest) largest = size;
      }
    }
    return largest / (rows * cols);
  }

  /// Measures how hard this board plays by repeatedly firing the first arrow
  /// with a clear shot and recording how many were available at each step.
  ///
  /// Restores every `escaped` flag before returning, so a measured board is
  /// still fully playable — generation measures the board it then hands out.
  SnakeDifficulty measureDifficulty() {
    if (arrows.isEmpty) {
      return const SnakeDifficulty(
        clearAtStart: 0,
        meanBranching: 0,
        forcedSteps: 0,
        solvableGreedily: false,
      );
    }

    final clearAtStart = arrows.where(isPathClear).length / arrows.length;
    final branching = <int>[];
    var stuck = false;

    while (!isSolved) {
      final clear = arrows.where((a) => !a.escaped && isPathClear(a)).toList();
      if (clear.isEmpty) {
        stuck = true;
        break;
      }
      branching.add(clear.length);
      final fired = clear.first;
      fired.escaped = true;
      // Bonus arrows have to be simulated, or the metric would be measuring a
      // game nobody plays: a cascade removes several obstacles at once and
      // genuinely changes how the rest of the board opens up.
      for (final freed in bonusFreedBy(fired)) {
        freed.escaped = true;
      }
    }

    for (final a in arrows) {
      a.escaped = false;
    }

    if (branching.isEmpty) {
      return SnakeDifficulty(
        clearAtStart: clearAtStart,
        meanBranching: 0,
        forcedSteps: 0,
        solvableGreedily: !stuck,
      );
    }
    return SnakeDifficulty(
      clearAtStart: clearAtStart,
      meanBranching: branching.reduce((a, b) => a + b) / branching.length,
      forcedSteps: branching.where((c) => c == 1).length / branching.length,
      solvableGreedily: !stuck,
    );
  }

  /// Builds a guaranteed-solvable board for [level].
  ///
  /// Snakes are placed in reverse-solve order: each new snake gets a head whose
  /// straight path to the edge is currently clear, then a long body grown
  /// greedily into empty cells (never into the head's forward path). Removing
  /// the snakes in reverse placement order is therefore always a valid
  /// solution. We keep placing long snakes until the grid is filled to
  /// [SnakeLevelConfig.fillTarget], so higher levels are dense and tangled.
  /// Deterministic per level (seeded).
  ///
  /// Construction guarantees *solvable*, but says nothing about *hard* — which
  /// is how level 42 came to measure as the easiest board in the game. So a
  /// sequence of candidates is built and measured, and the one whose branching
  /// factor lands closest to [snakeTargetBranchingForLevel] is chosen.
  ///
  /// Still deterministic and retry-stable: the seed sequence derives from the
  /// level, so the same level always yields the same board.
  static SnakeBoard generate(int level) {
    final cfg = snakeConfigForLevel(level);
    final target = snakeTargetBranchingForLevel(level);

    SnakeBoard? best;
    var bestDistance = double.infinity;

    // Pool scaled by area: a 28x41 candidate costs ~12x a 14x20 one, so a fixed
    // 768 would mean a ten-second wait on the biggest boards.
    final poolSize = (maxGenerationAttempts * 280 / (cfg.rows * cfg.cols))
        .round()
        .clamp(96, maxGenerationAttempts);
    for (var attempt = 0; attempt < poolSize; attempt++) {
      final board = _build(cfg, _seedFor(level, attempt));
      if (board.arrows.isEmpty) continue;

      // Assign the bonus *before* measuring, so the difficulty gate scores the
      // board the player will actually get rather than a bonus-free version of it.
      board.assignBonus(Random(_seedFor(level, attempt) ^ 0x5EED),
          freeCount: cfg.bonusFrees);

      final d = board.measureDifficulty();
      // Reverse-solve order should prevent this.
      if (!d.solvableGreedily) continue;

      // Candidates vary a lot in appearance as well as difficulty, so score
      // three things. Coverage alone proved insufficient: one level looked
      // broken at 86% full because the gap pooled into a single corner, so the
      // largest contiguous hole is scored separately and weighted hardest.
      // Openness breaks ties, preferring fewer obvious first moves.
      final fillShortfall =
          (cfg.fillTarget - board.fillFraction).clamp(0.0, 1.0);
      final holeExcess =
          (board.largestEmptyFraction - tolerableHoleFraction).clamp(0.0, 1.0);
      // Priority order, not a blend: difficulty must land inside the tolerance,
      // and among boards that do, the fullest and least holey wins. Scoring these
      // as one weighted sum let a wide pool spend itself buying branching
      // precision from 0.1 to 0.0 — worth nothing to a player — while giving up
      // several points of coverage, which is plainly visible.
      final branchingMiss = (d.meanBranching - target).abs();
      final distance =
          (branchingMiss <= onTargetTolerance ? 0.0 : branchingMiss * 10) +
              fillShortfall * fillShortfallWeight +
              holeExcess * holeExcessWeight +
              d.clearAtStart * 0.1;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = board;
      }
      // Good enough on both axes — searching further can't improve the level
      // meaningfully, and generation blocks the UI while a level loads.
      if ((d.meanBranching - target).abs() <= onTargetTolerance &&
          fillShortfall <= fullEnoughShortfall &&
          holeExcess <= 0) {
        return board;
      }
    }

    return best ?? _build(cfg, _seedFor(level, 0));
  }

  /// Candidate boards tried per level before settling for the closest found.
  ///
  /// A wide pool is what lets a board satisfy difficulty *and* coverage at once
  /// instead of trading one against the other, and a candidate costs well under a
  /// millisecond. Generation does block level load, but a few hundred ms once per
  /// level is imperceptible next to a board that looks unfinished or plays flat —
  /// spend the budget on quality, not on being fast for nobody's benefit.
  static const maxGenerationAttempts = 768;

  /// How near [snakeTargetBranchingForLevel] counts as on-curve — in units of
  /// "arrows ready to fire". Boards inside it are treated as equally correct in
  /// difficulty, so coverage decides between them.
  ///
  /// Don't tighten this expecting better levels: at 0.1 it excluded boards that
  /// were on-curve for any playable purpose, and the search fell back to worse
  /// ones, costing several points of coverage and doubling hole size. A player
  /// cannot feel 2.4 versus 2.6 arrows-per-step; they can see a gap in the board.
  static const onTargetTolerance = 0.3;

  /// Coverage shortfall (against [SnakeLevelConfig.fillTarget]) still considered
  /// a full-looking board for the early exit.
  static const fullEnoughShortfall = 0.04;

  /// Weight on coverage shortfall when scoring candidates. Tuned so ~10% of bare
  /// grid costs about the same as being 0.25 off the branching target — enough
  /// that a patchy board loses to a full one of similar difficulty, not enough to
  /// override difficulty outright.
  static const fillShortfallWeight = 2.5;

  /// A single contiguous gap up to this fraction of the grid reads as ordinary
  /// spacing between snakes. Beyond it the board starts looking unfinished:
  /// measured examples ranged from 5% (looked fine) to 23% (a visible void).
  static const tolerableHoleFraction = 0.08;

  /// Weight on hole size beyond [tolerableHoleFraction]. Heavier than coverage,
  /// because where the emptiness sits matters more to the eye than how much of
  /// it there is.
  static const holeExcessWeight = 4.0;

  static int _seedFor(int level, int attempt) =>
      level * 100003 + 41 + attempt * 7919;

  /// One ungated candidate, exposed so difficulty tuning
  /// (`tool/analyze_snake_difficulty.dart`) and tests can see the spread the
  /// gate picks from. Play code should always use [generate].
  static SnakeBoard buildAttempt(int level, int attempt) =>
      _build(snakeConfigForLevel(level), _seedFor(level, attempt));

  static SnakeBoard _build(SnakeLevelConfig cfg, int seed) {
    final rng = Random(seed);
    final occupied = List.generate(
      cfg.rows,
      (_) => List<bool>.filled(cfg.cols, false),
    );
    final arrows = <SnakeArrow>[];
    var id = 0;
    var filled = 0;
    final target = (cfg.rows * cfg.cols * cfg.fillTarget).round();
    final maxAttempts = cfg.rows * cfg.cols * 20;

    bool inBounds(int r, int c) =>
        r >= 0 && r < cfg.rows && c >= 0 && c < cfg.cols;

    // Per-cell "is the ray in this direction clear to the edge?", rebuilt once
    // per placement instead of walked per candidate. Each table is filled from
    // the edge inwards, so a cell's answer is its neighbour's answer plus one
    // occupancy check — O(cells) rather than O(cells x ray length).
    final rayClear = List.generate(
      Dir.values.length,
      (_) => List.generate(cfg.rows, (_) => List<bool>.filled(cfg.cols, false)),
    );
    // Summed-area table of empty cells, so a candidate's neighbourhood emptiness
    // is a constant-time lookup rather than a 5x5 scan. sat[r+1][c+1] holds the
    // count of empty cells in the rectangle above-left of (r, c) inclusive.
    final sat = List.generate(
      cfg.rows + 1,
      (_) => List<int>.filled(cfg.cols + 1, 0),
    );

    void refreshTables() {
      final up = rayClear[Dir.up.index];
      final down = rayClear[Dir.down.index];
      final left = rayClear[Dir.left.index];
      final right = rayClear[Dir.right.index];
      for (var c = 0; c < cfg.cols; c++) {
        for (var r = 0; r < cfg.rows; r++) {
          up[r][c] = r == 0 || (!occupied[r - 1][c] && up[r - 1][c]);
        }
        for (var r = cfg.rows - 1; r >= 0; r--) {
          down[r][c] = r == cfg.rows - 1 ||
              (!occupied[r + 1][c] && down[r + 1][c]);
        }
      }
      for (var r = 0; r < cfg.rows; r++) {
        for (var c = 0; c < cfg.cols; c++) {
          left[r][c] = c == 0 || (!occupied[r][c - 1] && left[r][c - 1]);
        }
        for (var c = cfg.cols - 1; c >= 0; c--) {
          right[r][c] = c == cfg.cols - 1 ||
              (!occupied[r][c + 1] && right[r][c + 1]);
        }
        for (var c = 0; c < cfg.cols; c++) {
          sat[r + 1][c + 1] = sat[r][c + 1] +
              sat[r + 1][c] -
              sat[r][c] +
              (occupied[r][c] ? 0 : 1);
        }
      }
    }

    /// Empty cells within [radius] of (r, c), clipped to the board.
    int emptyNear(int r, int c, int radius) {
      final r0 = (r - radius).clamp(0, cfg.rows);
      final r1 = (r + radius + 1).clamp(0, cfg.rows);
      final c0 = (c - radius).clamp(0, cfg.cols);
      final c1 = (c + radius + 1).clamp(0, cfg.cols);
      return sat[r1][c1] - sat[r0][c1] - sat[r1][c0] + sat[r0][c0];
    }

    // One placement sweep, accepting snakes of at least [minLength] cells.
    // Placement order is the reverse of solve order, and every snake still needs
    // a clear ray at the moment it is placed, so appending more snakes can never
    // break solvability — a later snake is always removed earlier.
    // Head candidates: an empty cell + exit direction whose forward ray is
    // clear, and which can grow at least one body cell off the exit lane.
    List<List<int>> enumerateHeads() {
      final heads = <List<int>>[];
      for (var r = 0; r < cfg.rows; r++) {
        for (var c = 0; c < cfg.cols; c++) {
          if (occupied[r][c]) continue;
          for (var d = 0; d < Dir.values.length; d++) {
            final dir = Dir.values[d];
            if (!rayClear[d][r][c]) continue;
            var growable = false;
            for (final nd in Dir.values) {
              if (nd == dir) continue; // first step can't go up the exit lane
              final nr = r + nd.dRow;
              final nc = c + nd.dCol;
              if (inBounds(nr, nc) && !occupied[nr][nc]) {
                growable = true;
                break;
              }
            }
            if (growable) heads.add([r, c, d]);
          }
        }
      }
      return heads;
    }

    // Big boards must place their *interior* heads first; small ones must not.
    final interiorFirst = cfg.cols >= 9;

    void placePass(int minLength) {
      var attempts = 0;
      // The board only changes when a snake is committed, so the tables and the
      // candidate list stay valid across failed attempts. Rebuilding them every
      // attempt instead made generation ~10x slower for identical output, since
      // most of the up-to-`maxAttempts` iterations end in a too-short body.
      var heads = <List<int>>[];
      var stale = true;

      while (filled < target && attempts < maxAttempts) {
        attempts++;

        if (stale) {
          refreshTables();
          heads = enumerateHeads();
          stale = false;
        }
        if (heads.isEmpty) break;

        // Prefer a head in the emptiest neighbourhood. Filling sparse areas first
        // stops a region from being walled off by its neighbours: once a void is
        // enclosed, every ray out of it is blocked, so no further snake can ever
        // be placed inside it — that is how a single hole reached 23% of the grid
        // while the rest of the board was dense.
        int rayLen(List<int> h) {
          final d = Dir.values[h[2]];
          return switch (d) {
            Dir.up => h[0],
            Dir.down => cfg.rows - 1 - h[0],
            Dir.left => h[1],
            Dir.right => cfg.cols - 1 - h[1],
          };
        }

        var bestRay = -1;
        var bestEmpty = -1;
        final sparseHeads = <List<int>>[];
        for (final h in heads) {
          final em = emptyNear(h[0], h[1], 2);
          if (interiorFirst) {
            // Ray length first: spend the hard interior placements while the
            // board is still empty enough for them to succeed.
            final rl = rayLen(h);
            if (rl > bestRay || (rl == bestRay && em > bestEmpty)) {
              bestRay = rl;
              bestEmpty = em;
              sparseHeads.clear();
            }
            if (rl == bestRay && em == bestEmpty) sparseHeads.add(h);
          } else {
            // Small boards: emptiness alone, exactly as before. Adding a ray
            // tiebreak here narrowed the candidate set and cost level 1 two
            // points of fill for no benefit — a 6x9 board has no interior to
            // speak of, so there is nothing for the ordering to fix.
            if (em > bestEmpty) {
              bestEmpty = em;
              sparseHeads.clear();
            }
            if (em == bestEmpty) sparseHeads.add(h);
          }
        }
        final pick = sparseHeads[rng.nextInt(sparseHeads.length)];
        final headCell = Cell(pick[0], pick[1]);
        final dir = Dir.values[pick[2]];

        // Cells in front of the head — the body must never enter these.
        final forward = <Cell>{};
        var fr = headCell.row + dir.dRow;
        var fc = headCell.col + dir.dCol;
        while (inBounds(fr, fc)) {
          forward.add(Cell(fr, fc));
          fr += dir.dRow;
          fc += dir.dCol;
        }

        // Grow a long winding body greedily.
        final path = <Cell>[headCell];
        final inPath = <Cell>{headCell};
        var cur = headCell;
        while (path.length < cfg.maxLength) {
          final options = <Cell>[];
          for (final nd in Dir.values) {
            final n = cur.step(nd);
            if (!inBounds(n.row, n.col)) continue;
            if (occupied[n.row][n.col]) continue;
            if (inPath.contains(n)) continue;
            if (forward.contains(n)) continue;
            options.add(n);
          }
          if (options.isEmpty) break;
          // Warnsdorff-style: step into the most constrained cell available, so
          // the body consumes dead ends as it goes instead of walking past them
          // and stranding pockets too small for any later snake to use. Purely
          // random steps left high levels ~72% full and visibly patchy.
          var fewest = 99;
          final mostConstrained = <Cell>[];
          for (final o in options) {
            var free = 0;
            for (final nd in Dir.values) {
              final m = o.step(nd);
              if (!inBounds(m.row, m.col)) continue;
              if (occupied[m.row][m.col]) continue;
              if (inPath.contains(m)) continue;
              if (forward.contains(m)) continue;
              free++;
            }
            if (free < fewest) {
              fewest = free;
              mostConstrained.clear();
            }
            if (free == fewest) mostConstrained.add(o);
          }
          cur = mostConstrained[rng.nextInt(mostConstrained.length)];
          path.add(cur);
          inPath.add(cur);
        }

        if (path.length < minLength) {
          // The board is untouched, so this head will fail again for as long as
          // it stays valid. Drop it rather than letting the random pick keep
          // rediscovering the same dead end.
          heads.remove(pick);
          continue;
        }

        for (final cell in path) {
          occupied[cell.row][cell.col] = true;
        }
        filled += path.length;
        arrows.add(
          SnakeArrow(
            id: id++,
            cells: path.reversed.toList(), // store tail -> head
            exitDir: dir,
          ),
        );
        stale = true;
      }
    }

    placePass(cfg.minLength);

    // Two ways of back-filling leftover gaps were tried and rejected; don't
    // reach for either again:
    //
    // - A second placement pass with a lower length floor does fill the board,
    //   but a snake placed last is removed *first*, so its ray is still clear at
    //   game start. Every gap-filler becomes a free opening move: level 42 went
    //   from 2.8 to 3.7 mean branching while getting fuller. Fill bought with
    //   easiness is not worth having.
    // - Growing existing snakes' tails adds no new move, but snakes fire in
    //   reverse placement order, so a snake may only grow into cells lying on no
    //   later snake's forward ray. The union of ~20 rays covers most of the
    //   board, and measured growth was exactly zero cells.
    //
    // Fill therefore has to come from placing bodies well in the first place —
    // hence the Warnsdorff-style step above.
    return SnakeBoard(rows: cfg.rows, cols: cfg.cols, arrows: arrows);
  }
}
