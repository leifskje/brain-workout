import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'merge_models.dart';

/// Playable Merge (2048): push the whole board with the arrow pad (or a
/// swipe); equal numbers slide together and merge. Reach the goal tile to win.
/// Tiles visibly slide so it's clear what moved.
class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen>
    with SingleTickerProviderStateMixin {
  static const _gameId = 'merge';
  static const _accent = Color(0xFFEDB22E);
  static const _boardBg = Color(0xFFBBADA0);
  static const _emptyCell = Color(0xFFCDC1B4);

  int _level = 1;
  late MergeGame _game;
  late final AnimationController _slide;

  // Animation state for the current move.
  List<TileSlide> _slides = const [];
  Set<(int, int)> _popCells = const {};
  bool _animating = false;
  int _moveSeq = 0;

  @override
  void initState() {
    super.initState();
    // Create eagerly in initState (never a lazy late field), so dispose()
    // can't construct it on a deactivated widget.
    // preserve: the slide is how the player sees which tiles merged, so it must
    // survive reduced-animation mode. See lib/theme/motion.dart.
    _slide = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        animationBehavior: AnimationBehavior.preserve)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) _onSlideDone();
      });
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpMerge,
            accent: _accent);
      }
    });
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _game = MergeGame.generate(level);
      _slides = const [];
      _popCells = const {};
      _animating = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _move(MergeDirection dir) {
    if (_animating || !willChange(_game.grid, dir)) return;

    // Plan the slide off the pre-move grid, then apply the move (mutates +
    // spawns a new tile).
    final slides = planSlides(_game.grid, dir);
    final before = [for (final row in _game.grid) [...row]];
    _game.move(dir);

    // Cells to pop after the slide settles: merge destinations + the spawn.
    final pops = <(int, int)>{
      for (final s in slides)
        if (s.merged) (s.toRow, s.toCol),
    };
    final spawn = _spawnedCell(before, slides);
    if (spawn != null) pops.add(spawn);

    HapticFeedback.lightImpact();
    setState(() {
      _slides = slides;
      _popCells = pops;
      _animating = true;
      _moveSeq++;
    });
    _slide.forward(from: 0);
  }

  /// The cell the model spawned a tile into: the one differing between the
  /// post-slide board (derived from [slides]) and the actual grid.
  (int, int)? _spawnedCell(List<List<int>> before, List<TileSlide> slides) {
    final n = _game.size;
    final afterSlide = List.generate(n, (_) => List<int>.filled(n, 0));
    for (final s in slides) {
      afterSlide[s.toRow][s.toCol] = s.merged ? s.value * 2 : s.value;
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (_game.grid[r][c] != afterSlide[r][c]) return (r, c);
      }
    }
    return null;
  }

  void _onSlideDone() {
    setState(() {
      _animating = false;
      _slides = const [];
    });
    if (_game.reachedTarget) {
      Future.delayed(const Duration(milliseconds: 150), _showWin);
    } else if (!_game.hasMoves) {
      Future.delayed(const Duration(milliseconds: 150), _showLose);
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final empty = _game.emptyCount;
    final stars = empty >= 8 ? 3 : (empty >= 4 ? 2 : 1);
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordStars(_gameId, _level, stars);
    showWinDialog(context, level: _level, accent: _accent, stars: stars)
        .then((action) {
      if (!mounted || action == null) return;
      if (action == WinAction.next) {
        _loadLevel(_level + 1);
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  void _showLose() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.noMoves),
        content: Text(t.noMovesBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(t.home),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              Navigator.pop(dialogContext);
              _restart();
            },
            child: Text(t.tryAgain),
          ),
        ],
      ),
    );
  }

  void _onSwipe(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.dx.abs() < 80 && v.dy.abs() < 80) return;
    if (v.dx.abs() > v.dy.abs()) {
      _move(v.dx > 0 ? MergeDirection.right : MergeDirection.left);
    } else {
      _move(v.dy > 0 ? MergeDirection.down : MergeDirection.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: t.levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: t.helpMerge, accent: _accent)),
            const SizedBox(height: 6),
            _buildGoal(t),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: GestureDetector(
                    onPanEnd: _onSwipe,
                    child: _buildBoard(),
                  ),
                ),
              ),
            ),
            _buildArrowPad(t),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildGoal(AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(t.mergeGoalLabel,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black54)),
        const SizedBox(width: 8),
        _miniTile(_game.target),
        const SizedBox(width: 16),
        Text(t.mergeScore(_game.score),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black45)),
      ],
    );
  }

  Widget _miniTile(int value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _tileColor(value),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$value',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: value <= 4 ? const Color(0xFF6D6459) : Colors.white)),
      );

  Widget _buildBoard() {
    final n = _game.size;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final dim = math.min(constraints.maxWidth, constraints.maxHeight);
        final cell = (dim - gap * (n + 1)) / n;
        final boardSize = cell * n + gap * (n + 1);
        double left(int c) => gap + c * (cell + gap);
        double top(int r) => gap + r * (cell + gap);

        final children = <Widget>[
          // Empty cell backers.
          for (var r = 0; r < n; r++)
            for (var c = 0; c < n; c++)
              Positioned(
                left: left(c),
                top: top(r),
                child: _cellBox(0, cell),
              ),
        ];

        if (_animating) {
          // Moving tiles slide from their old cell to the new one.
          children.add(
            AnimatedBuilder(
              animation: _slide,
              builder: (context, _) {
                final p = Curves.easeOut.transform(_slide.value);
                return Stack(
                  children: [
                    for (final s in _slides)
                      Positioned(
                        left: left(s.fromCol) +
                            (left(s.toCol) - left(s.fromCol)) * p,
                        top: top(s.fromRow) +
                            (top(s.toRow) - top(s.fromRow)) * p,
                        child: _cellBox(s.value, cell),
                      ),
                  ],
                );
              },
            ),
          );
        } else {
          // Settled board: real values, with a pop on merged/new tiles.
          for (var r = 0; r < n; r++) {
            for (var c = 0; c < n; c++) {
              final v = _game.grid[r][c];
              if (v == 0) continue;
              final pop = _popCells.contains((r, c));
              children.add(Positioned(
                left: left(c),
                top: top(r),
                child: pop
                    ? TweenAnimationBuilder<double>(
                        key: ValueKey('pop_${_moveSeq}_${r}_$c'),
                        tween: Tween(begin: 0.5, end: 1),
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: _cellBox(v, cell),
                      )
                    : _cellBox(v, cell),
              ));
            }
          }
        }

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: _boardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(children: children),
        );
      },
    );
  }

  Widget _cellBox(int value, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: value == 0 ? _emptyCell : _tileColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: value == 0
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800,
                    color:
                        value <= 4 ? const Color(0xFF6D6459) : Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  Color _tileColor(int v) {
    switch (v) {
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      default:
        return const Color(0xFFEDC22E); // 2048+
    }
  }

  Widget _buildArrowPad(AppLocalizations t) {
    Widget btn(IconData icon, MergeDirection dir, String key) => Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: _accent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: ValueKey(key),
              borderRadius: BorderRadius.circular(14),
              onTap: () => _move(dir),
              child: SizedBox(
                width: 64,
                height: 52,
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.mergeHint,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.black.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        btn(Icons.keyboard_arrow_up_rounded, MergeDirection.up, 'merge_up'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            btn(Icons.keyboard_arrow_left_rounded, MergeDirection.left,
                'merge_left'),
            const SizedBox(width: 64),
            btn(Icons.keyboard_arrow_right_rounded, MergeDirection.right,
                'merge_right'),
          ],
        ),
        btn(Icons.keyboard_arrow_down_rounded, MergeDirection.down,
            'merge_down'),
      ],
    );
  }
}
