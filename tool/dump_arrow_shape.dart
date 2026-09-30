// Prints a shaped board (Arrow Pictures, or the original three) as text — the agent's channel for anything
// visual (see CLAUDE.md). Shows the silhouette and each arrow's direction.
//
// Run: dart run tool/dump_arrow_shape.dart [shapeName]
// ignore_for_file: avoid_print
import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_shapes.dart';

const glyph = {
  Direction.up: '^', Direction.down: 'v',
  Direction.left: '<', Direction.right: '>',
};

void main(List<String> args) {
  final wanted = args.isEmpty ? null : args.first;
  for (final shape in [...pictureShapes, ...arrowShapes]) {
    if (wanted != null && shape.name != wanted) continue;
    final board = ArrowBoard.generateShaped(shape);
    final d = board.measureDifficulty();
    final at = {for (final p in board.pieces) (p.row, p.col): p.dir};
    print('--- ${shape.name}: ${board.pieces.length} arrows, '
        'branching ${d.meanBranching.toStringAsFixed(2)}, '
        'chain ${board.longestBlockingChain()}');
    for (var r = 0; r < board.rows; r++) {
      final row = [
        for (var c = 0; c < board.cols; c++) glyph[at[(r, c)]] ?? ' '
      ];
      print('   ${row.join(' ')}');
    }
    print('');
  }
}
