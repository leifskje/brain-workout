import 'dart:math';

/// A direction an arrow can point / travel in, with its grid step.
enum Direction {
  up(-1, 0),
  down(1, 0),
  left(0, -1),
  right(0, 1);

  const Direction(this.dRow, this.dCol);

  final int dRow;
  final int dCol;
}

/// A single arrow on the board.
class ArrowPiece {
  ArrowPiece({
    required this.id,
    required this.row,
    required this.col,
    required this.dir,
  });

  final int id;
  final int row;
  final int col;
  final Direction dir;

  /// Set once the arrow has left the board.
  bool escaped = false;
}

/// Per-level difficulty settings.
class ArrowLevelConfig {
  const ArrowLevelConfig({
    required this.rows,
    required this.cols,
    required this.arrowCount,
    required this.hearts,
  });

  final int rows;
  final int cols;
  final int arrowCount;
  final int hearts;
}

/// First level built by the dense generator.
///
/// Everything below this is frozen: players have progress (and possibly a
/// half-finished autosaved board) on those levels, so both [configForLevel] and
/// [ArrowBoard.generate] must keep returning byte-identical boards there. Same
/// precedent as the `preferLongRays` gate that shipped before it.
const arrowDenseFirstLevel = 41;

/// How much of the grid is covered at [level], for the dense generator only.
///
/// Level 41 starts essentially where the old curve left it — the tap count does
/// not jump at the boundary — and climbs to a completely full board at level 90.
///
/// 0.46 rather than 0.45, which is load-bearing rather than fussy.
/// `ArrowBoard.applyEscapedJson` refuses a save whose arrow count does not match
/// the board, and that refusal is what makes changing these levels safe for a
/// player with one in progress: the save is dropped, not misapplied. At 0.45
/// level 41 would keep exactly the 88 arrows the sparse generator gave it, so an
/// old save would pass the count check and mark ids 0..87 escaped on a board
/// where those ids are different arrows. One tick of density gives it 90 and the
/// guard covers every changed level.
///
/// The ramp is gentle on purpose and it is *not* where the difficulty comes
/// from. Measured over 64 seeds at 14x14, the achievable branching floor only
/// moves from 2.8 at 46% fill to 2.0 at 100% — a full board is barely harder
/// than a half-empty one built the same way, and it costs 108 extra taps.
/// Fill buys how the board *reads* ("there is still a lot of air in the board"),
/// [arrowTargetBranchingForLevel] buys how it plays.
double arrowFillForLevel(int level) =>
    (0.46 + (level - arrowDenseFirstLevel) * 0.011).clamp(0.46, 1.0);

/// Grows the board size and arrow density as the level increases.
ArrowLevelConfig configForLevel(int level) {
  // Grid and density both used to stop at level 13, then at level 21 with a 9x9
  // board — after which every level was config-identical, the same plateau Arrow
  // Maze was rescued from. Single-cell arrows stay legible far longer than Arrow
  // Maze's snakes (9x9 is ~40dp per cell on a phone against Arrow Maze's 23dp),
  // and past 9 the board is zoomable exactly as Arrow Maze's is, so the ladder
  // now runs to 14x14 at level 41 — ~24dp unzoomed, which is the same bargain
  // Arrow Maze already makes.
  final size = (4 + (level - 1) ~/ 4).clamp(4, 14);
  final maxCells = size * size;
  // Density has to *fall* as the board grows, which is the opposite of the
  // obvious move and was measured rather than guessed.
  //
  // A single-cell arrow is legal only when its whole ray to the edge is empty,
  // so on a dense board only pieces already at the rim qualify. On 14x14 the
  // count of *interior* legal moves goes 5.3 at density 0.45, 2.3 at 0.50, 0.1
  // at 0.55, and zero from 0.60 up. At 0.68 every legal move sits on the
  // perimeter: the board can only be peeled from the outside in, there is
  // nothing to plan, and zooming into the middle shows the player no move they
  // can make — which defeats the zoom the big boards exist for.
  //
  // "Fewer legal opening moves" was the metric being optimised and it rose while
  // the game got more mechanical. Same trap as the difficulty plateau in
  // docs/plans/arrow-maze-depth.md: count what makes it feel hard, not what is
  // easy to count.
  // Measured, not derived: these are the highest densities per size that still
  // leave a handful of interior legal moves, chosen so the arrow *count* never
  // drops as the board grows (55, 55, 57, 65, 76, 88 from 9x9 to 14x14).
  //
  // All of that describes the *sparse* generator, and every word of it was true
  // of it. It is not true of the geometry: see [ArrowBoard.generate], which
  // fills the grid completely and still opens with ~3% of arrows ready to fire.
  // From [arrowDenseFirstLevel] the density above is replaced by
  // [arrowFillForLevel].
  const bigBoardDensity = {10: 0.55, 11: 0.47, 12: 0.45, 13: 0.45, 14: 0.45};
  final density = level >= arrowDenseFirstLevel
      ? arrowFillForLevel(level)
      : size <= 9
          ? (0.35 + (level - 1) * 0.02).clamp(0.35, 0.68)
          : (bigBoardDensity[size] ?? 0.45);
  // The sparse generator's "- 2" left room to never quite fill the grid; the
  // dense one is allowed the last two cells. Gated so the old levels keep their
  // exact arrow counts.
  final count = (maxCells * density)
      .round()
      .clamp(4, level >= arrowDenseFirstLevel ? maxCells : maxCells - 2);
  return ArrowLevelConfig(
    rows: size,
    cols: size,
    arrowCount: count,
    hearts: _heartsForArrowCount(count),
  );
}

