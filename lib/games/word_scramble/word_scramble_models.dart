import 'dart:math';

import '../../data/word_pool.dart';
import '../../data/word_tier.dart';

/// Word Scramble — the letters of a familiar word are shuffled; tap them in
/// the right order to spell it. A level is a short run of words.
///
/// Draws on the shared categorised pool in `lib/data/word_pool.dart`. The
/// category travels with the word because roughly 60% of scrambles spell more
/// than one real word (LAKE/LEAK, MELK/KLEM), and the category is what tells the
/// player which one is wanted.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

class WordScrambleConfig {
  const WordScrambleConfig({
    required this.minLen,
    required this.maxLen,
    required this.words,
    required this.hearts,
    required this.tiers,
    required this.fromPool,
  });

  final int minLen;
  final int maxLen;
  final int words;
  final int hearts;

  /// Which commonness tiers this level may draw from. Never [WordTier.junk].
  final Set<WordTier> tiers;

  /// Whether words come from the curated pool (so a category can be shown) or
  /// from the full dictionary (harder, and no category).
  final bool fromPool;
}

/// The difficulty curve.
///
/// Early levels use the curated pool, so every puzzle carries a category to
/// identify it. Past that the pool is exhausted as a difficulty source — it holds
/// only 11 English words of 8 letters — so words come from the dictionary
/// instead, graded by how common they are. Those words have no category, and
/// losing the hint is itself the next step up; the near-miss rule keeps that fair,
/// since spelling a different real word still costs nothing.
///
/// Word length stops at 8 deliberately: the shipped dictionaries cover 3-8, and
/// longer tiles would crowd the board at the app's enlarged text size.
WordScrambleConfig wordScrambleConfigForLevel(int level) {
  const easy = {WordTier.common, WordTier.normal};
  if (level < 4) {
    return const WordScrambleConfig(
        minLen: 3, maxLen: 4, words: 3, hearts: 3, tiers: easy, fromPool: true);
  }
  if (level < 8) {
    return const WordScrambleConfig(
        minLen: 4, maxLen: 5, words: 4, hearts: 3, tiers: easy, fromPool: true);
  }
  if (level < 13) {
    return const WordScrambleConfig(
        minLen: 5, maxLen: 6, words: 4, hearts: 3, tiers: easy, fromPool: true);
  }

  // Dictionary levels: rarer words, longer words, and more of them per round.
  final tiers = level < 21
      ? const {WordTier.common}
      : level < 31
          ? const {WordTier.common, WordTier.normal}
          : const {WordTier.normal, WordTier.lessCommon};
  return WordScrambleConfig(
    minLen: (5 + (level - 13) ~/ 8).clamp(5, 7),
    maxLen: 8,
    words: (5 + (level - 13) ~/ 12).clamp(5, 7),
    hearts: 3,
    tiers: tiers,
    fromPool: false,
  );
}

const Map<String, int> _languageSalt = {'en': 1, 'nb': 2};

class ScrambleWord {
  ScrambleWord(this.word, this.letters, this.category);

  final String word;

  /// The word's letters in scrambled order (never equal to the word itself).
  final List<String> letters;

  /// Shown to the player so they know which word is wanted. Null on dictionary
  /// levels, where having no hint is part of the difficulty.
  final WordCategory? category;
}

/// Supplies dictionary words of a given length within [tiers], for the levels
/// that reach past the curated pool.
///
/// Passed in rather than looked up, so this file stays free of Flutter and the
/// generator stays unit-testable. When it is null — in tests, or before the
/// dictionary has loaded — generation falls back to the curated pool, which is
/// easier but never broken.
typedef DictionaryWords = List<String> Function(int length, Set<WordTier> tiers);

/// Builds the level's run of words, seeded per (level, language) so a retry
/// gives the same puzzles.
///
/// Words are *dealt*, not drawn: the candidates are shuffled once per language
/// and each level takes the next slice. Shuffling independently per level meant a
/// level had no idea what earlier ones had used, so across levels 1-40 Norwegian
/// served 188 puzzles from only 44 distinct words — BILDE twelve times. Dealing
/// from one order means a word cannot recur until the candidates are exhausted.
List<ScrambleWord> generateScrambleRound(
  int level,
  String language, {
  DictionaryWords? dictionaryWords,
  int dealOffset = 0,
}) {
  final cfg = wordScrambleConfigForLevel(level);
  final salt = _languageSalt[language] ?? 0;
  // One order per language, not per level — that is what stops repeats.
  final dealer = Random(salt * 389 + 7);

  // Pool words always have a category; dictionary words never do — hence the
  // nullable second field rather than weakening PoolWord.
  final candidates = <(String, WordCategory?)>[];
  if (!cfg.fromPool && dictionaryWords != null) {
    for (var n = cfg.minLen; n <= cfg.maxLen; n++) {
      candidates.addAll(dictionaryWords(n, cfg.tiers).map((w) => (w, null)));
    }
  }
  if (candidates.isEmpty) {
    // Pool levels, and the fallback when no dictionary is available.
    final entries = categorisedWords[language] ?? categorisedWords['en']!;
    candidates.addAll([
      for (final e in entries)
        if (e.word.length >= cfg.minLen && e.word.length <= cfg.maxLen)
          (e.word, e.category)
    ]);
  }
  candidates.shuffle(dealer);

  // Slice for this level, wrapping once the candidates run out.
  final start =
      ((level - 1) * cfg.words + dealOffset) % candidates.length;
  final picked = [
    for (var i = 0; i < cfg.words && i < candidates.length; i++)
      candidates[(start + i) % candidates.length],
  ];

  // Letter order still varies per level, so a repeat looks different.
  final rng = Random(level * 2741 + salt * 389 + 7);
  return [
    for (final (word, category) in picked)
      ScrambleWord(word, _scramble(word, rng), category),
  ];
}

/// A different word for slot [wordIndex] of [level]'s round — the "new word"
/// button, for when a player is simply stuck.
///
/// [swap] increments with each press so repeated taps keep moving through the
/// candidates rather than cycling between two words. Difficulty is unchanged:
/// the replacement comes from the same level's candidate list.
ScrambleWord swapScrambleWord(
  int level,
  String language,
  int wordIndex,
  int swap, {
  DictionaryWords? dictionaryWords,
}) {
  final cfg = wordScrambleConfigForLevel(level);
  // Shift the deal, not the level: a different level would bring a different
  // length band and tier set, so the replacement has to come from this level's
  // own candidates to keep the difficulty honest.
  final shifted = generateScrambleRound(
    level,
    language,
    dictionaryWords: dictionaryWords,
    dealOffset: swap * cfg.words,
  );
  return shifted[wordIndex % shifted.length];
}

/// The word's letters in an order that isn't the word itself. Every pool word
/// has at least two distinct letters, so this terminates.
List<String> _scramble(String word, Random rng) {
  final letters = word.split('');
  do {
    letters.shuffle(rng);
  } while (letters.join() == word);
  return letters;
}
