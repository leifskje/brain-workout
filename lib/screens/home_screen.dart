import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../games/games_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/game_definition.dart';
import '../services/app_locale.dart';
import '../services/progress_store.dart';
import 'coming_soon_screen.dart';
import 'credits_screen.dart';
import 'level_select_screen.dart';

const String _supportUrl = 'https://ko-fi.com/loffen';

/// Startup screen: pick a brain-training game to play.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Opens [game]. With [direct], level games skip the level picker and jump
  /// straight into their current level (used by Continue / Play next).
  Future<void> _open(GameDefinition game, {bool direct = false}) async {
    if (game.available) ProgressStore.instance.recordOpened(game.id);
    final WidgetBuilder builder;
    if (game.screenBuilder != null) {
      builder = game.screenBuilder!; // direct-entry game (e.g. Wordle)
    } else if (game.hasLevels) {
      builder = direct
          ? (_) =>
              game.levelBuilder!(ProgressStore.instance.highestLevel(game.id))
          : (_) => LevelSelectScreen(game: game);
    } else {
      final title = game.title(AppLocalizations.of(context));
      builder = (_) => ComingSoonScreen(title: title);
    }
    await Navigator.push(context, MaterialPageRoute(builder: builder));
    // Returning from a game may have advanced progress — refresh the cards.
    if (mounted) setState(() {});
  }

  /// The most recently opened playable game, or null before the first play.
  GameDefinition? get _lastPlayed {
    GameDefinition? best;
    var bestTime = 0;
    for (final game in gamesCatalog) {
      if (!game.available) continue;
      final t = ProgressStore.instance.lastOpened(game.id);
      if (t > bestTime) {
        bestTime = t;
        best = game;
      }
    }
    return best;
  }

  /// The game "Play next" suggests: rotates daily and advances with each
  /// completed level, so a workout naturally varies.
  GameDefinition get _suggested {
    final games = [for (final g in gamesCatalog) if (g.available) g];
    final day = DateTime.now().difference(DateTime(2026)).inDays;
    return games[(day + ProgressStore.instance.dailyCount) % games.length];
  }

  Future<void> _support() async {
    final ok = await launchUrl(
      Uri.parse(_supportUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).supportPageError)),
      );
    }
  }

  Widget _buildDailyCard() {
    final t = AppLocalizations.of(context);
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
                      ? t.streakDays(streak)
                      : t.startStreakToday,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (store.bestStreak > 1)
                Text(t.bestStreak(store.bestStreak),
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
                      ? t.workoutComplete
                      : t.workoutProgress(count.clamp(0, goal), goal),
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
          if (!complete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _open(_suggested, direct: true),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(t.playNext(_suggested.title(t))),
                style: FilledButton.styleFrom(
                  backgroundColor: _suggested.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Wide "Continue" card: jumps straight back into the most recently played
  /// game. Hidden until something has been played once.
  Widget _buildContinueCard() {
    final game = _lastPlayed;
    if (game == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final store = ProgressStore.instance;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(game, direct: true),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: game.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(game.icon, size: 28, color: game.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.continueLabel,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black45),
                      ),
                      Text(
                        game.hasLevels
                            ? t.gameAtLevel(
                                game.title(t), store.highestLevel(game.id))
                            : game.title(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill_rounded,
                    size: 34, color: game.color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Globe menu: follow the phone language, or force English / Norwegian.
  Widget _buildLanguageMenu() {
    final t = AppLocalizations.of(context);
    final current = ProgressStore.instance.appLanguageId ?? 'system';
    return PopupMenuButton<String>(
      tooltip: t.language,
      initialValue: current,
      icon: const Icon(Icons.language_rounded,
          size: 28, color: Colors.black45),
      onSelected: (id) {
        final language = id == 'system' ? null : id;
        ProgressStore.instance.setAppLanguageId(language);
        appLocaleOverride.value = language == null ? null : Locale(language);
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'system', child: Text(t.languageSystem)),
        const PopupMenuItem(value: 'en', child: Text('English')),
        const PopupMenuItem(value: 'nb', child: Text('Norsk')),
      ],
    );
  }

  /// Route to the word-list attribution. Norsk ordbank is CC BY 4.0, which
  /// obliges the app itself to carry the credit — so this button is a licence
  /// requirement, not a nicety, and shouldn't be removed.
  Widget _buildCreditsButton() {
    return IconButton(
      tooltip: AppLocalizations.of(context).credits,
      icon: const Icon(Icons.info_outline_rounded,
          size: 28, color: Colors.black45),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreditsScreen()),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).appTitle,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).homeTagline,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  _buildLanguageMenu(),
                  _buildCreditsButton(),
                ],
              ),
            ),
            _buildDailyCard(),
            _buildContinueCard(),
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
                label: Text(AppLocalizations.of(context).supportDeveloper),
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
    final t = AppLocalizations.of(context);
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
              Row(
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
                  const SizedBox(width: 6),
                  // Scales down rather than overflowing on narrow cards /
                  // large text scales.
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: game.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            game.category.label(t),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: game.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                game.title(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  game.subtitle(t),
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
                          ? t.levelN(
                              ProgressStore.instance.highestLevel(game.id))
                          : t.play,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: game.color),
                    ),
                    const Spacer(),
                    if (game.hasLevels &&
                        ProgressStore.instance.totalStars(game.id) > 0) ...[
                      const Icon(Icons.star_rounded,
                          size: 18, color: Color(0xFFF5B301)),
                      const SizedBox(width: 2),
                      Text(
                        '${ProgressStore.instance.totalStars(game.id)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54),
                      ),
                      const SizedBox(width: 4),
                    ],
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
                  child: Text(
                    t.comingSoon,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