/// Hearts scale with how much tapping a level asks for, not with how hard it is.
///
/// A slip costs a heart, so five hearts on a 196-arrow board demands more than
/// twice the per-tap accuracy of five on an 88-arrow one — which would deliver
/// part of the difficulty ramp as "don't misjudge a ray", the wrong axis for an
/// audience reading a 24dp grid. Difficulty belongs in the branching target.
///
/// Losing costs nothing but the restart of a long board, and the star bar is
/// unmoved: three stars still means a flawless run, two means at most two
/// mistakes, so a more forgiving board is not an easier one to score well on.
///
/// Every level up to 40 tops out at 88 arrows, so all of them keep their five.
int _heartsForArrowCount(int count) =>
    count <= 100 ? 5 : (5 + (count - 100) ~/ 32).clamp(5, 8);

/// How hard a board plays, measured rather than assumed.
///
/// Mirrors `SnakeDifficulty`, and for the same reason: board size and density
/// are poor proxies. Arrow Escape level 100 is 14x14 and measured *easier* than
/// level 20 on 8x8 — 27 of its 88 arrows could fire on the first tap, so there
/// was nothing to plan.
class ArrowDifficulty {
  const ArrowDifficulty({
    required this.clearAtStart,
    required this.meanBranching,
    required this.forcedSteps,
    required this.interiorSteps,
    required this.solvableGreedily,
  });

  /// Arrows with a clear shot before any move, as a fraction of all arrows.
  final double clearAtStart;

  /// Mean number of arrows that could legally fire, per step of a greedy solve.
  final double meanBranching;

  /// Fraction of steps with exactly one legal move.
  final double forcedSteps;

  /// Fraction of steps where at least one legal move sits two or more cells in
  /// from the rim.
  ///
  /// A completely full board can only open at its edge — the first tap is
  /// necessarily a rim arrow — so "interior moves exist at the start" is the
  /// wrong question to ask of it. What matters is whether the *middle* of the
  /// board is ever playable, because that is what zooming in is for.
  final double interiorSteps;

  /// Whether repeatedly firing whatever is clear empties the board.
  ///
  /// This is an exact solver, not a heuristic: arrows are only ever removed, so
  /// removing one can never block another. Firing order therefore cannot change
  /// whether the board clears, only the branching counts along the way.
  final bool solvableGreedily;
}

