// Prints, per Arrow Pictures level, how its board plays. Short-arrow levels show
// the spread their picture can achieve and where the level's hardness put it;
// long-arrow levels show snake count, how much of the picture is covered, and
// branching. Re-run after changing the list or either generator.
//
// Run: dart run tool/analyze_arrow_pictures.dart [lastLevel]
// ignore_for_file: avoid_print
import 'package:brain_workout/games/arrow_escape/arrow_escape_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_models.dart';
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_shapes.dart';

void main(List<String> args) {
  final last = args.isEmpty ? pictureShapes.length : int.parse(args.first);
  String f(double v) => v.toStringAsFixed(2).padLeft(5);
  print('lvl  picture               size   kind  | short: arrows pool min/med/max '
      'hard got | long: snakes fill branching | ms');
  for (var level = 1; level <= last; level++) {
    final shape = pictureShapeForLevel(level);
    final head = '${'$level'.padLeft(3)}  ${shape.name.padRight(21)} '
        '${'${shape.colCount}x${shape.rowCount}'.padRight(6)}';
    final watch = Stopwatch()..start();
    if (pictureArrowsForLevel(level) == PictureArrows.long) {
      final board = generateLongPictureBoard(level);
      final ms = watch.elapsedMilliseconds;
      final mask = [
        for (final r in shape.rows) [for (final ch in r.split('')) ch != '.']
      ];
      print('$head long  | ${' ' * 46}| '
          '${'${board.arrows.length}'.padLeft(3)} '
          '${(board.fillWithin(mask) * 100).toStringAsFixed(0).padLeft(3)}% '
          '${f(board.measureDifficulty().meanBranching)} | ${'$ms'.padLeft(4)}');
      continue;
    }
    final board = generatePictureBoard(level);
    final ms = watch.elapsedMilliseconds;
    final pool = [
      for (var a = 0; a < ArrowBoard.generationPoolSize; a++)
        ArrowBoard.buildShapedAttempt(shape, level, a)
            .measureDifficulty()
            .meanBranching
    ]..sort();
    print('$head short | ${'${board.pieces.length}'.padLeft(4)} '
        '${f(pool.first)} ${f(pool[pool.length ~/ 2])} ${f(pool.last)} '
        '${pictureHardnessForLevel(level).toStringAsFixed(2)} '
        '${f(board.measureDifficulty().meanBranching)} | ${' ' * 21}| '
        '${'$ms'.padLeft(4)}');
  }
}
