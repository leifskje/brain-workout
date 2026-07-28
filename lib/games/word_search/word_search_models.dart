import 'dart:math';

import '../../data/word_pool.dart';

/// Word Search — find hidden words in a letter grid. Early levels place words
/// forward-only (right, down, then diagonals); later ones add the reverse
/// directions, so a word may read right-to-left or bottom-to-top. Remaining
/// cells are filled with random letters, and placement-by-construction means
/// every target word is guaranteed findable.
///
/// From level 10 boards are *themed* — every word from one category, which is
/// shown — and from level 24 the word list is hidden, leaving only the category
/// and a count. That is the hardest thing this game does, and it is only fair
/// because the board is themed.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

/// The puzzle vocabulary now lives in `lib/data/word_pool.dart`, shared with
/// Word Scramble, which needs the same words plus a category for each. Keeping
/// two hand-written lists in sync was never going to work.

/// Letters used to fill the empty cells, per language.
const Map<String, String> _fillAlphabet = {
  'en': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  'nb': 'ABCDEFGHIJKLMNOPQRSTUVWXYZÆØÅ',
};

/// Fixed per-language seed salt (string hashCodes are not stable across runs).
const Map<String, int> _languageSalt = {'en': 1, 'nb': 2};

class WordSearchConfig {
  const WordSearchConfig({
    required this.size,
    required this.words,
    required this.directions,
    required this.allowCrossings,
    required this.themed,
    required this.showWordList,
  });

  final int size;
  final int words;

  /// Allowed placement directions as (dRow, dCol). Early levels are
  /// forward-reading only; later ones add the reverse directions, which is a
  /// large step up because a word can then run right-to-left or bottom-to-top.
  final List<(int, int)> directions;

  /// Whether words may cross / share letters. Off on lower levels — fully
  /// separate words are much easier to spot — and on from level 8 as a
  /// deliberate difficulty step.
  final bool allowCrossings;

  /// Whether every word comes from one category, which is then shown. Themed
  /// boards read as more deliberate than a random mix, and they are what makes
  /// hiding the word list playable.
  final bool themed;

  /// Whether the words are listed. When false, the player gets only the category
  /// and a count — a large difficulty jump, and the reason [themed] exists.
  final bool showWordList;
}

/// The difficulty curve.
///
/// Grid size stops at 11x11 on purpose. Letters need more room than Arrow Maze's
/// arrows, and the app enlarges all text globally, so a 12-wide grid crowds the
/// cells on a phone. Later levels get harder through reverse placement and
/// through hiding the word list instead — both cheaper on screen space and
/// harder than a few more cells.
WordSearchConfig wordSearchConfigForLevel(int level) {
  const right = (0, 1), down = (1, 0), downRight = (1, 1), upRight = (-1, 1);
  const left = (0, -1), up = (-1, 0), upLeft = (-1, -1), downLeft = (1, -1);
  const forward = [right, down, downRight, upRight];
  const every = [right, down, downRight, upRight, left, up, upLeft, downLeft];

  if (level < 3) {
    return const WordSearchConfig(
        size: 6,
        words: 4,
        directions: [right, down],
        allowCrossings: false,
        themed: false,
        showWordList: true);
  }
  if (level < 6) {
    return const WordSearchConfig(
        size: 7,
        words: 5,
        directions: [right, down, downRight],
        allowCrossings: false,
        themed: false,
        showWordList: true);
  }
  if (level < 10) {
    return WordSearchConfig(
        size: 8,
        words: 6,
        directions: const [right, down, downRight],
        allowCrossings: level >= 8,
        themed: false,
        showWordList: true);
  }
  if (level < 14) {
    return const WordSearchConfig(
        size: 9,
        words: 7,
        directions: forward,
        allowCrossings: true,
        themed: true,
        showWordList: true);
  }
  if (level < 18) {
    // Reverse placement arrives: words may now read backwards.
    return const WordSearchConfig(
        size: 10,
        words: 8,
        directions: [right, down, downRight, upRight, left, up],
        allowCrossings: true,
        themed: true,
        showWordList: true);
  }
  if (level < 24) {
    return const WordSearchConfig(
        size: 10,
        words: 9,
        directions: every,
        allowCrossings: true,
        themed: true,
        showWordList: true);
  }
  if (level < 30) {
    // The word list disappears: you get the category and a count.
    return const WordSearchConfig(
        size: 11,
        words: 9,
        directions: every,
        allowCrossings: true,
        themed: true,
        showWordList: false);
  }
  return const WordSearchConfig(
      size: 11,
      words: 10,
      directions: every,
      allowCrossings: true,
      themed: true,
      showWordList: false);
}

/// One placed target word and whether the player has found it yet.
class PlacedWord {
  PlacedWord(this.word, this.row, this.col, this.dRow, this.dCol);

  final String word;
  final int row;
  final int col;
  final int dRow;
  final int dCol;
  bool found = false;

  List<(int, int)> get cells => [
        for (var i = 0; i < word.length; i++)
          (row + dRow * i, col + dCol * i)
      ];
}

class WordSearchBoard {
  WordSearchBoard({required this.grid, required this.words, this.category});

  final List<List<String>> grid; // size x size of single letters
  final List<PlacedWord> words;

  /// Set on themed boards, where every word shares a category and the category
  /// is shown to the player. Null on the early mixed boards.
  final WordCategory? category;

  int get size => grid.length;
  bool get isSolved => words.every((w) => w.found);
  int get foundCount => words.where((w) => w.found).length;

  String letterAt(int r, int c) => grid[r][c];

