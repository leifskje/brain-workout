import 'package:flutter/material.dart';

/// Metadata describing a single mini-game shown on the home screen.
///
/// A game is considered playable when [builder] is provided; otherwise it is
/// rendered as "coming soon".
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.builder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder? builder;

  bool get available => builder != null;
}
