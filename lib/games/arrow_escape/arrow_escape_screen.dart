import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/board_autosave.dart';
import '../../services/board_prefetch.dart';
import '../../services/progress_store.dart';
import '../../theme/motion.dart';
import '../../widgets/game_header.dart';
import '../../widgets/picture_layer.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'arrow_escape_models.dart';

/// What differs between the games played on [ArrowEscapeScreen].
///
/// Arrow Pictures is Arrow Escape with different boards, so it shares the
/// screen rather than copying it.
class ArrowGameSpec {
  const ArrowGameSpec({
    required this.gameId,
    required this.accent,
    required this.help,
    required this.config,
    required this.generate,
    this.prefetch,
    this.warm,
    this.redirect,
    this.pictureColours,
    this.pictureOutline = false,
    this.winMessage,
  });

  final String gameId;
  final Color accent;
  final String Function(AppLocalizations t) help;
  final ArrowLevelConfig Function(int level) config;
  final ArrowBoard Function(int level) generate;

  /// When set, boards are built ahead of time off the UI isolate and a level
  /// loads behind a spinner. When null, [generate] runs inline — fine for
  /// Arrow Escape, whose boards are cheap.
  final BoardPrefetch<ArrowBoard>? prefetch;

  /// Warms the board for a level; defaults to [prefetch]. Overridden when the
  /// next level may not be this screen's kind of board at all.
  final void Function(int level)? warm;

  /// Given the level "Next level" leads to, opens it somewhere else and returns
  /// true — or returns false to load it here.
  final bool Function(BuildContext context, int level)? redirect;

  /// The picture a level's arrows form, one ARGB per cell (null outside).
  /// Revealed in colour once the last arrow has left; see
  /// lib/widgets/picture_layer.dart.
  final List<List<int?>>? Function(int level)? pictureColours;

  /// Whether the picture shows as a faint outline during play.
  final bool pictureOutline;

  /// Replaces the win dialog's "You cleared level N." — Arrow Pictures names
  /// the picture there, since a finished board no longer shows it plainly.
  final String Function(AppLocalizations t, int level)? winMessage;

  static final arrowEscape = ArrowGameSpec(
    gameId: 'arrow_escape',
    accent: const Color(0xFF3F7DAA),
    help: (t) => t.helpArrowEscape,
    config: configForLevel,
    generate: ArrowBoard.generate,
  );
}

/// Playable Arrow Escape board.
///
/// Tap an arrow to send it off the board in the direction it points. The
/// arrow only leaves if its straight path to the edge is clear; otherwise it
/// shakes and costs a heart. Clear the whole board to win.
class ArrowEscapeScreen extends StatefulWidget {
  const ArrowEscapeScreen({super.key, this.startLevel = 1, this.spec});

  final int startLevel;

  /// Defaults to Arrow Escape itself.
  final ArrowGameSpec? spec;

  @override
  State<ArrowEscapeScreen> createState() => _ArrowEscapeScreenState();
}

class _ArrowEscapeScreenState extends State<ArrowEscapeScreen>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        BoardAutosave<ArrowEscapeScreen> {
  /// Fallback only: replaced from the layout once the cell size is known. A
  /// fixed duration meant the *speed* varied with the device, because a piece
  /// slides the full width of the board and that distance scales with the screen.
  static const _fallbackMoveDuration = Duration(milliseconds: 380);
  Duration _moveDuration = _fallbackMoveDuration;
  late final ArrowGameSpec _spec = widget.spec ?? ArrowGameSpec.arrowEscape;
  String get _gameId => _spec.gameId;
  Color get _accent => _spec.accent;

  int _level = 1;
  late ArrowBoard _board;
  late int _hearts;
  int? _blockedId;
  bool _busy = false; // locks taps while a win/lose transition is pending

  /// Only ever true for a prefetched game: its board may still be building.
  bool _loading = false;
  bool _boardReady = false;
  Timer? _settleTimer;

  late final AnimationController _shake;
  late final AnimationController _reveal;

  /// Board zoom, for the boards past the old 9x9 ceiling.
  ///
  /// Zoom is an aid and never a requirement: at scale 1 the whole board is on
  /// screen with every arrow tappable, boundaryMargin is zero so it cannot be
  /// panned away, and loading or restarting a level returns to fit.
  late final TransformationController _zoom;
  Size _viewport = Size.zero;
  static const _maxZoom = 4.0;

  /// Boards wide enough that ~24dp cells are worth zooming into. Below this the
  /// controls would only cost the board vertical space.
  bool get _zoomable => _boardReady && _board.cols > 9;

