import 'dart:math';

import '../word_search/word_search_models.dart' show wordSearchWords;

/// Word Scramble — the letters of a familiar word are shuffled; tap them in
/// the right order to spell it. A level is a short run of words.
///
/// Reuses the curated word pools from Word Search (everyday words, en + nb).
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
  ScrambleWord(this.word, this.letters);

  final String word;

  /// The word's letters in scrambled order (never equal to the word itself).
  final List<String> letters;
}

/// Builds the level's run of words, seeded per (level, language) so a retry
/// gives the same puzzles.
List<ScrambleWord> generateScrambleRound(int level, String language) {
  final cfg = wordScrambleConfigForLevel(level);
  final pool = wordSearchWords[language] ?? wordSearchWords['en']!;
  final salt = _languageSalt[language] ?? 0;
  final rng = Random(level * 2741 + salt * 389 + 7);

  final candidates = [
    ...pool.where((w) => w.length >= cfg.minLen && w.length <= cfg.maxLen)
  ]..shuffle(rng);

  final words = <ScrambleWord>[];
  for (final word in candidates.take(cfg.words)) {
    final letters = word.split('');
    // Shuffle until the order differs from the word (every pool word has at
    // least two distinct letters, so this terminates).
    do {
      letters.shuffle(rng);
    } while (letters.join() == word);
    words.add(ScrambleWord(word, letters));
  }
  return words;
}
