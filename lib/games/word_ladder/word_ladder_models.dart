import 'dart:collection';
import 'dart:math';

import '../../data/word_tier.dart';

/// Word ladder: turn a start word into a target word one letter at a time,
/// every step a real word of the same length (COLD → CORD → WORD → WARD → WARM).
///
/// Pure Dart (no Flutter imports) so it stays unit-testable; the screen hands
/// in the dictionary.

const int minLadderLength = 4;
const int maxLadderLength = 6;

/// Words of 4–6 letters, linked when they differ in exactly one position.
///
/// Two graphs share one set of buckets: *every* real word, which decides what
/// a step may be (a player who knows a rare word is never told it isn't one),
/// and the words in a level's par tiers, which decide the par and the hints —
/// a par or hint that leans on GAUD or VELE would be unfair to set.
class LadderIndex {
  LadderIndex(this.language, Iterable<(String, WordTier)> words)
    : alphabet = language == 'nb'
          ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZÆØÅ'
          : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' {
    for (final (raw, tier) in words) {
      final word = raw.toUpperCase();
      if (word.length == minLadderLength - 1) _stems.add(word);
      if (word.length < minLadderLength || word.length > maxLadderLength) {
        continue;
      }
      if (!_inAlphabet(word)) continue;
      _tiers[word] = tier;
      for (var i = 0; i < word.length; i++) {
        (_buckets[_pattern(word, i)] ??= []).add(word);
      }
    }
  }

  final String language;

  /// The letters the keypad offers.
  final String alphabet;

  final Map<String, WordTier> _tiers = {};

  /// Three-letter words: never on a ladder, but the stems of IRKS and BUSES.
  final Set<String> _stems = {};

  /// `C_LD` → [COLD, CALD?...]: every word matching that wildcard pattern.
  final Map<String, List<String>> _buckets = {};

  bool _inAlphabet(String word) {
    for (var i = 0; i < word.length; i++) {
      if (!alphabet.contains(word[i])) return false;
    }
    return true;
  }

  static String _pattern(String word, int i) =>
      '${word.substring(0, i)}_${word.substring(i + 1)}';

  bool isWord(String word) => _tiers.containsKey(word);

  WordTier? tierOf(String word) => _tiers[word];

  /// Words of [length] in [tiers].
  List<String> wordsOf(int length, Set<WordTier> tiers) => [
    for (final e in _tiers.entries)
      if (e.key.length == length && tiers.contains(e.value)) e.key,
  ]..sort();

  final Map<int, List<String>> _endpoints = {};

  /// Words of [length] that may start or end a ladder, sorted.
  List<String> endpointsOf(int length) => _endpoints[length] ??= [
    for (final w in wordsOf(length, endpointTiersFor(language)))
      if (!isInflection(w, language, (s) => isWord(s) || _stems.contains(s)) &&
          !neverSet.contains(w))
        w,
  ];

  /// Words never set as an endpoint, par rung or hint, though still accepted
  /// as a step: English crude words its offensive screen missed, and
  /// Norwegian racial slurs, which sit in the ordinary tiers (NIGGER was a
  /// level-33 target). The owner accepted crude Norwegian words; slurs are a
  /// different matter.
  static const neverSet = {
    'WHORE',
    'TITS',
    'NIGGER',
    'NEGER',
    'NEGEREN',
    'NEGRE',
    'NEGRER',
    'NEGRENE',
  };

  /// Words one letter away from [word] whose tier is in [tiers] (null = all).
  /// [word] itself need not be in [tiers], or even a word.
  List<String> neighbours(String word, [Set<WordTier>? tiers]) {
    final all = _adjacency[word] ??= [
      for (var i = 0; i < word.length; i++)
        for (final w in _buckets[_pattern(word, i)] ?? const <String>[])
          if (w != word) w,
    ];
    if (tiers == null) return all;
    return [
      for (final w in all)
        if (tiers.contains(_tiers[w]) && !neverSet.contains(w)) w,
    ];
  }

  /// Every word's neighbours, filled in as searches reach them: BFS visits
  /// the same words over and over, and building the wildcard patterns each
  /// time was most of the cost of generating a level.
  final Map<String, List<String>> _adjacency = {};

  /// BFS distances from [from] over words in [tiers] (null = all), stopping
  /// once [maxDepth] is reached.
  Map<String, int> distancesFrom(
    String from, {
    Set<WordTier>? tiers,
    int maxDepth = 1 << 30,
  }) {
    final dist = <String, int>{from: 0};
    final queue = Queue<String>()..add(from);
    while (queue.isNotEmpty) {
      final w = queue.removeFirst();
      final d = dist[w]!;
      if (d >= maxDepth) continue;
      for (final n in neighbours(w, tiers)) {
        if (dist.containsKey(n)) continue;
        dist[n] = d + 1;
        queue.add(n);
      }
    }
    return dist;
  }

  /// A shortest ladder from [from] to [to] over [tiers] (both ends included),
  /// or null when there is none. Deterministic: ties go to the first
  /// neighbour in bucket order.
  List<String>? shortestPath(String from, String to, {Set<WordTier>? tiers}) {
    if (from == to) return [from];
    final back = distancesFrom(to, tiers: tiers);
    if (!back.containsKey(from)) {
      // [from] may itself be outside [tiers]; step off it into the graph.
      final starts = neighbours(from, tiers).where(back.containsKey).toList();
      if (starts.isEmpty) return null;
      starts.sort((a, b) => back[a]! - back[b]!);
      return [from, ..._descend(starts.first, back, tiers)];
    }
    return _descend(from, back, tiers);
  }

  List<String> _descend(String from, Map<String, int> back, Set<WordTier>? t) {
    final path = [from];
    var w = from;
    while (back[w]! > 0) {
      w = neighbours(w, t).firstWhere((n) => back[n] == back[w]! - 1);
      path.add(w);
    }
    return path;
  }
}

