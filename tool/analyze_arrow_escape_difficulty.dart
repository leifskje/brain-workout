// Measures how hard Arrow Escape levels actually are, so difficulty tuning is
// driven by numbers rather than by how a board looks.
//
// The metric that matters is the *branching factor*: how many arrows have a
// clear shot at each step. A board can be big and full yet trivial if a dozen
// arrows are always ready to fire — the player never has to plan. Real
// difficulty is a low branching factor, which forces looking ahead. Level 100
// once measured *easier* than level 20 for exactly this reason.
//
// The second table is the important one: it prints the spread the candidate
// pool actually offers, so `arrowTargetBranchingForLevel` stays inside what the
// generator can produce. A target below the achievable floor silently degrades
// to "closest board found", which is the plateau this whole metric exists to
// catch. Re-run this after any generator change.
//
// `chain` is the longest chain in the blocking relation — the forced sequential
// depth of the board. It is printed as a diagnostic, not a tuning target, and it
// carries a caveat worth reading before acting on it: the game is monotone, so a
// deep chain unfolds as the player taps rather than being planned. Filling the
// board took chain from 7 to 38 and branching from 11.3 to 3.4, and the owner
// still could not feel the difference — because both numbers describe the
// solution's shape, not the player's effort. Neither metric can see the thing
// Arrow Escape lacks, which is a decision: any legal move is always correct.
//
// Run: dart run tool/analyze_arrow_escape_difficulty.dart
// ignore_for_file: avoid_print
import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';

const _levels = [20, 30, 40, 41, 45, 50, 60, 70, 80, 91, 100, 120, 150, 200];

void main() {
  print('=== Boards actually handed to the player ===');
  print('lvl  board   arrows  hearts  fill  clear@start  interior  branch'
      '  forced  chain  target  miss    ms');
  for (final level in _levels) {
    final cfg = configForLevel(level);
    final sw = Stopwatch()..start();
    final board = ArrowBoard.generate(level);
    final ms = sw.elapsedMilliseconds;
    final d = board.measureDifficulty();
    final dense = level >= arrowDenseFirstLevel;
    final target = dense ? arrowTargetBranchingForLevel(level) : double.nan;

    print('${level.toString().padLeft(3)}  '
        '${'${cfg.cols}x${cfg.rows}'.padRight(7)} '
        '${board.pieces.length.toString().padLeft(6)}  '
        '${cfg.hearts.toString().padLeft(6)}  '
        '${'${(board.pieces.length / (cfg.rows * cfg.cols) * 100).toStringAsFixed(0)}%'.padLeft(4)} '
        '${'${(d.clearAtStart * 100).toStringAsFixed(0)}%'.padLeft(11)} '
        '${'${(d.interiorSteps * 100).toStringAsFixed(0)}%'.padLeft(8)} '
        '${d.meanBranching.toStringAsFixed(1).padLeft(6)} '
        '${'${(d.forcedSteps * 100).toStringAsFixed(0)}%'.padLeft(6)} '
        '${board.longestBlockingChain().toString().padLeft(5)} '
        '${(dense ? target.toStringAsFixed(1) : 'sparse').padLeft(7)} '
        '${(dense ? (d.meanBranching - target).toStringAsFixed(2) : '-').padLeft(6)} '
        '${ms.toString().padLeft(5)}');
  }

  print('\n=== Spread across the ${ArrowBoard.generationPoolSize} candidates '
      '(pre-selection), per level ===');
  print('Targets must live inside these, or the level quietly flattens.');
  print('lvl  arrows  meanBranching min/med/max   clear@start min/med/max  '
      'interior med  unsolvable  ms/pool');
  for (final level in _levels.where((l) => l >= arrowDenseFirstLevel)) {
    final cfg = configForLevel(level);
    final branches = <double>[];
    final clears = <double>[];
    final interiors = <double>[];
    var unsolvable = 0;
    final sw = Stopwatch()..start();
    for (var attempt = 0; attempt < ArrowBoard.generationPoolSize; attempt++) {
      final board = ArrowBoard.buildAttempt(level, attempt);
      final d = board.measureDifficulty();
      if (!d.solvableGreedily) {
        unsolvable++;
        continue;
      }
      branches.add(d.meanBranching);
      clears.add(d.clearAtStart);
      interiors.add(d.interiorSteps);
    }
    final ms = sw.elapsedMilliseconds;
    branches.sort();
    clears.sort();
    interiors.sort();

    String fmt(List<double> xs, {bool pct = false}) {
      String one(double v) =>
          pct ? '${(v * 100).toStringAsFixed(0)}%' : v.toStringAsFixed(1);
      return '${one(xs.first)}/${one(xs[xs.length ~/ 2])}/${one(xs.last)}';
    }

    print('${level.toString().padLeft(3)}  '
        '${cfg.arrowCount.toString().padLeft(6)}  '
        '${fmt(branches).padRight(26)} '
        '${fmt(clears, pct: true).padRight(23)} '
        '${'${(interiors[interiors.length ~/ 2] * 100).toStringAsFixed(0)}%'.padLeft(12)} '
        '${unsolvable.toString().padLeft(10)} '
        '${ms.toString().padLeft(7)}');
  }
}
