// Quick inspection tool: prints generated Number Cross boards as ASCII.
// Run: dart run tool/dump_number_cross.dart
// ignore_for_file: avoid_print
import 'package:brain_workout/games/number_cross/number_cross_models.dart';

void main() {
  for (final level in [1, 3, 5, 7, 10, 20, 30]) {
    final board = NumberCrossBoard.generate(level);
    final cfg = numberCrossConfigForLevel(level);
    print('--- level $level: ${board.runs.length}/${cfg.equations} equations, '
        '${board.rows}x${board.cols}, ${board.blankCount} blanks, '
        'pool ${board.pool} ---');
    for (final row in board.cells) {
      final line = StringBuffer();
      for (final cell in row) {
        final s = switch (cell.kind) {
          NcKind.blank => '.',
          NcKind.number => cell.fixed ? '${cell.value}' : '_',
          NcKind.op => opSymbol(cell.op!),
          NcKind.equals => '=',
        };
        line.write(s.padLeft(3));
      }
      print(line);
    }
  }
}
