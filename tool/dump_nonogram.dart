// Quick inspection tool: prints generated Picture Logic boards as text, with
// the clue gutters drawn the way the screen lays them out, so shape quality and
// gutter width can be judged without launching the app.
//
// Run: dart run tool/dump_nonogram.dart
// ignore_for_file: avoid_print
import 'package:brain_workout/games/nonogram/nonogram_models.dart';

void main() {
  for (final level in [1, 3, 5, 9, 16, 25, 40]) {
    final cfg = nonogramConfigForLevel(level);
    final board = NonogramBoard.generate(level);
    final gutter = [
      for (final r in board.rowClues) r.length,
      for (final c in board.colClues) c.length,
    ].fold<int>(0, (a, b) => a > b ? a : b);

    print('--- level $level: ${board.width}x${board.height}, '
        'fill ${(board.fillFraction * 100).toStringAsFixed(0)}%, '
        'branching ${board.branching.toStringAsFixed(2)} '
        '(target ${cfg.targetBranching.toStringAsFixed(2)}), '
        '${board.passes} passes, widest clue $gutter/${cfg.maxClues} ---');

    // Column clues, stacked bottom-aligned, exactly as the top gutter shows them.
    final colDepth = board.colClues.fold<int>(
        1, (a, c) => c.length > a ? c.length : a);
    final rowGutter = board.rowClues.fold<int>(
        1, (a, r) => r.length > a ? r.length : a);
    for (var line = 0; line < colDepth; line++) {
      final buf = StringBuffer(' ' * (rowGutter * 2 + 1));
      for (final clue in board.colClues) {
        final offset = colDepth - clue.length;
        buf.write(line < offset ? '  ' : '${clue[line - offset]} '
            .padLeft(2));
      }
      print(buf.toString());
    }

    for (var r = 0; r < board.height; r++) {
      final clue = board.rowClues[r];
      final label = clue.isEmpty ? '0' : clue.join(' ');
      final buf = StringBuffer(label.padLeft(rowGutter * 2 - 1));
      buf.write('  ');
      for (var c = 0; c < board.width; c++) {
        buf.write(board.solution[r][c] ? '# ' : '. ');
      }
      print(buf.toString());
    }
    print('');
  }
}
