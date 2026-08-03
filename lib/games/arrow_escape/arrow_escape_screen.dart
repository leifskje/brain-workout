import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../theme/motion.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'arrow_escape_models.dart';

/// Playable Arrow Escape board.
///
/// Tap an arrow to send it off the board in the direction it points. The
/// arrow only leaves if its straight path to the edge is clear; otherwise it
/// shakes and costs a heart. Clear the whole board to win.
class ArrowEscapeScreen extends StatefulWidget {
  const ArrowEscapeScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<ArrowEscapeScreen> createState() => _ArrowEscapeScreenState();
}

class _ArrowEscapeScreenState extends State<ArrowEscapeScreen>
    with SingleTickerProviderStateMixin {
  /// Fallback only: replaced from the layout once the cell size is known. A
  /// fixed duration meant the *speed* varied with the device, because a piece
  /// slides the full width of the board and that distance scales with the screen.
  static const _fallbackMoveDuration = Duration(milliseconds: 380);
  Duration _moveDuration = _fallbackMoveDuration;
  static const _gameId = 'arrow_escape';
  static const _accent = Color(0xFF3F7DAA);

  int _level = 1;
  late ArrowBoard _board;
  late int _hearts;
  int? _blockedId;
  bool _busy = false; // locks taps while a win/lose transition is pending

  late final AnimationController _shake;

  void _onShakeTick() {
    // The controller can tick during/after a route pop; only rebuild while
    // this widget is still in the tree.
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Create eagerly in initState (not as a lazy `late final`): if it were
    // created lazily, a play-through with no blocked tap would never construct
    // it, and dispose()'s _shake.dispose() would lazily build it mid-teardown,
    // triggering a TickerMode ancestor lookup on a deactivated widget.
    // preserve: reduced-animation mode would collapse this to one frame, and the
    // shake is how a blocked arrow reports itself. See lib/theme/motion.dart.
    _shake = AnimationController(
      animationBehavior: AnimationBehavior.preserve,
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_onShakeTick);
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpArrowEscape,
            accent: _accent);
      }
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = ArrowBoard.generate(level);
      _hearts = configForLevel(level).hearts;
      _blockedId = null;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onTapPiece(ArrowPiece p) {
    if (_busy || p.escaped) return;

    if (_board.isPathClear(p)) {
      HapticFeedback.lightImpact();
      setState(() => p.escaped = true);
      if (_board.isSolved) {
        _busy = true;
        Future.delayed(_moveDuration + const Duration(milliseconds: 80), () {
          if (mounted) _showWin();
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _blockedId = p.id;
        _hearts = math.max(0, _hearts - 1);
      });
      _shake.forward(from: 0);
      if (_hearts <= 0) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showLose();
        });
      }
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final lost = configForLevel(_level).hearts - _hearts;
    final stars = lost == 0 ? 3 : (lost <= 2 ? 2 : 1);
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).outOfHearts),
        content: Text(AppLocalizations.of(context).outOfHeartsBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(AppLocalizations.of(context).home),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _restart();
            },
            child: Text(AppLocalizations.of(context).tryAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHearts = configForLevel(_level).hearts;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: AppLocalizations.of(context).levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: AppLocalizations.of(context).helpArrowEscape,
                    accent: _accent)),
            _buildHearts(maxHearts),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: _buildBoard()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                AppLocalizations.of(context).arrowEscapeHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHearts(int maxHearts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < maxHearts; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < _hearts
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: i < _hearts ? const Color(0xFFE53935) : Colors.black26,
              size: 28,
            ),
          ),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dim = math.min(constraints.maxWidth, constraints.maxHeight);
        final cell = dim / _board.rows;
        // A piece leaves by sliding clear of the board, so time that distance at
        // the shared speed rather than fixing the duration. Same value feeds the
        // AnimatedPositioned and the post-move delay, so they cannot drift.
        _moveDuration = slideDuration(
            (math.max(_board.rows, _board.cols) + 2) * cell);
        final width = cell * _board.cols;
        final height = cell * _board.rows;

        return ClipRRect(
          // Named so tests can aim taps at a cell centre, as in Arrow Maze.
          key: const ValueKey('arrow_escape_board'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: width,
            height: height,
            color: const Color(0xFFE8EDF2),
            child: Stack(
              children: [
                for (var r = 0; r < _board.rows; r++)
                  for (var c = 0; c < _board.cols; c++)
                    Positioned(
                      left: c * cell,
                      top: r * cell,
                      width: cell,
                      height: cell,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                    ),
                for (final p in _board.pieces) _buildPiece(p, cell),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPiece(ArrowPiece p, double cell) {
    // Where the arrow ends up once it has left: fully clear of the board, in the
    // direction it points.
    var offset = Offset.zero;
    switch (p.dir) {
      case Direction.left:
        offset = Offset(-(_board.cols + 2) * cell, 0);
      case Direction.right:
        offset = Offset((_board.cols + 2) * cell, 0);
      case Direction.up:
        offset = Offset(0, -(_board.rows + 2) * cell);
      case Direction.down:
        offset = Offset(0, (_board.rows + 2) * cell);
    }

    final isBlocked = p.id == _blockedId && _shake.isAnimating;
    final shakeDx = isBlocked
        ? math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 6
        : 0.0;

    return _PieceView(
      key: ValueKey(p.id),
      home: Offset(p.col * cell, p.row * cell),
      away: offset,
      cell: cell,
      duration: _moveDuration,
      escaped: p.escaped,
      shakeDx: shakeDx,
      dir: p.dir,
      blocked: isBlocked,
      onTap: () => _onTapPiece(p),
    );
  }
}

/// One arrow on the board, owning the animation that carries it off.
///
/// This was an `AnimatedPositioned` + `AnimatedOpacity`, which reads better but
/// cannot survive the platform's "reduce animations" setting:
/// `ImplicitlyAnimatedWidgetState` builds its controller with the default
/// [AnimationBehavior.normal], and that runs at **5% duration** when animations
/// are disabled — the framework's own words are that this limits it "to a single
/// frame". The arrow teleported off the board while the game still waited a full
/// `_moveDuration` before the win dialog, so the move read as no animation at all.
/// An explicit controller can ask for [AnimationBehavior.preserve]; an implicit
/// one cannot. The slide is how this game reports what a tap did, so it is
/// functional motion, which is exactly what `preserve` is for.
///
/// One controller per piece (rather than one shared by the board) so a second tap
/// mid-slide does not snap the first arrow to its destination.
class _PieceView extends StatefulWidget {
  const _PieceView({
    super.key,
    required this.home,
    required this.away,
    required this.cell,
    required this.duration,
    required this.escaped,
    required this.shakeDx,
    required this.dir,
    required this.blocked,
    required this.onTap,
  });

  /// Top-left of the arrow's resting cell, and how far it travels to leave.
  final Offset home;
  final Offset away;
  final double cell;
  final Duration duration;
  final bool escaped;
  final double shakeDx;
  final Direction dir;
  final bool blocked;
  final VoidCallback onTap;

  @override
  State<_PieceView> createState() => _PieceViewState();
}

class _PieceViewState extends State<_PieceView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    // A level can be resumed with pieces already gone; don't animate those in.
    if (widget.escaped) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(_PieceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ctrl.duration = widget.duration;
    if (widget.escaped == oldWidget.escaped) return;
    if (widget.escaped) {
      _ctrl.forward(from: 0);
    } else {
      // Restart / next level reuses these widgets (the keys are piece ids, which
      // start over), so a controller left at 1 would hide the new arrow for good.
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    final slide = widget.away * Curves.easeIn.transform(t);
    return Positioned(
      left: widget.home.dx + slide.dx,
      top: widget.home.dy + slide.dy,
      width: widget.cell,
      height: widget.cell,
      child: Opacity(
        opacity: 1 - t,
        child: Transform.translate(
          offset: Offset(widget.shakeDx, 0),
          child: Padding(
            padding: EdgeInsets.all(widget.cell * 0.08),
            child: GestureDetector(
              onTap: widget.onTap,
              child: _ArrowTile(dir: widget.dir, blocked: widget.blocked),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowTile extends StatelessWidget {
  const _ArrowTile({required this.dir, required this.blocked});

  final Direction dir;
  final bool blocked;

  IconData get _icon => switch (dir) {
        Direction.up => Icons.arrow_upward_rounded,
        Direction.down => Icons.arrow_downward_rounded,
        Direction.left => Icons.arrow_back_rounded,
        Direction.right => Icons.arrow_forward_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color =
        blocked ? const Color(0xFFE53935) : const Color(0xFF37474F);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.62,
          heightFactor: 0.62,
          child: FittedBox(
            child: Icon(_icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
