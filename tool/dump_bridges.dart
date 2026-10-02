// ignore_for_file: avoid_print
// Prints a Bridges level as text, puzzle and solution side by side, for
// checking boards without launching the app.
//
//   dart run tool/dump_bridges.dart [level]
import 'package:brain_workout/games/bridges/bridges_models.dart';

void main(List<String> args) {
  final level = args.isNotEmpty ? int.parse(args[0]) : 1;
  final b = BridgesBoard.generate(level);
  List<List<String>> grid(bool solved) {
    final g = List.generate(b.rows, (_) => List.filled(b.cols, ' . '));
    for (final s in b.islands) {
      g[s.row][s.col] = '(${s.need})';
    }
    if (solved) {
      for (var e = 0; e < b.edges.length; e++) {
        final v = b.solution[e];
        if (v == 0) continue;
        final mark = b.edges[e].horizontal
            ? (v == 1 ? '---' : '===')
            : (v == 1 ? ' | ' : ' ‖ ');
        for (final (r, c) in b.edges[e].cells) {
          g[r][c] = mark;
        }
      }
    }
    return g;
  }

  final r = solveBridges(b.islands, b.edges, b.crossings);
  print(
    'Level $level: ${b.cols}x${b.rows}, ${b.islands.length} islands, '
    '${b.edges.length} possible bridges, '
    '${b.solution.where((v) => v == 0).length} decoys, '
    'connectivity steps ${r.advancedSteps}',
  );
  final p = grid(false), s = grid(true);
  for (var row = 0; row < b.rows; row++) {
    print('${p[row].join()}      ${s[row].join()}');
  }
}
