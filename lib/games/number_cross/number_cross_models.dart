import 'dart:math';

/// Number Cross — a math crossword. Across and down equations (`a op b = c`,
/// five cells each) are placed on a variable-size grid so they cross at shared
/// *number* cells; the rest of the grid stays empty, giving the classic
/// crossword shape. Some numbers are pre-filled; the rest are placed from a
/// pool so every equation holds.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

enum NcOp { add, sub, mul, div }

int applyOp(NcOp op, int a, int b) => switch (op) {
      NcOp.add => a + b,
      NcOp.sub => a - b,
      NcOp.mul => a * b,
      // Truncating, and never the whole story: see [opHolds]. Callers that are
      // *checking* an equation must not use this for division.
      NcOp.div => b == 0 ? 0 : a ~/ b,
    };

String opSymbol(NcOp op) => switch (op) {
      NcOp.add => '+',
      NcOp.sub => '−', // minus sign
      NcOp.mul => '×', // times sign
      NcOp.div => '÷', // division sign
    };

/// Whether `a op b == res` really holds.
///
/// Division needs its own check rather than a truncating `~/`: 7 ~/ 2 is 3, so a
/// player who put 7 above 2 would have "7 ÷ 2 = 3" accepted. An equation is only
/// satisfied when the division is exact and the divisor is non-zero.
bool opHolds(NcOp op, int a, int b, int res) {
  if (op == NcOp.div) {
    return b != 0 && a % b == 0 && a ~/ b == res;
  }
  return applyOp(op, a, b) == res;
}

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

  /// The value the player sees: the fixed value or the placed one.
  int? get effective => fixed ? value : placed;
}

/// One equation on the board: five cells `[num][op][num][=][num]` starting at
/// (r, c), running across or down.
class NcRun {
  const NcRun(this.r, this.c, {required this.across});

  final int r;
  final int c;
  final bool across;

  int rowOf(int offset) => across ? r : r + offset;
  int colOf(int offset) => across ? c + offset : c;
}

class NumberCrossConfig {
  const NumberCrossConfig({
    required this.equations,
    required this.rows,
    required this.cols,
    required this.ops,
    required this.maxVal,
    required this.maxResult,
    required this.blanks,
    required this.decoys,
  });

  final int equations;
  final int rows;
  final int cols;
  final List<NcOp> ops;
  final int maxVal;
  final int maxResult;
  final int blanks;
  final int decoys;
}

NumberCrossConfig numberCrossConfigForLevel(int level) {
  // Division last, and late: it is the only operator whose operands cannot be
  // chosen freely (they have to divide exactly), and it is the hardest to do in
  // the head. Blanks and decoys were the only knobs left with room, and both are
  // spent by level 32 -- this is the one that keeps the ladder moving after that.
  final ops = level < 3
      ? const [NcOp.add]
      : level < 6
          ? const [NcOp.add, NcOp.sub]
          : level < 14
              ? const [NcOp.add, NcOp.sub, NcOp.mul]
              : const [NcOp.add, NcOp.sub, NcOp.mul, NcOp.div];
  final maxVal = ops.contains(NcOp.mul) ? 9 : (8 + level).clamp(8, 15);
  final equations = (3 + (level - 1) ~/ 2).clamp(3, 7);
  // Taller than wide — the app is portrait. Sized so 5-cell equations have
  // room to branch; the board is trimmed to its bounding box afterwards.
  final (rows, cols) = switch (equations) {
    3 => (7, 7),
    4 => (9, 7),
    5 => (9, 9),
    _ => (11, 9),
  };
  // Blanks and decoys are the two knobs that still have room at 11x9 — the grid
  // itself is at the portrait limit. More blanks means fewer anchored numbers to
  // reason from; more decoys means the tray no longer tells you what fits.
  // Both caps used to be reached by level 12, which is where the plateau was.
  final blanks = (3 + level ~/ 2).clamp(3, 13);
  final decoys = level < 4 ? 0 : (level < 8 ? 1 : (2 + (level - 8) ~/ 6).clamp(2, 5));
  return NumberCrossConfig(
    equations: equations,
    rows: rows,
    cols: cols,
    ops: ops,
    maxVal: maxVal,
    maxResult: 99,
    blanks: blanks,
    decoys: decoys,
  );
}

/// The board: a variable-size [cells] grid, the equations found on it, and the
/// pool of numbers still to be placed.
class NumberCrossBoard {
  NumberCrossBoard({required this.cells, required this.pool})
      : runs = scanRuns(cells);

  final List<List<NcCell>> cells;
  final List<NcRun> runs;
  final List<int> pool; // numbers still available to place

  int get rows => cells.length;
  int get cols => cells[0].length;

  NcCell cellOf(NcRun run, int offset) =>
      cells[run.rowOf(offset)][run.colOf(offset)];