int hamming(String a, String b) {
  var n = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) n++;
  }
  return n;
}

/// Per-level shape. [par] and [detour] are *targets*: generation takes the
/// closest pair the word list allows, and the analyzer shows how close that is.
class WordLadderConfig {
  const WordLadderConfig({
    required this.length,
    required this.par,
    required this.detour,
    required this.parTiers,
  });

  final int length;

  /// Steps on the shortest ladder.
  final int par;

  /// How many of those steps cannot head straight for the target: par minus
  /// the number of letters that differ. At 0 the ladder is "change each letter
  /// to the target's, in the right order"; every extra step is a letter that
  /// has to go somewhere *else* first, which is where the puzzle lives.
  final int detour;

  /// Tiers the par ladder and the hints may use. Every word is accepted as a
  /// step regardless.
  final Set<WordTier> parTiers;
}

/// Tiers a par ladder and a hint may use, per language. The tiers are not on
/// the same scale: English tier 2 already holds CECA, SLUE and ILKS, while
/// Norwegian tier 3 is still GNIST, TVIST and EDDIK — and without it the
/// Norwegian 5-letter graph is so thin (mean degree 2.1) that every long
/// ladder funnels through the same chain of words.
Set<WordTier> parTiersFor(String language) => language == 'nb'
    ? const {WordTier.common, WordTier.normal, WordTier.lessCommon}
    : const {WordTier.common, WordTier.normal};

/// Endpoints are always everyday words: the puzzle is finding the way, not
/// decoding where it starts. Norwegian's common tier is far smaller, so it
/// takes the ordinary tier too.
Set<WordTier> endpointTiersFor(String language) => language == 'nb'
    ? const {WordTier.common, WordTier.normal}
    : const {WordTier.common};

