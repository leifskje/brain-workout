// Audits every game for the "difficulty plateau" bug: the level beyond which the
// per-level config stops changing, so level 60 plays exactly like level N.
//
// Arrow Maze had this (everything capped by level 17, making level 42 the easiest
// board in the game). This finds the rest rather than guessing which games share
// it. A late plateau is not automatically wrong — some games genuinely run out of
// knobs — but it should be a decision, not an accident.
//
// Run: dart run tool/analyze_level_curves.dart
// ignore_for_file: avoid_print
import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart'
    as arrow;
import 'package:brain_workout/games/crack_code/crack_code_models.dart';
import 'package:brain_workout/games/memory_match/memory_match_models.dart';
import 'package:brain_workout/games/merge/merge_models.dart';
import 'package:brain_workout/games/mini_sudoku/mini_sudoku_models.dart';
import 'package:brain_workout/games/number_cross/number_cross_models.dart';
import 'package:brain_workout/games/simon/simon_models.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';
import 'package:brain_workout/games/trail/trail_models.dart';
import 'package:brain_workout/games/what_next/what_next_models.dart';
import 'package:brain_workout/games/word_scramble/word_scramble_models.dart';
import 'package:brain_workout/games/word_search/word_search_models.dart';

/// Each entry renders a level's difficulty settings as a string; the audit finds
/// the last level at which that string changes.
final Map<String, String Function(int)> games = {
  'Arrow Escape': (l) {
    final c = arrow.configForLevel(l);
    return '${c.rows}x${c.cols} arrows=${c.arrowCount} hearts=${c.hearts}';
  },
  'Arrow Maze': (l) {
    final c = snakeConfigForLevel(l);
    return '${c.cols}x${c.rows} len=${c.minLength}-${c.maxLength} '
        'fill=${c.fillTarget.toStringAsFixed(2)} hearts=${c.hearts} '
        'branchTarget=${snakeTargetBranchingForLevel(l).toStringAsFixed(2)}';
  },
  'Crack the Code': (l) {
    final c = crackCodeConfigForLevel(l);
    return 'len=${c.length} symbols=${c.symbols} guesses=${c.maxGuesses}';
  },
  'Memory Match': (l) {
    final c = memoryConfigForLevel(l);
    return '${c.rows}x${c.cols}';
  },
  '2048 (Merge)': (l) {
    final c = mergeConfigForLevel(l);
    return 'size=${c.size} target=${c.target}';
  },
  'Mini Sudoku': (l) {
    final c = miniSudokuConfigForLevel(l);
    return 'size=${c.size} blanks=${c.blanks}';
  },
  'Number Cross': (l) {
    final c = numberCrossConfigForLevel(l);
    return 'eq=${c.equations} ${c.rows}x${c.cols} blanks=${c.blanks} '
        'decoys=${c.decoys}';
  },
  'Simon': (l) {
    final c = simonConfigForLevel(l);
    return 'len=${c.targetLength} flash=${c.flashMs} hearts=${c.hearts}';
  },
  'Follow the Trail': (l) {
    final c = trailConfigForLevel(l);
    return 'count=${c.count} alternating=${c.alternating} hearts=${c.hearts}';
  },
  'What Comes Next': (l) {
    final c = whatNextConfigForLevel(l);
    return 'questions=${c.questions} tier=${c.tier} hearts=${c.hearts}';
  },
  'Word Scramble': (l) {
    final c = wordScrambleConfigForLevel(l);
    return 'len=${c.minLen}-${c.maxLen} words=${c.words} hearts=${c.hearts}';
  },
  'Word Search': (l) {
    final c = wordSearchConfigForLevel(l);
    return '${c.size}x${c.size} words=${c.words} '
        'dirs=${c.directions.length} crossings=${c.allowCrossings}';
  },
};

void main() {
  const maxLevel = 80;
  final rows = <(String, int, String)>[];

  for (final entry in games.entries) {
    var lastChange = 1;
    for (var level = 2; level <= maxLevel; level++) {
      if (entry.value(level) != entry.value(level - 1)) lastChange = level;
    }
    rows.add((entry.key, lastChange, entry.value(maxLevel)));
  }

  rows.sort((a, b) => a.$2.compareTo(b.$2));
  print('Level beyond which nothing changes (audited to level $maxLevel)');
  print('');
  print('  plateau  game                 settings from then on');
  for (final (name, plateau, settings) in rows) {
    final flag = plateau <= 12 ? '  <-- flat early' : '';
    print('  ${plateau.toString().padLeft(7)}  ${name.padRight(20)} '
        '$settings$flag');
  }
  print('');
  print('"Plateau N" means level N is the last level that differs from the one');
  print('before it, so every level past N is identical to N.');
}
