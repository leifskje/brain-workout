# Follow the Trail (Følg sporet)

Tap scattered circles in order — 1, 2, 3 …, and from level 6 alternating
numbers and letters (1, A, 2, B …). The classic trail-making exercise:
attention and processing speed. Untimed (elderly-friendly); a wrong tap costs
a heart. A line traces the visited nodes. Stars by hearts lost.

## Design

- Model generates normalized (0..1) positions with a minimum spacing
  (`0.8/√count`, relaxed and retried if a layout gets too crowded) so the
  56dp circles never crowd each other. Seeded per level.
- Difficulty: 6 → 16 circles; alternating labels from level 6.
- Screen: Stack of positioned circles over a CustomPaint polyline.

## Status

✅ Shipped. Tested: count/labels/coordinate-range/min-spacing/determinism for
levels 1–30, plus a widget test: a wrong tap costs a heart, ordered taps win.
