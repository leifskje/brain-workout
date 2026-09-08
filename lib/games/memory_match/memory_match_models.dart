import 'dart:math';

/// One card in the memory grid.
class MemoryCard {
  MemoryCard({required this.id, required this.symbol});

  final int id;
  final String symbol;
  bool faceUp = false;
  bool matched = false;
}

/// Per-level board shape.
class MemoryLevelConfig {
  const MemoryLevelConfig({
    required this.rows,
    required this.cols,
    this.groupSize = 2,
  });

  final int rows;
  final int cols;

  /// How many cards make a match: 2 for pairs, 3 for triples.
  final int groupSize;

  /// How many matching groups the board holds.
  int get groups => (rows * cols) ~/ groupSize;

  bool get isTriples => groupSize == 3;
}

// Board shapes by level. Clamped at the last entry for higher levels.
//
// Rows grow rather than columns past 5x6: the screen sizes cards to fit, so
// widening to 7 columns would shrink them below the ~60dp this audience needs,
// whereas an extra row costs vertical space the portrait layout still has.
// 7x6 is the end of that road — 8 rows starts squeezing cards again.
//
// 21 pairs is the structural ceiling for *pairs*, which is why the ladder then
// switches to **triples**: matching three of a kind rather than two is a change
// of mechanic, and the only axis left once card size is width-bound.
//
// Triples restart smaller (8 groups against the 21 pairs just before), the same
// way Word Search's hidden-list levels do. A new rule should not arrive at full
// difficulty, and 24 cards of an unfamiliar mechanic is not a step down in
// practice. Every triples layout has a card count divisible by three.
const _layouts = <List<int>>[
  [2, 3, 2], // L1  — 3 pairs
  [2, 4, 2], // L2  — 4 pairs
  [3, 4, 2], // L3  — 6 pairs
  [4, 4, 2], // L4  — 8 pairs
  [4, 5, 2], // L5  — 10 pairs
  [4, 6, 2], // L6  — 12 pairs
  [5, 6, 2], // L7  — 15 pairs
  [6, 6, 2], // L8  — 18 pairs
  [7, 6, 2], // L9  — 21 pairs, the end of the pairs ladder
  [4, 6, 3], // L10 — 8 triples
  [5, 6, 3], // L11 — 10 triples
  [6, 6, 3], // L12 — 12 triples
  [7, 6, 3], // L13+ — 14 triples
];

MemoryLevelConfig memoryConfigForLevel(int level) {
  final l = _layouts[(level - 1).clamp(0, _layouts.length - 1)];
  return MemoryLevelConfig(rows: l[0], cols: l[1], groupSize: l[2]);
}

// Distinct, high-contrast, easily-told-apart symbols.
//
// The pool must be comfortably *larger* than the largest level, not merely big
// enough. At 21 symbols it exactly equalled the 21 pairs of level 9, so every
// level from 9 up drew the whole pool and showed the identical set of pictures —
// only the positions changed, and five levels in a row read as "the same board".
// Keep a wide margin here so the picture set varies too.
//
// Written as escapes so the file stays pure ASCII. Chosen to stay legible at
// ~45dp and to avoid confusable pairs (no tomato beside the apple, no wolf
// beside the dog).
const _symbols = <String>[
  // fruit & food
  '\u{1F34E}', '\u{1F34C}', '\u{1F347}', '\u{1F34A}', '\u{1F353}',
  '\u{1F352}', '\u{1F34B}', '\u{1F349}', '\u{1F370}', '\u{1F355}',
  // animals
  '\u{1F436}', '\u{1F431}', '\u{1F430}', '\u{1F43B}', '\u{1F438}',
  '\u{1F43C}', '\u{1F981}', '\u{1F437}', '\u{1F435}', '\u{1F427}',
  '\u{1F989}', '\u{1F41D}', '\u{1F422}', '\u{1F42C}',
  // nature & weather
  '\u{1F338}', '\u{1F33B}', '\u{1F332}', '\u{1F308}', '\u{1F31F}',
  '\u{1F319}', '\u{26C4}', '\u{1F525}',
  // things
  '\u{26BD}', '\u{1F697}', '\u{1F682}', '\u{26F5}', '\u{1F6B2}',
  '\u{1F388}', '\u{1F514}', '\u{1F98B}', '\u{1F381}', '\u{1F3E0}',
  '\u{1F511}', '\u{1F3B8}',
];

/// The memory board: a shuffled deck of matching pairs. Always winnable;
/// deterministic per level (seeded) so a retry gives the same layout.
class MemoryBoard {
  MemoryBoard({
    required this.rows,
    required this.cols,
    required this.cards,
    this.groupSize = 2,
  });

  final int rows;
  final int cols;
  final List<MemoryCard> cards;

  /// How many cards make a match on this board: 2 for pairs, 3 for triples.
  final int groupSize;

  bool get isTriples => groupSize == 3;

  /// How many matching groups the board holds.
  int get groups => cards.length ~/ groupSize;

  /// How many groups the player has completed.
  int get groupsFound => cards.where((c) => c.matched).length ~/ groupSize;

  bool get isSolved => cards.every((c) => c.matched);

  static MemoryBoard generate(int level) {
    final cfg = memoryConfigForLevel(level);
    final rng = Random(level * 524287 + 13);

    final pool = List<String>.of(_symbols)..shuffle(rng);
    final chosen = pool.take(cfg.groups).toList();

    final deck = <MemoryCard>[];
    var id = 0;
    for (final symbol in chosen) {
      for (var n = 0; n < cfg.groupSize; n++) {
        deck.add(MemoryCard(id: id++, symbol: symbol));
      }
    }
    deck.shuffle(rng);

    return MemoryBoard(
        rows: cfg.rows,
        cols: cfg.cols,
        cards: deck,
        groupSize: cfg.groupSize);
  }
}
