import 'dart:math';

/// Number Cross — a math crossword. A 3x3 lattice of numbers laid out as a 5x5
/// cell grid: each number sits in a row equation `a op b = c` *and* a column
/// equation, sharing the cell where they cross. Some numbers are pre-filled;
/// the rest are placed from a pool so every row and column equation holds.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

enum NcOp { add, sub, mul }

int applyOp(NcOp op, int a, int b) => switch (op) {
      NcOp.add => a + b,
      NcOp.sub => a - b,
      NcOp.mul => a * b,
    };

String opSymbol(NcOp op) => switch (op) {
      NcOp.add => '+',
      NcOp.sub => '−', // minus sign
      NcOp.mul => '×', // times sign
    };

enum NcKind { blank, number, op, equals }

class NcCell {
  NcCell._(this.kind, {this.value, this.op, this.fixed = false});

  factory NcCell.blank() => NcCell._(NcKind.blank);
  factory NcCell.number(int value, {required bool fixed}) =>
      NcCell._(NcKind.number, value: value, fixed: fixed);
  factory NcCell.op(NcOp op) => NcCell._(NcKind.op, op: op);
  factory NcCell.equals() => NcCell._(NcKind.equals);

  final NcKind kind;
  final int? value; // correct value (number cells)
  final NcOp? op; // operator cells
  final bool fixed; // number cell pre-filled (true) vs to-place (false)
  int? placed; // to-place number cell: current placed value (null = empty)
}

class NumberCrossConfig {
  const NumberCrossConfig({
    required this.ops,
    required this.maxVal,
    required this.maxResult,
    required this.blanks,
    required this.decoys,
  });

  final List<NcOp> ops;
  final int maxVal;
  final int maxResult;
  final int blanks;
  final int decoys;
}

NumberCrossConfig numberCrossConfigForLevel(int level) {
  final ops = level < 3
      ? const [NcOp.add]
      : level < 6
          ? const [NcOp.add, NcOp.sub]
          : const [NcOp.add, NcOp.sub, NcOp.mul];
  final maxVal = ops.contains(NcOp.mul) ? 9 : (8 + level).clamp(8, 15);
  final blanks = (3 + level ~/ 2).clamp(3, 7);
  final decoys = level < 4 ? 0 : (level < 8 ? 1 : 2);
  return NumberCrossConfig(
    ops: ops,
    maxVal: maxVal,
    maxResult: 99,
    blanks: blanks,
    decoys: decoys,
  );
}

/// The board: a 5x5 [cells] grid plus the row/column operators and the pool of
/// numbers still to be placed.
class NumberCrossBoard {
  NumberCrossBoard({
    required this.cells,
    required this.opRow,
    required this.opCol,
    required this.pool,
  });

  final List<List<NcCell>> cells; // 5x5
  final List<NcOp> opRow; // 3
  final List<NcOp> opCol; // 3
  final List<int> pool; // numbers still available to place

  NcCell numberCell(int i, int j) => cells[2 * i][2 * j];

  /// The effective value at lattice position (i,j): the fixed value, or the
  /// placed value, or null if a to-place cell is still empty.
  int? valueAt(int i, int j) {
    final c = numberCell(i, j);
    return c.fixed ? c.value : c.placed;
  }

