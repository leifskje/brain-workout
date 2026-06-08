import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/progress_store.dart';
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
  static const _moveDuration = Duration(milliseconds: 380);
  static const _gameId = 'arrow_escape';

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
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_onShakeTick);
    _loadLevel(widget.startLevel);
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
      setState(() => p.escaped = true);
      if (_board.isSolved) {
        _busy = true;
        Future.delayed(_moveDuration + const Duration(milliseconds: 80), () {
          if (mounted) _showWin();
        });
      }
    } else {
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Well done!'),
        content: Text('You cleared level $_level.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _loadLevel(_level + 1);
            },
            child: const Text('Next level'),
          ),
        ],
      ),
    );
  }

  void _showLose() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Out of hearts'),
        content: const Text('No hearts left. Want to try this level again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _restart();
            },
            child: const Text('Try again'),
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
            _buildHeader(context),
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
                'Tap an arrow to send it off the board. '
                'It needs a clear path to the edge.',
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 28,
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Level $_level',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            iconSize: 28,
            tooltip: 'Restart level',
            onPressed: _restart,
          ),
        ],
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
        final width = cell * _board.cols;
        final height = cell * _board.rows;

        return ClipRRect(
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
    var left = p.col * cell;
    var top = p.row * cell;

    // When escaped, slide the arrow fully off the board in its direction.
    if (p.escaped) {
      final offCols = (_board.cols + 2) * cell;
      final offRows = (_board.rows + 2) * cell;
      switch (p.dir) {
        case Direction.left:
          left = -offCols;
        case Direction.right:
          left = offCols;
        case Direction.up:
          top = -offRows;
        case Direction.down:
          top = offRows;
      }
    }

    final isBlocked = p.id == _blockedId && _shake.isAnimating;
    final shakeDx = isBlocked
        ? math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 6
        : 0.0;

    return AnimatedPositioned(
      key: ValueKey(p.id),
      duration: _moveDuration,
      curve: Curves.easeIn,
      left: left,
      top: top,
      width: cell,
      height: cell,
      child: AnimatedOpacity(
        duration: _moveDuration,
        opacity: p.escaped ? 0 : 1,
        child: Transform.translate(
          offset: Offset(shakeDx, 0),
          child: Padding(
            padding: EdgeInsets.all(cell * 0.08),
            child: GestureDetector(
              onTap: () => _onTapPiece(p),
              child: _ArrowTile(dir: p.dir, blocked: isBlocked),
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
