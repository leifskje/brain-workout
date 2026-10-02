// ignore_for_file: avoid_print
// Prints, per level, what the Bridges candidate pool can actually reach, so
// targets in bridgesConfigForLevel stay inside it. Re-run after any generator
// change.
//
//   dart run tool/analyze_bridges_difficulty.dart [maxLevel] [candidates]
import 'package:brain_workout/games/bridges/bridges_models.dart';

void main(List<String> args) {
  final maxLevel = args.isNotEmpty ? int.parse(args[0]) : 40;
  final candidates = args.length > 1 ? int.parse(args[1]) : 2500;
  print(
    'lvl  size   isl  target | solved  adv(min/med/max)  rounds | '
    'chosen adv isl  ms',
  );
  for (var level = 1; level <= maxLevel; level++) {
    final cfg = bridgesConfigForLevel(level);
    final sw = Stopwatch()..start();
    final pool = BridgesBoard.pool(level, candidates).toList();
    final poolMs = sw.elapsedMilliseconds;
    sw
      ..reset()
      ..start();
    final chosen = BridgesBoard.generate(level);
    final ms = sw.elapsedMilliseconds;
    final res = solveBridges(chosen.islands, chosen.edges, chosen.crossings);
    final adv = [for (final (_, r) in pool) r.advancedSteps]..sort();
    final rounds = [for (final (_, r) in pool) r.rounds]..sort();
    String med(List<int> xs) => xs.isEmpty ? '-' : '${xs[xs.length ~/ 2]}';
    final spread = adv.isEmpty ? '-' : '${adv.first}/${med(adv)}/${adv.last}';
    final size = '${cfg.cols}x${cfg.rows}';
    print(
      [
        '$level'.padLeft(3),
        size.padRight(6),
        '${cfg.islands}'.padLeft(3),
        '${cfg.targetAdvanced}'.padLeft(6),
        '|',
        '${pool.length}/$candidates'.padLeft(9),
        spread.padRight(16),
        med(rounds).padLeft(6),
        '|',
        '${res.advancedSteps}'.padLeft(10),
        '${chosen.islands.length}'.padLeft(3),
        '$ms'.padLeft(4),
        ' (pool ${poolMs}ms)',
      ].join(' '),
    );
  }
}
