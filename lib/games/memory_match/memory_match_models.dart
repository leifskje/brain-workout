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
  const MemoryLevelConfig({required this.rows, required this.cols});

  final int rows;
  final int cols;

  int get pairs => (rows * cols) ~/ 2;
}

// Board shapes by level (always an even number of cards). Clamped at the last
// entry for higher levels.
const _layouts = <List<int>>[
  [2, 3], // L1 — 3 pairs
  [2, 4], // L2 — 4 pairs
  [3, 4], // L3 — 6 pairs
  [4, 4], // L4 — 8 pairs
  [4, 5], // L5 — 10 pairs
  [4, 6], // L6 — 12 pairs
  [5, 6], // L7+ — 15 pairs
];

MemoryLevelConfig memoryConfigForLevel(int level) {
  final l = _layouts[(level - 1).clamp(0, _layouts.length - 1)];
  return MemoryLevelConfig(rows: l[0], cols: l[1]);
}

// Distinct, high-contrast, easily-told-apart symbols (must be >= max pairs).
const _symbols = <String>[
  '🍎', '🍌', '🍇', '🍊', '🍓', '🍒', '🍋', '🍉',
  '🐶', '🐱', '🐰', '🐻', '🌸', '🌟', '⚽', '🚗',
  '🎈', '🍰',
];

/// The memory board: a shuffled deck of matching pairs. Always winnable;
/// deterministic per level (seeded) so a retry gives the same layout.
class MemoryBoard {
  MemoryBoard({required this.rows, required this.cols, required this.cards});

  final int rows;
  final int cols;
  final List<MemoryCard> cards;

  bool get isSolved => cards.every((c) => c.matched);

  static MemoryBoard generate(int level) {
    final cfg = memoryConfigForLevel(level);
    final rng = Random(level * 524287 + 13);

    final pool = List<String>.of(_symbols)..shuffle(rng);
    final chosen = pool.take(cfg.pairs).toList();

    final deck = <MemoryCard>[];
    var id = 0;
    for (final symbol in chosen) {
      deck.add(MemoryCard(id: id++, symbol: symbol));
      deck.add(MemoryCard(id: id++, symbol: symbol));
    }
    deck.shuffle(rng);

    return MemoryBoard(rows: cfg.rows, cols: cfg.cols, cards: deck);
  }
}
