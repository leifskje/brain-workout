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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => game.available
            ? LevelSelectScreen(game: game)
            : ComingSoonScreen(title: game.title),
      ),
    );
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
                      'Level ${ProgressStore.instance.highestLevel(game.id)}',
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
