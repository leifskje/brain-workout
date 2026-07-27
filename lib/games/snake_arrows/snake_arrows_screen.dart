import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'snake_arrows_models.dart';

/// Playable "Arrow Maze": long, bent arrows that must slither off the board.
///
/// Tap an arrow to send it off head-first. It only leaves if the straight path
/// ahead of its head is clear of other arrows; otherwise it shakes and costs a
/// heart. Clear the whole board to win.
class SnakeArrowsScreen extends StatefulWidget {
  const SnakeArrowsScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<SnakeArrowsScreen> createState() => _SnakeArrowsScreenState();
}

class _SnakeArrowsScreenState extends State<SnakeArrowsScreen>
    with TickerProviderStateMixin {
  static const _escapeDuration = Duration(milliseconds: 520);
  static const _gameId = 'arrow_maze';
  static const _accent = Color(0xFF2E8B8B);

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
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpArrowMaze,
            accent: _accent);
      }
    });
  }

  @override
  void dispose() {
    _escapeCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
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
      HapticFeedback.lightImpact();
      setState(() {
        _escapingId = arrow.id;
        _blockedId = null;
        _busy = true;
      });
      _escapeCtrl.forward(from: 0);
    } else {
      HapticFeedback.mediumImpact();
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
    HapticFeedback.heavyImpact();
    final lost = snakeConfigForLevel(_level).hearts - _hearts;
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
    final maxHearts = snakeConfigForLevel(_level).hearts;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: AppLocalizations.of(context).levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: AppLocalizations.of(context).helpArrowMaze,
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
                AppLocalizations.of(context).arrowMazeHint,
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
        final cell = math.min(
          constraints.maxWidth / _board.cols,
          constraints.maxHeight / _board.rows,
        );
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
              key: const ValueKey('arrow_maze_board'),
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
  static const _boardColor = Color(0xFFE8EDF2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _boardColor,
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
    final dir = arrow.exitDir;
    var color = _normalColor;
    List<Offset> points;
    Offset headCenter;

    if (arrow.id == escapingId) {
      // Slither out: shift every body point forward along the snake's "rail"
      // (its spine, then a straight extension past the head). The head leads
      // out in the exit direction and each segment follows the path ahead of
      // it — like a snake leaving its burrow, not a rigid block sliding.
      final n = arrow.cells.length;
      final spineLen = (n - 1) * cell;
      // Enough travel for the tail to clear the board (square: rows == cols).
      final totalShift = (n - 1 + board.rows + 1) * cell;
      final shift = Curves.easeInOut.transform(escapeT) * totalShift;

      points = <Offset>[];
      final headArc = spineLen + shift;
      final step = cell / 4; // sample finely so bends round smoothly
      for (var a = shift; a < headArc; a += step) {
        points.add(_railPoint(arrow, a));
      }
      points.add(_railPoint(arrow, headArc));
      headCenter = points.last;
    } else {
      var shake = Offset.zero;
      if (arrow.id == blockedId && shakeT != null) {
        color = _blockedColor;
        final dx = math.sin(shakeT! * math.pi * 6) * (1 - shakeT!) * 6;
        shake = Offset(dx, 0);
      }
      points = [for (final c in arrow.cells) _center(c) + shake];
      headCenter = points.last;
    }

    // Flat-cut tail: push the tail point back so it fills its cell and ends in
    // a straight edge. A blunt tail plus a flared head means "which way does
    // this point?" is answerable from the ends alone, without tracing the body.
    if (points.length >= 2) {
      final back = points[0] - points[1];
      if (back.distance > 0) {
        points[0] += back / back.distance * (cell * 0.2);
      }
    }

    // Carry the body past the head centre along the exit direction. This turns
    // the head corner into an ordinary rounded *join* — identical to every other
    // bend in the snake — rather than a flat end cap, which read as the body
    // "just stopping" next to a sideways arrowhead. It also leaves a short
    // straight run pointing the way before the head starts, so a bent head no
    // longer sits directly on the turn. See _drawHead for the runway budget.
    points.add(headCenter +
        Offset(dir.dCol.toDouble(), dir.dRow.toDouble()) * (cell * 0.24));

    final body = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // Deliberately thin. The head reads by contrast with the body, so
      // slimming the body is what makes it stand out — cheaper than enlarging
      // the head, and it opens up whitespace between neighbouring arrows so a
      // dense board stops merging into one dark mass. It also buys runway: a
      // narrower body lets the head shrink at the same flare, and the length it
      // gives up becomes straight run before the head (see _drawHead).
      ..strokeWidth = cell * 0.26
      // Butt, not round: a round cap bulges out from under the arrowhead and
      // blunts the point when the last segment bends. Bends stay smooth
      // regardless — those are joins, not caps.
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, body);

    _drawHead(canvas, headCenter, dir, color);
  }

  /// Solid arrowhead at the head cell, pointing along the exit direction.
  ///
  /// A modest plain triangle, carried by the thin body it sits on rather than by
  /// its own bulk: 0.52 cell wide against a 0.26 cell body is a 2x flare. Two
  /// earlier attempts overshot — a 1.9x head with swept-back barbs and a
  /// board-coloured halo read as a detached chevron scribbled over the arrow,
  /// and plain-but-large hung off bends like a flag. What the original lacked
  /// was contrast, not size.
  ///
  /// **Runway budget.** The spine runs through cell centres, so on a bent head
  /// the turn happens at the head cell's centre, leaving 0.5 * cell to the board
  /// edge — and nothing may cross into the next cell, which often holds another
  /// arrow (a blocked path is the puzzle). The body's straight run and the head
  /// share that 0.5: run to 0.24, head from 0.20 to 0.48, so 0.20 of visible
  /// straight body points the way before the head starts. Flare is what makes a
  /// head read, not absolute size, so runway is bought by thinning the *body* —
  /// that shrinks the head at a constant 2x and frees the difference. Going
  /// after it by shortening the head alone just leaves it squatter than it is
  /// long, which was the previous iteration's problem.
  void _drawHead(Canvas canvas, Offset headCenter, Dir dir, Color color) {
    final dirOff = Offset(dir.dCol.toDouble(), dir.dRow.toDouble());
    final perpUnit = Offset(-dir.dRow.toDouble(), dir.dCol.toDouble());
    final tip = headCenter + dirOff * (cell * 0.48);
    // Behind the stub's flat end, so the base always overlaps the body rather
    // than meeting it exactly and risking a hairline seam.
    final base = headCenter + dirOff * (cell * 0.20);
    final wing = perpUnit * (cell * 0.26);

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((base + wing).dx, (base + wing).dy)
        ..lineTo((base - wing).dx, (base - wing).dy)
        ..close(),
      Paint()..color = color,
    );
  }

  /// Maps arc-length [arc] (measured from the tail) onto the snake's rail: the
  /// spine through its cell centres, then a straight extension in the exit
  /// direction past the head. Driving every body point along this rail makes
  /// the arrow slither out head-first.
  Offset _railPoint(SnakeArrow arrow, double arc) {
    final n = arrow.cells.length;
    final spineLen = (n - 1) * cell;
    if (arc <= spineLen) {
      final k = (arc / cell).floor().clamp(0, n - 2);
      final t = (arc - k * cell) / cell;
      return Offset.lerp(
          _center(arrow.cells[k]), _center(arrow.cells[k + 1]), t)!;
    }
    final headCenter = _center(arrow.cells[n - 1]);
    final extra = arc - spineLen;
    return headCenter +
        Offset(arrow.exitDir.dCol * extra, arrow.exitDir.dRow * extra);
  }

  @override
  bool shouldRepaint(_SnakePainter oldDelegate) => true;
}
