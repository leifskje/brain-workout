import 'dart:math';

import '../../data/word_tier.dart';

/// Letter hive: seven letters in a honeycomb, one in the centre. Make words of
/// four or more letters from them, always using the centre letter; letters may
/// repeat. A word using all seven is a *pangram* and scores a bonus.
///
/// Every puzzle is built from a pangram, so there is always at least one.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable; the screen hands
/// in the dictionary.

const int minWordLength = 4;

/// The dictionary stops at 8 letters, so pangrams are 7 or 8 letters long.
const int maxWordLength = 8;

/// Words grouped by the *set* of letters they use, as a bitmask. A puzzle's
/// answers are then the words under the 64 letter sets that are subsets of its
/// seven letters and contain the centre: 64 lookups instead of a dictionary
/// scan.
class HiveIndex {
  HiveIndex(this.language, Iterable<(String, WordTier)> words)
    : alphabet = language == 'nb'
          ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZÆØÅ'
          : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' {
    for (var i = 0; i < alphabet.length; i++) {
      _bit[alphabet[i]] = 1 << i;
    }
    for (final (raw, tier) in words) {
      final word = raw.toUpperCase();
      if (word.length < minWordLength || word.length > maxWordLength) continue;
      final mask = maskOf(word);
      if (mask == null || _bitCount(mask) > 7) continue;
      _all[word] = mask;
      if (tier == WordTier.junk) continue;
      (_answersByMask[mask] ??= []).add((word, tier));
      if (word.length >= 7 &&
          _bitCount(mask) == 7 &&
          tier != WordTier.lessCommon &&
          (mask & _excluded) == 0) {
        seeds.add(word);
      }
    }
  }

  final String language;
  final String alphabet;
  final Map<String, int> _bit = {};

  /// Every accepted word (junk included) to its letter mask.
  final Map<String, int> _all = {};

  /// Fair answers only (no junk), grouped by letter mask.
  final Map<int, List<(String, WordTier)>> _answersByMask = {};

  /// Ordinary 7-distinct-letter words, each the starting point of a puzzle.
  /// The pangram has to be findable, so rare words are never seeds.
  final List<String> seeds = [];

  /// The seeds' distinct letter sets, each once, in a fixed shuffled order:
  /// the sequence levels walk through (see [LetterHivePuzzle.generate]).
  late final List<String> letterSets = () {
    final byMask = <int, String>{};
    for (final seed in seeds) {
      final letters = <String>[];
      for (var i = 0; i < seed.length; i++) {
        if (!letters.contains(seed[i])) letters.add(seed[i]);
      }
      letters.sort();
      byMask.putIfAbsent(maskOf(seed)!, () => letters.join());
    }
    final sets = byMask.values.toList()..sort();
    return sets..shuffle(Random(20261002));
  }();

  /// English drops S from the letter sets, as the well-known version of this
  /// puzzle does: with an S nearly every word comes with its plural and the
  /// puzzle doubles in size without getting any more interesting.
  int get _excluded => language == 'en' ? (_bit['S'] ?? 0) : 0;

  int? maskOf(String word) {
    var mask = 0;
    for (var i = 0; i < word.length; i++) {
      final b = _bit[word[i]];
      if (b == null) return null;
      mask |= b;
    }
    return mask;
  }

  bool isWord(String word) => _all.containsKey(word);

  /// Answers in [tiers] whose letters are within [full] and include [centre].
  List<String> answersFor(int full, int centre, Set<WordTier> tiers) {
    final bits = [
      for (var b = 0; b < 30; b++)
        if (full & (1 << b) != 0 && (1 << b) != centre) 1 << b,
    ];
    final out = <String>[];
    for (var subset = 0; subset < 1 << bits.length; subset++) {
      var mask = centre;
      for (var i = 0; i < bits.length; i++) {
        if (subset & (1 << i) != 0) mask |= bits[i];
      }
      for (final (word, tier)
          in _answersByMask[mask] ?? const <(String, WordTier)>[]) {
        if (tiers.contains(tier)) out.add(word);
      }
    }
    return out..sort();
  }

  static int _bitCount(int x) {
    var n = 0;
    while (x != 0) {
      x &= x - 1;
      n++;
    }
    return n;
  }
}

/// Per-level shape and goal.
class LetterHiveConfig {
  const LetterHiveConfig({
    required this.minAnswers,
    required this.maxAnswers,
    required this.goal,
    required this.tiers,
  });

  /// How many fair answers a puzzle may have. Too few and there is nothing to
  /// hunt for; too many and every guess lands.
  final int minAnswers;
  final int maxAnswers;

  /// Fraction of the puzzle's points needed to clear the level.
  final double goal;

  /// Which words count toward the goal. Rarer ones are always *accepted*;
  /// this only decides whether the goal expects you to know them.
  final Set<WordTier> tiers;
}

LetterHiveConfig letterHiveConfigForLevel(int level) {
  final t = min(1.0, (level - 1) / 30);
  // Early goals count only everyday and ordinary words, so they are reachable
  // without a specialist vocabulary; SCOWL's rarer tier is where BEBEERU and
  // MUUMUU live. From level 16 the goal expects some of those too, which is
  // where a strong vocabulary starts to pay.
  final rare = level > 15;
  return LetterHiveConfig(
    minAnswers: rare ? 20 : 12,
    maxAnswers: rare ? 55 : 40,
    goal: 0.25 + 0.30 * t,
    tiers: rare
        ? const {WordTier.common, WordTier.normal, WordTier.lessCommon}
        : const {WordTier.common, WordTier.normal},
  );
}

