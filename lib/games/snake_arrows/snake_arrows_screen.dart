import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/board_autosave.dart';
import '../../services/board_prefetch.dart';
import '../../services/progress_store.dart';
import '../../theme/motion.dart';
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
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        BoardAutosave<SnakeArrowsScreen> {
  static const _escapeDuration = Duration(milliseconds: 520);
  static const _gameId = 'arrow_maze';
  static const _accent = Color(0xFF2E8B8B);

  int _level = 1;
  late SnakeBoard _board;
  late int _hearts;
  int? _escapingId;
  int? _blockedId;

  /// Cell size from the last layout, in logical pixels. The escape animation is
  /// timed from how far the arrow actually travels, and only the layout knows
  /// that — a fixed duration made the *speed* vary with screen size.
  double _cell = 0;
  bool _busy = false; // locks taps while an arrow is leaving / dialog pending

  late final AnimationController _escapeCtrl;
  late final AnimationController _shakeCtrl;

  /// Zoom/pan for the board.
  ///
  /// Boards past ~14 columns cannot be read at a phone's width — 26 columns is
  /// about 13dp per cell against a ~23dp floor — so the big late boards need this
  /// to exist at all. It is deliberately an *aid*, never a requirement: the whole
  /// board is always visible at the default scale of 1, and every arrow is
  /// tappable there. See docs/plans/arrow-maze-depth.md.
  late final TransformationController _zoom;

  /// The viewport the board is laid out into, remembered so the zoom buttons can
  /// scale about its centre.
  Size _viewport = Size.zero;

  static const _maxZoom = 4.0;

  /// Arrows freed by a bonus arrow that are still waiting to fly off.
  ///
  /// They leave one at a time, reusing the ordinary escape animation, so a bonus
  /// reads as a chain reaction rather than arrows blinking out of existence. The
  /// board stays locked (`_busy`) until the queue drains.
  final List<int> _cascade = [];

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    startAutosave();
    // Created here rather than lazily, same rule as the animation controllers:
    // a lazy field can end up constructed during dispose().
    _zoom = TransformationController();
    // Create eagerly in initState so dispose() never lazily constructs a
    // controller (which would do a TickerMode ancestor lookup) during teardown.
    // animationBehavior: preserve — see the note in lib/theme/motion.dart. When
    // the platform asks for reduced animations, Flutter runs a `normal`
    // controller at 5% duration, i.e. a single frame: the escape became 26ms and
    // testers reported it as missing. These two animations carry meaning rather
    // than decorate — one shows which arrow left and where it went, the other is
    // how a lost heart is communicated — so they opt out, exactly as Flutter's
    // own scroll physics controller does.
    _escapeCtrl = AnimationController(
      vsync: this,
      duration: _escapeDuration,
      animationBehavior: AnimationBehavior.preserve,
    )
      ..addListener(_tick)
      ..addStatusListener(_onEscapeStatus);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      animationBehavior: AnimationBehavior.preserve,
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
    saveBoardNow();
    stopAutosave();
    _zoom.dispose();
    _escapeCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  /// Loads [level], resuming a saved position for it when one exists. Hearts
  /// travel with the save — returning to a part-cleared board with full lives
  /// would feel like a bug.
  void _loadLevel(int level, {bool allowResume = true}) {
    ProgressStore.instance.recordReached(_gameId, level);
    // Built in the background while the win dialog was up, if we got that far.
    // Identical to generating here — generation is deterministic in the level — so
    // this only changes *when* the work happened, never what the player sees.
    final board = BoardPrefetch.take(level) ?? SnakeBoard.generate(level);
    var hearts = snakeConfigForLevel(level).hearts;
    final saved =
        allowResume ? ProgressStore.instance.loadBoard(_gameId, level) : null;
    if (saved != null && board.applyEscapedJson(saved)) {
      final h = saved['hearts'];
      if (h is int && h > 0 && h <= hearts) hearts = h;
    }
    // A new board always starts fit to the screen; carrying a previous level's
    // pan over would drop the player into a corner of an unfamiliar board.
    _zoom.value = Matrix4.identity();
    _cascade.clear();
    setState(() {
      _level = level;
      _board = board;
      _hearts = hearts;
      _escapingId = null;
      _blockedId = null;
      _busy = false;
    });
  }

  void _restart() {
    ProgressStore.instance.clearBoard(_gameId);
    _loadLevel(_level, allowResume: false);
  }

  // ---- BoardAutosave ----

  @override
  String get autosaveGameId => _gameId;

  @override
  int get autosaveLevel => _level;

  @override
  Map<String, dynamic>? captureBoard() {
    if (_board.isSolved) return null; // finished
    if (_hearts <= 0) return null; // lost; the level restarts anyway
    if (!_board.hasProgress) return null; // untouched
    return {..._board.escapedJson(), 'hearts': _hearts};
  }

  void _onEscapeStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status != AnimationStatus.completed || _escapingId == null) return;
    final arrow = _board.arrows.firstWhere((a) => a.id == _escapingId);
    // A bonus arrow takes its linked arrows with it, and they now *fly out* one
    // after another using this same animation rather than blinking out of
    // existence. Queue them and let each completion start the next.
    final freed = _board.bonusFreedBy(arrow);
    setState(() {
      arrow.escaped = true;
      _escapingId = null;
    });
    if (freed.isNotEmpty) {
      _cascade.addAll([for (final a in freed) a.id]);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context).bonusArrowFreed(freed.length),
              style: const TextStyle(fontSize: 18)),
          duration: const Duration(seconds: 2),
        ));
    }
    if (_cascade.isNotEmpty) {
      // Stay locked: the board is mid-chain and a tap now would race it.
      //
      // Deferred out of this status listener rather than called directly. We are
      // inside the controller's own status notification, and restarting it from
      // there only delivered the first link of the chain — the second and third
      // arrows never fired. A microtask puts the restart after the notification
      // has finished unwinding.
      Future.microtask(() {
        if (mounted && _cascade.isNotEmpty) _startNextCascade();
      });
      return;
    }
    setState(() => _busy = false);
    if (_board.isSolved) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _showWin();
      });
    }
  }

  /// How long [arrow] should take to slide out, from how far it actually travels,
  /// so the speed is identical on every screen. The painter moves it this same
  /// distance (see `_drawArrow`'s totalShift), so the two must stay in step.
  Duration _slideFor(SnakeArrow arrow) =>
      slideDuration((arrow.cells.length - 1 + _board.rows + 1) * _cell);

  /// Sends the next freed arrow on its way.
  ///
  /// Prefers one whose path is *now* clear — the bonus arrow leaving often opens a
  /// lane — so as many as possible look like an ordinary escape rather than
  /// sliding through their neighbours.
  void _startNextCascade() {
    final pending = [
      for (final id in _cascade)
        _board.arrows.firstWhere((a) => a.id == id)
    ]..sort((a, b) {
        final ac = _board.isPathClear(a) ? 0 : 1;
        final bc = _board.isPathClear(b) ? 0 : 1;
        return ac.compareTo(bc);
      });
    final next = pending.first;
    _cascade.remove(next.id);
    _escapeCtrl.duration = _slideFor(next);
    setState(() => _escapingId = next.id);
    _escapeCtrl.forward(from: 0);
  }

  void _handleTapCell(int row, int col) {
    if (_busy) return;
    final arrow = _board.arrowAt(row, col);
    if (arrow == null || arrow.escaped) return;

    if (_board.isPathClear(arrow)) {
      HapticFeedback.lightImpact();
      // Time the slide from how far it travels, so the speed is the same on every
      // screen. The painter moves the arrow this same distance (see _drawArrow's
      // totalShift), so the two must stay in step.
      _escapeCtrl.duration = _slideFor(arrow);
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
    ProgressStore.instance.clearBoard(_gameId);
    // Start the next board now, in the background. The dialog takes ~1.1s to play
    // out before the player can even choose, which is enough to hide a generation
    // that would otherwise be felt as a pause after tapping "Next level".
    BoardPrefetch.warm(_level + 1);
    HapticFeedback.heavyImpact();
    final lost = snakeConfigForLevel(_level).hearts - _hearts;
    final stars = lost == 0 ? 3 : (lost <= 2 ? 2 : 1);
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordCleared(_gameId, _level, stars);
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
            if (_board.cols > 14) _buildZoomBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                _board.cols > 14
                    ? AppLocalizations.of(context).arrowMazeHintZoom
                    : AppLocalizations.of(context).arrowMazeHint,
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

  /// Current zoom factor; 1 means the whole board is on screen.
  double get _scale => _zoom.value.getMaxScaleOnAxis();

  /// Scales about the centre of the viewport, so whatever the player is looking
  /// at stays put. Buttons exist because pinching is genuinely awkward for this
  /// audience — pinch still works, it is just not the only way in.
  void _setZoom(double target) {
    if (_viewport.isEmpty) return;
    final s = target.clamp(1.0, _maxZoom);
    final centre = Offset(_viewport.width / 2, _viewport.height / 2);
    final inverse = Matrix4.tryInvert(_zoom.value);
    if (inverse == null) return;
    // The board point currently under the viewport centre; it must land there
    // again at the new scale, which fixes the translation: t = centre - s*p.
    final p = MatrixUtils.transformPoint(inverse, centre);
    setState(() {
      _zoom.value = Matrix4.identity()
        ..translateByDouble(centre.dx - s * p.dx, centre.dy - s * p.dy, 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    });
  }

  void _resetZoom() => setState(() => _zoom.value = Matrix4.identity());

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          constraints.maxWidth / _board.cols,
          constraints.maxHeight / _board.rows,
        );
        // Remembered for the tap handler, which needs the travel distance to time
        // the escape at a constant speed. Only the layout knows the cell size.
        _cell = cell;
        final boardSize = Size(cell * _board.cols, cell * _board.rows);
        _viewport = boardSize;

        // The InteractiveViewer sits *outside* the GestureDetector on purpose.
        // Hit testing passes through the transform, so the detector below always
        // receives coordinates in board space and the cell maths needs no
        // knowledge of the zoom at all. Putting the detector outside instead
        // would hand it screen coordinates and silently mis-target every tap
        // once zoomed.
        return InteractiveViewer(
          key: const ValueKey('arrow_maze_viewer'),
          transformationController: _zoom,
          minScale: 1.0,
          maxScale: _maxZoom,
          // Keeps the board inside the viewport, so it can never be panned off
          // screen and lost.
          boundaryMargin: EdgeInsets.zero,
          child: GestureDetector(
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
          ),
        );
      },
    );
  }

  /// Zoom controls, shown only on boards too wide to read unaided.
  ///
  /// Hidden on the narrow early boards because they do not need it and the row
  /// would cost vertical space the board can use instead — the existing levels
  /// look exactly as they did.
  Widget _buildZoomBar() {
    final t = AppLocalizations.of(context);
    Widget button(String key, IconData icon, String tooltip, VoidCallback? tap) {
      return IconButton(
        key: ValueKey(key),
        onPressed: tap,
        icon: Icon(icon),
        iconSize: 28,
        color: _accent,
        tooltip: tooltip,
        // The platform minimum, and this audience needs it.
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button('arrow_maze_zoom_out', Icons.zoom_out_rounded, t.zoomOut,
            _scale > 1.0 ? () => _setZoom(_scale / 1.5) : null),
        button('arrow_maze_zoom_fit', Icons.fit_screen_rounded, t.zoomFit,
            _scale > 1.0 ? _resetZoom : null),
        button('arrow_maze_zoom_in', Icons.zoom_in_rounded, t.zoomIn,
            _scale < _maxZoom ? () => _setZoom(_scale * 1.5) : null),
      ],
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
  /// Bonus arrow: clearing it sweeps its linked arrows off the board too. The
  /// *only* extra colour on the board — see [_drawLinkMark].
  static const _bonusColor = Color(0xFFB8860B);
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
    // Only the bonus arrow is marked, and only by its colour. The arrows it frees
    // carry nothing at all.
    //
    // Two rejected versions got here: a second lighter gold for the linked arrows
    // (four or five gold arrows on a board of ~22 — "a bit too much, there appears
    // to be multiple colours"), then a gold dot on their heads (too big at ~23dp
    // per cell). The owner's call is that the link needs no cue.
    //
    // The cost is deliberate and worth knowing: the cascade is now a surprise
    // rather than something to plan around, so the mechanic no longer rewards
    // choosing an order the way it was originally justified. What survives is the
    // weaker but real heuristic that the golden arrow is worth freeing early.
    var color = arrow.isBonus ? _bonusColor : _normalColor;
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