  /// Spells the selection and, if it reads as a not-yet-found target word
  /// (forwards or backwards), marks it found and returns it. Null otherwise.
  PlacedWord? trySelect(List<(int, int)> cells) {
    final spelled = [for (final (r, c) in cells) grid[r][c]].join();
    final reversed = spelled.split('').reversed.join();
    for (final w in words) {
      if (!w.found && (w.word == spelled || w.word == reversed)) {
        w.found = true;
        return w;
      }
    }
    return null;
  }

  /// Builds a board for [level] in [language] ('en' or 'nb'), seeded so a
  /// retry gives the same puzzle. Every target word is placed before the
  /// filler letters, so all of them are guaranteed findable.
  static WordSearchBoard generate(int level, String language) {
    final cfg = wordSearchConfigForLevel(level);
    final alphabet = _fillAlphabet[language] ?? _fillAlphabet['en']!;
    final salt = _languageSalt[language] ?? 0;
    final rng = Random(level * 6151 + salt * 977 + 13);

    // Themed levels draw every word from one category, which is then shown. A
    // category is only usable if it has enough words that fit the grid — the
    // longest words are the scarcest — so unusable ones are skipped rather than
    // silently producing a board with too few words.
    WordCategory? category;
    var pool = wordPoolFor(language);
    if (cfg.themed) {
      final grouped = wordPoolByCategory(language);
      final usable = [
        for (final entry in grouped.entries)
          if (entry.value.where((w) => w.length <= cfg.size).length >=
              cfg.words)
            entry.key,
      ]..sort((a, b) => a.index.compareTo(b.index)); // stable order to seed from
      if (usable.isNotEmpty) {
        category = usable[rng.nextInt(usable.length)];
        pool = grouped[category]!;
      }
    }

    for (var attempt = 0; attempt < 200; attempt++) {
      final board = _tryGenerate(cfg, pool, alphabet, rng, category);
      if (board != null) return board;
    }
    // Practically unreachable: placement of a handful of short words on the
    // grid succeeds within a few attempts. Loosen to fewer words as a net.
    return _tryGenerate(
        WordSearchConfig(
            size: cfg.size,
            words: 3,
            directions: cfg.directions,
            allowCrossings: cfg.allowCrossings,
            themed: cfg.themed,
            showWordList: cfg.showWordList),
        pool,
        alphabet,
        rng,
        category)!;
  }

  static WordSearchBoard? _tryGenerate(WordSearchConfig cfg,
      List<String> pool, String alphabet, Random rng, WordCategory? category) {
    final size = cfg.size;
    final grid = List.generate(size, (_) => List<String?>.filled(size, null));
    final candidates = [...pool.where((w) => w.length <= size)]..shuffle(rng);
    final placed = <PlacedWord>[];

    // Cells must be empty — or, when crossings are allowed, may hold the
    // same letter where two words cross.
    bool fits(String word, int r0, int c0, int dr, int dc) {
      for (var i = 0; i < word.length; i++) {
        final r = r0 + dr * i, c = c0 + dc * i;
        if (r < 0 || r >= size || c < 0 || c >= size) return false;
        final existing = grid[r][c];
        if (existing != null &&
            !(cfg.allowCrossings && existing == word[i])) {
          return false;
        }
      }
      return true;
    }

    void put(String word, int r0, int c0, int dr, int dc) {
      for (var i = 0; i < word.length; i++) {
        grid[r0 + dr * i][c0 + dc * i] = word[i];
      }
      placed.add(PlacedWord(word, r0, c0, dr, dc));
    }

    for (final word in candidates) {
      if (placed.length == cfg.words) break;
      var done = false;

      // When crossings are allowed, actively try placements that cross an
      // already-placed word — random placement almost never does by chance.
      if (cfg.allowCrossings && placed.isNotEmpty) {
        final anchors = <(int, int, int, int)>[]; // r0, c0, dr, dc
        for (final pw in placed) {
          for (final (r, c) in pw.cells) {
            final letter = grid[r][c]!;
            for (var i = 0; i < word.length; i++) {
              if (word[i] != letter) continue;
              for (final (dr, dc) in cfg.directions) {
                anchors.add((r - dr * i, c - dc * i, dr, dc));
              }
            }
          }
        }
        anchors.shuffle(rng);
        for (final (r0, c0, dr, dc) in anchors.take(25)) {
          if (fits(word, r0, c0, dr, dc)) {
            put(word, r0, c0, dr, dc);
            done = true;
            break;
          }
        }
      }

      for (var t = 0; t < 40 && !done; t++) {
        final (dr, dc) = cfg.directions[rng.nextInt(cfg.directions.length)];
        final span = word.length - 1;
        final rMin = dr < 0 ? span : 0, rMax = size - 1 - (dr > 0 ? span : 0);
        final cMin = dc < 0 ? span : 0, cMax = size - 1 - (dc > 0 ? span : 0);
        if (rMax < rMin || cMax < cMin) continue;
        final r0 = rMin + rng.nextInt(rMax - rMin + 1);
        final c0 = cMin + rng.nextInt(cMax - cMin + 1);
        if (!fits(word, r0, c0, dr, dc)) continue;
        put(word, r0, c0, dr, dc);
        done = true;
      }
    }
    if (placed.length < cfg.words) return null;

    final filled = [
      for (final row in grid)
        [
          for (final cell in row)
            cell ?? alphabet[rng.nextInt(alphabet.length)]
        ]
    ];
    // Show the word list alphabetically so it reads calmly.
    placed.sort((a, b) => a.word.compareTo(b.word));
    return WordSearchBoard(grid: filled, words: placed, category: category);
  }
}