  void _onShakeTick() {
    // The controller can tick during/after a route pop; only rebuild while
    // this widget is still in the tree.
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    startAutosave();
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
    // Decorative, so it keeps the default behaviour: with reduced animations
    // the picture simply appears, and its end state is what matters.
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _zoom = TransformationController();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: _spec.help(AppLocalizations.of(context)),
            accent: _accent);
      }
    });
  }

  @override
  void dispose() {
    saveBoardNow();
    stopAutosave();
    _settleTimer?.cancel();
    _shake.dispose();
    _reveal.dispose();
    _zoom.dispose();
    super.dispose();
  }

  /// Loads [level], resuming a saved position for it when one exists.
  ///
  /// Hearts travel with the save: coming back with a full board but no lives
  /// left, or a cleared board with lives restored, would both feel like a bug.
  void _loadLevel(int level, {bool allowResume = true}) {
    ProgressStore.instance.recordReached(_gameId, level);
    final prefetch = _spec.prefetch;
    if (prefetch == null) {
      _showBoard(level, _spec.generate(level), allowResume: allowResume);
    } else {
      _loadPrefetched(prefetch, level, allowResume: allowResume);
    }
  }

  /// The prefetched path, modelled on Arrow Maze's: spinner while the board is
  /// not ready, then a short tap guard, then warm the next level.
  Future<void> _loadPrefetched(BoardPrefetch<ArrowBoard> prefetch, int level,
      {required bool allowResume}) async {
    _settleTimer?.cancel();
    final load = ++_loadSerial;
    setState(() {
      _loading = true;
      _busy = true;
      _level = level;
      _hearts = _spec.config(level).hearts;
      _blockedId = null;
    });
    final (board: board, wasWarm: _) = await prefetch.obtain(level);
    // A newer load (restart, next level) may have started while this awaited.
    if (!mounted || load != _loadSerial) return;
    _showBoard(level, board, allowResume: allowResume);
    // Held briefly even on a warm board: the win dialog's exit transition keeps
    // the old board visible for ~340ms, so a second press on "Next level" would
    // otherwise land on this board. See the note in Arrow Maze's _loadLevel.
    _busy = true;
    _settleTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _busy = false);
      // On the tail of the guard so the isolate spawn never competes with the
      // board's first frame.
      prefetch.remember(level, board);
      (_spec.warm ?? prefetch.warm)(level + 1);
    });
  }

  /// Bumped per prefetched load, so a superseded one can tell it is stale.
  int _loadSerial = 0;

  void _showBoard(int level, ArrowBoard board, {required bool allowResume}) {
    var hearts = _spec.config(level).hearts;
    final saved =
        allowResume ? ProgressStore.instance.loadBoard(_gameId, level) : null;
    if (saved != null && board.applyEscapedJson(saved)) {
      final h = saved['hearts'];
      if (h is int && h > 0 && h <= hearts) hearts = h;
    }
    setState(() {
      _level = level;
      _board = board;
      _hearts = hearts;
      _blockedId = null;
      _busy = false;
      _loading = false;
      _boardReady = true;
      _reveal.value = 0;
      _zoom.value = Matrix4.identity(); // a new board always starts fitted
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
    if (!_boardReady || _loading) return null; // still being built
    if (_board.isSolved) return null; // finished
    if (_hearts <= 0) return null; // lost; the level restarts anyway
    if (!_board.hasProgress) return null; // untouched
    return {..._board.escapedJson(), 'hearts': _hearts};
  }

  void _onTapPiece(ArrowPiece p) {
    if (_busy || _loading || p.escaped) return;

    if (_board.isPathClear(p)) {
      HapticFeedback.lightImpact();
      setState(() => p.escaped = true);
      if (_board.isSolved) {
        _busy = true;
        Future.delayed(_moveDuration + const Duration(milliseconds: 80), () {
          if (mounted) _revealThenWin();
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

  /// On a picture level, fades the finished picture in and lets it sit for a
  /// moment before the dialog covers it: the picture is the reward. Anywhere
  /// else, straight to the dialog.
  void _revealThenWin() {
    if (!mounted) return;
    if (_spec.pictureColours == null) {
      _showWin();
      return;
    }
    // Back to fit first: a reveal seen zoomed in shows only part of the picture.
    _resetZoom();
    _reveal.forward(from: 0).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _showWin();
      });
    });
  }

  void _showWin() {
    if (!mounted) return;
    ProgressStore.instance.clearBoard(_gameId);
    HapticFeedback.heavyImpact();
    final lost = _spec.config(_level).hearts - _hearts;
    final stars = lost == 0 ? 3 : (lost <= 2 ? 2 : 1);
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordCleared(_gameId, _level, stars);
    showWinDialog(context,
            level: _level,
            accent: _accent,
            stars: stars,
            message:
                _spec.winMessage?.call(AppLocalizations.of(context), _level))
        .then((action) {
      if (!mounted || action == null) return;
      if (action == WinAction.next) {
        if (_spec.redirect?.call(context, _level + 1) ?? false) return;
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
    final maxHearts = _spec.config(_level).hearts;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: AppLocalizations.of(context).levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: _spec.help(AppLocalizations.of(context)),
                    accent: _accent)),
            _buildHearts(maxHearts),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: _loading || !_boardReady
                      ? Column(
                          key: ValueKey('${_gameId}_loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: _accent),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).buildingBoard,
                              style: const TextStyle(
                                  fontSize: 17, color: Colors.black54),
                            ),
                          ],
                        )
                      : _buildBoard(),
                ),
              ),
            ),
            if (_zoomable) _buildZoomBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                _zoomable
                    ? AppLocalizations.of(context).arrowEscapeHintZoom
                    : AppLocalizations.of(context).arrowEscapeHint,
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

  /// Scales about the centre of the viewport so whatever the player is looking
  /// at stays put. Buttons exist because pinching is genuinely awkward for this
  /// audience — pinch still works, it is just not the only way in.
  void _setZoom(double target) {
    if (_viewport.isEmpty) return;
    final s = target.clamp(1.0, _maxZoom);
    final centre = Offset(_viewport.width / 2, _viewport.height / 2);
    final inverse = Matrix4.tryInvert(_zoom.value);
    if (inverse == null) return;
    final p = MatrixUtils.transformPoint(inverse, centre);
    setState(() {
      _zoom.value = Matrix4.identity()
        ..translateByDouble(centre.dx - s * p.dx, centre.dy - s * p.dy, 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    });
  }

  void _resetZoom() => setState(() => _zoom.value = Matrix4.identity());

  /// Zoom controls, shown only on boards wide enough to need them.
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
        button('${_gameId}_zoom_out', Icons.zoom_out_rounded, t.zoomOut,
            _scale > 1.0 ? () => _setZoom(_scale / 1.5) : null),
        button('${_gameId}_zoom_fit', Icons.fit_screen_rounded, t.zoomFit,
            _scale > 1.0 ? _resetZoom : null),
        button('${_gameId}_zoom_in', Icons.zoom_in_rounded, t.zoomIn,
            _scale < _maxZoom ? () => _setZoom(_scale * 1.5) : null),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fits either dimension, since picture boards need not be square.
        final cell = math.min(constraints.maxWidth / _board.cols,
            constraints.maxHeight / _board.rows);
        // A piece leaves by sliding clear of the board, so time that distance at
        // the shared speed rather than fixing the duration. Same value feeds the
        // AnimatedPositioned and the post-move delay, so they cannot drift.
        _moveDuration = slideDuration(
            (math.max(_board.rows, _board.cols) + 2) * cell);
        final width = cell * _board.cols;
        final height = cell * _board.rows;

        // The viewport is the whole board area, not just the board: a short,
        // wide picture zoomed inside its own box only ever grew within a strip.
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);

        // The InteractiveViewer sits *outside* the board content, as in Arrow
        // Maze. Here the arrows are real widgets rather than a painted canvas,
        // so each one receives its own local taps and there is no cell
        // arithmetic that could mis-target once zoomed.
        final board = ClipRRect(
          // Named so tests can aim taps at a cell centre, as in Arrow Maze.
          key: ValueKey('${_gameId}_board'),
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
                if (_spec.pictureColours?.call(_level) case final colours?)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PictureLayerPainter(
                        colours: colours,
                        cell: cell,
                        outline: _spec.pictureOutline,
                        reveal: _reveal.value,
                      ),
                    ),
                  ),
                for (final p in _board.pieces) _buildPiece(p, cell),
              ],
            ),
          ),
        );

        if (!_zoomable) return board;
        return InteractiveViewer(
          key: ValueKey('${_gameId}_viewer'),
          transformationController: _zoom,
          minScale: 1.0,
          maxScale: _maxZoom,
          // Keeps the board inside the viewport, so it can never be panned off
          // screen and lost.
          boundaryMargin: EdgeInsets.zero,
          child: SizedBox.fromSize(
            size: _viewport,
            child: Center(child: board),
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
