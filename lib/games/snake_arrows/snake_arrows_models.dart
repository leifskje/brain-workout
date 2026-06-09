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
    required this.snakeCount,
    required this.minLength,
    required this.maxLength,
    required this.hearts,
  });

  final int rows;
  final int cols;
  final int snakeCount;
  final int minLength;
  final int maxLength;
  final int hearts;
}

SnakeLevelConfig snakeConfigForLevel(int level) {
  final size = (5 + (level - 1) ~/ 3).clamp(5, 8);
  final count = (3 + level ~/ 2).clamp(3, 11);
  final maxLen = (3 + level ~/ 3).clamp(3, 6);
  return SnakeLevelConfig(
    rows: size,
    cols: size,
    snakeCount: count,
    minLength: 2,
    maxLength: maxLen,
    hearts: 5,
  );
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

  /// Builds a guaranteed-solvable board for [level].
  ///
  /// Snakes are placed in reverse-solve order. For each one we pick a head cell
  /// + exit direction whose straight path to the edge is currently clear, then
  /// grow a body backwards into empty cells (never into the head's forward
  /// path). Removing the snakes in the reverse of their placement order is
  /// therefore always a valid solution. Deterministic per level (seeded).
  static SnakeBoard generate(int level) {
    final cfg = snakeConfigForLevel(level);
    final rng = Random(level * 100003 + 41);
    final occupied =
        List.generate(cfg.rows, (_) => List<bool>.filled(cfg.cols, false));
    final arrows = <SnakeArrow>[];
    var id = 0;
    var attempts = 0;
    const maxAttempts = 400;

    bool inBounds(int r, int c) =>
        r >= 0 && r < cfg.rows && c >= 0 && c < cfg.cols;

    while (arrows.length < cfg.snakeCount && attempts < maxAttempts) {
      attempts++;

      // Candidate heads: empty cell + direction whose forward ray is clear.
      final heads = <List<int>>[];
      for (var r = 0; r < cfg.rows; r++) {
        for (var c = 0; c < cfg.cols; c++) {
          if (occupied[r][c]) continue;
          for (var d = 0; d < Dir.values.length; d++) {
            final dir = Dir.values[d];
            var rr = r + dir.dRow;
            var cc = c + dir.dCol;
            var clear = true;
            while (inBounds(rr, cc)) {
              if (occupied[rr][cc]) {
                clear = false;
                break;
              }
              rr += dir.dRow;
              cc += dir.dCol;
            }
            if (clear) heads.add([r, c, d]);
          }
        }
      }
      if (heads.isEmpty) break;

      final pick = heads[rng.nextInt(heads.length)];
      final headCell = Cell(pick[0], pick[1]);
      final dir = Dir.values[pick[2]];

      // Cells in front of the head — the body must not grow into these.
      final forward = <Cell>{};
      var fr = headCell.row + dir.dRow;
      var fc = headCell.col + dir.dCol;
      while (inBounds(fr, fc)) {
        forward.add(Cell(fr, fc));
        fr += dir.dRow;
        fc += dir.dCol;
      }

      // Grow the body backwards via a random walk.
      final desired =
          cfg.minLength + rng.nextInt(cfg.maxLength - cfg.minLength + 1);
      final path = <Cell>[headCell];
      final inPath = <Cell>{headCell};
      var cur = headCell;
      while (path.length < desired) {
        final options = <Dir>[];
        for (final d in Dir.values) {
          final n = cur.step(d);
          if (!inBounds(n.row, n.col)) continue;
          if (occupied[n.row][n.col]) continue;
          if (inPath.contains(n)) continue;
          if (forward.contains(n)) continue;
          options.add(d);
        }
        if (options.isEmpty) break;
        cur = cur.step(options[rng.nextInt(options.length)]);
        path.add(cur);
        inPath.add(cur);
      }

      if (path.length < cfg.minLength) continue; // too cramped; try again

      for (final cell in path) {
        occupied[cell.row][cell.col] = true;
      }
      arrows.add(SnakeArrow(
        id: id++,
        cells: path.reversed.toList(), // store tail -> head
        exitDir: dir,
      ));
    }

    return SnakeBoard(rows: cfg.rows, cols: cfg.cols, arrows: arrows);
  }
}
