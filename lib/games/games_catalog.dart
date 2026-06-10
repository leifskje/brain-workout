import 'package:flutter/material.dart';

import '../models/game_definition.dart';
import 'arrow_escape/arrow_escape_screen.dart';
import 'memory_match/memory_match_screen.dart';
import 'number_cross/number_cross_screen.dart';
import 'snake_arrows/snake_arrows_screen.dart';
import 'what_next/what_next_screen.dart';
import 'wordle/wordle_screen.dart';

/// The list of mini-games shown on the home screen.
///
/// To add a new game: build its screen, then add an entry here with a
/// `builder`. Entries without a `builder` show up as "coming soon".
final List<GameDefinition> gamesCatalog = [
  GameDefinition(
    id: 'arrow_escape',
    title: (t) => t.gameArrowEscapeTitle,
    subtitle: (t) => t.gameArrowEscapeSubtitle,
    icon: Icons.alt_route_rounded,
    color: const Color(0xFF3F7DAA),
    category: GameCategory.logic,
    levelBuilder: (level) => ArrowEscapeScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'arrow_maze',
    title: (t) => t.gameArrowMazeTitle,
    subtitle: (t) => t.gameArrowMazeSubtitle,
    icon: Icons.polyline_rounded,
    color: const Color(0xFF2E8B8B),
    category: GameCategory.logic,
    levelBuilder: (level) => SnakeArrowsScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'wordle',
    title: (t) => t.gameWordTitle,
    subtitle: (t) => t.gameWordSubtitle,
    icon: Icons.abc_rounded,
    color: const Color(0xFF6AAA64),
    category: GameCategory.words,
    screenBuilder: (_) => const WordleScreen(),
  ),
  GameDefinition(
    id: 'number_cross',
    title: (t) => t.gameNumberCrossTitle,
    subtitle: (t) => t.gameNumberCrossSubtitle,
    icon: Icons.calculate_rounded,
    color: const Color(0xFFB5651D),
    category: GameCategory.numbers,
    levelBuilder: (level) => NumberCrossScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'memory_match',
    title: (t) => t.gameMemoryMatchTitle,
    subtitle: (t) => t.gameMemoryMatchSubtitle,
    icon: Icons.grid_view_rounded,
    color: const Color(0xFF7E57C2),
    category: GameCategory.memory,
    levelBuilder: (level) => MemoryMatchScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'what_next',
    title: (t) => t.gameWhatNextTitle,
    subtitle: (t) => t.gameWhatNextSubtitle,
    icon: Icons.trending_up_rounded,
    color: const Color(0xFFEF8A3D),
    category: GameCategory.logic,
    levelBuilder: (level) => WhatNextScreen(startLevel: level),
  ),
];
