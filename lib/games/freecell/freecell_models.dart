import 'dart:math';

/// FreeCell. 52 cards in 8 cascades, a few free cells, four foundations built
/// Ace to King by suit. Cascades build down in alternating colours.
///
/// **Every deal is proven solvable by [solveFreeCell] before anyone sees it.**
/// Most FreeCell deals can be won, but not all, and with fewer free cells far
/// fewer. A deal the solver cannot finish within its node budget is thrown away.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

// ---------------------------------------------------------------- cards ---

/// Cards are ints 0..51: suit = card ~/ 13 (clubs, diamonds, hearts, spades),
/// rank = card % 13 + 1 (Ace = 1, King = 13).
int cardSuit(int card) => card ~/ 13;
int cardRank(int card) => card % 13 + 1;
bool cardRed(int card) {
  final s = card ~/ 13;
  return s == 1 || s == 2;
}

int cardOf(int suit, int rank) => suit * 13 + rank - 1;

/// Whether [card] may sit on [onto] in a cascade: one lower, other colour.
bool stacksOn(int card, int onto) =>
    cardRank(onto) == cardRank(card) + 1 && cardRed(onto) != cardRed(card);

const int cascadeCount = 8;

// ---------------------------------------------------------------- moves ---

enum PileKind { cascade, cell, foundation }

/// One player move. [count] > 1 only for a run moving between cascades (a
/// "supermove", which the rules allow when enough space exists to do it one
/// card at a time). A foundation move's [to] is always the card's suit.
class FreeCellMove {
  const FreeCellMove(
    this.fromKind,
    this.from,
    this.toKind,
    this.to, [
    this.count = 1,
  ]);

  final PileKind fromKind;
  final int from;
  final PileKind toKind;
  final int to;
  final int count;

  /// Packed as one int for the autosave.
  int encode() =>
      (((fromKind.index * 8 + from) * 3 + toKind.index) * 8 + to) * 64 + count;

  static FreeCellMove decode(int v) {
    final count = v % 64;
    v ~/= 64;
    final to = v % 8;
    v ~/= 8;
    final toKind = PileKind.values[v % 3];
    v ~/= 3;
    final from = v % 8;
    final fromKind = PileKind.values[v ~/ 8];
    return FreeCellMove(fromKind, from, toKind, to, count);
  }

  @override
  bool operator ==(Object other) =>
      other is FreeCellMove && other.encode() == encode();

  @override
  int get hashCode => encode();

  @override
  String toString() =>
      '${fromKind.name}$from -> ${toKind.name}$to${count > 1 ? ' x$count' : ''}';
}

// ------------------------------------------------------------- position ---

/// A position: the cascades (bottom card first), the free cells (-1 = empty)
/// and how many cards each suit has on its foundation.
class FreeCellPosition {
  FreeCellPosition(this.cascades, this.cells, this.foundations);

  /// Deals [deck] round-robin: the first four cascades get 7 cards, the rest 6.
  factory FreeCellPosition.deal(List<int> deck, int cellCount) {
    final cascades = List.generate(cascadeCount, (_) => <int>[]);
    for (var i = 0; i < deck.length; i++) {
      cascades[i % cascadeCount].add(deck[i]);
    }
    return FreeCellPosition(
      cascades,
      List.filled(cellCount, -1),
      List.filled(4, 0),
    );
  }

  final List<List<int>> cascades;
  final List<int> cells;

  /// Cards on each suit's foundation, i.e. the rank of its top card.
  final List<int> foundations;

  FreeCellPosition copy() => FreeCellPosition(
    [for (final c in cascades) List.of(c)],
    List.of(cells),
    List.of(foundations),
  );

  int get homeCount =>
      foundations[0] + foundations[1] + foundations[2] + foundations[3];

  bool get isWon => homeCount == 52;

  int get emptyCells {
    var n = 0;
    for (final c in cells) {
      if (c < 0) n++;
    }
    return n;
  }

  int get emptyCascades {
    var n = 0;
    for (final c in cascades) {
      if (c.isEmpty) n++;
    }
    return n;
  }

  /// Index where the movable run at the bottom of cascade [col] starts: every
  /// card from there down is in alternating-colour descending order.
  int runStart(int col) {
    final c = cascades[col];
    if (c.isEmpty) return 0;
    var k = c.length - 1;
    while (k > 0 && stacksOn(c[k], c[k - 1])) {
      k--;
    }
    return k;
  }

