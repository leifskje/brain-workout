// Asks whether the word games actually get harder, and whether the data we ship
// contains a usable difficulty axis.
//
// For a scramble, difficulty is not mainly vocabulary — it is how hard the
// letters are to rearrange. Two properties are measurable from the dictionaries
// already in assets/words/:
//   - length
//   - how many *other* real words share the same letters (rival answers: more
//     rivals means more dead ends before the right one)
// Plus one that needs no dictionary at all: whether the word is in the curated
// pool (common) or only in the full list (rarer).
//
// Run: dart run tool/analyze_word_difficulty.dart
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:brain_workout/data/word_pool.dart';
import 'package:brain_workout/games/word_scramble/word_scramble_models.dart';
import 'package:brain_workout/games/word_search/word_search_models.dart';

String sig(String w) => (w.split('')..sort()).join();

void main() {
  for (final lang in ['en', 'nb']) {
    final pool = wordPoolFor(lang).toSet();
    final rivals = <String, int>{};
    final byLength = <int, List<String>>{};
    for (final line in File('assets/words/${lang}_all.txt').readAsLinesSync()) {
      final w = line.split('	').first.trim().toUpperCase();
      if (w.isEmpty) continue;
      rivals[sig(w)] = (rivals[sig(w)] ?? 0) + 1;
      byLength.putIfAbsent(w.length, () => []).add(w);
    }
    int rivalsFor(String w) => (rivals[sig(w)] ?? 1) - 1;

    print('=== $lang ===');
    print('Config per level (does it keep climbing?)');
    for (final level in [1, 5, 10, 15, 20, 30, 40, 60]) {
      final s = wordScrambleConfigForLevel(level);
      final f = wordSearchConfigForLevel(level);
      final served = generateScrambleRound(level, lang);
      final avgLen =
          served.fold<int>(0, (a, w) => a + w.word.length) / served.length;
      final avgRivals =
          served.fold<int>(0, (a, w) => a + rivalsFor(w.word)) / served.length;
      print('  lvl ${level.toString().padLeft(2)}  '
          'scramble ${s.minLen}-${s.maxLen} letters, ${s.words} words, '
          '${s.hearts} hearts | search ${f.size}x${f.size}, ${f.words} words '
          '| served avg len ${avgLen.toStringAsFixed(1)}, '
          'avg rivals ${avgRivals.toStringAsFixed(1)}');
    }

    // Is there headroom for harder words? Compare the curated pool against the
    // full list at the same lengths.
    print('Available difficulty headroom, by length:');
    for (var n = 4; n <= 9; n++) {
      final all = byLength[n] ?? const <String>[];
      if (all.isEmpty) continue;
      final poolAt = pool.where((w) => w.length == n).toList();
      final poolRivals = poolAt.isEmpty
          ? 0.0
          : poolAt.fold<int>(0, (a, w) => a + rivalsFor(w)) / poolAt.length;
      final allRivals =
          all.fold<int>(0, (a, w) => a + rivalsFor(w)) / all.length;
      final hardest = all.where((w) => rivalsFor(w) >= 4).length;
      print('  $n letters: pool ${poolAt.length.toString().padLeft(3)} words '
          '(avg ${poolRivals.toStringAsFixed(1)} rivals)  |  '
          'full list ${all.length.toString().padLeft(5)} '
          '(avg ${allRivals.toStringAsFixed(1)}), '
          '$hardest with 4+ rivals');
    }
    print('');
  }
}