/// Wanted mean branching for [level] — *lower is harder*, because few legal
/// moves is what forces the player to look for one.
///
/// Calibrated against what the generator actually produces; run
/// `dart run tool/analyze_arrow_escape_difficulty.dart`, which prints the
/// spread over the whole candidate pool per level. A target outside that spread
/// silently degrades to "the closest board found", which is exactly the
/// flattening this metric exists to catch.
///
/// Both ends are set by the measured spread, not by taste. Across 96 candidates
/// the pool runs about 2.0 to 8.0 with medians near 4.0, so:
///
/// - The ramp starts at 6.5, not at the 10.4 the last sparse board measures.
///   Matching level 40 exactly would mean asking for a board near the very top
///   of what the pool offers, and an earlier attempt at 7.5 did just that: level
///   50 could not find one and quietly fell back to "closest found", 0.43 off —
///   the silent flattening this whole metric exists to catch. Level 41 is where
///   the board becomes zoomable and is already a change of chapter; it takes the
///   step.
/// - The tail bottoms out at 2.3. The pool's floor is 1.9-2.0 at every fill, so
///   2.3 is reachable with candidates to spare while 2.0 would be asking for the
///   single best of 96 every time.
///
/// The slope is gentle past level 90 (where fill saturates) so the last of the
/// headroom is spread over a hundred levels rather than spent in ten. Fill and
/// branching between them mean no two level numbers below ~260 are
/// configuration-identical.
double arrowTargetBranchingForLevel(int level) {
  if (level <= 90) {
    return (6.5 - (level - arrowDenseFirstLevel) * 0.064).clamp(3.3, 6.5);
  }
  return (3.3 - (level - 90) * 0.006).clamp(2.3, 3.3);
}

/// The arrow board: holds pieces and the rules for moving them.
class ArrowBoard {
  ArrowBoard({required this.rows, required this.cols, required this.pieces});

  final int rows;
  final int cols;
  final List<ArrowPiece> pieces;

  /// The non-escaped piece occupying [r],[c], or null.
  ArrowPiece? pieceAt(int r, int c) {
    for (final p in pieces) {
      if (!p.escaped && p.row == r && p.col == c) return p;
    }
    return null;
  }

