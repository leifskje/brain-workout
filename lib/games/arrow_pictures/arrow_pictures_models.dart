import '../arrow_escape/arrow_escape_models.dart';
import '../snake_arrows/snake_arrows_models.dart';
import 'arrow_pictures_palette.dart';
import 'arrow_pictures_shapes.dart';

/// Arrow Pictures: Arrow Escape's rules, but every board is a silhouette.
///
/// No generator of its own — [ArrowBoard.generateShaped] already produces a
/// guaranteed-solvable board for any mask. What this file owns is which picture
/// each level shows and how hard it should play.
///
/// **Levels are [pictureShapes] in order, and that list is append-only.** New
/// pictures only ever go on the end, so a level someone has played never
/// changes. Past the end the game cycles through the long-arrow pictures only,
/// each with a new seed (a different board of the same picture), mirrored on
/// alternate laps — cycling the whole list sent level 83 back to a 42-arrow key. Those cycled levels shift
/// when pictures are added, which
/// is survivable because a save whose arrow count no longer matches is dropped
/// by `ArrowBoard.applyEscapedJson`, and [pictureGeneratorVersion] retires any
/// cached board.

/// Bump when generation changes what a level produces.
const _generatorRevision = 2;

/// Stamped on prefetched boards. Folds in the list length because appending a
/// picture changes every cycled level.
int get pictureGeneratorVersion =>
    _generatorRevision * 10000 + pictureShapes.length;

/// Which list position (1-based) [level] shows: itself on the first pass,
/// then round the long-arrow tier.
int picturePositionForLevel(int level) {
  final n = pictureShapes.length;
  if (level <= n) return level;
  final lap = n - pictureFirstLongPosition + 1;
  return pictureFirstLongPosition + (level - n - 1) % lap;
}

/// Whether [level] shows its picture mirrored left-to-right: every other lap
/// past the end, starting with the first, so a replay looks new at no drawing
/// cost. The first pass is never mirrored.
bool pictureMirroredForLevel(int level) {
  final n = pictureShapes.length;
  if (level <= n) return false;
  final lap = n - pictureFirstLongPosition + 1;
  return ((level - n - 1) ~/ lap).isEven;
}

/// The picture for [level] (1-based).
ArrowShape pictureShapeForLevel(int level) {
  final shape = pictureShapes[picturePositionForLevel(level) - 1];
  if (!pictureMirroredForLevel(level)) return shape;
  return _mirrored[shape.name] ??= ArrowShape(shape.name, [
    for (final r in shape.rows) r.split('').reversed.join(),
  ]);
}

final _mirrored = <String, ArrowShape>{};

/// Cache key for a level's picture: which picture, and which way round.
(int, bool) _pictureKey(int level) =>
    (picturePositionForLevel(level), pictureMirroredForLevel(level));

/// How hard [level] plays *relative to its own picture*: 0 is the picture's
/// median board, 1 its hardest. See [ArrowBoard.generateShapedAtHardness] for
/// why this is not an absolute branching target like Arrow Escape's.
///
/// Climbs across the first pass through the list, then stays at the top: a
/// second lap is the same pictures at their hardest. Arrow count — which the
/// list order sets — carries the rest of the ramp.
double pictureHardnessForLevel(int level) {
  final n = pictureShapes.length;
  if (level >= n || n == 1) return 1.0;
  return (level - 1) / (n - 1);
}

/// Which kind of arrow fills a picture.
enum PictureArrows { short, long }

/// First list position (1-based) drawn with long arrows.
///
/// The high-resolution pictures. Short arrows get *looser* as a picture gets
/// bigger — every arrow facing open canvas out to the board edge is free from
/// the start, so levels 62-82 measured 7-10 arrows free per step and the
/// windmill 20 — while long arrows bend along the strokes and hold the same
/// pictures at 2-4. At the small end it is the other way round: a picture under
/// ~100 cells holds only 6-15 snakes, too short a puzzle.
const pictureFirstLongPosition = 102;

/// Long snakes only. Filled 92-98% of every picture measured; shorter snakes
/// fill no better and only add easy moves.
const pictureLongMinLength = 4;

PictureArrows pictureArrowsForLevel(int level) =>
    picturePositionForLevel(level) >= pictureFirstLongPosition
        ? PictureArrows.long
        : PictureArrows.short;

/// Hearts on a long-arrow level. Fixed so the header can show them before the
/// board exists; 30-90 snakes is about Arrow Maze's late range, a notch kinder.
const pictureLongHearts = 4;

/// The long-arrow board for [level]. Deterministic in the level, like
/// [generatePictureBoard].
SnakeBoard generateLongPictureBoard(int level) {
  final shape = pictureShapeForLevel(level);
  final huge = shape.cellCount > pictureHugeCells;
  return SnakeBoard.generateShaped(
    shape.rows,
    seed: level,
    minLength: pictureLongMinLength,
    // Huge pictures need longer snakes to cover their interiors: capped at 14,
    // a 40x56 picture measured 81% covered, at 30 it reached 94%.
    maxLength: huge ? 28 : 14,
    // Half the default: measured on the slowest pictures, 48 candidates covered
    // as much as 96 at half the wait. Huge pictures keep 48 too: at 24, three
    // of them fell to 88-89% at their level's seed, and 48 costs ~0.4-0.8s on
    // desktop, which the prefetch hides.
    poolSize: 48,
  );
}

/// Pictures above this many cells are the huge tier: longer snakes, a smaller
/// candidate pool. Every picture drawn before that tier is below it, so their
/// boards are unchanged by it.
const pictureHugeCells = 900;

/// [level]'s picture as a grid, `true` inside. Cached: the screen repaints the
/// board every animation frame.
List<List<bool>> pictureMaskForLevel(int level) {
  final shape = pictureShapeForLevel(level);
  return _masks[_pictureKey(level)] ??= [
    for (final r in shape.rows) [for (final ch in r.split('')) ch != '.']
  ];
}

final _masks = <(int, bool), List<List<bool>>>{};

/// [level]'s picture in colour: one ARGB per cell from [picturePalette], null
/// outside. Cached, like [pictureMaskForLevel].
List<List<int?>> pictureColoursForLevel(int level) {
  final shape = pictureShapeForLevel(level);
  return _colours[_pictureKey(level)] ??= [
    for (final r in shape.rows)
      [for (final ch in r.split('')) ch == '.' ? null : picturePalette[ch]]
  ];
}

final _colours = <(int, bool), List<List<int?>>>{};

/// Size, arrow count and hearts for [level], all taken from its picture.
ArrowLevelConfig pictureConfigForLevel(int level) {
  final shape = pictureShapeForLevel(level);
  final count = shape.cellCount;
  return ArrowLevelConfig(
    rows: shape.rowCount,
    cols: shape.colCount,
    arrowCount: count,
    hearts: arrowHeartsForCount(count),
  );
}

/// The board for [level]. Deterministic in the level, so a retry — or a board
/// built ahead of time in another isolate — is identical.
ArrowBoard generatePictureBoard(int level) =>
    ArrowBoard.generateShapedAtHardness(
      pictureShapeForLevel(level),
      seed: level,
      hardness: pictureHardnessForLevel(level),
    );
