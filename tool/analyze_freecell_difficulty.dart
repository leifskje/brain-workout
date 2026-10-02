// ignore_for_file: avoid_print
// Prints how each FreeCell level measures, so the curve in
// `freeCellConfigForLevel` stays inside what the generator can produce.
// Re-run it after any change to the solver or the generator.
//
//   dart run tool/analyze_freecell_difficulty.dart [fromLevel] [toLevel]
//
// Columns: free cells given, cells the deal needs (target / measured), the
// room for error, candidates tried, solver effort at the level's own cell
// count, solution length, and generation time. A measured need below the
// target means the band ran out of candidates and fell back to an easier deal.
//
// The second table is the achievable spread: of a sample of seeded deals, the
// fewest free cells the solver wins each with.
import 'package:brain_workout/games/freecell/freecell_models.dart';

void main(List<String> args) {
  final from = args.isNotEmpty ? int.parse(args[0]) : 1;
  final to = args.length > 1 ? int.parse(args[1]) : 80;
  print('level cells  need  got slack tried nodes@cells moves genMs');
  var worst = 0, worstLevel = 0, offTarget = 0;
  final times = <int>[];
  for (var level = from; level <= to; level++) {
    final sw = Stopwatch()..start();
    final d = FreeCellDeal.generate(level);
    final ms = sw.elapsedMilliseconds;
    times.add(ms);
    if (ms > worst) {
      worst = ms;
      worstLevel = level;
    }
    final cfg = freeCellConfigForLevel(level);
    final hit = cfg.needAtMost
        ? d.need <= cfg.targetNeed
        : d.need == cfg.targetNeed;
    if (!hit) offTarget++;
    final atCells = solveFreeCell(d.start(), maxNodes: 60000);
    final need = '${cfg.needAtMost ? '<=' : ''}${cfg.targetNeed}';
    print(
      '${'$level'.padLeft(5)} ${'${d.cells}'.padLeft(5)} '
      '${need.padLeft(5)} ${'${cfg.needAtMost ? '<=' : ''}${d.need}'.padLeft(4)} '
      '${'${d.cells - d.need}'.padLeft(5)} ${'${d.candidatesTried}'.padLeft(5)} '
      '${'${atCells.nodes}'.padLeft(11)} ${'${d.solution.length}'.padLeft(5)} '
      '${'$ms'.padLeft(5)}${hit ? '' : '  OFF TARGET'}',
    );
  }
  times.sort();
  print(
    'generation: median ${times[times.length ~/ 2]}ms, '
    'p90 ${times[(times.length * 9) ~/ 10]}ms, '
    'worst ${worst}ms (level $worstLevel); off target: $offTarget',
  );

  print('\nachievable spread over 80 deals (probe budget $needProbeNodes):');
  final counts = List.filled(6, 0);
  for (var s = 0; s < 80; s++) {
    final deck = shuffledDeck(FreeCellDeal.seedFor(1000 + s, 0));
    var k = 0;
    while (k <= 4 &&
        !solveFreeCell(
          FreeCellPosition.deal(deck, k),
          maxNodes: needProbeNodes,
        ).solved) {
      k++;
    }
    counts[k]++;
  }
  for (var k = 0; k <= 4; k++) {
    print('  needs $k cells: ${counts[k]}');
  }
  print('  not won even with 4: ${counts[5]}');
}
