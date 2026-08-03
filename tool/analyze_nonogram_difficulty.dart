// Measures how hard Picture Logic (nonogram) levels actually are, so tuning is
// driven by numbers rather than by how a board looks.
//
// Two sections, and the first matters more:
//
//  1. **Achievable spread.** For each grid size, samples raw candidates and
//     reports the branching range among the ones the line solver can finish.
//     Per-level targets must sit inside that range — a target outside it is not
//     an error, it just silently degrades to "closest available", which flattens
//     the curve without saying so. Arrow Maze learned this the hard way.
//  2. **Boards actually handed to the player**, with the miss against target.
//
// Re-run after ANY change to candidate building: making shapes blobbier or
// denser moves the whole achievable band, so targets that were reachable stop
// being reachable.
//
// Run: dart run tool/analyze_nonogram_difficulty.dart
// ignore_for_file: avoid_print
import 'dart:math';

import 'package:brain_workout/games/nonogram/nonogram_models.dart';

const _levels = [1, 2, 3, 4, 6, 8, 9, 12, 15, 16, 20, 25, 30, 40];

void main() {
  print('=== Achievable spread per size (raw candidates) ===');
  print('size  solvable  clueOK   branching: min   p25   med   p75   max');
  for (final size in [5, 8, 10, 12]) {
    final cfg = NonogramConfig(
      width: size,
      height: size,
      // Mid-range of the density the real configs use. Sampling a density the
      // game never ships understates the reachable band, since branching is
      // sensitive to density and peaks near here.
      density: 0.38,
      maxClues: maxCluesFor(size),
      targetBranching: 0,
    );
    final rng = Random(20260803);
    final values = <double>[];
    var clueOk = 0;
    const samples = 900;
    for (var i = 0; i < samples; i++) {
      final (passedClueCap, board) = sampleCandidate(cfg, rng);
      if (passedClueCap) clueOk++;
      if (board != null) values.add(board.branching);
    }
    values.sort();
    String q(double f) => values.isEmpty
        ? '  -  '
        : values[(f * (values.length - 1)).round()].toStringAsFixed(2);
    print('${size.toString().padLeft(4)}  '
        '${values.length.toString().padLeft(8)}  '
        '${clueOk.toString().padLeft(6)}   '
        '${''.padLeft(11)}${q(0).padLeft(5)} ${q(0.25).padLeft(5)} '
        '${q(0.5).padLeft(5)} ${q(0.75).padLeft(5)} ${q(1).padLeft(5)}');
  }

  print('');
  print('=== Boards actually handed to the player ===');
  print('lvl  grid    maxClue  fill   empty  branch  target  miss   pass    ms');
  for (final level in _levels) {
    final cfg = nonogramConfigForLevel(level);
    final sw = Stopwatch()..start();
    final board = NonogramBoard.generate(level);
    final ms = sw.elapsedMilliseconds;
    final widest = [
      for (final r in board.rowClues) r.length,
      for (final c in board.colClues) c.length,
    ].reduce(max);
    final emptyLines = board.rowClues.where((r) => r.isEmpty).length +
        board.colClues.where((c) => c.isEmpty).length;
    final miss = board.branching - cfg.targetBranching;

    print('${level.toString().padLeft(3)}  '
        '${'${cfg.width}x${cfg.height}'.padRight(6)} '
        '${'$widest/${cfg.maxClues}'.padLeft(7)}  '
        '${'${(board.fillFraction * 100).toStringAsFixed(0)}%'.padLeft(5)} '
        '${emptyLines.toString().padLeft(6)} '
        '${board.branching.toStringAsFixed(2).padLeft(7)} '
        '${cfg.targetBranching.toStringAsFixed(2).padLeft(7)} '
        '${miss.toStringAsFixed(2).padLeft(6)} '
        '${board.passes.toString().padLeft(5)} '
        '${ms.toString().padLeft(5)}');
  }
  print('');
  print('miss inside +/-${onTargetTolerance.toStringAsFixed(2)} counts as '
      'on target; looks break the tie.');
}

/// One raw candidate. Returns whether it passed the clue cap, and the board if
/// the line solver could also finish it — the two rejection reasons are counted
/// separately because they want different fixes (layout vs. difficulty).
///
/// Mirrors what `NonogramBoard.generate` does per attempt, minus the scoring:
/// deliberately duplicated so the analyzer measures the *pool*, not the winner.
(bool, NonogramBoard?) sampleCandidate(NonogramConfig cfg, Random rng) {
  final grid = buildCandidateGrid(cfg, rng);
  final rowClues = [for (final row in grid) cluesFor(row)];
  final colClues = [
    for (var c = 0; c < cfg.width; c++)
      cluesFor([for (var r = 0; r < cfg.height; r++) grid[r][c]])
  ];
  if (rowClues.any((r) => r.length > cfg.maxClues)) return (false, null);
  if (colClues.any((c) => c.length > cfg.maxClues)) return (false, null);
  final result = solveNonogram(rowClues, colClues);
  if (!result.solved) return (true, null);
  return (
    true,
    NonogramBoard(
      solution: grid,
      rowClues: rowClues,
      colClues: colClues,
      branching: result.branching,
      passes: result.passes,
    )
  );
}