  /// True when every cell between [p] and the board edge (in its direction)
  /// is empty, so the arrow can fly off the board.
  bool isPathClear(ArrowPiece p) {
    var r = p.row + p.dir.dRow;
    var c = p.col + p.dir.dCol;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      if (pieceAt(r, c) != null) return false;
      r += p.dir.dRow;
      c += p.dir.dCol;
    }
    return true;
  }

  bool get isSolved => pieces.every((p) => p.escaped);

  /// Which arrows have already left, for resuming after an interruption. Only the
  /// escaped ids need saving — the board regenerates from the level number.
  Map<String, dynamic> escapedJson() => {
        'count': pieces.length,
        'escaped': [
          for (final p in pieces)
            if (p.escaped) p.id
        ],
      };

  /// Restores an escaped set written by [escapedJson]. Returns false and changes
  /// nothing if the save doesn't describe this board.
  ///
  /// No winnability check — see the note on the Arrow Maze equivalent. Removing
  /// arrows from a solvable board can only open paths, so every subset is
  /// solvable and such a check could never reject anything. The invariant is
  /// asserted in the tests instead.
  bool applyEscapedJson(Map<String, dynamic> json) {
    if (json['count'] != pieces.length) return false;
    final raw = json['escaped'];
    if (raw is! List) return false;

    final ids = <int>{};
    final valid = {for (final p in pieces) p.id};
    for (final v in raw) {
      if (v is! int || !valid.contains(v)) return false;
      ids.add(v);
    }
    for (final p in pieces) {
      p.escaped = ids.contains(p.id);
    }
    return true;
  }

  /// Whether the player has cleared anything yet.
  bool get hasProgress => pieces.any((p) => p.escaped);

  /// Measures how hard this board plays, by repeatedly firing whatever is clear
  /// and recording how many arrows were available at each step.
  ///
  /// The longest chain in the blocking relation: how many rounds of *forced*
  /// reasoning the board demands, as opposed to how few moves are visible at
  /// each step.
  ///
  /// An arrow can only fire once everything on its ray has gone, so
  /// `depth(a) = 1 + max(depth of the arrows on a's ray)`. Mean branching cannot
  /// tell a long forced spine from many short ones, and the spine is the thing a
  /// player experiences as structure — the axis CLAUDE.md lists as unmeasured
  /// for both arrow games.
  ///
  /// **Read it with the monotonicity caveat.** Arrows are only ever removed, so
  /// any legal move is always correct and firing whatever is clear solves the
  /// board exactly. A deep chain therefore does *not* mean the player plans that
  /// far ahead — it unfolds as they tap. Both this and branching describe the
  /// solution's shape, not the player's effort, which is why filling the board
  /// took this from 7 to 38 without the game feeling harder. Diagnostic, not a
  /// tuning target: nothing in generation selects on it.
  ///
  /// Deliberately not part of [ArrowDifficulty] — that drives candidate
  /// selection, and adding a field there would change which boards are chosen.
  int longestBlockingChain() {
    final depths = <int, int>{};
    int depthOf(ArrowPiece p) {
      final known = depths[p.id];
      if (known != null) return known;
      depths[p.id] = 1; // a solvable board has no cycles; this just bounds one
      var deepest = 0;
      var r = p.row + p.dir.dRow;
      var c = p.col + p.dir.dCol;
      while (r >= 0 && r < rows && c >= 0 && c < cols) {
        final blocker = pieceAt(r, c);
        if (blocker != null) {
          final d = depthOf(blocker);
          if (d > deepest) deepest = d;
        }
        r += p.dir.dRow;
        c += p.dir.dCol;
      }
      return depths[p.id] = deepest + 1;
    }

    var longest = 0;
    for (final p in pieces) {
      if (p.escaped) continue;
      final d = depthOf(p);
      if (d > longest) longest = d;
    }
    return longest;
  }

  /// Leaves every `escaped` flag alone — the simulation runs on a private grid —
  /// so a measured board is still exactly the board the player gets.
  ///
  /// Costs O(cells * (rows + cols)) rather than the obvious O(cells^3), because
  /// of the characterisation in [_Frontier]: the legal moves are always among
  /// the edge-most live cells of each row and column.
  ArrowDifficulty measureDifficulty() {
    final live = [
      for (final p in pieces)
        if (!p.escaped) p
    ];
    if (live.isEmpty) {
      return const ArrowDifficulty(
        clearAtStart: 0,
        meanBranching: 0,
        forcedSteps: 0,
        interiorSteps: 0,
        solvableGreedily: true,
      );
    }

    final frontier = _Frontier(rows, cols);
    final dirAt = List.generate(rows, (_) => List<Direction?>.filled(cols, null));
    for (final p in live) {
      frontier.setLive(p.row, p.col);
      dirAt[p.row][p.col] = p.dir;
    }
    frontier.rebuild();

    final branching = <int>[];
    var interiorSteps = 0;
    var clearAtStart = 0;
    var remaining = live.length;
    var stuck = false;

    while (remaining > 0) {
      var count = 0;
      var fireRow = -1, fireCol = -1;
      var hasInterior = false;
      frontier.forEachCandidate((r, c, dir, _) {
        if (dirAt[r][c] != dir) return;
        count++;
        if (fireRow < 0) {
          fireRow = r;
          fireCol = c;
        }
        final ring = [r, c, rows - 1 - r, cols - 1 - c]
            .reduce((a, b) => a < b ? a : b);
        if (ring >= 2) hasInterior = true;
      });
      if (count == 0) {
        stuck = true;
        break;
      }
      if (branching.isEmpty) clearAtStart = count;
      branching.add(count);
      if (hasInterior) interiorSteps++;
      dirAt[fireRow][fireCol] = null;
      frontier.remove(fireRow, fireCol);
      remaining--;
    }

    return ArrowDifficulty(
      clearAtStart: clearAtStart / live.length,
      meanBranching: branching.reduce((a, b) => a + b) / branching.length,
      forcedSteps: branching.where((c) => c == 1).length / branching.length,
      interiorSteps: interiorSteps / branching.length,
      solvableGreedily: !stuck,
    );
  }

  /// Builds a guaranteed-solvable board for [level].
  ///
  /// Two generators, split at [arrowDenseFirstLevel]. Below it, the original
  /// sparse one, kept untouched so levels players have already reached (and may
  /// have autosaved mid-board) regenerate identically. At and above it, the
  /// dense one — see [_buildDense] — with a pool of candidates measured by
  /// [measureDifficulty] and the one closest to
  /// [arrowTargetBranchingForLevel] kept.
  ///
  /// The pool is what stops "solvable" being mistaken for "hard": construction
  /// guarantees only the first. Deterministic per level either way, so retrying
  /// gives the same board.
  static ArrowBoard generate(int level) {
    if (level < arrowDenseFirstLevel) return _buildSparse(level);

    final cfg = configForLevel(level);
    final target = arrowTargetBranchingForLevel(level);
    ArrowBoard? best;
    var bestMiss = double.infinity;

    for (var attempt = 0; attempt < generationPoolSize; attempt++) {
      final board = _buildDense(cfg, _seedFor(level, attempt));
      final d = board.measureDifficulty();
      // Construction guarantees this; belt and braces.
      if (!d.solvableGreedily) continue;
      final miss = (d.meanBranching - target).abs();
      // Fill is fixed by the config here, so unlike Arrow Maze there is no
      // second axis to trade against difficulty — the closest board simply wins.
      if (miss < bestMiss) {
        bestMiss = miss;
        best = board;
      }
      // Nobody can feel 3.2 arrows-per-step against 3.4; stop paying for it.
      if (miss <= onTargetTolerance) return board;
    }

    return best ?? _buildDense(cfg, _seedFor(level, 0));
  }

  /// Candidate boards measured per level before settling for the closest found.
  ///
  /// A candidate costs ~0.1ms even on a full 14x14 grid — the whole pool is
  /// ~30ms, against Arrow Maze's ~400ms — so this is set by what the curve
  /// needs, not by the budget. 96 was not enough: the branching distribution is
  /// right-skewed, so the top of the ramp (levels 41-50, target ~6) lives in a
  /// thin tail and level 45 missed by 0.40, silently taking the closest board
  /// instead. Generation blocks the UI for this game — there is no prefetch
  /// isolate as Arrow Maze has — which is what keeps it this side of a thousand.
  static const generationPoolSize = 320;

  /// How near [arrowTargetBranchingForLevel] counts as on-curve, in units of
  /// "arrows ready to fire".
  static const onTargetTolerance = 0.25;

  static int _seedFor(int level, int attempt) =>
      level * 100003 + 41 + attempt * 7919;

  /// One ungated candidate, exposed so difficulty tuning
  /// (`tool/analyze_arrow_escape_difficulty.dart`) and tests can see the spread
  /// the pool picks from. Play code should always use [generate].
  static ArrowBoard buildAttempt(int level, int attempt) =>
      _buildDense(configForLevel(level), _seedFor(level, attempt));

  /// Fills the grid completely (or to [ArrowLevelConfig.arrowCount]) with a
  /// guaranteed-solvable arrangement.
  ///
  /// Runs the game *forwards* from a full board rather than placing arrows onto
  /// an empty one: repeatedly take a cell that has some clear ray, give it that
  /// direction, and remove it. The removal order is by construction a valid
  /// solution, and unlike the sparse generator it can never paint itself into a
  /// corner — a non-empty board always has a topmost live cell in some column,
  /// and that cell can always be pointed up. So 100% coverage is not something
  /// the generator has to be lucky to reach; it is where it always lands.
  ///
  /// The direction is the *longest* clear ray available, chosen uniformly among
  /// ties. That one choice is the whole difficulty mechanism. A long ray depends
  /// on many cells, so the arrow it belongs to can only fire late, which keeps
  /// the board interlocked; pointing every arrow at its nearest edge instead
  /// produces the same 100% fill at mean branching ~27 (measured), i.e. a full
  /// board that plays itself. The random tiebreak is what gives the candidate
  /// pool its spread: 2.0 to 11.3 mean branching over 64 seeds at 14x14.
  ///
  /// Holes, where the level is not yet at full fill, are punched at random
  /// before the run. Any subset of a solvable board is solvable, and starting
  /// from fewer cells cannot break the argument above.
  static ArrowBoard _buildDense(ArrowLevelConfig cfg, int seed) {
    final rng = Random(seed);
    final frontier = _Frontier(cfg.rows, cfg.cols);
    final cells = [for (var i = 0; i < cfg.rows * cfg.cols; i++) i]
      ..shuffle(rng);
    for (final i in cells.take(cfg.arrowCount)) {
      frontier.setLive(i ~/ cfg.cols, i % cfg.cols);
    }
    frontier.rebuild();

    // [row, col, directionIndex], in the order the arrows leave the board.
    final fired = <List<int>>[];
    for (var n = 0; n < cfg.arrowCount; n++) {
      var bestRay = -1, bestRow = -1, bestCol = -1, bestDir = 0, ties = 0;
      frontier.forEachCandidate((r, c, dir, ray) {
        if (ray > bestRay) {
          bestRay = ray;
          bestRow = r;
          bestCol = c;
          bestDir = dir.index;
          ties = 1;
        } else if (ray == bestRay) {
          ties++;
          // Reservoir sampling: every longest-ray candidate equally likely,
          // without building a list on the hot path.
          if (rng.nextInt(ties) == 0) {
            bestRow = r;
            bestCol = c;
            bestDir = dir.index;
          }
        }
      });
      if (bestRow < 0) break; // unreachable; see the doc comment.
      fired.add([bestRow, bestCol, bestDir]);
      frontier.remove(bestRow, bestCol);
    }

    // `pieces.reversed` is the documented solve order for this game, so store
    // the firing order backwards.
    final pieces = <ArrowPiece>[];
    for (var i = fired.length - 1; i >= 0; i--) {
      pieces.add(ArrowPiece(
        id: pieces.length,
        row: fired[i][0],
        col: fired[i][1],
        dir: Direction.values[fired[i][2]],
      ));
    }
    return ArrowBoard(rows: cfg.rows, cols: cfg.cols, pieces: pieces);
  }

  /// The original generator, for levels below [arrowDenseFirstLevel].
  ///
  /// Pieces are placed in reverse-solve order: each new arrow is only placed
  /// where its straight path to the edge is currently clear of the arrows
  /// already placed. Removing the arrows in the reverse of their placement
  /// order is therefore always a valid solution. Deterministic per level.
  ///
  /// It cannot fill a grid — it runs out of legal placements well short of the
  /// asked-for density — which is why it does not run the high levels any more.
  /// It stays because those levels are frozen, not because it is better.
  static ArrowBoard _buildSparse(int level) {
    final cfg = configForLevel(level);
    final rng = Random(level * 7919 + 17);
    final occupied =
        List.generate(cfg.rows, (_) => List<bool>.filled(cfg.cols, false));
    final pieces = <ArrowPiece>[];
    var id = 0;

    // Past the old 9x9 ceiling, prefer placements with a *long* ray. A piece is
    // only legal while its whole path to the edge is clear, so success runs at
    // roughly (1-density)^rayLength: short-ray placements near an edge stay legal
    // almost to the end, while an interior piece pointing across the board is
    // impossible once the board fills. Picking uniformly therefore spends the
    // empty board on easy placements and then cannot place the hard ones — which
    // is why a 14x14 board reached only 0.53 density against the 0.68 asked for.
    //
    // This is the same fix, and the same reasoning, as Arrow Maze's "place
    // long-ray heads first" (see CLAUDE.md). Gated on size so every board up to
    // level 24 is byte-identical to what players already have; the small boards
    // do not need it and re-rolling them would shift a curve that is already
    // tuned.
    final preferLongRays = cfg.rows > 9;

    while (pieces.length < cfg.arrowCount) {
      // [row, col, directionIndex] placements that keep the board solvable.
      final candidates = <List<int>>[];
      final weights = <int>[];
      var totalWeight = 0;
      for (var r = 0; r < cfg.rows; r++) {
        for (var c = 0; c < cfg.cols; c++) {
          if (occupied[r][c]) continue;
          for (var d = 0; d < Direction.values.length; d++) {
            final dir = Direction.values[d];
            if (!_rayClear(occupied, r, c, dir, cfg)) continue;
            candidates.add([r, c, d]);
            if (preferLongRays) {
              final w = _rayLength(r, c, dir, cfg);
              weights.add(w);
              totalWeight += w;
            }
          }
        }
      }
      if (candidates.isEmpty) break;

      List<int> pick;
      if (preferLongRays && totalWeight > 0) {
        // Weighted by ray length rather than simply taking the longest, so
        // boards still vary instead of all growing the same skeleton.
        var target = rng.nextInt(totalWeight);
        var chosen = candidates.length - 1;
        for (var i = 0; i < weights.length; i++) {
          target -= weights[i];
          if (target < 0) {
            chosen = i;
            break;
          }
        }
        pick = candidates[chosen];
      } else {
        pick = candidates[rng.nextInt(candidates.length)];
      }
      occupied[pick[0]][pick[1]] = true;
      pieces.add(ArrowPiece(
        id: id++,
        row: pick[0],
        col: pick[1],
        dir: Direction.values[pick[2]],
      ));
    }

    return ArrowBoard(rows: cfg.rows, cols: cfg.cols, pieces: pieces);
  }

  /// How many cells lie between (r, c) and the edge along [dir] — the length of
  /// the path that has to stay clear for this placement to remain legal.
  static int _rayLength(int r, int c, Direction dir, ArrowLevelConfig cfg) {
    var n = 0;
    var rr = r + dir.dRow, cc = c + dir.dCol;
    while (rr >= 0 && rr < cfg.rows && cc >= 0 && cc < cfg.cols) {
      n++;
      rr += dir.dRow;
      cc += dir.dCol;
    }
    return n;
  }

  static bool _rayClear(
    List<List<bool>> occupied,
    int r,
    int c,
    Direction dir,
    ArrowLevelConfig cfg,
  ) {
    var rr = r + dir.dRow;
    var cc = c + dir.dCol;
    while (rr >= 0 && rr < cfg.rows && cc >= 0 && cc < cfg.cols) {
      if (occupied[rr][cc]) return false;
      rr += dir.dRow;
      cc += dir.dCol;
    }
    return true;
  }
}

