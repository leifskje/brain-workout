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
  const bigBoardDensity = {10: 0.55, 11: 0.47, 12: 0.45, 13: 0.45, 14: 0.45};
  final density = size <= 9
      ? (0.35 + (level - 1) * 0.02).clamp(0.35, 0.68)
      : (bigBoardDensity[size] ?? 0.45);
  final count = (maxCells * density).round().clamp(4, maxCells - 2);
  return ArrowLevelConfig(
    rows: size,
    cols: size,
    arrowCount: count,
    hearts: 5,
  );
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

  /// Builds a guaranteed-solvable board for [level].
  ///
  /// Pieces are placed in reverse-solve order: each new arrow is only placed
  /// where its straight path to the edge is currently clear of the arrows
  /// already placed. Removing the arrows in the reverse of their placement
  /// order is therefore always a valid solution. Generation is deterministic
  /// per level (seeded), so retrying a level gives the same board.
  static ArrowBoard generate(int level) {
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
