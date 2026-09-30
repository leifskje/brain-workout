import 'package:flutter/material.dart';

/// Paints an Arrow Pictures picture under the arrows.
///
/// Two states. During play, at most a barely-there neutral outline — long
/// arrows are thin lines, and without it a picture board reads as scattered
/// strokes, but anything stronger (a brown tint was tried) looks like a layer
/// sitting on the board. Colour is withheld until the last arrow has left,
/// because this audience reads colour as a rule; then [reveal] fades the
/// picture in, in its real colours, as the level's reward.
///
/// [colours] holds one ARGB value per picture cell and null outside it.
void paintPicture(
  Canvas canvas, {
  required List<List<int?>> colours,
  required double cell,
  required bool outline,
  required double reveal,
}) {
  // Cells drawn slightly oversized so neighbours merge into one shape instead
  // of showing the grid between them.
  Rect at(int r, int c) =>
      Rect.fromLTWH(c * cell - 0.5, r * cell - 0.5, cell + 1, cell + 1);

  if (outline && reveal < 1) {
    final faint = Paint()..color = Colors.black.withValues(alpha: 0.06);
    for (var r = 0; r < colours.length; r++) {
      for (var c = 0; c < colours[r].length; c++) {
        if (colours[r][c] != null) canvas.drawRect(at(r, c), faint);
      }
    }
  }
  if (reveal <= 0) return;
  final paint = Paint();
  for (var r = 0; r < colours.length; r++) {
    for (var c = 0; c < colours[r].length; c++) {
      final argb = colours[r][c];
      if (argb == null) continue;
      paint.color = Color(argb).withValues(alpha: reveal);
      canvas.drawRect(at(r, c), paint);
    }
  }
}

/// [paintPicture] as a layer of its own, for boards built from widgets.
class PictureLayerPainter extends CustomPainter {
  const PictureLayerPainter({
    required this.colours,
    required this.cell,
    required this.outline,
    required this.reveal,
  });

  final List<List<int?>> colours;
  final double cell;
  final bool outline;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) => paintPicture(canvas,
      colours: colours, cell: cell, outline: outline, reveal: reveal);

  @override
  bool shouldRepaint(PictureLayerPainter old) =>
      !identical(old.colours, colours) ||
      old.cell != cell ||
      old.outline != outline ||
      old.reveal != reveal;
}
