// Validates lib/data/word_pool.dart against the rules stated in its own doc:
// every entry 3-8 letters and present in assets/words/<lang>_all.txt, so a
// puzzle answer can never be a word the near-miss check would reject.
//
// Run: dart run tool/check_word_pool.dart
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:brain_workout/data/word_pool.dart';

void main() {
  var problems = 0;
  for (final lang in categorisedWords.keys) {
    final entries = categorisedWords[lang]!;
    final dict = File('assets/words/${lang}_all.txt')
        .readAsLinesSync()
        .map((l) => l.trim().toUpperCase())
        .where((l) => l.isNotEmpty)
        .toSet();

    final tooShort = <String>[];
    final tooLong = <String>[];
    final missing = <String>[];
    // A word listed under two categories makes the hint ambiguous — the whole
    // point is that the category identifies which word is wanted.
    final catsOf = <String, Set<String>>{};

    for (final e in entries) {
      final w = e.word;
      if (w.length < 3) tooShort.add(w);
      if (w.length > 8) tooLong.add(w);
      if (!dict.contains(w)) missing.add(w);
      catsOf.putIfAbsent(w, () => <String>{}).add(e.category.name);
    }
    final dupes = [
      for (final e in catsOf.entries)
        if (e.value.length > 1) '${e.key} (${e.value.join("+")})',
    ];

    final byCat = <WordCategory, int>{};
    final byLen = <int, int>{};
    for (final e in entries) {
      byCat[e.category] = (byCat[e.category] ?? 0) + 1;
      byLen[e.word.length] = (byLen[e.word.length] ?? 0) + 1;
    }

    print('=== $lang: ${entries.length} words ===');
    print('  by category: '
        '${byCat.entries.map((e) => "${e.key.name} ${e.value}").join(", ")}');
    print('  by length:   '
        '${[for (var n = 2; n <= 10; n++) if ((byLen[n] ?? 0) > 0) "$n:${byLen[n]}"].join(", ")}');
    if (tooShort.isNotEmpty) print('  TOO SHORT (<3): ${tooShort.join(", ")}');
    if (tooLong.isNotEmpty) print('  TOO LONG (>8): ${tooLong.join(", ")}');
    if (dupes.isNotEmpty) print("  IN TWO CATEGORIES: ${dupes.join(", ")}");
    if (missing.isNotEmpty) {
      print('  NOT IN DICTIONARY (${missing.length}): ${missing.join(", ")}');
    }
    problems += tooShort.length + tooLong.length + missing.length + dupes.length;
    print('');
  }
  print(problems == 0 ? 'All entries valid.' : '$problems problem(s) found.');
  if (problems > 0) exitCode = 1;
}
