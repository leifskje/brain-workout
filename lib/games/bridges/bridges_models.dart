import 'dart:math';

/// Bridges (Hashiwokakero). Numbered islands on a grid; join them with straight
/// bridges, one or two per pair, never crossing, so that every island has its
/// number of bridges and all islands form one connected group.
///
/// **Solvability is proven by a solver, as in Picture Logic.** The numbers are
/// derived from a generated solution, and whether they can be deduced is an
/// emergent property, so it cannot be constructed. [solveBridges] only ever
/// makes deductions that hold in *every* solution; if it fixes every edge, the
/// puzzle needs no guessing and its solution is unique. Candidates it cannot
/// finish are thrown away.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

/// A numbered island. [need] is how many bridges it must end up with.
class Island {
  const Island(this.row, this.col, this.need);

  final int row;
  final int col;
  final int need;
}

/// A pair of islands that can see each other along a row or column, i.e. a
/// place where bridges are allowed. [a] is always the top/left island.
class BridgeEdge {
  BridgeEdge(this.a, this.b, this.horizontal, this.cells);

  final int a;
  final int b;
  final bool horizontal;

  /// The water cells the bridge passes over, between the two islands.
  final List<(int, int)> cells;
}

/// Whether two edges would cross if both carried a bridge.
bool edgesCross(BridgeEdge e, BridgeEdge f, List<Island> islands) {
  if (e.horizontal == f.horizontal) return false;
  final h = e.horizontal ? e : f;
  final v = e.horizontal ? f : e;
  final row = islands[h.a].row;
  final col = islands[v.a].col;
  return islands[h.a].col < col &&
      col < islands[h.b].col &&
      islands[v.a].row < row &&
      row < islands[v.b].row;
}

/// Every pair of islands with a clear line of sight between them. Bridges do
/// not block sight; whether they may cross is a separate rule.
List<BridgeEdge> visibleEdges(int rows, int cols, List<Island> islands) {
  final at = <int, int>{
    for (var i = 0; i < islands.length; i++)
      islands[i].row * cols + islands[i].col: i,
  };
  final edges = <BridgeEdge>[];
  for (var i = 0; i < islands.length; i++) {
    final s = islands[i];
    for (final (dr, dc, horizontal) in const [(0, 1, true), (1, 0, false)]) {
      final cells = <(int, int)>[];
      var r = s.row + dr, c = s.col + dc;
      while (r < rows && c < cols) {
        final j = at[r * cols + c];
        if (j != null) {
          if (cells.isNotEmpty) edges.add(BridgeEdge(i, j, horizontal, cells));
          break;
        }
        cells.add((r, c));
        r += dr;
        c += dc;
      }
    }
  }
  return edges;
}

/// For each edge, the indices of the edges it crosses.
List<List<int>> crossingsFor(List<BridgeEdge> edges, List<Island> islands) {
  final out = [for (var i = 0; i < edges.length; i++) <int>[]];
  for (var i = 0; i < edges.length; i++) {
    for (var j = i + 1; j < edges.length; j++) {
      if (edgesCross(edges[i], edges[j], islands)) {
        out[i].add(j);
        out[j].add(i);
      }
    }
  }
  return out;
}

/// Whether [counts] joins every island into one group.
bool bridgesConnected(
  int islandCount,
  List<BridgeEdge> edges,
  List<int> counts,
) {
  if (islandCount <= 1) return true;
  final adj = [for (var i = 0; i < islandCount; i++) <int>[]];
  for (var e = 0; e < edges.length; e++) {
    if (counts[e] > 0) {
      adj[edges[e].a].add(edges[e].b);
      adj[edges[e].b].add(edges[e].a);
    }
  }
  final seen = List.filled(islandCount, false)..[0] = true;
  final stack = [0];
  var reached = 1;
  while (stack.isNotEmpty) {
    for (final n in adj[stack.removeLast()]) {
      if (!seen[n]) {
        seen[n] = true;
        reached++;
        stack.add(n);
      }
    }
  }
  return reached == islandCount;
}

class BridgesSolveResult {
  const BridgesSolveResult({
    required this.solved,
    required this.values,
    required this.advancedSteps,
    required this.rounds,
  });

