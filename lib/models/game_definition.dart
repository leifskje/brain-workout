import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// The skill a game trains — shown as a chip on its card and (later) the
/// basis for section headers and a balanced daily workout.
enum GameCategory {
  words,
  numbers,
  memory,
  logic;

  String label(AppLocalizations t) => switch (this) {
        words => t.categoryWords,
        numbers => t.categoryNumbers,
        memory => t.categoryMemory,
        logic => t.categoryLogic,
      };
}

/// Metadata describing a single mini-game shown on the home screen.
///
/// Titles and subtitles are resolved through [AppLocalizations] so cards
/// follow the app language.
///
/// A game is playable when it provides either [levelBuilder] (a level-based
/// game shown via the level picker) or [screenBuilder] (a direct-entry game
/// with no numbered levels, e.g. Wordle). Otherwise it renders as "coming soon".
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    this.levelBuilder,
    this.screenBuilder,
  });

  final String id;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;
  final IconData icon;
  final Color color;
  final GameCategory category;

  /// Builds the playable screen starting at [level] (level-based game).
  final Widget Function(int level)? levelBuilder;

  /// Builds a direct-entry screen (no numbered levels). Takes precedence over
  /// [levelBuilder] for routing.
  final WidgetBuilder? screenBuilder;

  bool get available => levelBuilder != null || screenBuilder != null;
  bool get hasLevels => levelBuilder != null && screenBuilder == null;
}