  /// Longest run that may move at once: (empty cells + 1) x 2^(empty
  /// cascades), not counting the destination when it is itself empty.
  int maxRun({required bool toEmptyCascade}) {
    var empties = emptyCascades;
    if (toEmptyCascade) empties--;
    return (emptyCells + 1) << (empties < 0 ? 0 : empties);
  }

  bool canGoHome(int card) => foundations[cardSuit(card)] == cardRank(card) - 1;

  /// The standard "safe to auto-play" rule: aces and twos always; anything
  /// else once both opposite-colour cards one rank lower are already home, so
  /// nothing could still want to be placed on it.
  bool isSafeHome(int card) {
    final r = cardRank(card);
    if (r <= 2) return true;
    final red = cardRed(card);
    final a = red ? 0 : 1, b = red ? 3 : 2;
    return foundations[a] >= r - 1 && foundations[b] >= r - 1;
  }

  /// The card at the bottom of the group [m] would move, or -1.
  int movingCard(FreeCellMove m) {
    switch (m.fromKind) {
      case PileKind.cell:
        return m.from < cells.length ? cells[m.from] : -1;
      case PileKind.cascade:
        final c = cascades[m.from];
        return m.count <= c.length ? c[c.length - m.count] : -1;
      case PileKind.foundation:
        return -1;
    }
  }

  bool canMove(FreeCellMove m) {
    if (m.count < 1) return false;
    if (m.fromKind == PileKind.foundation) return false;
    if (m.fromKind == PileKind.cell) {
      if (m.from >= cells.length || cells[m.from] < 0 || m.count != 1) {
        return false;
      }
    } else {
      if (m.from >= cascadeCount) return false;
      final c = cascades[m.from];
      if (c.length < m.count) return false;
      if (runStart(m.from) > c.length - m.count) return false;
    }
    final card = movingCard(m);
    switch (m.toKind) {
      case PileKind.foundation:
        return m.count == 1 && m.to == cardSuit(card) && canGoHome(card);
      case PileKind.cell:
        return m.count == 1 &&
            m.to < cells.length &&
            cells[m.to] < 0 &&
            !(m.fromKind == PileKind.cell && m.from == m.to);
      case PileKind.cascade:
        if (m.to >= cascadeCount) return false;
        if (m.fromKind == PileKind.cascade && m.from == m.to) return false;
        final dest = cascades[m.to];
        if (dest.isEmpty) return m.count <= maxRun(toEmptyCascade: true);
        return stacksOn(card, dest.last) &&
            m.count <= maxRun(toEmptyCascade: false);
    }
  }

  /// Applies [m] without checking it; call [canMove] first.
  void apply(FreeCellMove m) {
    final List<int> moving;
    if (m.fromKind == PileKind.cell) {
      moving = [cells[m.from]];
      cells[m.from] = -1;
    } else {
      final c = cascades[m.from];
      moving = c.sublist(c.length - m.count);
      c.length -= m.count;
    }
    switch (m.toKind) {
      case PileKind.foundation:
        foundations[m.to]++;
      case PileKind.cell:
        cells[m.to] = moving.single;
      case PileKind.cascade:
        cascades[m.to].addAll(moving);
    }
  }

