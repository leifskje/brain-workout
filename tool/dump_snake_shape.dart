// Prints a long-arrow (Arrow Maze) picture board as text — the agent's channel
// for anything visual (see CLAUDE.md). Each snake gets a letter, its head shows
// its exit direction, and `O` marks a picture cell no snake covers.
//
// Run: dart run tool/dump_snake_shape.dart <pictureName> [minLength]
// ignore_for_file: avoid_print
import 'package:brain_workout/games/arrow_pictures/arrow_pictures_shapes.dart';
import 'package:brain_workout/games/snake_arrows/snake_arrows_models.dart';

const glyphs =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ0123456789';
const heads = {Dir.up: '^', Dir.down: 'v', Dir.left: '<', Dir.right: '>'};

void main(List<String> args) {
  final shape = pictureShapes.firstWhere((s) => s.name == args[0]);
  final minLength = args.length > 1 ? int.parse(args[1]) : 3;
  final board =
      SnakeBoard.generateShaped(shape.rows, seed: 1, minLength: minLength);
  final mask = [
    for (final r in shape.rows) [for (final ch in r.split('')) ch != '.']
  ];
  final at = <(int, int), String>{};
  for (final a in board.arrows) {
    for (final c in a.cells) {
      at[(c.row, c.col)] = glyphs[a.id % glyphs.length];
    }
    at[(a.head.row, a.head.col)] = heads[a.exitDir]!;
  }
  final d = board.measureDifficulty();
  print('--- ${shape.name} min$minLength: ${board.arrows.length} snakes, '
      'fill ${(board.fillWithin(mask) * 100).toStringAsFixed(0)}%, '
      'branching ${d.meanBranching.toStringAsFixed(2)}');
  for (var r = 0; r < shape.rowCount; r++) {
    print([
      for (var c = 0; c < shape.colCount; c++)
        at[(r, c)] ?? (shape.filled(r, c) ? 'O' : ' ')
    ].join());
  }
}
