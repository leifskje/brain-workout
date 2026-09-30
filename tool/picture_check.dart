// Checks draft Arrow Pictures against the rules in docs/plans/picture-boards.md
// ("Adding pictures — the recipe") before they go into the real list.
//
// A draft file is a script of its own:
//
//   import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
//   import 'picture_check.dart';
//   const drafts = <ArrowShape>[ArrowShape('heart', [...]), ...];
//   void main() => checkDrafts(drafts);
//
// Run: dart run tool/_draft_<name>.dart
// Prints each picture in one colour (judge the silhouette from that, never the
// coloured rows), its tier, and PASS or the reasons it fails.
// ignore_for_file: avoid_print
import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_palette.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_shapes.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';

/// Seeds a long picture is covered at: a level's seed is its number, and the
/// finished list puts these pictures somewhere in 40-220.
const _longSeeds = [1, 120, 200];

void checkDrafts(List<ArrowShape> drafts, {bool silhouettes = true}) {
  final existing = {for (final s in pictureShapes) s.name};
  final seen = <String>{};
  var failed = 0;
  for (final shape in drafts) {
    final problems = <String>[];
    final notes = <String>[];
    if (existing.contains(shape.name)) problems.add('name already in the list');
    if (!seen.add(shape.name)) problems.add('name twice in this draft');

    final w = shape.colCount, h = shape.rowCount;
    for (final row in shape.rows) {
      if (row.length != w) problems.add('ragged row (${row.length} vs $w)');
      for (final ch in row.split('')) {
        if (ch == '#') problems.add('uncoloured # cell');
        if (ch != '.' && !picturePalette.containsKey(ch)) {
          problems.add('"$ch" is not a palette letter');
        }
      }
    }
    if (problems.isNotEmpty) {
      _report(shape, problems.toSet().toList(), notes, silhouettes);
      failed++;
      continue;
    }

    final cells = shape.cellCount;
    final bbox = cells / (w * h);
    final long = w > 16;
    final tier = !long
        ? 'small'
        : cells > pictureHugeCells
            ? 'huge'
            : cells >= 600
                ? 'large'
                : 'mid';
    notes.add('${w}x$h, $cells cells, $tier, '
        '${(bbox * 100).toStringAsFixed(0)}% of its box');
    if (w > 44) problems.add('wider than 44');
    if (h > 60) problems.add('taller than 60');

    if (!long) {
      if (cells < 40 || cells > 170) problems.add('small tier is 40-170 cells');
      final pool = [
        for (var a = 0; a < ArrowBoard.generationPoolSize; a++)
          ArrowBoard.buildShapedAttempt(shape, 1, a)
              .measureDifficulty()
              .meanBranching
      ]..sort();
      notes.add('short arrows, branching '
          '${pool.first.toStringAsFixed(1)}/'
          '${pool[pool.length ~/ 2].toStringAsFixed(1)}/'
          '${pool.last.toStringAsFixed(1)} (min/med/max)');
      if (pool.first > 9) problems.add('hardest board branching > 9 (plays itself)');
    } else {
      if (cells < 400) problems.add('long tiers start at 400 cells');
      final mask = [
        for (final r in shape.rows) [for (final ch in r.split('')) ch != '.']
      ];
      // No 1-cell strokes: long arrows are lines, a thin part reads as nothing.
      var thin = 0;
      bool inside(int r, int c) => r >= 0 && r < h && c >= 0 && c < w && mask[r][c];
      for (var r = 0; r < h; r++) {
        for (var c = 0; c < w; c++) {
          if (!mask[r][c]) continue;
          var ok = false;
          for (final (dr, dc) in [(0, 0), (-1, 0), (0, -1), (-1, -1)]) {
            final r0 = r + dr, c0 = c + dc;
            if (inside(r0, c0) &&
                inside(r0 + 1, c0) &&
                inside(r0, c0 + 1) &&
                inside(r0 + 1, c0 + 1)) {
              ok = true;
            }
          }
          if (!ok) thin++;
        }
      }
      if (thin > 0) problems.add('$thin cells in 1-wide strokes');
      if (bbox < 0.55) notes.add('under 55% of its box — only OK if tall/thin by nature');
      final huge = cells > pictureHugeCells;
      final fills = <String>[];
      for (final seed in _longSeeds) {
        final board = SnakeBoard.generateShaped(shape.rows,
            seed: seed,
            minLength: pictureLongMinLength,
            maxLength: huge ? 28 : 14,
            poolSize: 48);
        final fill = board.fillWithin(mask);
        fills.add('${(fill * 100).toStringAsFixed(0)}%'
            ' (${board.arrows.length} snakes, '
            'br ${board.measureDifficulty().meanBranching.toStringAsFixed(1)})');
        if (fill < 0.915) problems.add('seed $seed covers ${(fill * 100).toStringAsFixed(0)}% < 92%');
      }
      notes.add('long arrows, covered ${fills.join(', ')}');
    }
    if (problems.isNotEmpty) failed++;
    _report(shape, problems, notes, silhouettes);
  }
  print('${drafts.length - failed}/${drafts.length} pass');
}

void _report(ArrowShape shape, List<String> problems, List<String> notes,
    bool silhouette) {
  print('=== ${shape.name}: ${problems.isEmpty ? 'PASS' : 'FAIL'}');
  for (final n in notes) {
    print('  $n');
  }
  for (final p in problems) {
    print('  ! $p');
  }
  if (silhouette) {
    for (final row in shape.rows) {
      print('  ${row.replaceAll(RegExp(r'[^.]'), '#')}');
    }
  }
}
