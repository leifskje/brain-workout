import 'dart:math';

/// Follow the Trail — tap scattered circles in order (1, 2, 3 …; higher
/// levels alternate numbers and letters: 1, A, 2, B …). The classic
/// trail-making exercise: attention and processing speed.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

class TrailConfig {
  const TrailConfig({
    required this.count,
    required this.alternating,
    required this.hearts,
  });

  final int count;
  final bool alternating; // 1, A, 2, B … instead of 1, 2, 3 …
  final int hearts;
}

TrailConfig trailConfigForLevel(int level) {
  return TrailConfig(
    // More nodes means more crowding and a longer sequence to hold — the old
    // ceiling of 16 arrived at level 20 and left every later level identical.
    count: (6 + level ~/ 2).clamp(6, 30),
    alternating: level >= 6,
    hearts: 3,
  );
}

class TrailNode {
  TrailNode(this.label, this.x, this.y);

  final String label;

  /// Position in normalized 0..1 canvas coordinates.
  final double x;
  final double y;
}

class TrailBoard {
  TrailBoard(this.nodes);

  /// Nodes in the order they must be tapped.
  final List<TrailNode> nodes;

  /// Builds the level's board, seeded so a retry gives the same layout.
  /// Nodes keep a minimum spacing so labels stay readable and tappable.
  static TrailBoard generate(int level) {
    final cfg = trailConfigForLevel(level);
    final rng = Random(level * 6917 + 521);

    var minDist = 0.8 / sqrt(cfg.count);
    final points = <(double, double)>[];
    while (points.length < cfg.count) {
      var placed = false;
      for (var t = 0; t < 200 && !placed; t++) {
        final x = rng.nextDouble(), y = rng.nextDouble();
        final ok = points.every((p) {
          final dx = p.$1 - x, dy = p.$2 - y;
          return dx * dx + dy * dy >= minDist * minDist;
        });
        if (ok) {
          points.add((x, y));
          placed = true;
        }
      }
      if (!placed) {
        // Too crowded for this spacing — relax slightly and start over.
        minDist *= 0.9;
        points.clear();
      }
    }

    final nodes = <TrailNode>[];
    for (var i = 0; i < cfg.count; i++) {
      final String label;
      if (!cfg.alternating) {
        label = '${i + 1}';
      } else if (i.isEven) {
        label = '${i ~/ 2 + 1}';
      } else {
        label = String.fromCharCode('A'.codeUnitAt(0) + i ~/ 2);
      }
      nodes.add(TrailNode(label, points[i].$1, points[i].$2));
    }
    return TrailBoard(nodes);
  }
}
