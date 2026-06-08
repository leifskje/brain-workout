import 'package:flutter/material.dart';

import '../models/game_definition.dart';
import 'arrow_escape/arrow_escape_screen.dart';
import 'snake_arrows/snake_arrows_screen.dart';

/// The list of mini-games shown on the home screen.
///
/// To add a new game: build its screen, then add an entry here with a
/// `builder`. Entries without a `builder` show up as "coming soon".
final List<GameDefinition> gamesCatalog = [
  GameDefinition(
    id: 'arrow_escape',
    title: 'Arrow Escape',
    subtitle: 'Send every arrow off the board',
    icon: Icons.alt_route_rounded,
    color: const Color(0xFF3F7DAA),
    builder: (_) => const ArrowEscapeScreen(),
  ),
  GameDefinition(
    id: 'arrow_maze',
    title: 'Arrow Maze',
    subtitle: 'Untangle the long snaking arrows',
    icon: Icons.polyline_rounded,
    color: const Color(0xFF2E8B8B),
    builder: (_) => const SnakeArrowsScreen(),
  ),
  const GameDefinition(
    id: 'word_builder',
    title: 'Word Builder',
    subtitle: 'Find the hidden words',
    icon: Icons.abc_rounded,
    color: Color(0xFF6A8D3F),
  ),
  const GameDefinition(
    id: 'quick_maths',
    title: 'Quick Maths',
    subtitle: 'Warm up with numbers',
    icon: Icons.calculate_rounded,
    color: Color(0xFFB5651D),
  ),
  const GameDefinition(
    id: 'memory_match',
    title: 'Memory Match',
    subtitle: 'Remember the pairs',
    icon: Icons.grid_view_rounded,
    color: Color(0xFF7E57C2),
  ),
];