  /// Number of cells the player must fill.
  int get blankCount {
    var n = 0;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (!numberCell(i, j).fixed) n++;
      }
    }
    return n;
  }

  bool _rowValid(int i) {
    final a = valueAt(i, 0), b = valueAt(i, 1), c = valueAt(i, 2);
    if (a == null || b == null || c == null) return false;
    return applyOp(opRow[i], a, b) == c;
  }

  bool _colValid(int j) {
    final a = valueAt(0, j), b = valueAt(1, j), c = valueAt(2, j);
    if (a == null || b == null || c == null) return false;
    return applyOp(opCol[j], a, b) == c;
  }

  bool get isSolved {
    for (var i = 0; i < 3; i++) {
      if (!_rowValid(i)) return false;
    }
    for (var j = 0; j < 3; j++) {
      if (!_colValid(j)) return false;
    }
    return true;
  }

  /// Builds a guaranteed-consistent, solvable board for [level], seeded so a
  /// retry gives the same puzzle.
  static NumberCrossBoard generate(int level) {
    final cfg = numberCrossConfigForLevel(level);
    final rng = Random(level * 7919 + 101);

    for (var attempt = 0; attempt < 5000; attempt++) {
      final board = _tryGenerate(cfg, rng);
      if (board != null) return board;
    }
    // Fallback: addition-only is always consistent.
    return _tryGenerate(
          const NumberCrossConfig(
              ops: [NcOp.add], maxVal: 9, maxResult: 99, blanks: 3, decoys: 0),
          rng,
        ) ??
        _tryGenerate(
          const NumberCrossConfig(
              ops: [NcOp.add], maxVal: 9, maxResult: 99, blanks: 3, decoys: 0),
          Random(1),
        )!;
  }

  static NumberCrossBoard? _tryGenerate(NumberCrossConfig cfg, Random rng) {
    NcOp pick() => cfg.ops[rng.nextInt(cfg.ops.length)];
    int input() => rng.nextInt(cfg.maxVal) + 1;

    final n00 = input(), n01 = input(), n10 = input(), n11 = input();
    final opR0 = pick(), opR1 = pick(), opC0 = pick(), opC1 = pick();

    final r0 = applyOp(opR0, n00, n01); // n02
    final r1 = applyOp(opR1, n10, n11); // n12
    final c0 = applyOp(opC0, n00, n10); // n20
    final c1 = applyOp(opC1, n01, n11); // n21
    bool ok(int v) => v >= 0 && v <= cfg.maxResult;
    if (!ok(r0) || !ok(r1) || !ok(c0) || !ok(c1)) return null;

    // Choose the last-row / last-column operators so the shared corner agrees.
    NcOp? opR2, opC2;
    int? corner;
    for (final or2 in cfg.ops) {
      for (final oc2 in cfg.ops) {
        final v1 = applyOp(or2, c0, c1);
        final v2 = applyOp(oc2, r0, r1);
        if (v1 == v2 && ok(v1)) {
          opR2 = or2;
          opC2 = oc2;
          corner = v1;
          break;
        }
      }
      if (corner != null) break;
    }
    if (corner == null) return null;

    final n = [
      [n00, n01, r0],
      [n10, n11, r1],
      [c0, c1, corner],
    ];
    final opRow = [opR0, opR1, opR2!];
    final opCol = [opC0, opC1, opC2!];

    // Pick which numbers are blank (to place).
    final positions = [for (var p = 0; p < 9; p++) p]..shuffle(rng);
    final toPlace = positions.take(cfg.blanks.clamp(1, 9)).toSet();

    final cells = List.generate(
        5, (_) => List<NcCell>.generate(5, (_) => NcCell.blank()));
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        cells[2 * i][2 * j] =
            NcCell.number(n[i][j], fixed: !toPlace.contains(i * 3 + j));
      }
    }
    for (var i = 0; i < 3; i++) {
      cells[2 * i][1] = NcCell.op(opRow[i]);
      cells[2 * i][3] = NcCell.equals();
    }
    for (var j = 0; j < 3; j++) {
      cells[1][2 * j] = NcCell.op(opCol[j]);
      cells[3][2 * j] = NcCell.equals();
    }

    final pool = [for (final p in toPlace) n[p ~/ 3][p % 3]];
    for (var d = 0; d < cfg.decoys; d++) {
      pool.add(rng.nextInt(cfg.maxResult) + 1);
    }
    pool.shuffle(rng);

    return NumberCrossBoard(
        cells: cells, opRow: opRow, opCol: opCol, pool: pool);
  }
}
