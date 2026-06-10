import 'dart:math';

/// Word Search — find hidden words in a letter grid. Words are placed
/// forward-only (right, down, and diagonals at higher levels) so nothing has
/// to be read backwards; remaining cells are filled with random letters.
/// Placement-by-construction means every target word is guaranteed findable.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

/// Curated, familiar words (3–8 letters) per language — everyday nouns an
/// elderly player recognises at a glance. Uppercase; Norwegian includes ÆØÅ.
const Map<String, List<String>> wordSearchWords = {
  'en': [
    'APPLE', 'BREAD', 'MILK', 'BUTTER', 'CHEESE', 'FISH', 'CAR', 'BOAT',
    'TRAIN', 'PLANE', 'HOUSE', 'CABIN', 'FOREST', 'HILL', 'LAKE', 'BEACH',
    'FLOWER', 'ROSE', 'CAT', 'DOG', 'HORSE', 'COW', 'SHEEP', 'BIRD', 'FOX',
    'BEAR', 'SUN', 'MOON', 'STAR', 'RAIN', 'SNOW', 'WIND', 'SUMMER',
    'WINTER', 'SPRING', 'AUTUMN', 'COFFEE', 'TEA', 'CAKE', 'SUGAR', 'SALT',
    'TABLE', 'CHAIR', 'BED', 'LAMP', 'DOOR', 'WINDOW', 'ROOF', 'FLOOR',
    'BOOK', 'PAPER', 'LETTER', 'PEN', 'CLOCK', 'KEY', 'HAT', 'GLOVE',
    'SHOE', 'JACKET', 'DRESS', 'CHILD', 'MOTHER', 'FATHER', 'FRIEND',
    'CITY', 'STREET', 'ROAD', 'BRIDGE', 'CHURCH', 'SCHOOL', 'SHOP', 'MONEY',
    'HEART', 'HAND', 'FOOT', 'EYE', 'EAR', 'NOSE', 'MOUTH', 'HAIR', 'TOOTH',
    'ARM', 'LEG', 'MUSIC', 'SONG', 'DANCE', 'PARTY', 'GIFT', 'PICTURE',
    'COLOR', 'RED', 'BLUE', 'GREEN', 'YELLOW', 'WHITE', 'BLACK', 'GARDEN',
    'GRASS', 'TREE', 'LEAF', 'STONE', 'RIVER',
  ],
  'nb': [
    'EPLE', 'BRØD', 'MELK', 'SMØR', 'OST', 'FISK', 'BIL', 'BÅT', 'TOG',
    'FLY', 'HUS', 'HYTTE', 'SKOG', 'FJELL', 'SJØ', 'STRAND', 'BLOMST',
    'ROSE', 'KATT', 'HUND', 'HEST', 'SAU', 'FUGL', 'ELG', 'REV', 'BJØRN',
    'SOL', 'MÅNE', 'STJERNE', 'REGN', 'SNØ', 'VIND', 'SOMMER', 'VINTER',
    'VÅR', 'HØST', 'KAFFE', 'KAKE', 'SUKKER', 'SALT', 'BORD', 'STOL',
    'SENG', 'LAMPE', 'DØR', 'VINDU', 'TAK', 'GULV', 'BOK', 'AVIS', 'BREV',
    'PENN', 'KLOKKE', 'NØKKEL', 'GENSER', 'LUE', 'VOTT', 'SKO', 'JAKKE',
    'KJOLE', 'BARN', 'MOR', 'FAR', 'BESTEMOR', 'VENN', 'NABO', 'GATE',
    'VEI', 'BRO', 'KIRKE', 'SKOLE', 'BUTIKK', 'PENGER', 'HJERTE', 'HÅND',
    'FOT', 'ØYE', 'ØRE', 'NESE', 'MUNN', 'HÅR', 'TANN', 'ARM', 'BEIN',
    'MUSIKK', 'SANG', 'DANS', 'FEST', 'GAVE', 'JUL', 'PÅSKE', 'FERIE',
    'BILDE', 'FARGE', 'RØD', 'BLÅ', 'GRØNN', 'GUL', 'HVIT', 'SVART',
    'HAGE', 'GRESS', 'TRE', 'BLAD', 'STEIN', 'ELV',
  ],
};

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
  });

  final int size;
  final int words;

  /// Allowed placement directions as (dRow, dCol) — forward-reading only, so
  /// no word has to be read backwards.
  final List<(int, int)> directions;

  /// Whether words may cross / share letters. Off on lower levels — fully
  /// separate words are much easier to spot — and on from level 8 as a
  /// deliberate difficulty step.
  final bool allowCrossings;
}

WordSearchConfig wordSearchConfigForLevel(int level) {
  const right = (0, 1), down = (1, 0), downRight = (1, 1), upRight = (-1, 1);
  if (level < 3) {
    return const WordSearchConfig(
        size: 6, words: 4, directions: [right, down], allowCrossings: false);
  }
  if (level < 6) {
    return const WordSearchConfig(
        size: 7,
        words: 5,
        directions: [right, down, downRight],
        allowCrossings: false);
  }
  if (level < 10) {
    return WordSearchConfig(
        size: 8,
        words: 6,
        directions: const [right, down, downRight],
        allowCrossings: level >= 8);
  }
  return const WordSearchConfig(
      size: 9,
      words: 7,
      directions: [right, down, downRight, upRight],
      allowCrossings: true);
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
  WordSearchBoard({required this.grid, required this.words});

  final List<List<String>> grid; // size x size of single letters
  final List<PlacedWord> words;

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
    final pool = wordSearchWords[language] ?? wordSearchWords['en']!;
    final alphabet = _fillAlphabet[language] ?? _fillAlphabet['en']!;
    final salt = _languageSalt[language] ?? 0;
    final rng = Random(level * 6151 + salt * 977 + 13);

    for (var attempt = 0; attempt < 200; attempt++) {
      final board = _tryGenerate(cfg, pool, alphabet, rng);
      if (board != null) return board;
    }
    // Practically unreachable: placement of a handful of short words on the
    // grid succeeds within a few attempts. Loosen to fewer words as a net.
    return _tryGenerate(
        WordSearchConfig(
            size: cfg.size,
            words: 3,
            directions: cfg.directions,
            allowCrossings: cfg.allowCrossings),
        pool,
        alphabet,
        rng)!;
  }

  static WordSearchBoard? _tryGenerate(WordSearchConfig cfg,
      List<String> pool, String alphabet, Random rng) {
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
    return WordSearchBoard(grid: filled, words: placed);
  }
}
