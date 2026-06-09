import 'package:flutter/material.dart';

/// Metadata describing a single mini-game shown on the home screen.
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
    this.levelBuilder,
    this.screenBuilder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Builds the playable screen starting at [level] (level-based game).
  final Widget Function(int level)? levelBuilder;

  /// Builds a direct-entry screen (no numbered levels). Takes precedence over
  /// [levelBuilder] for routing.
  final WidgetBuilder? screenBuilder;

  bool get available => levelBuilder != null || screenBuilder != null;
  bool get hasLevels => levelBuilder != null && screenBuilder == null;
}
