// ignore_for_file: avoid_print
// Prints Word Ladder puzzles per level for both languages, plus the spread the
// word lists can actually produce: how many honest endpoint pairs exist at
// each (par, detour), per word length and par tiers. A level target outside
// that spread silently degrades to "closest pair found", so keep the config
// inside it. Re-run after changing the generator or the word lists.
//
//   dart run tool/analyze_word_ladder.dart [maxLevel] [en|nb] [--spread] [--path]
import 'dart:io';
import 'dart:math';

import 'package:brain_workout/data/word_tier.dart';
import 'package:brain_workout/games/word_ladder/word_ladder_models.dart';

LadderIndex load(String language) {
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
  return LadderIndex(language, words);
}

const ordinary = {WordTier.common, WordTier.normal};
const withRare = {WordTier.common, WordTier.normal, WordTier.lessCommon};

void graphStats(LadderIndex index) {
  for (var length = minLadderLength; length <= maxLadderLength; length++) {
    for (final (name, tiers) in [
      ('1-2', ordinary),
      ('1-3', withRare),
      ('all', null),
    ]) {
      final words = index.wordsOf(length, tiers ?? WordTier.values.toSet());
      var degree = 0;
      var isolated = 0;
      for (final w in words) {
        final d = index.neighbours(w, tiers).length;
        degree += d;
        if (d == 0) isolated++;
      }
      print(
        '  len $length tiers $name: ${words.length} words, '
        'mean degree ${(degree / max(1, words.length)).toStringAsFixed(1)}, '
        'isolated ${(100 * isolated / max(1, words.length)).round()}%',
      );
    }
  }
}

/// Honest pairs (no shorter ladder through any word) by par × detour, from
/// [samples] random endpoint starts.
void spread(LadderIndex index, int length, Set<WordTier> tiers, String name) {
  final rng = Random(1);
  final pool = index
      .endpointsOf(length)
      .where((w) => index.neighbours(w, tiers).length >= 2)
      .toList();
  final ends = index.endpointsOf(length).toSet();
  final counts = <int, Map<int, int>>{};
  var dishonest = 0;
  var total = 0;
  const samples = 120;
  for (var s = 0; s < samples; s++) {
    final start = pool[rng.nextInt(pool.length)];
    final fair = index.distancesFrom(start, tiers: tiers, maxDepth: 10);
    final any = index.distancesFrom(start, maxDepth: 10);
    for (final e in fair.entries) {
      if (e.value < 2 || !ends.contains(e.key)) continue;
      total++;
      if (any[e.key] != e.value) {
        dishonest++;
        continue;
      }
      final detour = e.value - hamming(start, e.key);
      final row = counts[e.value] ??= {};
      row[detour] = (row[detour] ?? 0) + 1;
    }
  }
  print(
    '  len $length tiers $name: ${pool.length} endpoint words; '
    '${(100 * dishonest / max(1, total)).round()}% of pairs have a rare '
    'shortcut (rejected)',
  );
  print('    par: pairs per start at detour 0 / 1 / 2 / 3 / 4+');
  for (final par in counts.keys.toList()..sort()) {
    final row = counts[par]!;
    String cell(int d) => d < 4
        ? ((row[d] ?? 0) / samples).toStringAsFixed(1)
        : (row.entries.where((e) => e.key >= 4).fold(0, (a, e) => a + e.value) /
                  samples)
              .toStringAsFixed(1);
    print(
      '    ${par.toString().padLeft(3)}: '
      '${[for (var d = 0; d <= 4; d++) cell(d).padLeft(6)].join(' ')}',
    );
  }
}

/// Share of a node's moves that are one step closer to the target, averaged
/// along the solution: low means most legal moves lead nowhere useful.
double progressShare(WordLadderPuzzle p) {
  final back = p.index.distancesFrom(p.target, tiers: p.parTiers);
  var sum = 0.0;
  for (final w in p.solution.take(p.solution.length - 1)) {
    final moves = p.index.neighbours(w);
    final closer = moves.where((n) => back[n] == back[w]! - 1).length;
    sum += closer / max(1, moves.length);
  }
  return sum / max(1, p.solution.length - 1);
}

void main(List<String> args) {
  final maxLevel = args.isNotEmpty && int.tryParse(args[0]) != null
      ? int.parse(args[0])
      : 40;
  final languages = args.contains('nb')
      ? ['nb']
      : (args.contains('en') ? ['en'] : ['en', 'nb']);
  for (final language in languages) {
    final sw = Stopwatch()..start();
    final index = load(language);
    print('== $language: index ${sw.elapsedMilliseconds}ms');
    graphStats(index);
    if (args.contains('--spread')) {
      for (var length = 4; length <= 6; length++) {
        spread(index, length, parTiersFor(language), 'par');
      }
    }
    if (args.contains('--pairs')) {
      // Every distinct honest pair per level shape, from every start. Slow,
      // but it is the number that says how long a shape lasts before it
      // repeats.
      final shapes = <String, WordLadderConfig>{};
      for (var level = 1; level <= 60; level++) {
        final c = wordLadderConfigForLevel(level, language);
        shapes['${c.length}/${c.par}/${c.detour}'] ??= c;
      }
      for (final MapEntry(key: name, value: c) in shapes.entries) {
        final ends = index.endpointsOf(c.length).toSet();
        final pairs = <String>{};
        final starts = <String>{};
        for (final s in ends) {
          final fair = index.distancesFrom(
            s,
            tiers: c.parTiers,
            maxDepth: c.par,
          );
          final any = index.distancesFrom(s, maxDepth: c.par);
          for (final e in fair.entries) {
            if (e.value == c.par &&
                ends.contains(e.key) &&
                any[e.key] == c.par &&
                c.par - hamming(s, e.key) == c.detour) {
              pairs.add(([s, e.key]..sort()).join('/'));
              starts.add(s);
            }
          }
        }
        print(
          '  shape $name: ${pairs.length} distinct pairs, '
          '${starts.length} of ${ends.length} endpoints take part',
        );
      }
    }
    print('level len par detour(target) share  gen   ladder');
    final times = <int>[];
    // A thin pool repeats itself: the same pair on two levels is the same
    // puzzle twice.
    final seenPairs = <String, int>{};
    final repeats = <String>[];
    for (var level = 1; level <= maxLevel; level++) {
      sw
        ..reset()
        ..start();
      final p = WordLadderPuzzle.generate(level, index);
      final pair = ([p.start, p.target]..sort()).join('/');
      final earlier = seenPairs[pair];
      if (earlier != null) repeats.add('$level=$earlier');
      seenPairs[pair] ??= level;
      final ms = sw.elapsedMilliseconds;
      times.add(ms);
      final cfg = wordLadderConfigForLevel(level, language);
      final miss = p.par != cfg.par || p.detour != cfg.detour ? ' *' : '';
      print(
        '${level.toString().padLeft(5)} ${p.length.toString().padLeft(3)} '
        '${p.par.toString().padLeft(3)} '
        '${'${p.detour}(${cfg.detour})'.padLeft(9)} '
        '${progressShare(p).toStringAsFixed(2).padLeft(6)} '
        '${'${ms}ms'.padLeft(6)}   '
        '${args.contains('--path') ? p.solution.join(' > ') : '${p.start} > ${p.target}'}'
        '$miss',
      );
    }
    times.sort();
    print(
      'generation: median ${times[times.length ~/ 2]}ms, '
      'p90 ${times[times.length * 9 ~/ 10]}ms, max ${times.last}ms',
    );
    print('repeated puzzles: ${repeats.isEmpty ? 'none' : repeats.join(', ')}');
  }
}
