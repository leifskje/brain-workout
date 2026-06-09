import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../games/games_catalog.dart';
import '../models/game_definition.dart';
import '../services/progress_store.dart';
import 'coming_soon_screen.dart';
import 'level_select_screen.dart';

// TODO: replace with your real Ko-fi / Buy Me a Coffee page URL.
const String _supportUrl = 'https://ko-fi.com/yourname';

/// Startup screen: pick a brain-training game to play.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(GameDefinition game) async {
    final WidgetBuilder builder;
    if (game.screenBuilder != null) {
      builder = game.screenBuilder!; // direct-entry game (e.g. Wordle)
    } else if (game.hasLevels) {
      builder = (_) => LevelSelectScreen(game: game);
    } else {
      builder = (_) => ComingSoonScreen(title: game.title);
    }
    await Navigator.push(context, MaterialPageRoute(builder: builder));
    // Returning from a game may have advanced progress — refresh the cards.
    if (mounted) setState(() {});
  }

  Future<void> _support() async {
    final ok = await launchUrl(
      Uri.parse(_supportUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the support page.')),
      );
    }
  }

  Widget _buildDailyCard() {
    final store = ProgressStore.instance;
    final count = store.dailyCount;
    final goal = ProgressStore.dailyGoal;
    final complete = store.dailyWorkoutComplete;
    final streak = store.currentStreak;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: complete ? const Color(0xFF66BB6A) : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(streak > 0 ? '🔥' : '🧠',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  streak > 0
                      ? '$streak day streak'
                      : 'Start your streak today!',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (store.bestStreak > 1)
                Text('Best: ${store.bestStreak}',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  complete
                      ? 'Today\'s workout complete! 🎉'
                      : 'Today\'s workout: ${count.clamp(0, goal)} of $goal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: complete
                        ? const Color(0xFF2E7D32)
                        : Colors.black87,
                  ),
                ),
              ),
              for (var i = 0; i < goal; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    i < count
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 24,
                    color: i < count
                        ? const Color(0xFF66BB6A)
                        : Colors.black26,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brain Workout',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick a game for today\'s workout',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            _buildDailyCard(),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
                children: [
                  for (final game in gamesCatalog)
                    _GameCard(game: game, onOpen: () => _open(game)),
                ],
              ),
            ),
            // Quiet, optional support link below the games.
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: TextButton.icon(
                onPressed: _support,
                icon: const Icon(Icons.coffee_rounded, size: 18),
                label: const Text('Support the developer'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black45,
                  textStyle:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onOpen});

  final GameDefinition game;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: game.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(game.icon, size: 36, color: game.color),
              ),
              const Spacer(),
              Text(
                game.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  game.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 8),
              if (game.available)
                Row(
                  children: [
                    Text(
                      game.hasLevels
                          ? 'Level ${ProgressStore.instance.highestLevel(game.id)}'
                          : 'Play',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: game.color),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 22, color: game.color),
                  ],
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Coming soon',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