  /// Every edge was forced, so the puzzle is guess-free and unique.
  final bool solved;

  /// Bridges per edge when [solved].
  final List<int> values;

  /// How often counting alone ran dry and a connectivity argument was needed
  /// to go on — the "don't cut a group off" reasoning. This is the difficulty
  /// metric: counting is what every player sees, connectivity is what they have
  /// to learn to look for.
  final int advancedSteps;

  /// Counting sweeps until done; a rough measure of how long the chains of
  /// consequence are.
  final int rounds;
}

/// Deduces the puzzle without guessing. Each edge carries bounds `[lo, hi]` on
/// its bridge count, and three rules narrow them:
///
///  1. **Counting** (per island): the other edges can supply at most their
///     `hi` and at least their `lo`, which bounds this one.
///  2. **Crossing**: an edge known to carry a bridge closes every edge it
///     crosses.
///  3. **Connectivity**, only when 1 and 2 are stuck: an increment that would
///     leave a group with every island already full is impossible (it would be
///     sealed off), and an edge whose loss would split the possible bridges in
///     two must carry at least one.
///
/// Every rule holds in every solution, which is why a finished run proves the
/// solution unique.
BridgesSolveResult solveBridges(
  List<Island> islands,
  List<BridgeEdge> edges,
  List<List<int>> crossings,
) {
  final n = islands.length;
  final m = edges.length;
  final need = [for (final s in islands) s.need];
  final lo = List.filled(m, 0);
  final hi = [for (final e in edges) min(2, min(need[e.a], need[e.b]))];
  final incident = [for (var i = 0; i < n; i++) <int>[]];
  for (var e = 0; e < m; e++) {
    incident[edges[e].a].add(e);
    incident[edges[e].b].add(e);
  }

  var rounds = 0;
  var advanced = 0;
  BridgesSolveResult fail() => BridgesSolveResult(
    solved: false,
    values: lo,
    advancedSteps: advanced,
    rounds: rounds,
  );

  // Rules 1 and 2 to a fixpoint. False on a contradiction.
  bool basic() {
    var changed = true;
    while (changed) {
      changed = false;
      rounds++;
      for (var i = 0; i < n; i++) {
        var sumLo = 0, sumHi = 0;
        for (final e in incident[i]) {
          sumLo += lo[e];
          sumHi += hi[e];
        }
        if (sumLo > need[i] || sumHi < need[i]) return false;
        for (final e in incident[i]) {
          final newLo = max(lo[e], need[i] - (sumHi - hi[e]));
          final newHi = min(hi[e], need[i] - (sumLo - lo[e]));
          if (newLo > newHi) return false;
          if (newLo != lo[e] || newHi != hi[e]) {
            sumLo += newLo - lo[e];
            sumHi += newHi - hi[e];
            lo[e] = newLo;
            hi[e] = newHi;
            changed = true;
          }
        }
      }
      for (var e = 0; e < m; e++) {
        if (lo[e] == 0) continue;
        for (final f in crossings[e]) {
          if (lo[f] > 0) return false;
          if (hi[f] > 0) {
            hi[f] = 0;
            changed = true;
          }
        }
      }
    }
    return true;
  }

  // Rule 3a: sealed groups.
  bool sealOff() {
    final parent = List.generate(n, (i) => i);
    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
      }
      return x;
    }

    for (var e = 0; e < m; e++) {
      if (lo[e] > 0) parent[find(edges[e].a)] = find(edges[e].b);
    }
    final deficit = List.filled(n, 0);
    final size = List.filled(n, 0);
    for (var i = 0; i < n; i++) {
      var sumLo = 0;
      for (final e in incident[i]) {
        sumLo += lo[e];
      }
      deficit[find(i)] += need[i] - sumLo;
      size[find(i)]++;
    }
    for (var e = 0; e < m; e++) {
      if (lo[e] == hi[e]) continue;
      final ca = find(edges[e].a), cb = find(edges[e].b);
      final d = (ca == cb ? deficit[ca] : deficit[ca] + deficit[cb]) - 2;
      final s = ca == cb ? size[ca] : size[ca] + size[cb];
      if (d == 0 && s < n) {
        hi[e] = lo[e];
        return true;
      }
    }
    return false;
  }

  // Rule 3b: cut edges of the still-possible bridges (Tarjan). Returns null on
  // a contradiction (the possible bridges are already in two pieces).
  bool? mustBridge() {
    final adj = [for (var i = 0; i < n; i++) <int>[]];
    for (var e = 0; e < m; e++) {
      if (hi[e] > 0) {
        adj[edges[e].a].add(e);
        adj[edges[e].b].add(e);
      }
    }
    final disc = List.filled(n, -1);
    final low = List.filled(n, 0);
    var time = 0;
    int? found;
    void dfs(int u, int viaEdge) {
      disc[u] = low[u] = time++;
      for (final e in adj[u]) {
        if (e == viaEdge) continue;
        final v = edges[e].a == u ? edges[e].b : edges[e].a;
        if (disc[v] < 0) {
          dfs(v, e);
          low[u] = min(low[u], low[v]);
          if (low[v] > disc[u] && lo[e] == 0) found ??= e;
        } else {
          low[u] = min(low[u], disc[v]);
        }
      }
    }

    dfs(0, -1);
    if (disc.contains(-1)) return null;
    if (found == null) return false;
    lo[found!] = 1;
    return true;
  }

  while (true) {
    if (!basic()) return fail();
    if (Iterable<int>.generate(m).every((e) => lo[e] == hi[e])) break;
    if (sealOff()) {
      advanced++;
      continue;
    }
    final cut = mustBridge();
    if (cut == null) return fail();
    if (cut) {
      advanced++;
      continue;
    }
    return fail();
  }

  final ok = bridgesConnected(n, edges, lo);
  return BridgesSolveResult(
    solved: ok,
    values: lo,
    advancedSteps: advanced,
    rounds: rounds,
  );
}

