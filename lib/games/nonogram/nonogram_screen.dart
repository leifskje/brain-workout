import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'nonogram_models.dart';

/// Playable Picture Logic. Tap a cell to cycle fill -> cross -> blank; no mode
/// toggle and no long-press, so there is no hidden gesture to discover.
///
/// There is no lose state and no penalty for a wrong fill: self-correcting *is*
/// the puzzle. The optional Check button is the concession to the audience —
/// it points at wrong cells, and using it costs a star.
///
/// **Deliberately unanimated.** A cell's state is fully visible in its end
/// state, so nothing here carries information through motion. That makes it the
/// decorative case the platform's "reduce animations" setting exists for — do
/// not reach for `AnimationBehavior.preserve` here (see the motion notes in
/// CLAUDE.md; the rule is easy to over-apply).
class NonogramScreen extends StatefulWidget {
  const NonogramScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<NonogramScreen> createState() => _NonogramScreenState();
}

class _NonogramScreenState extends State<NonogramScreen> {
  static const _gameId = 'nonogram';
  static const _accent = Color(0xFF00796B);

  int _level = 1;
  late NonogramBoard _board;

  /// Distinct cells the player has filled in wrongly at some point. Kept for
  /// stars only — nothing about play depends on it.
  final Set<(int, int)> _mistakes = {};
  int _checksUsed = 0;
  bool _showingCheck = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpNonogram,
            accent: _accent);
      }
    });
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = NonogramBoard.generate(level);
      _mistakes.clear();
      _checksUsed = 0;
      _showingCheck = false;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onCellTap(int r, int c) {
    if (_busy) return;
    setState(() {
      _showingCheck = false;
      _board.cycle(r, c);
      if (_board.isWrongFill(r, c)) _mistakes.add((r, c));
    });
    HapticFeedback.selectionClick();
    if (_board.isSolved) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 200), _showWin);
    }
  }

  void _onCheck() {
    if (_busy) return;
    final wrong = _board.wrongFills;
    setState(() {
      _checksUsed++;
      _showingCheck = wrong > 0;
    });
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
            wrong == 0 ? t.nonogramCheckClean : t.nonogramCheckFound(wrong),
            style: const TextStyle(fontSize: 18)),
        duration: const Duration(seconds: 3),
      ));
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    // Check is the only real cost; a player who never asks for help and never
    // mis-fills gets three stars.
    final stars = _mistakes.isEmpty && _checksUsed == 0
        ? 3
        : (_mistakes.length <= 3 && _checksUsed <= 1 ? 2 : 1);
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
                    showHowToPlay(context, body: t.helpNonogram, accent: _accent)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: _buildPuzzle()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: _onCheck,
                icon: const Icon(Icons.spellcheck_rounded),
                label: Text(t.nonogramCheck),
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
                t.nonogramHint,
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

  /// Clue gutters plus grid, sized so the whole thing always fits.
  ///
  /// Clue slots are narrower than cells (see [_slotRatio]) because a gutter of
  /// full-width cells would eat more of a phone than the board does — that is
  /// the real constraint on grid size in this game.
  static const _slotRatio = 0.62;

  Widget _buildPuzzle() {
    final w = _board.width, h = _board.height;
    final rowSlots = _board.rowClues.fold<int>(1, (a, r) => math.max(a, r.length));
    final colSlots = _board.colClues.fold<int>(1, (a, c) => math.max(a, c.length));

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          constraints.maxWidth / (w + rowSlots * _slotRatio),
          constraints.maxHeight / (h + colSlots * _slotRatio),
        );
        final gutterW = rowSlots * _slotRatio * cell;
        final gutterH = colSlots * _slotRatio * cell;

        return SizedBox(
          width: gutterW + w * cell,
          height: gutterH + h * cell,
          child: Column(
            children: [
              Row(children: [
                SizedBox(width: gutterW, height: gutterH),
                for (var c = 0; c < w; c++)
                  _clueStack(_board.colClues[c], cell, gutterH, vertical: true),
              ]),
              for (var r = 0; r < h; r++)
                Row(children: [
                  _clueStack(_board.rowClues[r], cell, gutterW, vertical: false),
                  for (var c = 0; c < w; c++) _buildCell(r, c, cell),
                ]),
            ],
          ),
        );
      },
    );
  }

  /// One line's clue numbers, pushed up against the grid so they read as
  /// belonging to it. An empty line shows "0" rather than nothing, which is
  /// clearer than a blank gutter for someone new to the puzzle.
  Widget _clueStack(List<int> clue, double cell, double extent,
      {required bool vertical}) {
    final labels = clue.isEmpty ? const [0] : clue;
    final style = TextStyle(
      fontSize: cell * 0.44,
      fontWeight: FontWeight.w700,
      color: clue.isEmpty ? Colors.black26 : Colors.black87,
    );
    final children = [
      for (final n in labels)
        SizedBox(
          width: vertical ? cell : _slotRatio * cell,
          height: vertical ? _slotRatio * cell : cell,
          child: Center(child: Text('$n', style: style)),
        ),
    ];
    return SizedBox(
      width: vertical ? cell : extent,
      height: vertical ? extent : cell,
      child: vertical
          ? Column(mainAxisAlignment: MainAxisAlignment.end, children: children)
          : Row(mainAxisAlignment: MainAxisAlignment.end, children: children),
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final mark = _board.marks[r][c];
    final wrong = _showingCheck && _board.isWrongFill(r, c);

    // A heavier divider every fifth cell gives the eye something to count from,
    // which is how these puzzles are actually read.
    BorderSide side(bool major) => BorderSide(
        color: major ? Colors.black45 : Colors.black12,
        width: major ? 1.6 : 0.6);

    return GestureDetector(
      // Keyed so widget tests can drive specific cells; the clue gutters are
      // plain SizedBoxes, so a by-type finder would be ambiguous.
      key: ValueKey('nonogram-$r-$c'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _onCellTap(r, c),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: switch (mark) {
            NonogramMark.filled =>
              wrong ? const Color(0xFFC62828) : const Color(0xFF00695C),
            NonogramMark.crossed => const Color(0xFFF2F2F2),
            NonogramMark.blank => Colors.white,
          },
          border: Border(
            top: side(r % 5 == 0),
            left: side(c % 5 == 0),
            right: side(c == _board.width - 1),
            bottom: side(r == _board.height - 1),
          ),
        ),
        alignment: Alignment.center,
        child: mark == NonogramMark.crossed
            ? Icon(Icons.close_rounded,
                size: size * 0.6, color: Colors.black38)
            : null,
      ),
    );
  }
}