  /// The next card that may go home automatically, or null.
  FreeCellMove? nextAutoMove() {
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      if (c >= 0 && canGoHome(c) && isSafeHome(c)) {
        return FreeCellMove(PileKind.cell, i, PileKind.foundation, cardSuit(c));
      }
    }
    for (var i = 0; i < cascadeCount; i++) {
      final col = cascades[i];
      if (col.isEmpty) continue;
      final c = col.last;
      if (canGoHome(c) && isSafeHome(c)) {
        return FreeCellMove(
          PileKind.cascade,
          i,
          PileKind.foundation,
          cardSuit(c),
        );
      }
    }
    return null;
  }

  /// Plays every safe auto-move, returning them in order.
  List<FreeCellMove> autoPlay() {
    final done = <FreeCellMove>[];
    for (var m = nextAutoMove(); m != null; m = nextAutoMove()) {
      apply(m);
      done.add(m);
    }
    return done;
  }

  /// Whether the player has any legal move at all.
  bool get hasAnyMove {
    if (isWon) return false;
    if (emptyCells > 0 || emptyCascades > 0) return true;
    return candidateMoves().isNotEmpty;
  }

  /// The moves the solver considers. Not every legal move: of several empty
  /// free cells (or cascades) only the first is offered, since they are
  /// interchangeable, and a run that already fills its cascade is never moved
  /// into an empty one.
  List<FreeCellMove> candidateMoves() {
    final moves = <FreeCellMove>[];
    var firstEmptyCol = -1;
    for (var i = 0; i < cascadeCount; i++) {
      if (cascades[i].isEmpty) {
        firstEmptyCol = i;
        break;
      }
    }
    final firstFreeCell = cells.indexOf(-1);

    // Home, for cards that are not yet safe to auto-play.
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      if (c >= 0 && canGoHome(c)) {
        moves.add(
          FreeCellMove(PileKind.cell, i, PileKind.foundation, cardSuit(c)),
        );
      }
    }
    for (var i = 0; i < cascadeCount; i++) {
      final col = cascades[i];
      if (col.isNotEmpty && canGoHome(col.last)) {
        moves.add(
          FreeCellMove(
            PileKind.cascade,
            i,
            PileKind.foundation,
            cardSuit(col.last),
          ),
        );
      }
    }

    // Cascade to cascade.
    final capFull = maxRun(toEmptyCascade: false);
    for (var s = 0; s < cascadeCount; s++) {
      final src = cascades[s];
      if (src.isEmpty) continue;
      final rs = runStart(s);
      for (var d = 0; d < cascadeCount; d++) {
        if (d == s) continue;
        final dst = cascades[d];
        if (dst.isEmpty) continue;
        final top = dst.last;
        // At most one card of the run can sit on [top]: the rank decides it.
        final k = src.length - 1 - (cardRank(top) - 1 - cardRank(src.last));
        if (k < rs || k >= src.length) continue;
        if (!stacksOn(src[k], top)) continue;
        final n = src.length - k;
        if (n <= capFull) {
          moves.add(FreeCellMove(PileKind.cascade, s, PileKind.cascade, d, n));
        }
      }
      if (firstEmptyCol >= 0 && rs > 0) {
        final cap = maxRun(toEmptyCascade: true);
        final n = min(src.length - rs, cap);
        moves.add(
          FreeCellMove(PileKind.cascade, s, PileKind.cascade, firstEmptyCol, n),
        );
        if (n > 1) {
          moves.add(
            FreeCellMove(
              PileKind.cascade,
              s,
              PileKind.cascade,
              firstEmptyCol,
              1,
            ),
          );
        }
      }
    }

    // Free cell to cascade.
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      if (c < 0) continue;
      for (var d = 0; d < cascadeCount; d++) {
        final dst = cascades[d];
        if (dst.isNotEmpty && stacksOn(c, dst.last)) {
          moves.add(FreeCellMove(PileKind.cell, i, PileKind.cascade, d));
        }
      }
      if (firstEmptyCol >= 0) {
        moves.add(
          FreeCellMove(PileKind.cell, i, PileKind.cascade, firstEmptyCol),
        );
      }
    }

    // Cascade to free cell.
    if (firstFreeCell >= 0) {
      for (var s = 0; s < cascadeCount; s++) {
        if (cascades[s].isNotEmpty) {
          moves.add(
            FreeCellMove(PileKind.cascade, s, PileKind.cell, firstFreeCell),
          );
        }
      }
    }
    return moves;
  }

  /// A hash of the position that ignores the order of the cascades and of the
  /// free cells, which do not matter to the game. Foundations are implied by
  /// which cards are left.
  int stateKey() {
    final hs = List<int>.filled(cascadeCount, 0);
    for (var i = 0; i < cascadeCount; i++) {
      var h = 17;
      for (final c in cascades[i]) {
        h = (h * 1000003) ^ (c + 1);
      }
      hs[i] = h;
    }
    hs.sort();
    var h = 0x2545F491;
    for (final x in hs) {
      h = (h * 0x100000001B3) ^ x;
    }
    final cs = cells.where((c) => c >= 0).toList()..sort();
    for (final c in cs) {
      h = (h * 31) ^ (c + 7);
    }
    return h;
  }

  /// How far from won the position looks. Cards still out, plus every card
  /// sitting on a lower card of the same cascade (it must move before that
  /// one can go home), plus how deep each next-to-go-home card is buried, plus
  /// occupied free cells. The weights were compared on the analyzer's sample
  /// and matter less than one might think; none moved the solve rate by more
  /// than a few deals in sixty.
  int heuristic() {
    var h = (52 - homeCount) * 4;
    for (final col in cascades) {
      var minBelow = 99;
      for (var k = 0; k < col.length; k++) {
        final c = col[k];
        final r = cardRank(c);
        if (r > minBelow) h += 2;
        if (r < minBelow) minBelow = r;
        if (foundations[cardSuit(c)] == r - 1) {
          h += col.length - 1 - k;
        }
      }
    }
    for (final c in cells) {
      if (c >= 0) h += 2;
    }
    return h;
  }

  Map<String, dynamic> toJson() => {
    'cascades': [for (final c in cascades) List.of(c)],
    'cells': List.of(cells),
    'foundations': List.of(foundations),
  };

  static FreeCellPosition? fromJson(Map<String, dynamic> json) {
    try {
      final cascades = [
        for (final c in json['cascades'] as List)
          [for (final x in c as List) x as int],
      ];
      final cells = [for (final x in json['cells'] as List) x as int];
      final f = [for (final x in json['foundations'] as List) x as int];
      if (cascades.length != cascadeCount || f.length != 4) return null;
      return FreeCellPosition(cascades, cells, f);
    } catch (_) {
      return null;
    }
  }
}

