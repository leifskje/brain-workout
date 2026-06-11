import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'trail_models.dart';

/// Playable Follow the Trail: tap the scattered circles in order; a line
/// traces your progress. A wrong tap costs a heart.
class TrailScreen extends StatefulWidget {
  const TrailScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends State<TrailScreen> {
  static const _gameId = 'trail';
  static const _accent = Color(0xFFCC7722);
  static const _nodeSize = 56.0;

  int _level = 1;
  late TrailBoard _board;
  late int _hearts;
  int _visited = 0; // nodes tapped in order so far
  int? _wrongFlash; // node briefly flashed red after a wrong tap
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpTrail,
            accent: _accent);
      }
    });
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = TrailBoard.generate(level);
      _hearts = trailConfigForLevel(level).hearts;
      _visited = 0;
      _wrongFlash = null;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onNodeTap(int index) {
    if (_busy || index < _visited) return;
    if (index == _visited) {
      HapticFeedback.lightImpact();
      setState(() {
        _visited++;
        _wrongFlash = null;
      });
      if (_visited == _board.nodes.length) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 350), _showWin);
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _wrongFlash = index;
        _hearts = (_hearts - 1).clamp(0, 1 << 30);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _wrongFlash = null);
      });
      if (_hearts <= 0) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 550), () {
          if (mounted) _showLose();
        });
      }
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final lost = trailConfigForLevel(_level).hearts - _hearts;
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: t.levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () =>
                    showHowToPlay(context, body: t.helpTrail, accent: _accent)),
            _buildHearts(trailConfigForLevel(_level).hearts),
            const SizedBox(height: 6),
            Text(
              _visited < _board.nodes.length
                  ? t.trailNext(_board.nodes[_visited].label)
                  : '',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: _accent),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCanvas(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                t.trailHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.black.withValues(alpha: 0.6)),
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

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth, h = constraints.maxHeight;
        Offset center(TrailNode n) => Offset(
              n.x * (w - _nodeSize) + _nodeSize / 2,
              n.y * (h - _nodeSize) + _nodeSize / 2,
            );

        return Container(
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _TrailPainter(
                  points: [
                    for (var i = 0; i < _visited; i++)
                      center(_board.nodes[i])
                  ],
                  color: _accent,
                ),
              ),
              for (var i = 0; i < _board.nodes.length; i++)
                Positioned(
                  left: _board.nodes[i].x * (w - _nodeSize),
                  top: _board.nodes[i].y * (h - _nodeSize),
                  child: _node(i),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _node(int i) {
    final visited = i < _visited;
    final wrong = _wrongFlash == i;
    return GestureDetector(
      key: ValueKey('trail_node_$i'),
      onTap: () => _onNodeTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(
          color: wrong
              ? const Color(0xFFE53935)
              : visited
                  ? _accent
                  : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: wrong ? const Color(0xFFB71C1C) : _accent, width: 2.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          _board.nodes[i].label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: visited || wrong ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.points.length != points.length || old.color != color;
}
