import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/board_autosave.dart';
import '../../services/level_timer.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/level_clock.dart';
import '../../widgets/win_dialog.dart';
import 'bridges_models.dart';

/// Playable Bridges. Two ways to build, both always on: tap an island and then
/// a neighbour, or tap the water between two islands. Tapping a bridge cycles
/// one → two → none.
///
/// Like Picture Logic there is no lose state: a wrong bridge is fixed by
/// tapping it, and the Check button (which costs a star) points at wrong ones.
///
/// **Deliberately unanimated.** Every state is visible in its end state.
class BridgesScreen extends StatefulWidget {
  const BridgesScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<BridgesScreen> createState() => _BridgesScreenState();
}

class _BridgesScreenState extends State<BridgesScreen>
    with WidgetsBindingObserver, BoardAutosave<BridgesScreen> {
  static const _gameId = 'bridges';
  static const _accent = Color(0xFF0277BD);

  final LevelTimer _timer = LevelTimer();

  int _level = 1;
  late BridgesBoard _board;
  int? _selected;

  /// Distinct edges that at some point held more bridges than the solution.
  /// Kept for stars only.
  final Set<int> _mistakes = {};
  int _checksUsed = 0;
  bool _showingCheck = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    startAutosave();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(
          context,
          gameId: _gameId,
          body: AppLocalizations.of(context).helpBridges,
          accent: _accent,
        );
      }
    });
  }

  /// The board is regenerated from the level number; a save only carries the
  /// bridges, and is ignored if it came from a different generator.
  void _loadLevel(int level, {bool allowResume = true}) {
    ProgressStore.instance.recordReached(_gameId, level);
    final board = BridgesBoard.generate(level);
    final saved = allowResume
        ? ProgressStore.instance.loadBoard(_gameId, level)
        : null;
    final usable = saved != null && saved['v'] == BridgesBoard.generatorVersion;
    if (usable) board.applyCountsJson(saved);
    final carried = usable ? (saved['seconds'] as int? ?? 0) : 0;
    setState(() {
      _level = level;
      _board = board;
      _selected = null;
      _mistakes.clear();
      _checksUsed = 0;
      _showingCheck = false;
      _busy = false;
      _timer.start(from: Duration(seconds: carried));
    });
  }

  void _restart() {
    ProgressStore.instance.clearBoard(_gameId);
    _loadLevel(_level, allowResume: false);
  }

  @override
  void dispose() {
    saveBoardNow();
    stopAutosave();
    super.dispose();
  }

  // ---- BoardAutosave ----

  @override
  String get autosaveGameId => _gameId;

  @override
  int get autosaveLevel => _level;

  @override
  Map<String, dynamic>? captureBoard() {
    if (_board.isSolved || !_board.hasProgress) return null;
    return {
      ..._board.countsJson(),
      'v': BridgesBoard.generatorVersion,
      'seconds': _timer.elapsed.inSeconds,
    };
  }

  @override
  void onLifecycleChange(AppLifecycleState state) =>
      _timer.handleLifecycle(state);

  // ---- Input ----

  void _onTap(Offset p, double cell) {
    if (_busy) return;
    final island = _islandAt(p, cell);
    if (island != null) {
      _onIslandTap(island);
      return;
    }
    final edge = _edgeAt(p, cell);
    if (edge != null) {
      _cycle(edge);
    } else if (_selected != null) {
      setState(() => _selected = null);
    }
  }

  void _onIslandTap(int i) {
    final from = _selected;
    if (from == null || from == i) {
      setState(() => _selected = from == i ? null : i);
      HapticFeedback.selectionClick();
      return;
    }
    final e = _board.edgeBetween(from, i);
    if (e < 0) {
      // Not a neighbour: start again from the island just tapped.
      setState(() => _selected = i);
      HapticFeedback.selectionClick();
      return;
    }
    _cycle(e);
  }

  void _cycle(int e) {
    final t = AppLocalizations.of(context);
    if (!_board.cycle(e)) {
      HapticFeedback.mediumImpact();
      setState(() => _selected = null);
      _snack(t.bridgesNoCrossing);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _selected = null;
      _showingCheck = false;
      if (_board.isWrong(e)) _mistakes.add(e);
    });
    if (_board.isSolved) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 250), _showWin);
    } else if (_board.allFull) {
      _snack(t.bridgesNotJoined);
    }
  }

  /// Island whose centre is within reach of [p]. Generous on purpose: islands
  /// are never adjacent, so the whole cell is unambiguous.
  int? _islandAt(Offset p, double cell) {
    for (var i = 0; i < _board.islands.length; i++) {
      final s = _board.islands[i];
      final centre = Offset((s.col + 0.5) * cell, (s.row + 0.5) * cell);
      if ((p - centre).distance <= cell * 0.6) return i;
    }
    return null;
  }

  /// The edge nearest to [p] whose span [p] falls within, if it is close
  /// enough. Where a horizontal and a vertical edge cross, the one carrying
  /// bridges wins, since only it can be changed.
  int? _edgeAt(Offset p, double cell) {
    int? best;
    var bestDist = cell * 0.55;
    for (var e = 0; e < _board.edges.length; e++) {
      final edge = _board.edges[e];
      final a = _board.islands[edge.a], b = _board.islands[edge.b];
      final double along, across, start, end;
      if (edge.horizontal) {
        along = p.dx;
        across = (p.dy - (a.row + 0.5) * cell).abs();
        start = (a.col + 1) * cell;
        end = b.col * cell;
      } else {
        along = p.dy;
        across = (p.dx - (a.col + 0.5) * cell).abs();
        start = (a.row + 1) * cell;
        end = b.row * cell;
      }
      if (along < start || along > end) continue;
      final built = _board.counts[e] > 0;
      final d = built ? across - cell * 0.2 : across;
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text, style: const TextStyle(fontSize: 18)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _onCheck() {
    if (_busy) return;
    final wrong = _board.wrongEdges;
    setState(() {
      _checksUsed++;
      _showingCheck = wrong > 0;
      _selected = null;
    });
    final t = AppLocalizations.of(context);
    _snack(wrong == 0 ? t.bridgesCheckClean : t.bridgesCheckFound(wrong));
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ProgressStore.instance.clearBoard(_gameId);
    final stars = _mistakes.isEmpty && _checksUsed == 0
        ? 3
        : (_mistakes.length <= 3 && _checksUsed <= 1 ? 2 : 1);
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordCleared(_gameId, _level, stars);
    // Local-only personal best; nothing here is ever sent anywhere.
    final beat = ProgressStore.instance.recordBest(
      _gameId,
      _level,
      _mistakes.length,
      lowerIsBetter: true,
    );
    final best = ProgressStore.instance.bestResult(_gameId, _level);
    _timer.stop();
    final seconds = _timer.elapsed.inSeconds;
    final beatTime = ProgressStore.instance.recordBestTime(
      _gameId,
      _level,
      seconds,
    );
    final bestTime = ProgressStore.instance.bestSeconds(_gameId, _level);
    final t = AppLocalizations.of(context);
    final timeLine = bestTime == null
        ? t.timeTaken(formatLevelTime(Duration(seconds: seconds)))
        : t.timeAndBest(
            formatLevelTime(Duration(seconds: seconds)),
            formatLevelTime(Duration(seconds: bestTime)),
          );
    showWinDialog(
      context,
      level: _level,
      accent: _accent,
      stars: stars,
      newRecord: beat || beatTime,
      bestText: [if (best != null) t.bestMistakes(best), timeLine].join('\n'),
    ).then((action) {
      if (!mounted || action == null) return;
      if (action == WinAction.next) {
        _loadLevel(_level + 1);
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  // ---- Layout ----

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
                  showHowToPlay(context, body: t.helpBridges, accent: _accent),
            ),
            LevelClock(timer: _timer, accent: _accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: _buildBoard()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: _onCheck,
                icon: const Icon(Icons.spellcheck_rounded),
                label: Text(t.bridgesCheck),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: const BorderSide(color: _accent, width: 1.5),
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
              child: Text(
                t.bridgesHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          constraints.maxWidth / _board.cols,
          constraints.maxHeight / _board.rows,
        );
        final size = Size(cell * _board.cols, cell * _board.rows);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _onTap(d.localPosition, cell),
          child: CustomPaint(
            key: const ValueKey('bridges_board'),
            size: size,
            painter: _BridgesPainter(
              board: _board,
              cell: cell,
              selected: _selected,
              showWrong: _showingCheck,
              accent: _accent,
            ),
          ),
        );
      },
    );
  }
}

class _BridgesPainter extends CustomPainter {
  _BridgesPainter({
    required this.board,
    required this.cell,
    required this.selected,
    required this.showWrong,
    required this.accent,
  }) : counts = List.of(board.counts);

  final BridgesBoard board;
  final double cell;
  final int? selected;
  final bool showWrong;
  final Color accent;

  /// Snapshot, so [shouldRepaint] can see a change on the shared board.
  final List<int> counts;

  static const _water = Color(0xFFE3F2FD);
  static const _bridge = Color(0xFF37474F);
  static const _wrong = Color(0xFFC62828);

  Offset _centre(Island s) =>
      Offset((s.col + 0.5) * cell, (s.row + 0.5) * cell);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      Paint()..color = _water,
    );

    final radius = cell * 0.42;

    // While an island is selected, show where it can reach, so the second
    // tap is not a guess.
    final sel = selected;
    if (sel != null) {
      final hint = Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..strokeWidth = math.max(2, cell * 0.1)
        ..strokeCap = StrokeCap.round;
      for (var e = 0; e < board.edges.length; e++) {
        final edge = board.edges[e];
        if (edge.a != sel && edge.b != sel) continue;
        if (counts[e] == 0 && board.blockerOf(e) != null) continue;
        canvas.drawLine(
          _centre(board.islands[edge.a]),
          _centre(board.islands[edge.b]),
          hint,
        );
      }
    }

    final stroke = math.max(2.5, cell * 0.09);
    for (var e = 0; e < board.edges.length; e++) {
      final n = counts[e];
      if (n == 0) continue;
      final edge = board.edges[e];
      final paint = Paint()
        ..color = showWrong && board.isWrong(e) ? _wrong : _bridge
        ..strokeWidth = stroke;
      final a = _centre(board.islands[edge.a]);
      final b = _centre(board.islands[edge.b]);
      final normal = edge.horizontal ? const Offset(0, 1) : const Offset(1, 0);
      final offsets = n == 1 ? [0.0] : [-cell * 0.13, cell * 0.13];
      for (final o in offsets) {
        canvas.drawLine(a + normal * o, b + normal * o, paint);
      }
    }

    for (var i = 0; i < board.islands.length; i++) {
      final s = board.islands[i];
      final c = _centre(s);
      final over = board.isOver(i);
      final full = board.isFull(i);
      final fill = over
          ? const Color(0xFFFFCDD2)
          : full
          ? accent
          : Colors.white;
      final border = over ? _wrong : (full ? accent : const Color(0xFF263238));
      canvas.drawCircle(c, radius, Paint()..color = fill);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, cell * 0.06),
      );
      if (i == selected) {
        canvas.drawCircle(
          c,
          radius + cell * 0.08,
          Paint()
            ..color = const Color(0xFFFFA000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(3, cell * 0.1),
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: '${s.need}',
          style: TextStyle(
            fontSize: cell * 0.5,
            fontWeight: FontWeight.w800,
            color: over
                ? _wrong
                : full
                ? Colors.white
                : const Color(0xFF263238),
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_BridgesPainter old) =>
      old.board != board ||
      old.cell != cell ||
      old.selected != selected ||
      old.showWrong != showWrong ||
      !_same(old.counts, counts);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
