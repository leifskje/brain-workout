// Measures how often a Word Scramble puzzle has more than one valid answer.
//
// The complaint: the scrambled letters can spell several real words, but only
// the one the app picked is accepted, and nothing on screen says which is
// wanted. This quantifies both halves of the problem:
//   - collisions inside the curated pool (two pool words share letters)
//   - collisions against the full 3-8 letter dictionaries in assets/words/
//
// It also reports how little variety the pool offers, because each level draws
// only from words inside its own length band, which is a much smaller set.
//
// Run: dart run tool/analyze_scramble_ambiguity.dart
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:brain_workout/games/word_scramble/word_scramble_models.dart';
import 'package:brain_workout/data/word_pool.dart';

String sig(String w) {
  final letters = w.split('')..sort();
  return letters.join();
}

void main() {
  for (final lang in ['en', 'nb']) {
    final pool = wordPoolFor(lang);
    final dict = File('assets/words/${lang}_all.txt')
        .readAsLinesSync()
        .map((l) => l.trim().toUpperCase())
        .where((l) => l.isNotEmpty)
        .toList();

    final byPoolSig = <String, List<String>>{};
    for (final w in pool) {
      byPoolSig.putIfAbsent(sig(w), () => []).add(w);
    }
    final byDictSig = <String, List<String>>{};
    for (final w in dict) {
      byDictSig.putIfAbsent(sig(w), () => []).add(w);
    }

    print('=== $lang: pool ${pool.length} words, dictionary ${dict.length} '
        '(3-8 letters) ===');

    final poolClashes =
        byPoolSig.values.where((ws) => ws.length > 1).toList();
    print('Pool words sharing letters with another pool word: '
        '${poolClashes.fold<int>(0, (s, ws) => s + ws.length)}');
    for (final ws in poolClashes) {
      print('   ${ws.join(" / ")}');
    }

    // Every pool word can now be checked, at any length.
    var checked = 0;
    var ambiguous = 0;
    final examples = <String>[];
    for (final w in pool) {
      checked++;
      final others =
          (byDictSig[sig(w)] ?? const <String>[]).where((d) => d != w).toList();
      if (others.isNotEmpty) {
        ambiguous++;
        if (examples.length < 12) {
          examples.add('$w -> ${others.join(", ")}');
        }
      }
    }
    print('Pool words with a real dictionary anagram: '
        '$ambiguous of $checked');
    for (final e in examples) {
      print('   $e');
    }

    // How much variety the pool can actually offer. Each level draws only from
    // words inside its length band, so the pool a player meets is far smaller
    // than the pool as a whole.
    print('Pool words available per level band:');
    for (final level in [1, 4, 7, 10]) {
      final cfg = wordScrambleConfigForLevel(level);
      final inBand = pool
          .where((w) => w.length >= cfg.minLen && w.length <= cfg.maxLen)
          .length;
      print('   level $level+ (${cfg.minLen}-${cfg.maxLen} letters): '
          '$inBand words, ${cfg.words} used per level');
    }

    // Repetition across a long play session.
    final counts = <String, int>{};
    for (var level = 1; level <= 40; level++) {
      for (final sw in generateScrambleRound(level, lang)) {
        counts[sw.word] = (counts[sw.word] ?? 0) + 1;
      }
    }
    final totalPuzzles = counts.values.fold<int>(0, (s, n) => s + n);
    final repeated = counts.entries.where((e) => e.value > 1).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    print('Levels 1-40: $totalPuzzles puzzles drawn from '
        '${counts.length} distinct words (pool has ${pool.length})');
    print('   words seen more than once: ${repeated.length}; '
        'worst offenders: '
        '${repeated.take(5).map((e) => "${e.key} x${e.value}").join(", ")}');

    // What the player actually meets in the first 20 levels.
    final served = <String>{};
    for (var level = 1; level <= 20; level++) {
      for (final sw in generateScrambleRound(level, lang)) {
        served.add(sw.word);
      }
    }
    final servedAmbiguous = served.where((w) {
      final inPool = (byPoolSig[sig(w)] ?? const []).length > 1;
      final inDict =
          (byDictSig[sig(w)] ?? const <String>[]).any((d) => d != w);
      return inPool || inDict;
    }).toList()
      ..sort();
    print('Words served in levels 1-20: ${served.length}, of which '
        '${servedAmbiguous.length} have a known alternative answer');
    if (servedAmbiguous.isNotEmpty) print('   ${servedAmbiguous.join(", ")}');
    print('');
  }
}
