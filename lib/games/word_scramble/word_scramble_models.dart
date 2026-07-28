import 'dart:math';

import '../../data/word_pool.dart';

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
  });

  final int minLen;
  final int maxLen;
  final int words;
  final int hearts;
}

WordScrambleConfig wordScrambleConfigForLevel(int level) {
  if (level < 4) {
    return const WordScrambleConfig(minLen: 3, maxLen: 4, words: 3, hearts: 3);
  }
  if (level < 7) {
    return const WordScrambleConfig(minLen: 4, maxLen: 5, words: 4, hearts: 3);
  }
  if (level < 10) {
    return const WordScrambleConfig(minLen: 5, maxLen: 6, words: 4, hearts: 3);
  }
  return const WordScrambleConfig(minLen: 5, maxLen: 8, words: 5, hearts: 3);
}

const Map<String, int> _languageSalt = {'en': 1, 'nb': 2};

class ScrambleWord {
  ScrambleWord(this.word, this.letters, this.category);

  final String word;

  /// The word's letters in scrambled order (never equal to the word itself).
  final List<String> letters;

  /// Shown to the player, so they know which word the letters are meant to be.
  final WordCategory category;
}

/// Builds the level's run of words, seeded per (level, language) so a retry
/// gives the same puzzles.
///
/// Words are *dealt*, not drawn: the band's words are shuffled once per language
/// and each level takes the next slice. Shuffling independently per level meant a
/// level had no idea what earlier ones had used, so across levels 1-40 Norwegian
/// served 188 puzzles from only 44 distinct words — BILDE twelve times. Dealing
/// from one order means a word cannot recur until the band is exhausted.
List<ScrambleWord> generateScrambleRound(int level, String language) {
  final cfg = wordScrambleConfigForLevel(level);
  final entries = categorisedWords[language] ?? categorisedWords['en']!;
  final salt = _languageSalt[language] ?? 0;

  final band = [
    ...entries.where(
        (e) => e.word.length >= cfg.minLen && e.word.length <= cfg.maxLen)
  ]..shuffle(Random(salt * 389 + 7)); // one order per language, not per level

  // Slice for this level, wrapping once the band runs out.
  final start = ((level - 1) * cfg.words) % band.length;
  final picked = [
    for (var i = 0; i < cfg.words && i < band.length; i++)
      band[(start + i) % band.length],
  ];

  // Letter order still varies per level, so a repeat looks different.
  final rng = Random(level * 2741 + salt * 389 + 7);
  return [
    for (final entry in picked)
      ScrambleWord(entry.word, _scramble(entry.word, rng), entry.category),
  ];
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