// --------------------------------------------------------------- solver ---

class FreeCellSolveResult {
  const FreeCellSolveResult(this.solved, this.moves, this.nodes);

  final bool solved;

  /// Player moves; replay each with [FreeCellPosition.autoPlay] after it.
  final List<FreeCellMove> moves;

  /// Positions expanded — the effort it took.
  final int nodes;
}

class _Node {
  _Node(this.pos, this.parent, this.move, this.depth, this.priority);

  final FreeCellPosition pos;
  final _Node? parent;
  final FreeCellMove? move;
  final int depth;
  final int priority;
}

/// A binary min-heap on [_Node.priority]; ties go to the newest node, which
/// keeps the search diving rather than spreading.
class _Heap {
  final _items = <_Node>[];
  final _order = <int>[];
  var _counter = 0;

  bool get isEmpty => _items.isEmpty;

  bool _less(int i, int j) {
    final a = _items[i].priority, b = _items[j].priority;
    return a < b || (a == b && _order[i] > _order[j]);
  }

  void _swap(int i, int j) {
    final t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;
    final o = _order[i];
    _order[i] = _order[j];
    _order[j] = o;
  }

  void push(_Node n) {
    _items.add(n);
    _order.add(_counter++);
    var i = _items.length - 1;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (!_less(i, p)) break;
      _swap(i, p);
      i = p;
    }
  }

  _Node pop() {
    final top = _items.first;
    final last = _items.removeLast();
    final lastOrder = _order.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      _order[0] = lastOrder;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _less(l, m)) m = l;
        if (r < _items.length && _less(r, m)) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }
}

/// Best-first search for a win from [start], expanding at most [maxNodes]
/// positions. Safe auto-moves are applied after every move, exactly as the
/// game does, so the returned moves replay on screen as they are.
///
/// Not finding a win is *not* proof there is none — only that this search ran
/// out of budget. The generator relies only on the other direction: a found
/// solution is checked move by move.
FreeCellSolveResult solveFreeCell(
  FreeCellPosition start, {
  int maxNodes = 20000,
}) {
  final root = start.copy()..autoPlay();
  if (root.isWon) return const FreeCellSolveResult(true, [], 0);
  final seen = <int>{root.stateKey()};
  final heap = _Heap()..push(_Node(root, null, null, 0, root.heuristic()));
  var expanded = 0;
  while (!heap.isEmpty && expanded < maxNodes) {
    final n = heap.pop();
    expanded++;
    for (final m in n.pos.candidateMoves()) {
      final child = n.pos.copy()
        ..apply(m)
        ..autoPlay();
      if (!seen.add(child.stateKey())) continue;
      final node = _Node(
        child,
        n,
        m,
        n.depth + 1,
        child.heuristic() + n.depth + 1,
      );
      if (child.isWon) {
        final moves = <FreeCellMove>[];
        for (_Node? p = node; p != null && p.move != null; p = p.parent) {
          moves.add(p.move!);
        }
        return FreeCellSolveResult(true, moves.reversed.toList(), expanded);
      }
      heap.push(node);
    }
  }
  return FreeCellSolveResult(false, const [], expanded);
}

/// Whether [moves] really win from [start] under the rules, checked move by
/// move with [FreeCellPosition.canMove] rather than trusted from the search.
bool replayWins(FreeCellPosition start, List<FreeCellMove> moves) {
  final p = start.copy()..autoPlay();
  for (final m in moves) {
    if (!p.canMove(m)) return false;
    p
      ..apply(m)
      ..autoPlay();
  }
  return p.isWon;
}