/// Exhaustive solution counter, independent of [solveBridges], so the tests can
/// check the uniqueness claim rather than assume it. Stops at [limit]. Only
/// practical on small boards.
int countBridgesSolutions(
  List<Island> islands,
  List<BridgeEdge> edges,
  List<List<int>> crossings, {
  int limit = 2,
}) {
  final n = islands.length;
  final m = edges.length;
  final have = List.filled(n, 0);
  // Capacity still reachable for each island from edges not yet decided.
  final rest = List.filled(n, 0);
  for (final e in edges) {
    rest[e.a] += 2;
    rest[e.b] += 2;
  }
  final value = List.filled(m, 0);
  var count = 0;

  void go(int e) {
    if (count >= limit) return;
    if (e == m) {
      for (var i = 0; i < n; i++) {
        if (have[i] != islands[i].need) return;
      }
      if (bridgesConnected(n, edges, value)) count++;
      return;
    }
    final a = edges[e].a, b = edges[e].b;
    rest[a] -= 2;
    rest[b] -= 2;
    for (var v = 0; v <= 2; v++) {
      if (have[a] + v > islands[a].need || have[b] + v > islands[b].need) break;
      if (v > 0 && crossings[e].any((f) => f < e && value[f] > 0)) break;
      have[a] += v;
      have[b] += v;
      value[e] = v;
      if (have[a] + rest[a] >= islands[a].need &&
          have[b] + rest[b] >= islands[b].need) {
        go(e + 1);
      }
      have[a] -= v;
      have[b] -= v;
      value[e] = 0;
    }
    rest[a] += 2;
    rest[b] += 2;
  }

  go(0);
  return count;
}

/// Per-level shape and difficulty target.
class BridgesConfig {
  const BridgesConfig({
    required this.rows,
    required this.cols,
    required this.islands,
    required this.targetAdvanced,
  });

  final int rows;
  final int cols;

  /// How many islands the generator aims for.
  final int islands;

  /// Wanted [BridgesSolveResult.advancedSteps].
  final int targetAdvanced;
}