/// Why a word was or wasn't accepted.
enum HiveVerdict { ok, tooShort, missingCentre, notAWord, alreadyFound }

class LetterHivePuzzle {
  LetterHivePuzzle._(this.index, this.letters, this.answers, this.level)
    : _full = index.maskOf(letters)!,
      _centre = index.maskOf(letters[0])! {
    pangrams = {
      for (final w in answers)
        if (index.maskOf(w) == _full) w,
    };
    totalPoints = answers.fold(0, (sum, w) => sum + pointsFor(w));
  }

  final HiveIndex index;
  final int level;

  /// The seven letters; `letters[0]` is the centre.
  final String letters;

  /// The words the goal counts, sorted. Any other real word is a bonus.
  final List<String> answers;

  late final Set<String> pangrams;
  late final int totalPoints;

  final int _full;
  final int _centre;

  String get centre => letters[0];

  /// 1 point for a four-letter word, otherwise a point per letter; a pangram
  /// adds 7 — the usual scoring for this puzzle.
  int pointsFor(String word) {
    final base = word.length == minWordLength ? 1 : word.length;
    return index.maskOf(word) == _full ? base + 7 : base;
  }

  bool isPangram(String word) => index.maskOf(word) == _full;

  /// Points needed for one, two and three stars. One star clears the level.
  List<int> get starPoints {
    final goal = (totalPoints * letterHiveConfigForLevel(level).goal).ceil();
    return [
      goal,
      min(totalPoints, (goal * 1.5).ceil()),
      min(totalPoints, max(goal * 2, (totalPoints * 0.8).ceil())),
    ];
  }

  /// Checks [word] (letters already restricted to the hive by the keypad).
  /// Any real word counts, obscure ones included: a player who knows a rare
  /// word should never be told it isn't one. Only ordinary words are in
  /// [answers], so rarer finds are a bonus on top of the goal.
  HiveVerdict check(String word, Set<String> found) {
    if (word.length < minWordLength) return HiveVerdict.tooShort;
    if (!word.contains(centre)) return HiveVerdict.missingCentre;
    if (found.contains(word)) return HiveVerdict.alreadyFound;
    final mask = index.maskOf(word);
    if (mask == null || (mask & ~_full) != 0 || (mask & _centre) == 0) {
      return HiveVerdict.notAWord;
    }
    return index.isWord(word) ? HiveVerdict.ok : HiveVerdict.notAWord;
  }

  /// Bumped whenever generation changes, so a save from an older generator is
  /// not laid onto a different puzzle.
  static const generatorVersion = 2;

  /// Deterministic per level and language: same puzzle on every retry.
  ///
  /// Levels walk [HiveIndex.letterSets] in order, each taking the next set
  /// with a centre letter that fits its band, so no letter set comes back
  /// until every one has been used. Version 1 drew a random seed word per
  /// level from `Random(level * k + c)`, and nearby seeds gave correlated
  /// draws: 29 of the first 120 Norwegian levels repeated an earlier one,
  /// level 36 the very same letters as 35.
  static LetterHivePuzzle generate(int level, HiveIndex index) {
    final sets = index.letterSets;
    if (sets.isEmpty) {
      throw StateError('No seed words for ${index.language}');
    }
    var current = 1;
    (String, List<String>)? closest;
    // Later laps reuse a set with a different centre. The cap only grows
    // with the level, so a very high level still finds its place.
    final cap = sets.length * (3 + level ~/ 100);
    for (var i = 0; i < cap; i++) {
      final cfg = letterHiveConfigForLevel(current);
      final rng = Random(i * 7919 + 17);
      final distinct = sets[i % sets.length].split('')..shuffle(rng);
      for (final centre in distinct) {
        final others = distinct.where((c) => c != centre).join();
        final letters = centre + others;
        final answers = index.answersFor(
          index.maskOf(letters)!,
          index.maskOf(centre)!,
          cfg.tiers,
        );
        if (answers.length >= cfg.minAnswers &&
            answers.length <= cfg.maxAnswers) {
          if (current == level) {
            return LetterHivePuzzle._(index, letters, answers, level);
          }
          current++;
          closest = null;
          break;
        }
        // Remember the closest miss, so a thin word list still yields a puzzle.
        if (current == level &&
            (closest == null ||
                _bandDistance(answers.length, cfg) <
                    _bandDistance(closest.$2.length, cfg))) {
          closest = (letters, answers);
        }
      }
    }
    // Not expected: only if the band admits almost nothing in this language.
    final fallback =
        closest ??
        () {
          final letters = sets[level % sets.length];
          return (
            letters,
            index.answersFor(
              index.maskOf(letters)!,
              index.maskOf(letters[0])!,
              letterHiveConfigForLevel(level).tiers,
            ),
          );
        }();
    return LetterHivePuzzle._(index, fallback.$1, fallback.$2, level);
  }

  static int _bandDistance(int n, LetterHiveConfig cfg) => n < cfg.minAnswers
      ? cfg.minAnswers - n
      : (n > cfg.maxAnswers ? n - cfg.maxAnswers : 0);
}
