import 'dart:math';

/// Merge (2048-style) — slide the board; equal numbers that bump into each
/// other merge into their sum (2+2=4, 4+4=8 …). Reach the level's target
/// tile to win; the board filling up with no possible merges is a loss.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

enum MergeDirection { up, down, left, right }

class MergeConfig {
  const MergeConfig({required this.size, required this.target});

  final int size;
  final int target;
}

MergeConfig mergeConfigForLevel(int level) {
  // Target grows one power of two per level: 32 at level 1 up to 2048.
  final exp = (5 + level - 1).clamp(5, 11);
  return MergeConfig(size: 4, target: 1 << exp);
}

/// Collapses one line toward index 0: drop gaps, then merge equal neighbours
/// once each. Returns the new line (same length, zero-padded) and the score
/// gained from merges. Pure — the screen and tests both use it directly.
({List<int> line, int gained}) collapseLine(List<int> line) {
  final tiles = [for (final v in line) if (v != 0) v];
  final result = <int>[];
  var gained = 0;
  var i = 0;
  while (i < tiles.length) {
    if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
      final merged = tiles[i] * 2;
      result.add(merged);
      gained += merged;
      i += 2;
    } else {
      result.add(tiles[i]);
      i++;
    }
  }
  while (result.length < line.length) {
    result.add(0);
  }
  return (line: result, gained: gained);
}

/// One tile's motion during a move: it slides from (fromRow,fromCol) to
/// (toRow,toCol). [merged] marks the tile that slides *into* another and
/// disappears as the destination doubles. Used purely to drive the slide
/// animation — the board state itself comes from [MergeGame.move].
class TileSlide {
  const TileSlide({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.value,
    required this.merged,
  });

  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final int value;
  final bool merged;

  bool get moves => fromRow != toRow || fromCol != toCol;
}

/// The grid coordinates of [line] (row or column) ordered so index 0 is the
/// cell tiles slide toward for [dir].
List<(int, int)> _orderedCoords(MergeDirection dir, int line, int size) {
  switch (dir) {
    case MergeDirection.left:
      return [for (var i = 0; i < size; i++) (line, i)];
    case MergeDirection.right:
      return [for (var i = 0; i < size; i++) (line, size - 1 - i)];
    case MergeDirection.up:
      return [for (var i = 0; i < size; i++) (i, line)];
    case MergeDirection.down:
      return [for (var i = 0; i < size; i++) (size - 1 - i, line)];
  }
}

/// Plans where every tile would slide for a move in [dir], without mutating
/// the grid. Pure, so the screen animates from it and tests check it.
List<TileSlide> planSlides(List<List<int>> grid, MergeDirection dir) {
  final size = grid.length;
  final slides = <TileSlide>[];
  for (var line = 0; line < size; line++) {
    final coords = _orderedCoords(dir, line, size);
    final entries = <({int index, int value})>[];
    for (var i = 0; i < size; i++) {
      final (r, c) = coords[i];
      if (grid[r][c] != 0) entries.add((index: i, value: grid[r][c]));
    }
    var out = 0, k = 0;
    while (k < entries.length) {
      final e = entries[k];
      final dest = coords[out];
      final src = coords[e.index];
      if (k + 1 < entries.length && entries[k + 1].value == e.value) {
        final src2 = coords[entries[k + 1].index];
        slides.add(TileSlide(
            fromRow: src.$1,
            fromCol: src.$2,
            toRow: dest.$1,
            toCol: dest.$2,
            value: e.value,
            merged: false));
        slides.add(TileSlide(
            fromRow: src2.$1,
            fromCol: src2.$2,
            toRow: dest.$1,
            toCol: dest.$2,
            value: e.value,
            merged: true));
        out++;
        k += 2;
      } else {
        slides.add(TileSlide(
            fromRow: src.$1,
            fromCol: src.$2,
            toRow: dest.$1,
            toCol: dest.$2,
            value: e.value,
            merged: false));
        out++;
        k++;
      }
    }
  }
  return slides;
}

/// Whether a move in [dir] would change the board (some tile slides or merges).
bool willChange(List<List<int>> grid, MergeDirection dir) =>
    planSlides(grid, dir).any((s) => s.merged || s.moves);

class MergeGame {
  MergeGame._(this.grid, this.target, this._rng);

