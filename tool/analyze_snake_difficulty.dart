// Measures how hard Arrow Maze levels actually are, so difficulty tuning is
// driven by numbers rather than by how a board looks.
//
// The metric that matters is the *branching factor*: how many arrows have a
// clear shot at each step. A board can be huge and dense yet trivial if a dozen
// arrows are always ready to fire — the player never has to plan. Real
// difficulty is a low branching factor, which forces looking ahead.
//
// Run: dart run tool/analyze_snake_difficulty.dart
// ignore_for_file: avoid_print
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';

const _levels = [1, 4, 8, 12, 17, 20, 25, 30, 35, 40, 42, 43, 60];

void main() {
  print('=== Boards actually handed to the player ===');
  print('lvl  board   hearts  len     arrows  fill  hole  clear@start  branch'
      '  forced  target  miss    ms');
  for (final level in _levels) {
    final cfg = snakeConfigForLevel(level);
    final target = snakeTargetBranchingForLevel(level);
    final sw = Stopwatch()..start();
    final board = SnakeBoard.generate(level);
    final ms = sw.elapsedMilliseconds;
    final d = board.measureDifficulty();
    final cells = board.arrows.fold<int>(0, (s, a) => s + a.cells.length);

    print('${level.toString().padLeft(3)}  '
        '${'${cfg.cols}x${cfg.rows}'.padRight(7)} '
        '${cfg.hearts.toString().padLeft(6)}  '
        '${'${cfg.minLength}-${cfg.maxLength}'.padRight(6)} '
        '${board.arrows.length.toString().padLeft(6)} '
        '${(cells / (cfg.rows * cfg.cols) * 100).toStringAsFixed(0).padLeft(4)}% '
        '${'${(board.largestEmptyFraction * 100).toStringAsFixed(0)}%'.padLeft(5)} '
        '${'${(d.clearAtStart * 100).toStringAsFixed(0)}%'.padLeft(11)} '
        '${d.meanBranching.toStringAsFixed(1).padLeft(7)} '
        '${'${(d.forcedSteps * 100).toStringAsFixed(0)}%'.padLeft(6)} '
        '${target.toStringAsFixed(1).padLeft(7)} '
        '${(d.meanBranching - target).toStringAsFixed(2).padLeft(6)} '
        '${ms.toString().padLeft(5)}');
  }

  // What the generator can actually produce, so gate thresholds are calibrated
  // to reality rather than wishful: set them below the achievable floor and
  // every level silently falls back to "hardest of N", flattening the curve.
  print('\n=== Spread across the ${SnakeBoard.maxGenerationAttempts} seeds '
      '(pre-gate), per level ===');
  print('lvl  clear@start min/med/max      meanBranching min/med/max');
  for (final level in _levels) {
    final clears = <double>[];
    final branches = <double>[];
    for (var attempt = 0; attempt < SnakeBoard.maxGenerationAttempts; attempt++) {
      final board = SnakeBoard.buildAttempt(level, attempt);
      if (board.arrows.isEmpty) continue;
      final d = board.measureDifficulty();
      clears.add(d.clearAtStart);
      branches.add(d.meanBranching);
    }
    clears.sort();
    branches.sort();
    String fmt(List<double> xs, {bool pct = false}) {
      String one(double v) =>
          pct ? '${(v * 100).toStringAsFixed(0)}%' : v.toStringAsFixed(1);
      return '${one(xs.first)}/${one(xs[xs.length ~/ 2])}/${one(xs.last)}';
    }

    print('${level.toString().padLeft(3)}  '
        '${fmt(clears, pct: true).padRight(16)} '
        '${fmt(branches).padRight(16)}');
  }
}