/// The edge-most live cell of every row and column.
///
/// An arrow can fire exactly when its whole ray to the edge is empty, which is
/// the same thing as: an arrow pointing *up* is legal iff it is the topmost
/// live cell of its column, and correspondingly for the other three directions.
/// So at any moment there are at most `2 * (rows + cols)` cells that could fire
/// at all — 56 on a 14x14 board, not 196 — and each of them is found in
/// constant time.
///
/// That is what makes generating and measuring a full board cheap, and it is
/// also the termination proof the dense generator rests on: any non-empty board
/// has a topmost live cell in some column, so there is always a legal move to
/// construct.
class _Frontier {
  _Frontier(this.rows, this.cols)
      : _live = List.generate(rows, (_) => List<bool>.filled(cols, false)),
        _top = List<int>.filled(cols, -1),
        _bottom = List<int>.filled(cols, -1),
        _left = List<int>.filled(rows, -1),
        _right = List<int>.filled(rows, -1);

  final int rows;
  final int cols;
  final List<List<bool>> _live;
  final List<int> _top;
  final List<int> _bottom;
  final List<int> _left;
  final List<int> _right;

  void setLive(int r, int c) => _live[r][c] = true;

  /// Recomputes every extreme. Call once after the live cells are set up.
  void rebuild() {
    for (var c = 0; c < cols; c++) {
      _rescanColumn(c);
    }
    for (var r = 0; r < rows; r++) {
      _rescanRow(r);
    }
  }

