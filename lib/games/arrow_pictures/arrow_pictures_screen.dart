import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/board_prefetch.dart';
import '../arrow_escape/arrow_escape_screen.dart';
import '../snake_arrows/snake_arrows_screen.dart';
import 'arrow_pictures_models.dart';

/// Arrow Pictures: every board a picture, in short arrows (Arrow Escape's
/// screen) or long ones (Arrow Maze's), whichever the level's picture uses.
///
/// Prefetched either way: the grids that make a good picture are the expensive
/// ones, and generating them inline would freeze the screen.
class ArrowPicturesScreen extends StatelessWidget {
  const ArrowPicturesScreen({super.key, this.startLevel = 1});

  final int startLevel;

  static const gameId = 'arrow_pictures';
  static const accent = Color(0xFF8D6E63);

  /// Crossing to the other kind of arrow swaps the screen; staying on the same
  /// kind loads in place, as every other game does.
  static bool Function(BuildContext, int) _redirectUnless(PictureArrows kind) =>
      (context, level) {
        if (pictureArrowsForLevel(level) == kind) return false;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
              builder: (_) => ArrowPicturesScreen(startLevel: level)),
        );
        return true;
      };

  /// "You cleared level 76. It was a seahorse!"
  static String winMessage(AppLocalizations t, int level) => t.pictureCleared(
      level, t.pictureName(pictureShapeForLevel(level).name));

  static final shortSpec = ArrowGameSpec(
    gameId: gameId,
    accent: accent,
    help: (t) => t.helpArrowPictures,
    config: pictureConfigForLevel,
    generate: generatePictureBoard,
    prefetch: arrowPicturesPrefetch,
    warm: warmPictureLevel,
    redirect: _redirectUnless(PictureArrows.short),
    pictureColours: pictureColoursForLevel,
    winMessage: winMessage,
  );

  static final longSpec = SnakeGameSpec(
    gameId: gameId,
    accent: accent,
    help: (t) => t.helpArrowPictures,
    hearts: (_) => pictureLongHearts,
    // Long arrows are thin lines: without an outline the picture is invisible
    // until it is finished. Short arrows are solid tiles and need none.
    pictureColours: pictureColoursForLevel,
    pictureOutline: true,
    winMessage: winMessage,
    prefetch: arrowPicturesLongPrefetch,
    warm: warmPictureLevel,
    redirect: _redirectUnless(PictureArrows.long),
  );

  @override
  Widget build(BuildContext context) =>
      pictureArrowsForLevel(startLevel) == PictureArrows.long
          ? SnakeArrowsScreen(startLevel: startLevel, spec: longSpec)
          : ArrowEscapeScreen(startLevel: startLevel, spec: shortSpec);
}