/// (length, par, detour) per level band, kept inside what the word lists
/// produce — see `tool/analyze_word_ladder.dart --spread`.
///
/// From level 41 three shapes take turns. Pairs this long are scarce (about
/// 1.4 per start for Norwegian 5-letter at par 9), so one shape alone served
/// the same puzzle twice within twenty levels; three pools last three times
/// as long. A 4-letter ladder with three detours is no easier than a longer
/// one: short words leave fewer letters to park a detour in.
///
/// Norwegian never goes to six letters: that graph is too thin (190 and 70
/// distinct pairs for the two 6-letter shapes, against 2346+ in English), so
/// its six-letter slots take a 4-letter shape with as many detours instead.
WordLadderConfig wordLadderConfigForLevel(int level, String language) {
  final nb = language == 'nb';
  final (L, par, detour) = switch (level) {
    <= 3 => (4, 3, 0),
    <= 6 => (4, 4, 0),
    <= 9 => (4, 4, 1),
    <= 12 => (4, 5, 1),
    <= 18 => (5, 5, 1),
    <= 24 => (5, 6, 2),
    <= 30 => (5, 7, 2),
    <= 40 when level % 3 == 0 => nb ? (4, 6, 2) : (6, 7, 2),
    <= 40 => (5, 8, 3),
    _ when level % 3 == 2 => nb ? (4, 8, 4) : (6, 8, 3),
    _ => const [(5, 9, 4), (4, 7, 3)][level % 3],
  };
  return WordLadderConfig(
    length: L,
    par: par,
    detour: detour,
    parTiers: parTiersFor(language),
  );
}

/// An inflected form whose stem is also a word: DAYS, BASED, HESTEN, MØTET.
/// Fine as a step, weak as an endpoint ("turn HOWS into BELL").
bool isInflection(String word, String language, bool Function(String) isWord) {
  const en = ['S', 'ES', 'ED', 'D'];
  const nb = ['EN', 'ET', 'ENE', 'ER', 'ERE', 'TE', 'DE'];
  for (final suffix in language == 'nb' ? nb : en) {
    if (word.length > suffix.length + 2 &&
        word.endsWith(suffix) &&
        isWord(word.substring(0, word.length - suffix.length))) {
      return true;
    }
  }
  return false;
}

/// Why a step was or wasn't accepted.
enum StepVerdict { ok, unchanged, notAWord, alreadyUsed }

class WordLadderPuzzle {
  WordLadderPuzzle._({
    required this.index,
    required this.level,
    required this.start,
    required this.target,
    required this.par,
    required this.parTiers,
    required this.solution,
  });

  final LadderIndex index;
  final int level;
  final String start;
  final String target;

  /// Steps on the shortest ladder. No ladder through *any* real word is
  /// shorter, so "Shortest: N steps" is literally true.
  final int par;
  final Set<WordTier> parTiers;

  /// One shortest ladder, both ends included.
  final List<String> solution;

  int get length => start.length;
  int get detour => par - hamming(start, target);

  /// Whether [word] may follow [current]: exactly one letter changed (the
  /// keypad guarantees that), a real word, and not already on the ladder. Any
  /// tier counts: a player who knows a rare word is never told it isn't one.
  StepVerdict check(String current, String word, List<String> ladder) {
    if (word == current) return StepVerdict.unchanged;
    if (word.length != current.length || hamming(word, current) != 1) {
      return StepVerdict.notAWord;
    }
    if (!index.isWord(word)) return StepVerdict.notAWord;
    if (ladder.contains(word)) return StepVerdict.alreadyUsed;
    return StepVerdict.ok;
  }

  /// The next word on a shortest ladder from [current] to the target, or null
  /// when there is no way on from here.
  ///
  /// Searched over the par tiers, so a hint never needs a word the player may
  /// not know; only if [current] is stranded there (the player stepped onto a
  /// rare word) does it fall back to every word.
  String? hint(String current) {
    if (current == target) return null;
    final path =
        index.shortestPath(current, target, tiers: parTiers) ??
        index.shortestPath(current, target);
    return path == null || path.length < 2 ? null : path[1];
  }