  /// Number of cells the player must fill.
  int get blankCount {
    var n = 0;
    for (final row in cells) {
      for (final cell in row) {
        if (cell.kind == NcKind.number && !cell.fixed) n++;
      }
    }
    return n;
  }

  bool runValid(NcRun run) {
    final a = cellOf(run, 0).effective;
    final b = cellOf(run, 2).effective;
    final res = cellOf(run, 4).effective;
    if (a == null || b == null || res == null) return false;
    return opHolds(cellOf(run, 1).op!, a, b, res);
  }

  bool get isSolved => runs.every(runValid);

  /// The numbers the player has placed, for resuming after an interruption.
  ///
  /// Board and pool both regenerate from the level number, so the save carries
  /// only the placements — one entry per to-place cell, in row-major order, with
  /// null for "still empty". The pool is then rebuilt by removing what is placed,
  /// rather than being stored, so the two can never disagree.
  Map<String, dynamic> placementsJson() => {
        'rows': cells.length,
        'cols': cells.first.length,
        'placed': [
          for (final row in cells)
            for (final cell in row)
              if (cell.kind == NcKind.number && !cell.fixed) cell.placed,
        ],
      };

  /// Restores placements written by [placementsJson], rebuilding the pool to
  /// match. Returns false and changes nothing if the save doesn't fit.
  bool applyPlacementsJson(Map<String, dynamic> json) {
    if (json['rows'] != cells.length) return false;
    if (json['cols'] != cells.first.length) return false;
    final placed = json['placed'];
    if (placed is! List) return false;

    final slots = [
      for (final row in cells)
        for (final cell in row)
          if (cell.kind == NcKind.number && !cell.fixed) cell,
    ];
    if (placed.length != slots.length) return false;
    for (final v in placed) {
      if (v != null && v is! int) return false;
    }

    // Every placed number has to come out of the pool, or the player could end
    // up with more tiles than the puzzle has.
    final remaining = [...pool];
    final toPlace = <int?>[];
    for (final v in placed) {
      if (v == null) {
        toPlace.add(null);
        continue;
      }
      if (!remaining.remove(v as int)) return false;
      toPlace.add(v);
    }

    for (var i = 0; i < slots.length; i++) {
      slots[i].placed = toPlace[i];
    }
    pool
      ..clear()
      ..addAll(remaining);
    return true;
  }

  /// Whether the player has placed anything yet.
  bool get hasProgress => cells.any((row) => row.any(
      (c) => c.kind == NcKind.number && !c.fixed && c.placed != null));

  /// Finds every equation on the grid by scanning for maximal across/down
  /// segments of non-blank cells. Any segment of two or more cells must be
  /// exactly `[num][op][num][=][num]` — anything else is a generator bug.
  static List<NcRun> scanRuns(List<List<NcCell>> cells) {
    final rows = cells.length, cols = cells[0].length;
    const pattern = [
      NcKind.number,
      NcKind.op,
      NcKind.number,
      NcKind.equals,
      NcKind.number,
    ];
    final runs = <NcRun>[];

    void scanLine(int r0, int c0, bool across) {
      final dr = across ? 0 : 1, dc = across ? 1 : 0;
      var r = r0, c = c0;
      while (r < rows && c < cols) {
        if (cells[r][c].kind == NcKind.blank) {
          r += dr;
          c += dc;
          continue;
        }
        final startR = r, startC = c;
        var len = 0;
        while (r < rows && c < cols && cells[r][c].kind != NcKind.blank) {
          len++;
          r += dr;
          c += dc;
        }
        if (len == 1) continue; // lone crossing cell in this direction
        if (len != pattern.length) {
          throw StateError('segment of $len cells at ($startR,$startC)');
        }
        for (var o = 0; o < pattern.length; o++) {
          if (cells[startR + dr * o][startC + dc * o].kind != pattern[o]) {
            throw StateError('bad segment at ($startR,$startC) offset $o');
          }
        }
        runs.add(NcRun(startR, startC, across: across));
      }
    }

    for (var r = 0; r < rows; r++) {
      scanLine(r, 0, true);
    }
    for (var c = 0; c < cols; c++) {
      scanLine(0, c, false);
    }
    return runs;
  }

  /// Builds a guaranteed-consistent, solvable board for [level], seeded so a
  /// retry gives the same puzzle.
  static NumberCrossBoard generate(int level) {
    final cfg = numberCrossConfigForLevel(level);
    final rng = Random(level * 7919 + 101);

    _Layout best = _grow(cfg, rng);
    for (var attempt = 0; attempt < 120 && best.count < cfg.equations; attempt++) {
      final layout = _grow(cfg, rng);
      if (layout.count > best.count) best = layout;
    }
    return _toBoard(best, cfg, rng);
  }