BridgesConfig bridgesConfigForLevel(int level) {
  // Width stops at 12: ~28dp per cell on a small phone, about the smallest an
  // island with a readable number can be. A portrait screen has height to
  // spare, so boards are taller than wide.
  final cols = min(12, 7 + (level - 1) ~/ 4);
  final rows = cols + 2;
  final density = 0.17 + 0.06 * min(1.0, (level - 1) / 30);
  // Measured with tool/analyze_bridges_difficulty.dart over 2500 candidates:
  // most need no connectivity step at all, and 5+ only turns up reliably on
  // the 11- and 12-wide boards. Targets sit inside that, so the curve keeps
  // climbing after the board stops growing instead of silently flattening.
  // Re-run the analyzer after any generator change; the spread moves.
  final target = switch (level) {
    <= 3 => 0,
    <= 8 => 1,
    <= 14 => 2,
    <= 20 => 3,
    <= 30 => 4,
    _ => 5,
  };
  return BridgesConfig(
    rows: rows,
    cols: cols,
    islands: (rows * cols * density).round(),
    targetAdvanced: target,
  );
}

/// A generated puzzle plus the player's bridges.
class BridgesBoard {
  BridgesBoard._(this.rows, this.cols, this.islands, this.solution)
    : edges = visibleEdges(rows, cols, islands) {
    crossings = crossingsFor(edges, islands);
    counts = List.filled(edges.length, 0);
    _incident = [for (var i = 0; i < islands.length; i++) <int>[]];
    for (var e = 0; e < edges.length; e++) {
      _incident[edges[e].a].add(e);
      _incident[edges[e].b].add(e);
    }
  }

  final int rows;
  final int cols;
  final List<Island> islands;
  final List<BridgeEdge> edges;
  late final List<List<int>> crossings;

  /// Bridges per edge in the (unique) solution.
  final List<int> solution;

  /// The player's bridges per edge.
  late List<int> counts;
  late final List<List<int>> _incident;

  int edgeBetween(int a, int b) {
    for (final e in _incident[a]) {
      if (edges[e].a == b || edges[e].b == b) return e;
    }
    return -1;
  }

  /// Bridges the player has built on island [i].
  int built(int i) {
    var sum = 0;
    for (final e in _incident[i]) {
      sum += counts[e];
    }
    return sum;
  }

  bool isFull(int i) => built(i) == islands[i].need;
  bool isOver(int i) => built(i) > islands[i].need;

  /// The edge whose bridge stops [e] from being built, or null.
  int? blockerOf(int e) {
    for (final f in crossings[e]) {
      if (counts[f] > 0) return f;
    }
    return null;
  }

  /// none → one → two → none. Returns false when a crossing bridge blocks it.
  bool cycle(int e) {
    if (counts[e] == 0 && blockerOf(e) != null) return false;
    counts[e] = (counts[e] + 1) % 3;
    return true;
  }

  bool get allFull => Iterable<int>.generate(islands.length).every(isFull);
  bool get isConnected => bridgesConnected(islands.length, edges, counts);
  bool get isSolved => allFull && isConnected;
  bool get hasProgress => counts.any((c) => c > 0);

  /// Rows plus columns without a single island: the measure of open sea.
  int get emptyLines {
    final rowsUsed = {for (final s in islands) s.row};
    final colsUsed = {for (final s in islands) s.col};
    return rows - rowsUsed.length + cols - colsUsed.length;
  }

  /// Edges carrying more bridges than the solution has there.
  bool isWrong(int e) => counts[e] > solution[e];
  int get wrongEdges =>
      Iterable<int>.generate(edges.length).where(isWrong).length;

  Map<String, dynamic> countsJson() => {
    'rows': rows,
    'cols': cols,
    'counts': List<int>.from(counts),
  };

  /// Restores saved bridges. Ignores a save that doesn't fit this board.
  bool applyCountsJson(Map<String, dynamic> json) {
    final saved = json['counts'];
    if (json['rows'] != rows ||
        json['cols'] != cols ||
        saved is! List ||
        saved.length != edges.length) {
      return false;
    }
    final values = [
      for (final v in saved) v is int && v >= 0 && v <= 2 ? v : 0,
    ];
    counts = values;
    return true;
  }

  /// Bumped whenever generation changes, so saved bridges from an older
  /// generator are not laid onto a different board.
  static const generatorVersion = 1;