  void remove(int r, int c) {
    _live[r][c] = false;
    _rescanColumn(c);
    _rescanRow(r);
  }

  void _rescanColumn(int c) {
    var top = -1, bottom = -1;
    for (var r = 0; r < rows; r++) {
      if (!_live[r][c]) continue;
      if (top < 0) top = r;
      bottom = r;
    }
    _top[c] = top;
    _bottom[c] = bottom;
  }

  void _rescanRow(int r) {
    var left = -1, right = -1;
    for (var c = 0; c < cols; c++) {
      if (!_live[r][c]) continue;
      if (left < 0) left = c;
      right = c;
    }
    _left[r] = left;
    _right[r] = right;
  }

  /// Visits every (cell, direction) pair whose ray to the edge is currently
  /// clear, with the number of cells that ray crosses.
  void forEachCandidate(
      void Function(int r, int c, Direction dir, int ray) visit) {
    for (var c = 0; c < cols; c++) {
      final t = _top[c];
      if (t >= 0) visit(t, c, Direction.up, t);
      final b = _bottom[c];
      if (b >= 0) visit(b, c, Direction.down, rows - 1 - b);
    }
    for (var r = 0; r < rows; r++) {
      final l = _left[r];
      if (l >= 0) visit(r, l, Direction.left, l);
      final ri = _right[r];
      if (ri >= 0) visit(r, ri, Direction.right, cols - 1 - ri);
    }
  }
}