  /// 3 stars at par without a hint, 2 within two steps of par, else 1. A hint
  /// caps it at 2, as in the other word games.
  static int starsFor(int steps, int par, {required bool usedHint}) {
    final earned = steps <= par ? 3 : (steps <= par + 2 ? 2 : 1);
    return usedHint ? min(earned, 2) : earned;
  }

  /// Bumped whenever generation changes, so a save from an older generator is
  /// not laid onto a different puzzle.
  static const generatorVersion = 1;

  /// Deterministic per level and language: same ladder on every retry.
  static WordLadderPuzzle generate(int level, LadderIndex index) {
    final cfg = wordLadderConfigForLevel(level, index.language);
    final rng = Random(_seedFor(level));
    final endpoints = index.endpointsOf(cfg.length);
    final pool = endpoints
        .where((w) => index.neighbours(w, cfg.parTiers).length >= 2)
        .toList();
    if (pool.isEmpty) throw StateError('No words for ${index.language}');
    final isEndpoint = endpoints.toSet();

    // Perfect pairs from several starts, then one picked at random. Taking the
    // first perfect pair found made the few starts that *can* reach a long
    // par win level after level, and the same puzzle came round again.
    _Candidate? best;
    final perfect = <List<_Candidate>>[];
    final tried = <String>{};
    for (var attempt = 0; attempt < 80 && perfect.length < 4; attempt++) {
      final start = pool[rng.nextInt(pool.length)];
      if (!tried.add(start)) continue;
      // Within one step of the target par, so a near miss is still on hand.
      final depth = cfg.par + 1;
      final fair = index.distancesFrom(
        start,
        tiers: cfg.parTiers,
        maxDepth: depth,
      );
      final candidates = [
        for (final e in fair.entries)
          if (e.value >= 2 && isEndpoint.contains(e.key))
            _Candidate(start, e.key, e.value, cfg),
      ];
      final floor = best?.score ?? 1 << 30;
      final useful = [
        for (final c in candidates)
          if (c.score <= floor) c,
      ];
      // Nothing here could beat what we have, so skip the costly search.
      if (useful.isEmpty) continue;
      // Every word, so a par can never be beaten by a rare shortcut.
      final any = index.distancesFrom(start, maxDepth: depth);
      final honest = [
        for (final c in useful)
          if (any[c.target] == c.par) c,
      ]..sort((a, b) => a.target.compareTo(b.target));
      for (final c in honest) {
        if (best == null || c.score < best.score) best = c;
      }
      final hits = [
        for (final c in honest)
          if (c.score == 0) c,
      ];
      if (hits.isNotEmpty) perfect.add(hits);
    }
    final b = perfect.isEmpty
        ? best!
        : (perfect[rng.nextInt(perfect.length)]..shuffle(rng)).first;
    return WordLadderPuzzle._(
      index: index,
      level: level,
      start: b.start,
      target: b.target,
      par: b.par,
      parTiers: cfg.parTiers,
      solution: index.shortestPath(b.start, b.target, tiers: cfg.parTiers)!,
    );
  }
}

/// The level, hashed. Dart's `Random` gives correlated early draws for
/// nearby seeds, and with `level * 7919 + 101` levels of one shape kept
/// landing on the same pair: Norwegian level 38 repeated level 32, from a
/// pool of 1468 pairs.
int _seedFor(int level) {
  var x = (level * 0x9E3779B1 + 0x7F4A7C15) & 0xFFFFFFFF;
  x = ((x ^ (x >> 16)) * 0x85EBCA6B) & 0xFFFFFFFF;
  x = ((x ^ (x >> 13)) * 0xC2B2AE35) & 0xFFFFFFFF;
  return x ^ (x >> 16);
}

class _Candidate {
  _Candidate(this.start, this.target, this.par, WordLadderConfig cfg)
    : score =
          (par - cfg.par).abs() * 10 +
          ((par - hamming(start, target)) - cfg.detour).abs();

  final String start;
  final String target;
  final int par;
  final int score;
}