  static BridgesBoard generate(int level, {int candidates = 2500}) {
    final cfg = bridgesConfigForLevel(level);
    BridgesBoard? best;
    var bestScore = 1 << 30;
    for (final (board, result) in pool(level, candidates)) {
      // A priority order, not a blend (see the Arrow Maze notes in CLAUDE.md):
      // difficulty, then looks, then decoys — places a bridge could go but
      // doesn't. Without decoys a board is pure counting: level 1 once had ten
      // possible bridges and a solution that used all ten. Looks outrank them
      // because growing from one island can leave half the board as open sea,
      // which reads as broken.
      final decoys = board.solution.where((v) => v == 0).length;
      final score =
          (result.advancedSteps - cfg.targetAdvanced).abs() * 1000000 +
          board.emptyLines * 10000 +
          (100 - decoys) * 100 +
          (cfg.islands - board.islands.length).abs();
      if (score < bestScore) {
        bestScore = score;
        best = board;
      }
    }
    return best ?? _fallback(cfg);
  }

  /// The guess-free candidates for [level], in seeded order. Public so
  /// `tool/analyze_bridges_difficulty.dart` measures exactly what [generate]
  /// chooses from.
  static Iterable<(BridgesBoard, BridgesSolveResult)> pool(
    int level,
    int candidates,
  ) sync* {
    final cfg = bridgesConfigForLevel(level);
    final rng = Random(level * 7927 + 3301);
    for (var i = 0; i < candidates; i++) {
      final board = _candidate(cfg, rng);
      if (board == null) continue;
      final result = solveBridges(board.islands, board.edges, board.crossings);
      if (result.solved) yield (board, result);
    }
  }