  /// For tests: build a game from an explicit grid (0 = empty).
  factory MergeGame.fromGrid(List<List<int>> grid,
          {int target = 2048, int seed = 0}) =>
      MergeGame._(grid, target, Random(seed));

  final List<List<int>> grid;
  final int target;
  final Random _rng;
  int score = 0;

  int get size => grid.length;

  bool get reachedTarget =>
      grid.any((row) => row.any((v) => v >= target));

  int get emptyCount => _emptyCells.length;

  /// Whether any move is still possible (an empty cell or an equal neighbour).
  bool get hasMoves {
    if (_emptyCells.isNotEmpty) return true;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final v = grid[r][c];
        if (c + 1 < size && grid[r][c + 1] == v) return true;
        if (r + 1 < size && grid[r + 1][c] == v) return true;
      }
    }
    return false;
  }

  List<(int, int)> get _emptyCells => [
        for (var r = 0; r < size; r++)
          for (var c = 0; c < size; c++)
            if (grid[r][c] == 0) (r, c)
      ];

  void _spawn() {
    final empty = _emptyCells;
    if (empty.isEmpty) return;
    final (r, c) = empty[_rng.nextInt(empty.length)];
    grid[r][c] = _rng.nextInt(10) == 0 ? 4 : 2; // 10% chance of a 4
  }

  /// Applies a move. Returns true if anything moved/merged (and then a new
  /// tile spawns); false for a no-op move, which leaves the board untouched.
  bool move(MergeDirection dir) {
    final before = _flat();
    final lines = _extractLines(dir);
    final collapsed = <List<int>>[];
    var gained = 0;
    for (final line in lines) {
      final r = collapseLine(line);
      collapsed.add(r.line);
      gained += r.gained;
    }
    _writeLines(dir, collapsed);

    final after = _flat();
    var changed = false;
    for (var i = 0; i < after.length; i++) {
      if (after[i] != before[i]) {
        changed = true;
        break;
      }
    }
    if (!changed) return false;
    score += gained;
    _spawn();
    return true;
  }

  List<int> _flat() => [for (final row in grid) ...row];

  /// Each line ordered so index 0 is the cell a tile slides toward.
  List<List<int>> _extractLines(MergeDirection dir) {
    final lines = <List<int>>[];
    switch (dir) {
      case MergeDirection.left:
        for (var r = 0; r < size; r++) {
          lines.add([for (var c = 0; c < size; c++) grid[r][c]]);
        }
      case MergeDirection.right:
        for (var r = 0; r < size; r++) {
          lines.add([for (var c = size - 1; c >= 0; c--) grid[r][c]]);
        }
      case MergeDirection.up:
        for (var c = 0; c < size; c++) {
          lines.add([for (var r = 0; r < size; r++) grid[r][c]]);
        }
      case MergeDirection.down:
        for (var c = 0; c < size; c++) {
          lines.add([for (var r = size - 1; r >= 0; r--) grid[r][c]]);
        }
    }
    return lines;
  }

  void _writeLines(MergeDirection dir, List<List<int>> lines) {
    switch (dir) {
      case MergeDirection.left:
        for (var r = 0; r < size; r++) {
          for (var c = 0; c < size; c++) {
            grid[r][c] = lines[r][c];
          }
        }
      case MergeDirection.right:
        for (var r = 0; r < size; r++) {
          for (var c = 0; c < size; c++) {
            grid[r][size - 1 - c] = lines[r][c];
          }
        }
      case MergeDirection.up:
        for (var c = 0; c < size; c++) {
          for (var r = 0; r < size; r++) {
            grid[r][c] = lines[c][r];
          }
        }
      case MergeDirection.down:
        for (var c = 0; c < size; c++) {
          for (var r = 0; r < size; r++) {
            grid[size - 1 - r][c] = lines[c][r];
          }
        }
    }
  }

  /// Builds a fresh board for [level], seeded so the opening tiles are
  /// deterministic on a retry.
  static MergeGame generate(int level) {
    final cfg = mergeConfigForLevel(level);
    final rng = Random(level * 7333 + 19);
    final grid =
        List.generate(cfg.size, (_) => List<int>.filled(cfg.size, 0));
    final game = MergeGame._(grid, cfg.target, rng);
    game._spawn();
    game._spawn();
    return game;
  }
}
