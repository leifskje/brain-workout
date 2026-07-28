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
  // Grid and density both used to stop at level 13. Single-cell arrows stay
  // legible far longer than Arrow Maze's snakes — a 9x9 board is ~40dp per cell
  // on a phone against Arrow Maze's 23dp — so there is room to keep growing.
  final size = (4 + (level - 1) ~/ 4).clamp(4, 9);
  final maxCells = size * size;
  final density = (0.35 + (level - 1) * 0.02).clamp(0.35, 0.68);
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

    while (pieces.length < cfg.arrowCount) {
      // [row, col, directionIndex] placements that keep the board solvable.
      final candidates = <List<int>>[];
      for (var r = 0; r < cfg.rows; r++) {
        for (var c = 0; c < cfg.cols; c++) {
          if (occupied[r][c]) continue;
          for (var d = 0; d < Direction.values.length; d++) {
            if (_rayClear(occupied, r, c, Direction.values[d], cfg)) {
              candidates.add([r, c, d]);
            }
          }
        }
      }
      if (candidates.isEmpty) break;

      final pick = candidates[rng.nextInt(candidates.length)];
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