  /// Grows one layout: a first across equation, then equations attached one at
  /// a time, each crossing an already-placed number cell (so the shared value
  /// is fixed and the free operand/operator is chosen to fit). May fall short
  /// of the target — the caller keeps the best of several tries.
  static _Layout _grow(NumberCrossConfig cfg, Random rng) {
    final grid = List.generate(
        cfg.rows, (_) => List<_GCell?>.filled(cfg.cols, null));
    final layout = _Layout(grid);

    NcOp pickOp() => cfg.ops[rng.nextInt(cfg.ops.length)];
    int input() => rng.nextInt(cfg.maxVal) + 1;
    bool ok(int v) => v >= 0 && v <= cfg.maxResult;

    // First equation: across, roomy anchor. Falls back to addition, which
    // always passes the range check.
    for (var t = 0; t < 30 && layout.count == 0; t++) {
      final op = t < 20 ? pickOp() : NcOp.add;
      // Division is the one operator whose operands cannot be picked freely:
      // choose the divisor and the answer, then the dividend follows. Picking a
      // and b and computing a ~/ b would place "7 ÷ 2 = 3" -- which opHolds
      // rejects, so the board would be unsolvable.
      final int a, b, res;
      if (op == NcOp.div) {
        b = 2 + rng.nextInt(8); // 2..9; a divisor of 1 is not a puzzle
        res = input();
        a = b * res;
      } else {
        a = input();
        b = input();
        res = applyOp(op, a, b);
      }
      if (!ok(a) || !ok(b) || !ok(res)) continue;
      final r = 1 + rng.nextInt(cfg.rows - 2);
      final c = rng.nextInt(cfg.cols - 4);
      layout.place(r, c, across: true, a: a, op: op, b: b, res: res);
    }

    var failures = 0;
    while (layout.count < cfg.equations && failures < 80) {
      if (!_attach(layout, cfg, rng, pickOp, input, ok)) failures++;
    }
    return layout;
  }

  /// Tries to attach one new equation crossing an existing number cell.
  static bool _attach(
    _Layout layout,
    NumberCrossConfig cfg,
    Random rng,
    NcOp Function() pickOp,
    int Function() input,
    bool Function(int) ok,
  ) {
    final numbers = layout.numberCells;
    final (rx, cx) = numbers[rng.nextInt(numbers.length)];
    final v = layout.grid[rx][cx]!.value!;
    final across = !layout.hasRunThrough(rx, cx, across: true);
    if (!across && layout.hasRunThrough(rx, cx, across: false)) {
      return false; // already crossed both ways
    }
    final k = [0, 2, 4][rng.nextInt(3)]; // which number slot is the crossing
    final r0 = across ? rx : rx - k;
    final c0 = across ? cx - k : cx;
    if (!layout.canPlace(r0, c0, across: across, crossing: k)) return false;

    // Choose op and free operands so slot [k] equals the fixed value v.
    for (var t = 0; t < 12; t++) {
      final op = pickOp();
      int a, b, res;
      switch (k) {
        case 0:
          a = v;
          if (op == NcOp.div) {
            // The dividend is fixed, so the divisor has to divide it exactly.
            if (v < 2) continue;
            final divisors = [
              for (var d = 2; d <= v; d++)
                if (v % d == 0) d
            ];
            if (divisors.isEmpty) continue; // v is prime: nothing but 1 and v
            b = divisors[rng.nextInt(divisors.length)];
            res = v ~/ b;
          } else {
            b = input();
            res = applyOp(op, a, b);
          }
        case 2:
          b = v;
          if (op == NcOp.div) {
            if (v < 2) continue; // a divisor of 0 or 1 is no equation
            res = input();
            a = v * res;
          } else {
            a = input();
            res = applyOp(op, a, b);
          }
        default: // crossing at the result
          res = v;
          switch (op) {
            case NcOp.add:
              if (v < 2) continue;
              a = 1 + rng.nextInt(v - 1);
              b = v - a;
            case NcOp.sub:
              b = input();
              a = v + b;
            case NcOp.mul:
              if (v < 1) continue;
              final divisors = [
                for (var d = 1; d <= v; d++)
                  if (v % d == 0) d
              ];
              a = divisors[rng.nextInt(divisors.length)];
              b = v ~/ a;
            case NcOp.div:
              // The answer is fixed; pick a divisor and the dividend follows.
              if (v < 1) continue;
              b = 2 + rng.nextInt(8);
              a = b * v;
          }
      }
      if (!ok(a) || !ok(b) || !ok(res)) continue;
      layout.place(r0, c0, across: across, a: a, op: op, b: b, res: res);
      return true;
    }
    return false;
  }

