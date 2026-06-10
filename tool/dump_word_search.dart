// Quick inspection tool: prints generated Word Search boards as text, with
// placed-word cells in lowercase so placements and crossings stand out.
// Run: dart run tool/dump_word_search.dart
// ignore_for_file: avoid_print
import 'package:brain_workout/games/word_search/word_search_models.dart';

void main() {
  for (final level in [1, 4, 8, 12]) {
    final cfg = wordSearchConfigForLevel(level);
    final board = WordSearchBoard.generate(level, 'nb');
    final wordCells = <(int, int)>{};
    final crossings = <(int, int)>{};
    for (final w in board.words) {
      for (final cell in w.cells) {
        if (!wordCells.add(cell)) crossings.add(cell);
      }
    }
    print('--- level $level: ${board.size}x${board.size}, '
        '${board.words.length} words, crossings allowed: '
        '${cfg.allowCrossings} (actual: ${crossings.length}) ---');
    print('words: ${[for (final w in board.words) w.word].join(', ')}');
    for (var r = 0; r < board.size; r++) {
      final line = StringBuffer();
      for (var c = 0; c < board.size; c++) {
        final ch = board.grid[r][c];
        line.write(' ');
        line.write(crossings.contains((r, c))
            ? '*'
            : wordCells.contains((r, c))
                ? ch.toLowerCase()
                : ch);
      }
      print(line);
    }
  }
}
