import 'package:flutter/material.dart';

import '../models/game_definition.dart';
import 'arrow_escape/arrow_escape_screen.dart';
import 'crack_code/crack_code_screen.dart';
import 'memory_match/memory_match_screen.dart';
import 'merge/merge_screen.dart';
import 'mini_sudoku/mini_sudoku_screen.dart';
import 'nonogram/nonogram_screen.dart';
import 'number_cross/number_cross_screen.dart';
import 'simon/simon_screen.dart';
import 'snake_arrows/snake_arrows_screen.dart';
import 'trail/trail_screen.dart';
import 'what_next/what_next_screen.dart';
import 'word_scramble/word_scramble_screen.dart';
import 'word_search/word_search_screen.dart';
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
    id: 'word_search',
    title: (t) => t.gameWordSearchTitle,
    subtitle: (t) => t.gameWordSearchSubtitle,
    icon: Icons.manage_search_rounded,
    color: const Color(0xFFB5527D),
    category: GameCategory.words,
    levelBuilder: (level) => WordSearchScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'mini_sudoku',
    title: (t) => t.gameMiniSudokuTitle,
    subtitle: (t) => t.gameMiniSudokuSubtitle,
    icon: Icons.grid_3x3_rounded,
    color: const Color(0xFF5C6BC0),
    category: GameCategory.numbers,
    levelBuilder: (level) => MiniSudokuScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'merge',
    title: (t) => t.gameMergeTitle,
    subtitle: (t) => t.gameMergeSubtitle,
    icon: Icons.apps_rounded,
    color: const Color(0xFFEDB22E),
    category: GameCategory.numbers,
    levelBuilder: (level) => MergeScreen(startLevel: level),
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
    id: 'word_scramble',
    title: (t) => t.gameWordScrambleTitle,
    subtitle: (t) => t.gameWordScrambleSubtitle,
    icon: Icons.shuffle_rounded,
    color: const Color(0xFF7A9D3C),
    category: GameCategory.words,
    levelBuilder: (level) => WordScrambleScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'crack_code',
    title: (t) => t.gameCrackCodeTitle,
    subtitle: (t) => t.gameCrackCodeSubtitle,
    icon: Icons.password_rounded,
    color: const Color(0xFF607D8B),
    category: GameCategory.logic,
    levelBuilder: (level) => CrackCodeScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'trail',
    title: (t) => t.gameTrailTitle,
    subtitle: (t) => t.gameTrailSubtitle,
    icon: Icons.timeline_rounded,
    color: const Color(0xFFCC7722),
    category: GameCategory.logic,
    levelBuilder: (level) => TrailScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'simon',
    title: (t) => t.gameSimonTitle,
    subtitle: (t) => t.gameSimonSubtitle,
    icon: Icons.touch_app_rounded,
    color: const Color(0xFFC94B4B),
    category: GameCategory.memory,
    levelBuilder: (level) => SimonScreen(startLevel: level),
  ),
  GameDefinition(
    id: 'nonogram',
    title: (t) => t.gameNonogramTitle,
    subtitle: (t) => t.gameNonogramSubtitle,
    icon: Icons.gradient_rounded,
    color: const Color(0xFF00796B),
    category: GameCategory.logic,
    levelBuilder: (level) => NonogramScreen(startLevel: level),
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
