import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/board_autosave.dart';
import '../../services/progress_store.dart';
import '../../theme/motion.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'freecell_models.dart';

/// Playable FreeCell. Tap a card to pick it up (with the run below it), tap
/// where it should go. Tapping the picked-up card again sends it home, or to a
/// free cell. No dragging anywhere: for this audience a drag is the gesture
/// most likely to go wrong.
///
/// Untimed on purpose — it is a planning game, and a clock on the default path
/// argues against sitting and thinking. Undo is free and unlimited and costs
/// nothing; stars only count hints, and the personal best is the length of the
/// winning line, so undoing a wrong turn is never punished twice.
class FreeCellScreen extends StatefulWidget {
  const FreeCellScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<FreeCellScreen> createState() => _FreeCellScreenState();
}

/// What is picked up: a free cell, or a cascade from [start] to its end.
class _Selection {
  const _Selection.cell(this.index) : kind = PileKind.cell, start = 0;
  const _Selection.cascade(this.index, this.start) : kind = PileKind.cascade;

  final PileKind kind;
  final int index;
  final int start;
}

/// Where a card currently is.
class _Loc {
  const _Loc(this.kind, this.index, this.depth);

  final PileKind kind;
  final int index;
  final int depth;
}

class _FreeCellScreenState extends State<FreeCellScreen>
    with
        WidgetsBindingObserver,
        BoardAutosave<FreeCellScreen>,
        SingleTickerProviderStateMixin {
  static const _gameId = 'freecell';
  static const _accent = Color(0xFF2E7D32);

  /// Solver budget for a hint from the middle of a game.
  static const _hintNodes = 40000;

  late final AnimationController _anim;

  int _level = 1;
  late FreeCellPosition _pos;

  /// Position before each player move, for undo, and the moves themselves,
  /// which are what the autosave stores.
  final List<FreeCellPosition> _history = [];
  final List<FreeCellMove> _moves = [];

  /// A winning line from the current position, while the player follows it.
  /// Starts as the deal's own proof, so a hint on a fresh deal is instant.
  List<FreeCellMove>? _knownLine;

  _Selection? _sel;
  FreeCellMove? _hint;
  int _hintsUsed = 0;
  bool _busy = false;
  bool _stuck = false;
  bool _won = false;

  Size? _boardSize;

  /// Where each moving card started, while a slide is running.
  Map<int, Rect> _from = const {};

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          // The slide says which card went where; it must survive the platform's
          // reduce-animations setting (see CLAUDE.md).
          animationBehavior: AnimationBehavior.preserve,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            scheduleMicrotask(() {
              if (mounted) _afterStep();
            });
          }
        });
    startAutosave();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(
          context,
          gameId: _gameId,
          body: AppLocalizations.of(context).helpFreecell,
          accent: _accent,
        );
      }
    });
  }

  @override
  void dispose() {
    saveBoardNow();
    stopAutosave();
    _anim.dispose();
    super.dispose();
  }

  void _loadLevel(int level, {bool allowResume = true}) {
    ProgressStore.instance.recordReached(_gameId, level);
    final deal = FreeCellDeal.generate(level);
    var pos = deal.start();
    final history = <FreeCellPosition>[];
    final moves = <FreeCellMove>[];
    var hints = 0;
    final saved = allowResume
        ? ProgressStore.instance.loadBoard(_gameId, level)
        : null;
    if (saved != null && saved['v'] == FreeCellDeal.generatorVersion) {
      // Replayed rather than stored as a position, so undo survives a resume
      // too. Any move that no longer replays means the save is not this deal.
      final replay = deal.start();
      final h = <FreeCellPosition>[];
      final m = <FreeCellMove>[];
      var ok = true;
      for (final v in (saved['moves'] as List? ?? const [])) {
        final move = FreeCellMove.decode(v as int);
        if (!replay.canMove(move)) {
          ok = false;
          break;
        }
        h.add(replay.copy());
        replay
          ..apply(move)
          ..autoPlay();
        m.add(move);
      }
      if (ok && !replay.isWon) {
        pos = replay;
        history.addAll(h);
        moves.addAll(m);
        hints = saved['hints'] as int? ?? 0;
      }
    }
    _anim.stop();
    setState(() {
      _level = level;
      _pos = pos;
      _history
        ..clear()
        ..addAll(history);
      _moves
        ..clear()
        ..addAll(moves);
      _knownLine = moves.isEmpty ? List.of(deal.solution) : null;
      _sel = null;
      _hint = null;
      _hintsUsed = hints;
      _busy = false;
      _won = false;
      _from = const {};
      _stuck = !_pos.hasAnyMove;
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
    if (_won || _pos.isWon || _moves.isEmpty) return null;
    return {
      'v': FreeCellDeal.generatorVersion,
      'moves': [for (final m in _moves) m.encode()],
      'hints': _hintsUsed,
    };
  }

  // ---- Where things are ----

  _Loc _locate(int card) {
    for (var c = 0; c < cascadeCount; c++) {
      final i = _pos.cascades[c].indexOf(card);
      if (i >= 0) return _Loc(PileKind.cascade, c, i);
    }
    final cell = _pos.cells.indexOf(card);
    if (cell >= 0) return _Loc(PileKind.cell, cell, 0);
    return _Loc(PileKind.foundation, cardSuit(card), cardRank(card));
  }

  // ---- Input ----

  void _tapCard(int card) {
    final loc = _locate(card);
    switch (loc.kind) {
      case PileKind.cascade:
        _tapCascade(loc.index, loc.depth);
      case PileKind.cell:
        _tapCell(loc.index);
      case PileKind.foundation:
        _tapFoundation();
    }
  }

  /// A tap on cascade [col]: on its card at [depth], or on its empty space.
  void _tapCascade(int col, int? depth) {
    if (_busy) return;
    final sel = _sel;
    if (sel == null) {
      if (depth == null) return;
      final start = math.max(depth, _pos.runStart(col));
      _select(_Selection.cascade(col, start));
      return;
    }
    if (sel.kind == PileKind.cascade && sel.index == col) {
      if (depth != null && depth >= sel.start) {
        _sendAway(sel);
      } else {
        _deselect();
      }
      return;
    }
    _moveSelectionTo(PileKind.cascade, col);
  }

  void _tapCell(int i) {
    if (_busy) return;
    final sel = _sel;
    if (sel == null) {
      if (i < _pos.cells.length && _pos.cells[i] >= 0) {
        _select(_Selection.cell(i));
      }
      return;
    }
    if (sel.kind == PileKind.cell && sel.index == i) {
      _sendAway(sel);
      return;
    }
    if (i >= _pos.cells.length) {
      _deselect(); // a closed cell
      return;
    }
    _moveSelectionTo(PileKind.cell, i);
  }

  void _tapFoundation() {
    if (_busy || _sel == null) return;
    _moveSelectionTo(PileKind.foundation, -1);
  }

  void _select(_Selection s) {
    HapticFeedback.selectionClick();
    setState(() => _sel = s);
  }

  void _deselect() {
    HapticFeedback.lightImpact();
    setState(() => _sel = null);
  }

  /// The move that would carry the selection to [kind]/[to], or null if the
  /// selection cannot go there at all.
  FreeCellMove? _moveFor(_Selection sel, PileKind kind, int to) {
    if (sel.kind == PileKind.cell) {
      final card = _pos.cells[sel.index];
      return FreeCellMove(
        PileKind.cell,
        sel.index,
        kind,
        kind == PileKind.foundation ? cardSuit(card) : to,
      );
    }
    final src = _pos.cascades[sel.index];
    var count = src.length - sel.start;
    if (kind == PileKind.cascade && _pos.cascades[to].isNotEmpty) {
      // Move just the part of the run that fits on the target card.
      final top = _pos.cascades[to].last;
      final k = src.indexWhere((c) => stacksOn(c, top), sel.start);
      if (k < 0) return null;
      count = src.length - k;
    } else if (kind != PileKind.cascade) {
      if (count != 1) return null;
    }
    return FreeCellMove(
      PileKind.cascade,
      sel.index,
      kind,
      kind == PileKind.foundation ? cardSuit(src.last) : to,
      count,
    );
  }

  void _moveSelectionTo(PileKind kind, int to) {
    final sel = _sel!;
    final m = _moveFor(sel, kind, to);
    if (m != null && _pos.canMove(m)) {
      _playerMove(m);
      return;
    }
    if (m != null && m.count > 1 && kind == PileKind.cascade) {
      final cap = _pos.maxRun(toEmptyCascade: _pos.cascades[to].isEmpty);
      if (m.count > cap) {
        _snack(AppLocalizations.of(context).freecellTooMany(cap));
      }
    }
    _deselect();
  }

  /// The second tap on a picked-up card: home if it can go, else a free cell,
  /// else the first column it fits.
  void _sendAway(_Selection sel) {
    final options = <(PileKind, int)>[
      (PileKind.foundation, -1),
      if (sel.kind == PileKind.cascade)
        for (var i = 0; i < _pos.cells.length; i++) (PileKind.cell, i),
      for (var c = 0; c < cascadeCount; c++)
        if (_pos.cascades[c].isNotEmpty) (PileKind.cascade, c),
      for (var c = 0; c < cascadeCount; c++)
        if (_pos.cascades[c].isEmpty) (PileKind.cascade, c),
    ];
    for (final (kind, to) in options) {
      final m = _moveFor(sel, kind, to);
      if (m != null && _pos.canMove(m)) {
        _playerMove(m);
        return;
      }
    }
    _deselect();
  }

  void _playerMove(FreeCellMove m) {
    HapticFeedback.selectionClick();
    _history.add(_pos.copy());
    _moves.add(m);
    final line = _knownLine;
    _knownLine = line != null && line.isNotEmpty && line.first == m
        ? line.sublist(1)
        : null;
    _sel = null;
    _hint = null;
    _busy = true;
    _step(m);
  }

  // ---- Animation ----

  /// Applies one move and slides every card whose place changed.
  void _step(FreeCellMove m) {
    final size = _boardSize;
    final before = size == null ? null : _Geometry(size, _pos).cardRects;
    setState(() => _pos.apply(m));
    if (size == null || before == null) {
      _afterStep();
      return;
    }
    final after = _Geometry(size, _pos).cardRects;
    final from = <int, Rect>{};
    var distance = 0.0;
    after.forEach((card, rect) {
      final old = before[card];
      if (old != null && old != rect) {
        from[card] = old;
        distance = math.max(distance, (old.center - rect.center).distance);
      }
    });
    _from = from;
    _anim.duration = slideDuration(
      distance,
      speedDpPerSecond: 1400,
      atLeast: const Duration(milliseconds: 140),
      atMost: const Duration(milliseconds: 380),
    );
    _anim.forward(from: 0);
  }

  void _afterStep() {
    final next = _pos.nextAutoMove();
    if (next != null) {
      _step(next);
      return;
    }
    setState(() {
      _from = const {};
      _busy = false;
      _stuck = !_pos.isWon && !_pos.hasAnyMove;
    });
    if (_pos.isWon) {
      _won = true;
      _busy = true;
      Future.delayed(const Duration(milliseconds: 300), _showWin);
    }
  }

  // ---- Undo, hint ----

  void _undo() {
    if (_busy || _history.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pos = _history.removeLast();
      _moves.removeLast();
      _knownLine = null;
      _sel = null;
      _hint = null;
      _stuck = false;
    });
  }

  void _onHint() {
    if (_busy) return;
    final t = AppLocalizations.of(context);
    var line = _knownLine;
    if (line == null || line.isEmpty) {
      final r = solveFreeCell(_pos, maxNodes: _hintNodes);
      line = r.solved && r.moves.isNotEmpty ? r.moves : null;
    }
    if (line == null) {
      setState(() => _hint = null);
      _snack(t.freecellHintStuck);
      return;
    }
    if (_hintsUsed == 0) _snack(t.hintCost);
    setState(() {
      _knownLine = line;
      _hint = line!.first;
      _hintsUsed++;
      _sel = null;
    });
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

  /// Three stars without hints, two with one or two, one beyond that. Undo
  /// never costs a star: in FreeCell trying a line and taking it back *is*
  /// the thinking, and the move-count best already rewards a clean line.
  int get _stars => _hintsUsed == 0 ? 3 : (_hintsUsed <= 2 ? 2 : 1);

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ProgressStore.instance.clearBoard(_gameId);
    final stars = _stars;
    final moves = _moves.length;
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordCleared(_gameId, _level, stars);
    final beat = ProgressStore.instance.recordBest(
      _gameId,
      _level,
      moves,
      lowerIsBetter: true,
    );
    final best = ProgressStore.instance.bestResult(_gameId, _level);
    final t = AppLocalizations.of(context);
    showWinDialog(
      context,
      level: _level,
      accent: _accent,
      stars: stars,
      message: t.clearedLevelInMoves(_level, moves),
      newRecord: beat,
      bestText: best == null ? null : t.bestMoves(best),
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
              showHint: true,
              onHint: _onHint,
              onHelp: () =>
                  showHowToPlay(context, body: t.helpFreecell, accent: _accent),
            ),
            Expanded(
              child: Container(
                color: _Colors.felt,
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                child: _buildBoard(),
              ),
            ),
            if (_stuck)
              Container(
                key: const ValueKey('freecell_stuck'),
                width: double.infinity,
                color: const Color(0xFFFFF8E1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  t.freecellNoMoves,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('freecell_undo'),
                    onPressed: _history.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo_rounded),
                    label: Text(t.freecellUndo),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent, width: 1.5),
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.freecellMoves(_moves.length),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _boardSize = size;
        return AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => _buildStack(size),
        );
      },
    );
  }

  Widget _buildStack(Size size) {
    final g = _Geometry(size, _pos);
    final t = Curves.easeInOut.transform(_anim.isAnimating ? _anim.value : 1);
    final children = <Widget>[];

    // Column backgrounds first, so a tap below the cards still means "here".
    for (var c = 0; c < cascadeCount; c++) {
      final area = g.cascadeArea(c);
      children.add(
        Positioned.fromRect(
          rect: area,
          child: GestureDetector(
            key: ValueKey('fc_cascade_$c'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapCascade(c, null),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: g.cardW,
                height: g.cardH,
                child: const _EmptySlot(),
              ),
            ),
          ),
        ),
      );
    }
    for (var i = 0; i < 4; i++) {
      final open = i < _pos.cells.length;
      children.add(
        Positioned.fromRect(
          rect: g.cellRect(i),
          child: GestureDetector(
            key: ValueKey('fc_cell_$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapCell(i),
            child: open ? const _EmptySlot() : const _LockedSlot(),
          ),
        ),
      );
    }
    for (var s = 0; s < 4; s++) {
      children.add(
        Positioned.fromRect(
          rect: g.foundationRect(s),
          child: GestureDetector(
            key: ValueKey('fc_found_$s'),
            behavior: HitTestBehavior.opaque,
            onTap: _tapFoundation,
            child: _EmptySlot(suit: s),
          ),
        ),
      );
    }

    // Cards: resting ones in table order, then the ones in flight on top.
    final selected = _selectedCards();
    final hinted = _hintCards();
    final resting = <int>[], flying = <int>[];
    for (final card in g.order) {
      (_from.containsKey(card) ? flying : resting).add(card);
    }
    for (final card in [...resting, ...flying]) {
      final rest = g.cardRects[card]!;
      final from = _from[card];
      final rect = from == null ? rest : Rect.lerp(from, rest, t)!;
      children.add(
        Positioned.fromRect(
          rect: rect,
          child: GestureDetector(
            key: ValueKey('fc_card_$card'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapCard(card),
            child: CustomPaint(
              painter: _CardPainter(
                card: card,
                selected: selected.contains(card),
                hinted: hinted.contains(card),
              ),
            ),
          ),
        ),
      );
    }

    final hintTarget = _hintTarget(g);
    if (hintTarget != null) {
      children.add(
        Positioned.fromRect(
          rect: hintTarget.inflate(3),
          child: IgnorePointer(
            child: Container(
              key: const ValueKey('freecell_hint_target'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(g.cardW * 0.14),
                border: Border.all(color: _Colors.hint, width: 4),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Set<int> _selectedCards() {
    final sel = _sel;
    if (sel == null) return const {};
    if (sel.kind == PileKind.cell) return {_pos.cells[sel.index]};
    return _pos.cascades[sel.index].sublist(sel.start).toSet();
  }

  Set<int> _hintCards() {
    final m = _hint;
    if (m == null) return const {};
    if (m.fromKind == PileKind.cell) return {_pos.cells[m.from]};
    final c = _pos.cascades[m.from];
    return c.sublist(c.length - m.count).toSet();
  }

  Rect? _hintTarget(_Geometry g) {
    final m = _hint;
    if (m == null) return null;
    switch (m.toKind) {
      case PileKind.foundation:
        return g.foundationRect(m.to);
      case PileKind.cell:
        return g.cellRect(m.to);
      case PileKind.cascade:
        final dest = _pos.cascades[m.to];
        return dest.isEmpty ? g.slotRect(m.to) : g.cardRects[dest.last];
    }
  }
}

/// Card and slot placement for a board of [size]. Pure arithmetic over the
/// position, so the slide animation can measure a move before and after.
class _Geometry {
  _Geometry(this.size, FreeCellPosition pos) {
    slotW = size.width / cascadeCount;
    final gap = math.max(2.0, slotW * 0.05);
    // Narrow enough to leave the cascades at least two cards of height.
    cardW = math.min(slotW - gap, (size.height / 2.6) / 1.4);
    cardH = cardW * 1.4;
    top = cardH + math.max(8.0, cardH * 0.18);

    for (var i = 0; i < pos.cells.length; i++) {
      final c = pos.cells[i];
      if (c >= 0) {
        cardRects[c] = cellRect(i);
        order.add(c);
      }
    }
    // Foundations bottom-up, so only the top card shows.
    for (var s = 0; s < 4; s++) {
      for (var r = 1; r <= pos.foundations[s]; r++) {
        final c = cardOf(s, r);
        cardRects[c] = foundationRect(s);
        order.add(c);
      }
    }
    // Tall enough for the corner label (0.44 of the width, plus padding).
    final roomy = cardH * 0.36;
    for (var col = 0; col < cascadeCount; col++) {
      final cards = pos.cascades[col];
      final n = cards.length;
      final room = size.height - top - cardH;
      final step = n <= 1
          ? roomy
          : math.max(0.0, math.min(roomy, room / (n - 1)));
      final base = slotRect(col);
      for (var k = 0; k < n; k++) {
        cardRects[cards[k]] = base.translate(0, step * k);
        order.add(cards[k]);
      }
    }
  }

  final Size size;
  late final double slotW;
  late final double cardW;
  late final double cardH;
  late final double top;
  final Map<int, Rect> cardRects = {};

  /// Paint order, bottom to top.
  final List<int> order = [];

  /// Foundations shown in alternating colours: spades, hearts, clubs, diamonds.
  static const _foundationSlot = [6, 7, 5, 4]; // by suit: C, D, H, S

  Rect _slot(int column, double y) =>
      Rect.fromLTWH(column * slotW + (slotW - cardW) / 2, y, cardW, cardH);

  Rect cellRect(int i) => _slot(i, 0);
  Rect foundationRect(int suit) => _slot(_foundationSlot[suit], 0);
  Rect slotRect(int col) => _slot(col, top);
  Rect cascadeArea(int col) =>
      Rect.fromLTWH(col * slotW, top, slotW, size.height - top);
}

abstract final class _Colors {
  static const felt = Color(0xFF2E6B3A);
  static const red = Color(0xFFC62828);
  static const black = Color(0xFF1A1A1A);
  static const selected = Color(0xFFFFB300);
  static const hint = Color(0xFF40C4FF);
}

const _suitGlyphs = ['♣', '♦', '♥', '♠'];
const _rankLabels = [
  '', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', //
];

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({this.suit});

  final int? suit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(c.maxWidth * 0.14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: suit == null
            ? null
            : Text(
                _suitGlyphs[suit!],
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: c.maxWidth * 0.55,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }
}

class _LockedSlot extends StatelessWidget {
  const _LockedSlot();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(c.maxWidth * 0.14),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.lock_outline_rounded,
          size: c.maxWidth * 0.5,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  _CardPainter({
    required this.card,
    required this.selected,
    required this.hinted,
  });

  final int card;
  final bool selected;
  final bool hinted;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = selected ? const Color(0xFFFFF4CC) : Colors.white,
    );
    final ring = selected
        ? _Colors.selected
        : hinted
        ? _Colors.hint
        : const Color(0xFF616161);
    canvas.drawRRect(
      rrect.deflate(selected || hinted ? 1.5 : 0.5),
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected || hinted ? 3 : 1,
    );

    final colour = cardRed(card) ? _Colors.red : _Colors.black;
    // Rank and suit in the corner: the only part a covered card shows, so it
    // must fit inside the cascade step (see `roomy` in _Geometry).
    final corner = TextPainter(
      text: TextSpan(
        text: '${_rankLabels[cardRank(card)]}${_suitGlyphs[cardSuit(card)]}',
        style: TextStyle(
          fontSize: w * 0.44,
          height: 1.0,
          fontWeight: FontWeight.w800,
          color: colour,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final pad = w * 0.07;
    final room = w - pad * 2;
    canvas.save();
    canvas.translate(pad, pad * 0.8);
    if (corner.width > room) {
      final s = room / corner.width;
      canvas.scale(s, s);
    }
    corner.paint(canvas, Offset.zero);
    canvas.restore();
    // No big suit in the middle: it only ever showed on a column's last card
    // and repeated the corner (owner, 2 Oct). The room went into a larger
    // corner instead.
  }

  @override
  bool shouldRepaint(_CardPainter old) =>
      old.card != card || old.selected != selected || old.hinted != hinted;
}