// ------------------------------------------------------------ the deals ---

/// A shuffled deck from [seed]: Fisher-Yates over 0..51.
List<int> shuffledDeck(int seed) {
  final rng = Random(seed);
  final deck = List<int>.generate(52, (i) => i);
  for (var i = deck.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final t = deck[i];
    deck[i] = deck[j];
    deck[j] = t;
  }
  return deck;
}

/// What a level asks for.
///
/// [cells] is how many free cells the player gets. [targetNeed] is how many the
/// deal should *need*: the fewest with which the solver can win it. The gap
/// between the two is the room for error, and it is the difficulty knob —
/// a deal that needs one cell while you hold four forgives almost anything,
/// one that needs every cell you have does not. [needAtMost] accepts any deal
/// needing no more than [targetNeed], for the opening levels.
class FreeCellConfig {
  const FreeCellConfig(this.cells, this.targetNeed, {this.needAtMost = false});

  final int cells;
  final int targetNeed;
  final bool needAtMost;

  int get slack => cells - targetNeed;
}

FreeCellConfig freeCellConfigForLevel(int level) {
  if (level <= 8) return const FreeCellConfig(4, 2, needAtMost: true);
  if (level <= 24) return const FreeCellConfig(4, 3);
  if (level <= 36) return const FreeCellConfig(3, 2);
  if (level <= 54) return const FreeCellConfig(3, 3);
  return const FreeCellConfig(2, 2);
}

/// Node budget for the "how many cells does it need" probes. Deterministic, so
/// the same level always measures the same, and small, because a failed probe
/// spends all of it.
const int needProbeNodes = 6000;

/// How many seeded deals a level may try before settling for the closest.
const int maxDealCandidates = 40;

/// A generated level: the deal, the free cells it is played with, and a
/// solution proving it can be won.
class FreeCellDeal {
  FreeCellDeal._(
    this.level,
    this.cells,
    this.deck,
    this.need,
    this.solution,
    this.candidatesTried,
  );

  /// Bump whenever generation changes, so a saved game from an older deal is
  /// not restored onto a different one.
  static const int generatorVersion = 1;

  final int level;
  final int cells;

  /// The shuffled deck, dealt round-robin by [FreeCellPosition.deal].
  final List<int> deck;

  /// The fewest free cells the solver needed (the difficulty metric).
  final int need;

  /// A winning line with [need] free cells, which is also valid with [cells].
  final List<FreeCellMove> solution;
  final int candidatesTried;

  /// The opening position, with any safe cards already sent home.
  FreeCellPosition start() => FreeCellPosition.deal(deck, cells)..autoPlay();

  static int seedFor(int level, int attempt) =>
      level * 7919 + attempt * 104729 + 31337;

  static FreeCellDeal generate(int level) {
    final cfg = freeCellConfigForLevel(level);
    final t = cfg.targetNeed;
    // Closest miss so far: a deal that needs fewer cells than the target.
    (List<int>, List<FreeCellMove>)? easier;
    for (var a = 0; a < maxDealCandidates; a++) {
      final deck = shuffledDeck(seedFor(level, a));
      FreeCellSolveResult probe(int k) => solveFreeCell(
        FreeCellPosition.deal(deck, k),
        maxNodes: needProbeNodes,
      );
      if (!cfg.needAtMost && t > 0) {
        final r = probe(t - 1);
        if (r.solved) {
          easier ??= (deck, r.moves);
          continue;
        }
      }
      final r = probe(t);
      if (r.solved) {
        return FreeCellDeal._(level, cfg.cells, deck, t, r.moves, a + 1);
      }
    }
    if (easier != null) {
      return FreeCellDeal._(
        level,
        cfg.cells,
        easier.$1,
        t - 1,
        easier.$2,
        maxDealCandidates,
      );
    }
    // Nothing measured: take the first deal a bigger search wins.
    for (var a = maxDealCandidates; ; a++) {
      final deck = shuffledDeck(seedFor(level, a));
      final r = solveFreeCell(
        FreeCellPosition.deal(deck, cfg.cells),
        maxNodes: needProbeNodes * 4,
      );
      if (r.solved) {
        return FreeCellDeal._(
          level,
          cfg.cells,
          deck,
          cfg.cells,
          r.moves,
          a + 1,
        );
      }
    }
  }
}