  /// Converts a layout into a playable board: trims to the bounding box,
  /// blanks out some numbers into the pool, adds decoys.
  static NumberCrossBoard _toBoard(
      _Layout layout, NumberCrossConfig cfg, Random rng) {
    var rMin = cfg.rows, rMax = -1, cMin = cfg.cols, cMax = -1;
    for (var r = 0; r < cfg.rows; r++) {
      for (var c = 0; c < cfg.cols; c++) {
        if (layout.grid[r][c] != null) {
          rMin = min(rMin, r);
          rMax = max(rMax, r);
          cMin = min(cMin, c);
          cMax = max(cMax, c);
        }
      }
    }

    final numberPositions = <(int, int)>[
      for (var r = rMin; r <= rMax; r++)
        for (var c = cMin; c <= cMax; c++)
          if (layout.grid[r][c]?.kind == NcKind.number) (r, c)
    ]..shuffle(rng);
    // Leave at least two givens as anchors.
    final blanks = cfg.blanks.clamp(1, numberPositions.length - 2);
    final toPlace = numberPositions.take(blanks).toSet();

    final cells = [
      for (var r = rMin; r <= rMax; r++)
        [
          for (var c = cMin; c <= cMax; c++)
            switch (layout.grid[r][c]) {
              null => NcCell.blank(),
              final g when g.kind == NcKind.number =>
                NcCell.number(g.value!, fixed: !toPlace.contains((r, c))),
              final g when g.kind == NcKind.op => NcCell.op(g.op!),
              _ => NcCell.equals(),
            }
        ]
    ];

    final pool = [for (final (r, c) in toPlace) layout.grid[r][c]!.value!];
    for (var d = 0; d < cfg.decoys; d++) {
      pool.add(rng.nextInt(cfg.maxResult) + 1);
    }
    pool.shuffle(rng);

    return NumberCrossBoard(cells: cells, pool: pool);
  }
}

class _GCell {
  _GCell.number(this.value)
      : kind = NcKind.number,
        op = null;
  _GCell.op(this.op)
      : kind = NcKind.op,
        value = null;
  _GCell.equals()
      : kind = NcKind.equals,
        value = null,
        op = null;

  final NcKind kind;
  final int? value;
  final NcOp? op;
}

/// A layout under construction: the working grid plus the placed runs.
class _Layout {
  _Layout(this.grid);

  final List<List<_GCell?>> grid;
  final List<NcRun> _runs = [];

  int get count => _runs.length;
  int get rows => grid.length;
  int get cols => grid[0].length;

  List<(int, int)> get numberCells => [
        for (var r = 0; r < rows; r++)
          for (var c = 0; c < cols; c++)
            if (grid[r][c]?.kind == NcKind.number) (r, c)
      ];

  bool hasRunThrough(int r, int c, {required bool across}) {
    for (final run in _runs) {
      if (run.across != across) continue;
      for (final o in const [0, 2, 4]) {
        if (run.rowOf(o) == r && run.colOf(o) == c) return true;
      }
    }
    return false;
  }

  bool _emptyOrOut(int r, int c) =>
      r < 0 || r >= rows || c < 0 || c >= cols || grid[r][c] == null;

  /// A 5-cell equation fits at (r0,c0) if its crossing slot lands on an
  /// existing number, every other cell is empty with empty side-neighbours
  /// (so segments never merge), and the cells beyond both ends are empty.
  bool canPlace(int r0, int c0, {required bool across, required int crossing}) {
    final dr = across ? 0 : 1, dc = across ? 1 : 0;
    if (r0 < 0 || c0 < 0) return false;
    if (r0 + dr * 4 >= rows || c0 + dc * 4 >= cols) return false;
    if (!_emptyOrOut(r0 - dr, c0 - dc)) return false;
    if (!_emptyOrOut(r0 + dr * 5, c0 + dc * 5)) return false;
    for (var o = 0; o < 5; o++) {
      final r = r0 + dr * o, c = c0 + dc * o;
      if (o == crossing) {
        if (grid[r][c]?.kind != NcKind.number) return false;
      } else {
        if (grid[r][c] != null) return false;
        if (!_emptyOrOut(r + dc, c + dr)) return false;
        if (!_emptyOrOut(r - dc, c - dr)) return false;
      }
    }
    return true;
  }

  void place(int r0, int c0,
      {required bool across,
      required int a,
      required NcOp op,
      required int b,
      required int res}) {
    final dr = across ? 0 : 1, dc = across ? 1 : 0;
    grid[r0][c0] = _GCell.number(a);
    grid[r0 + dr][c0 + dc] = _GCell.op(op);
    grid[r0 + dr * 2][c0 + dc * 2] = _GCell.number(b);
    grid[r0 + dr * 3][c0 + dc * 3] = _GCell.equals();
    grid[r0 + dr * 4][c0 + dc * 4] = _GCell.number(res);
    _runs.add(NcRun(r0, c0, across: across));
  }
}
