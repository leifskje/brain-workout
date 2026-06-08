import 'package:flutter/material.dart';

/// Metadata describing a single mini-game shown on the home screen.
///
/// A game is considered playable when [levelBuilder] is provided; otherwise it
/// is rendered as "coming soon".
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.levelBuilder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Builds the playable screen starting at [level]. Null = "coming soon".
  final Widget Function(int level)? levelBuilder;

  bool get available => levelBuilder != null;
}