  /// One candidate: grow a solution from a random island by repeatedly
  /// throwing a bridge out of an existing island to a new one, then add a few
  /// extra bridges between islands that can already see each other, so the
  /// solution has loops rather than being a tree.
  static BridgesBoard? _candidate(BridgesConfig cfg, Random rng) {
    final rows = cfg.rows, cols = cfg.cols;
    // 0 water, 1 island, 2 bridge.
    final grid = List.filled(rows * cols, 0);
    final pos = <(int, int)>[];
    final built = <(int, int), int>{}; // (island, island) -> bridges

    bool water(int r, int c) =>
        r >= 0 && r < rows && c >= 0 && c < cols && grid[r * cols + c] == 0;
    bool islandAt(int r, int c) =>
        r >= 0 && r < rows && c >= 0 && c < cols && grid[r * cols + c] == 1;

    // Start near the middle, so growth has room in every direction.
    final r0 = rows ~/ 4 + rng.nextInt(rows ~/ 2);
    final c0 = cols ~/ 4 + rng.nextInt(cols ~/ 2);
    grid[r0 * cols + c0] = 1;
    pos.add((r0, c0));

    const dirs = [(0, 1), (1, 0), (0, -1), (-1, 0)];
    final maxSpan = max(3, cols ~/ 2);

    // A legal new island thrown from island [from], or null.
    (int, int, int, int)? propose() {
      final from = rng.nextInt(pos.length);
      final (fr, fc) = pos[from];
      final (dr, dc) = dirs[rng.nextInt(4)];
      final len = 2 + rng.nextInt(maxSpan - 1);
      for (var k = 1; k < len; k++) {
        if (!water(fr + dr * k, fc + dc * k)) return null;
      }
      final tr = fr + dr * len, tc = fc + dc * len;
      if (!water(tr, tc)) return null;
      // No two islands side by side: they read as one blob, and a bridge
      // between them would have no water to sit on.
      if (islandAt(tr + 1, tc) ||
          islandAt(tr - 1, tc) ||
          islandAt(tr, tc + 1) ||
          islandAt(tr, tc - 1)) {
        return null;
      }
      return (from, tr, tc, len);
    }

    // How good a spot is: open water around it (so the board fills evenly
    // instead of clumping round the first island), and other islands in line
    // with it, which is where decoys come from — a pair that can see each
    // other but isn't bridged in the solution.
    final inRow = List.filled(rows, 0), inCol = List.filled(cols, 0);
    inRow[r0]++;
    inCol[c0]++;
    int merit(int r, int c, int from) {
      // Nearest island by Chebyshev distance, searched outward and capped at 3.
      var nearest = 3;
      search:
      for (var d = 1; d < 3; d++) {
        for (var dr = -d; dr <= d; dr++) {
          for (var dc = -d; dc <= d; dc++) {
            if (max(dr.abs(), dc.abs()) == d && islandAt(r + dr, c + dc)) {
              nearest = d;
              break search;
            }
          }
        }
      }
      // The source is always in line; it doesn't count.
      final inLine = inRow[r] + inCol[c] - 1;
      return nearest * 2 + min(inLine, 3);
    }

    // Give up after a run of failures rather than a total: a board that has
    // run out of room otherwise spends thousands of proposals finding that out,
    // which was most of the generation time.
    var misses = 0;
    while (pos.length < cfg.islands && misses < 25) {
      (int, int, int, int)? pick;
      var bestMerit = -1;
      for (var k = 0; k < 8; k++) {
        final p = propose();
        if (p == null) continue;
        final m = merit(p.$2, p.$3, p.$1);
        if (m > bestMerit) {
          bestMerit = m;
          pick = p;
        }
      }
      if (pick == null) {
        misses++;
        continue;
      }
      misses = 0;
      final (from, tr, tc, len) = pick;
      final (fr, fc) = pos[from];
      final dr = (tr - fr).sign, dc = (tc - fc).sign;
      for (var k = 1; k < len; k++) {
        grid[(fr + dr * k) * cols + fc + dc * k] = 2;
      }
      grid[tr * cols + tc] = 1;
      pos.add((tr, tc));
      inRow[tr]++;
      inCol[tc]++;
      built[(from, pos.length - 1)] = rng.nextDouble() < 0.35 ? 2 : 1;
    }
    if (pos.length < cfg.islands * 0.85) return null;

    // Islands in reading order, so ids (and widget keys) are stable.
    final order = List.generate(pos.length, (i) => i)
      ..sort((x, y) {
        final (xr, xc) = pos[x];
        final (yr, yc) = pos[y];
        return xr != yr ? xr - yr : xc - yc;
      });
    final rank = List.filled(pos.length, 0);
    for (var i = 0; i < order.length; i++) {
      rank[order[i]] = i;
    }
    final byNew = <(int, int), int>{
      for (final MapEntry(key: (x, y), :value) in built.entries)
        rank[x] < rank[y] ? (rank[x], rank[y]) : (rank[y], rank[x]): value,
    };

    final shape = [for (final i in order) Island(pos[i].$1, pos[i].$2, 0)];
    final edges = visibleEdges(rows, cols, shape);
    final values = List.filled(edges.length, 0);
    for (var e = 0; e < edges.length; e++) {
      values[e] = byNew[(edges[e].a, edges[e].b)] ?? 0;
    }
    // Extra bridges where the water is still free.
    final crossings = crossingsFor(edges, shape);
    for (var e = 0; e < edges.length; e++) {
      if (values[e] > 0) continue;
      if (crossings[e].any((f) => values[f] > 0)) continue;
      if (rng.nextDouble() < 0.3) values[e] = rng.nextDouble() < 0.3 ? 2 : 1;
    }

    final need = List.filled(shape.length, 0);
    for (var e = 0; e < edges.length; e++) {
      need[edges[e].a] += values[e];
      need[edges[e].b] += values[e];
    }
    final islands = [
      for (var i = 0; i < shape.length; i++)
        Island(shape[i].row, shape[i].col, need[i]),
    ];
    return BridgesBoard._(rows, cols, islands, values);
  }

  /// A fixed, trivially solvable board, so a level always opens. Not expected
  /// to be reached; the tests check that every level's pool finds one.
  static BridgesBoard _fallback(BridgesConfig cfg) {
    final islands = [
      const Island(0, 0, 2),
      const Island(0, 2, 2),
      const Island(2, 0, 2),
      const Island(2, 2, 2),
    ];
    final board = BridgesBoard._(cfg.rows, cfg.cols, islands, const []);
    return BridgesBoard._(
      cfg.rows,
      cfg.cols,
      islands,
      solveBridges(islands, board.edges, board.crossings).values,
    );
  }
}
