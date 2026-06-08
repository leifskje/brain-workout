import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'snake_arrows_models.dart';

/// Playable "Arrow Maze": long, bent arrows that must slither off the board.
///
/// Tap an arrow to send it off head-first. It only leaves if the straight path
/// ahead of its head is clear of other arrows; otherwise it shakes and costs a
/// heart. Clear the whole board to win.
class SnakeArrowsScreen extends StatefulWidget {
  const SnakeArrowsScreen({super.key});

  @override
  State<SnakeArrowsScreen> createState() => _SnakeArrowsScreenState();
}

class _SnakeArrowsScreenState extends State<SnakeArrowsScreen>
    with TickerProviderStateMixin {
  static const _escapeDuration = Duration(milliseconds: 360);

  int _level = 1;
  late SnakeBoard _board;
  late int _hearts;
  int? _escapingId;
  int? _blockedId;
  bool _busy = false; // locks taps while an arrow is leaving / dialog pending

  late final AnimationController _escapeCtrl;
  late final AnimationController _shakeCtrl;

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Create eagerly in initState so dispose() never lazily constructs a
    // controller (which would do a TickerMode ancestor lookup) during teardown.
    _escapeCtrl = AnimationController(vsync: this, duration: _escapeDuration)
      ..addListener(_tick)
      ..addStatusListener(_onEscapeStatus);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_tick);
    _loadLevel(1);
  }

  @override
  void dispose() {
    _escapeCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _loadLevel(int level) {
    setState(() {
      _level = level;
      _board = SnakeBoard.generate(level);
      _hearts = snakeConfigForLevel(level).hearts;
      _escapingId = null;
      _blockedId = null;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onEscapeStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status != AnimationStatus.completed || _escapingId == null) return;
    final arrow = _board.arrows.firstWhere((a) => a.id == _escapingId);
    setState(() {
      arrow.escaped = true;
      _escapingId = null;
      _busy = false;
    });
    if (_board.isSolved) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _showWin();
      });
    }
  }

  void _handleTapCell(int row, int col) {
    if (_busy) return;
    final arrow = _board.arrowAt(row, col);
    if (arrow == null || arrow.escaped) return;

    if (_board.isPathClear(arrow)) {
      setState(() {
        _escapingId = arrow.id;
        _blockedId = null;
        _busy = true;
      });
      _escapeCtrl.forward(from: 0);
    } else {
      setState(() {
        _blockedId = arrow.id;
        _hearts = math.max(0, _hearts - 1);
      });
      _shakeCtrl.forward(from: 0);
      if (_hearts <= 0) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 450), () {
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
    final maxHearts = snakeConfigForLevel(_level).hearts;
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
                'Tap a long arrow to send it off, head-first. '
                'The path ahead of its head must be clear.',
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
        final boardSize = Size(cell * _board.cols, cell * _board.rows);

        return GestureDetector(
          onTapUp: (details) {
            final c = (details.localPosition.dx / cell).floor();
            final r = (details.localPosition.dy / cell).floor();
            if (r >= 0 && r < _board.rows && c >= 0 && c < _board.cols) {
              _handleTapCell(r, c);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CustomPaint(
              size: boardSize,
              painter: _SnakePainter(
                board: _board,
                cell: cell,
                escapingId: _escapingId,
                escapeT: _escapeCtrl.value,
                blockedId: _blockedId,
                shakeT: _shakeCtrl.isAnimating ? _shakeCtrl.value : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SnakePainter extends CustomPainter {
  _SnakePainter({
    required this.board,
    required this.cell,
    required this.escapingId,
    required this.escapeT,
    required this.blockedId,
    required this.shakeT,
  });

  final SnakeBoard board;
  final double cell;
  final int? escapingId;
  final double escapeT;
  final int? blockedId;
  final double? shakeT;

  static const _normalColor = Color(0xFF37474F);
  static const _blockedColor = Color(0xFFE53935);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8EDF2),
    );

    final grid = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var r = 0; r <= board.rows; r++) {
      canvas.drawLine(
          Offset(0, r * cell), Offset(board.cols * cell, r * cell), grid);
    }
    for (var c = 0; c <= board.cols; c++) {
      canvas.drawLine(
          Offset(c * cell, 0), Offset(c * cell, board.rows * cell), grid);
    }

    for (final arrow in board.arrows) {
      if (!arrow.escaped) _drawArrow(canvas, arrow);
    }
  }

  Offset _center(Cell c) =>
      Offset(c.col * cell + cell / 2, c.row * cell + cell / 2);

  void _drawArrow(Canvas canvas, SnakeArrow arrow) {
    var slide = Offset.zero;
    var opacity = 1.0;
    var color = _normalColor;

    if (arrow.id == escapingId) {
      final eased = Curves.easeIn.transform(escapeT);
      final dist = eased * cell * (board.rows + 2);
      slide = Offset(arrow.exitDir.dCol * dist, arrow.exitDir.dRow * dist);
      opacity = (1 - escapeT * 1.4).clamp(0.0, 1.0);
    } else if (arrow.id == blockedId && shakeT != null) {
      color = _blockedColor;
      final dx = math.sin(shakeT! * math.pi * 6) * (1 - shakeT!) * 6;
      slide = Offset(dx, 0);
    }

    if (opacity <= 0) return;
    final paintColor = color.withValues(alpha: opacity);

    final points = [for (final c in arrow.cells) _center(c) + slide];

    final body = Paint()
      ..color = paintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.46
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, body);

    // Arrowhead at the head, pointing in the exit direction.
    final dir = arrow.exitDir;
    final headCenter = points.last;
    final reach = cell * 0.34;
    final tip = headCenter + Offset(dir.dCol * reach, dir.dRow * reach);
    final perp = Offset(-dir.dRow.toDouble(), dir.dCol.toDouble()) * (reach * 0.9);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((headCenter + perp).dx, (headCenter + perp).dy)
      ..lineTo((headCenter - perp).dx, (headCenter - perp).dy)
      ..close();
    canvas.drawPath(head, Paint()..color = paintColor);
  }

  @override
  bool shouldRepaint(_SnakePainter oldDelegate) => true;
}
