// ignore_for_file: avoid_print
// Prints Letter hive puzzles per level for both languages, plus how many
// answers puzzles tend to have, so the answer band stays inside what the word
// lists produce. Re-run after changing the generator or the word lists.
//
//   dart run tool/analyze_letter_hive.dart [maxLevel] [en|nb] [--words]
import 'dart:io';

import 'package:brain_workout/data/word_tier.dart';
import 'package:brain_workout/games/letter_hive/letter_hive_models.dart';

HiveIndex load(String language) {
  final words = <(String, WordTier)>[];
  for (final line in File(
    'assets/words/${language}_all.txt',
  ).readAsLinesSync()) {
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    words.add((
      line.substring(0, tab).trim(),
      WordTier.fromCode(line.substring(tab + 1).trim()),
    ));
  }
  return HiveIndex(language, words);
}

void main(List<String> args) {
  final maxLevel = args.isNotEmpty ? int.parse(args[0]) : 10;
  final languages = args.length > 1 && !args[1].startsWith('--')
      ? [args[1]]
      : ['en', 'nb'];
  final showWords = args.contains('--words');
  for (final language in languages) {
    final sw = Stopwatch()..start();
    final index = load(language);
    print(
      '== $language: ${index.seeds.length} seeds, index ${sw.elapsedMilliseconds}ms',
    );
    final counts = <int>[];
    for (final seed in index.seeds.take(2000)) {
      final full = index.maskOf(seed)!;
      final centre = index.maskOf(seed[0])!;
      counts.add(
        index
            .answersFor(full, centre, letterHiveConfigForLevel(1).tiers)
            .length,
      );
    }
    counts.sort();
    String pct(double p) => '${counts[(counts.length * p).floor()]}';
    print(
      'answers per puzzle: p10 ${pct(0.1)}  p50 ${pct(0.5)}  p90 ${pct(0.9)}',
    );
    for (var level = 1; level <= maxLevel; level++) {
      sw
        ..reset()
        ..start();
      final p = LetterHivePuzzle.generate(level, index);
      final stars = p.starPoints;
      print(
        'L$level ${p.letters[0]}+${p.letters.substring(1)}  '
        '${p.answers.length} words  ${p.totalPoints} pts  '
        'stars $stars  pangrams ${p.pangrams.join(",")}  '
        '${sw.elapsedMilliseconds}ms',
      );
      if (showWords) print('   ${p.answers.join(" ")}');
    }
  }
}
