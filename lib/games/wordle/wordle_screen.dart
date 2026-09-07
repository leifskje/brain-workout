import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'word_repository.dart';
import 'wordle_models.dart';

/// Playable Wordle-style game: guess a hidden 5-letter word in 6 tries, with
/// green/yellow/grey feedback and an on-screen keyboard. Language-switchable.
class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  static const _gameId = 'wordle';
  static const _accent = Color(0xFF6AAA64);
  static const _green = Color(0xFF6AAA64);
  static const _yellow = Color(0xFFC9B458);
  static const _grey = Color(0xFF787C7E);
  static const _keyIdle = Color(0xFFD3D6DA);

  late WordleLanguage _language;
  WordRepository? _repo;
  bool _loading = true;

  String _target = '';
  final List<String> _guesses = [];
  final List<List<LetterState>> _results = [];
  final Map<String, LetterState> _keyStates = {};
  String _current = '';
  bool _finished = false;

  /// True while playing the shared daily word; false in practice mode. Only a
  /// daily result is recorded and shareable — a practice word is nobody else's
  /// puzzle, so a shared grid from one would mean nothing.
  bool _isDaily = true;
  int _puzzleNumber = 0;

  /// Set once today's daily is finished, which swaps the board for the result
  /// card. The card shows the grid rather than restoring the board because the
  /// stored result keeps only the colours, never the words.
  bool _dailyDone = false;
  bool _dailySolved = false;
  List<List<LetterState>> _dailyRows = const [];

  /// Letters revealed by hints, as positions in [_target].
  ///
  /// Hints are practice-only. The daily word is the same puzzle for everyone and
  /// its grid is shareable, so a hinted daily result would misreport how it went
  /// — and the share is the one place this app makes a claim to another person.
  final Set<int> _hinted = {};

  bool _initedLanguage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initedLanguage) return;
    _initedLanguage = true;
    // No stored choice yet → match the app language (needs the inherited
    // Localizations, hence didChangeDependencies rather than initState).
    final stored = ProgressStore.instance.wordleLanguageId ??
        Localizations.localeOf(context).languageCode;
    _language = wordleLanguageById(stored);
    _load(_language);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpWord,
            accent: _accent);
      }
    });
  }

  Future<void> _load(WordleLanguage language) async {
    setState(() {
      _loading = true;
      _language = language;
    });
    final repo = await WordRepository.forLanguage(language);
    if (!mounted) return;
    _repo = repo;
    _startDaily();
  }

  /// Starts (or re-shows) today's shared word.
  ///
  /// The word is a pure function of the local date, so every player of this
  /// language gets the same one with no server involved — which is what makes the
  /// shared grid comparable.
  void _startDaily() {
    final puzzle = WordRepository.dailyPuzzleNumber(DateTime.now());
    final done = ProgressStore.instance.dailyWordResult(_language.id, puzzle);
    setState(() {
      _loading = false;
      _isDaily = true;
      _hinted.clear();
      _puzzleNumber = puzzle;
      _guesses.clear();
      _results.clear();
      _keyStates.clear();
      _current = '';
      _finished = done != null;
      _dailyDone = done != null;
      _dailySolved = done?.solved ?? false;
      _dailyRows = done == null ? const [] : _decodeRows(done.rows);
      _target = done != null ? '' : _repo!.wordOfTheDay(DateTime.now());
    });
  }

  static List<List<LetterState>> _decodeRows(List<String> rows) => [
        for (final row in rows)
          [
            for (final ch in row.split(''))
              switch (ch) {
                'c' => LetterState.correct,
                'p' => LetterState.present,
                _ => LetterState.absent,
              }
          ]
      ];

  static List<String> _encodeRows(List<List<LetterState>> rows) => [
        for (final row in rows)
          row.map((s) => switch (s) {
                LetterState.correct => 'c',
                LetterState.present => 'p',
                LetterState.absent => 'a',
              }).join()
      ];

  String _shareText(BuildContext context) => dailyShareText(
        title: AppLocalizations.of(context).dailyShareTitle(_puzzleNumber),
        rows: _dailyRows.isEmpty ? _results : _dailyRows,
        solved: _dailyDone ? _dailySolved : true,
      );

  /// Opens the system share sheet, falling back to the clipboard if it isn't
  /// there.
  ///
  /// The fallback is not defensive padding. `share_plus` is a *native* plugin, and
  /// plugin registration is generated at build time — so any app that picked up the
  /// Dart side without a full rebuild throws
  /// `MissingPluginException(No implementation found for method share ...)`. That
  /// happened on the first real run. It can also fail on a device with nothing
  /// registered to receive a share.
  ///
  /// Whatever the cause, the player's result must not be lost to a stack trace:
  /// the text goes to the clipboard instead and they are told so, which is a
  /// perfectly good way to send it to someone.
  Future<void> _shareResult() async {
    final text = _shareText(context);
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } on Object {
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) _toast(AppLocalizations.of(context).shareUnavailable);
    }
  }

  Future<void> _copyResult() async {
    final text = _shareText(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _toast(AppLocalizations.of(context).copiedToClipboard);
  }

  /// Files today's result, so returning shows the card rather than the answer.
  void _finishDaily({required bool solved}) {
    if (!_isDaily) return;
    ProgressStore.instance.recordDailyWord(_language.id, _puzzleNumber,
        solved: solved, rows: _encodeRows(_results));
    setState(() {
      _dailyDone = true;
      _dailySolved = solved;
      _dailyRows = [for (final r in _results) [...r]];
    });
  }

  /// A practice word: random, unrecorded, and not shareable.
  void _startNewWord() {
    setState(() {
      _loading = false;
      _isDaily = false;
      _dailyDone = false;
      _target = _repo!.randomWord();
      _guesses.clear();
      _results.clear();
      _keyStates.clear();
      _current = '';
      _finished = false;
      _hinted.clear();
    });
  }

  /// Reveals one unguessed letter of the practice word, in place.
  ///
  /// Practice only: see [_hinted]. The revealed letter is typed into the current
  /// guess at its real position, so it teaches the answer's shape rather than
  /// just naming a letter.
  void _useHint() {
    if (_finished || _loading || _isDaily) return;
    final t = AppLocalizations.of(context);

    // Positions the player has not already pinned down with a green.
    final known = <int>{..._hinted};
    for (final result in _results) {
      for (var i = 0; i < result.length; i++) {
        if (result[i] == LetterState.correct) known.add(i);
      }
    }
    final candidates = [
      for (var i = 0; i < _target.length; i++)
        if (!known.contains(i)) i,
    ];
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.hintNoneLeft)));
      return;
    }

    HapticFeedback.lightImpact();
    final first = _hinted.isEmpty;
    setState(() {
      final pos = candidates.first;
      _hinted.add(pos);
      // Pad the current guess so the letter lands on its own square.
      final buf = _current.padRight(_target.length).split('');
      buf[pos] = _target[pos];
      _current = buf.join().trimRight();
    });
    if (first) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.hintCost)));
    }
  }

  void _changeLanguage(String id) {
    if (id == _language.id) return;
    ProgressStore.instance.setWordleLanguageId(id);
    _load(wordleLanguageById(id));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _onLetter(String ch) {
    if (_finished || _current.length >= wordLength) return;
    setState(() => _current += ch);
  }

  void _onBackspace() {
    if (_finished || _current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _onEnter() {
    if (_finished) return;
    if (_current.length < wordLength) {
      _toast(AppLocalizations.of(context).notEnoughLetters);
      return;
    }
    if (!_repo!.isValid(_current)) {
      HapticFeedback.mediumImpact();
      _toast(AppLocalizations.of(context).notInWordList);
      return;
    }

    final result = scoreGuess(_current, _target);
    HapticFeedback.lightImpact();
    setState(() {
      for (var i = 0; i < wordLength; i++) {
        final ch = _current[i];
        final s = result[i];
        final existing = _keyStates[ch];
        if (existing == null || _rank(s) > _rank(existing)) {
          _keyStates[ch] = s;
        }
      }
      _guesses.add(_current);
      _results.add(result);
      _current = '';
    });

    if (result.every((s) => s == LetterState.correct)) {
      _finished = true;
      ProgressStore.instance.registerPlay(_gameId);
      _finishDaily(solved: true);
      Future.delayed(const Duration(milliseconds: 200), _showWin);
    } else if (_guesses.length >= maxGuesses) {
      _finished = true;
      _finishDaily(solved: false);
      Future.delayed(const Duration(milliseconds: 200), _showLose);
    }
  }

  int _rank(LetterState s) => switch (s) {
        LetterState.correct => 3,
        LetterState.present => 2,
        LetterState.absent => 1,
      };

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final n = _guesses.length;
    final t = AppLocalizations.of(context);
    // On the daily word the dialog sits on top of the result card, so its buttons
    // have to lead *to* the share rather than away from it. Offering "New word"
    // here was the bug: it was the only non-Home action, and taking it replaced
    // the finished daily with a practice word — so the share buttons could never
    // be reached at all.
    showWinDialog(
      context,
      level: n,
      accent: _accent,
      // A hinted practice word cannot be a 3-star result.
      stars: _hinted.isEmpty ? wordleStars(n) : wordleStars(n).clamp(1, 2),
      message: t.solvedInGuesses(n),
      nextLabel: _isDaily ? t.shareResult : t.newWord,
      closeLabel: _isDaily ? t.closeAction : null,
    ).then((action) {
      if (!mounted || action == null) return;
      switch (action) {
        case WinAction.next:
          if (_isDaily) {
            _shareResult();
          } else {
            _startNewWord();
          }
        // Stays on the result card, where Copy and the practice word live.
        case WinAction.close:
          break;
        case WinAction.home:
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
        title: Text(AppLocalizations.of(context).outOfGuesses),
        content: Text(AppLocalizations.of(context).theWordWas(_target)),
        actions: [
          // Same reasoning as the win dialog: on the daily word, dismissing has to
          // leave the player on the result card, not send them away from it.
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (!_isDaily) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: Text(_isDaily
                ? AppLocalizations.of(context).closeAction
                : AppLocalizations.of(context).home),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              Navigator.pop(dialogContext);
              if (_isDaily) {
                _shareResult();
              } else {
                _startNewWord();
              }
            },
            child: Text(_isDaily
                ? AppLocalizations.of(context).shareResult
                : AppLocalizations.of(context).newWord),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_dailyDone)
              // Today's word is finished, so there is no board to show and no
              // keyboard to offer: only the result and a way to pass it on.
              Expanded(child: Center(child: _buildDailyResult()))
            else ...[
              Expanded(child: Center(child: _buildBoard())),
              _buildKeyboard(),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  /// The end-of-day card: how it went, the spoiler-free grid, and two ways to
  /// pass it on.
  ///
  /// Both share routes are offered on purpose. The share sheet is what most
  /// people expect and goes straight to WhatsApp or SMS; copy-to-clipboard always
  /// works, needs no other app to cooperate, and is the more predictable of the
  /// two for someone who finds the sheet confusing.
  Widget _buildDailyResult() {
    final t = AppLocalizations.of(context);
    final rows = _dailyRows.isEmpty ? _results : _dailyRows;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _dailySolved ? t.dailyDoneTitle : t.dailyNotSolved,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            t.wordOfTheDay(_puzzleNumber),
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          // The grid is the shareable artefact: colours only, never the letters,
          // so showing it to someone who hasn't played spoils nothing.
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final s in row)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: switch (s) {
                          LetterState.correct => _green,
                          LetterState.present => _yellow,
                          LetterState.absent => _keyIdle,
                        },
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const ValueKey('wordle_share'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                onPressed: _shareResult,
                icon: const Icon(Icons.share_rounded),
                label: Text(t.shareResult),
              ),
              OutlinedButton.icon(
                key: const ValueKey('wordle_copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: const BorderSide(color: _accent, width: 1.5),
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                onPressed: _copyResult,
                icon: const Icon(Icons.copy_rounded),
                label: Text(t.copyResult),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            t.dailyDoneBody,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          // "One word a day" is the shared ritual, not a limit on playing. This
          // was a faint TextButton and read as a footnote — the owner concluded
          // the game was over for the day. It is a real button now, because
          // "keep playing" is the more common thing to want here.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('wordle_practice'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent, width: 1.5),
                minimumSize: const Size(0, 56),
              ),
              onPressed: _startNewWord,
              icon: const Icon(Icons.replay_rounded),
              label: Text(t.practiceWord),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.practiceWordNote,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final t = AppLocalizations.of(context);
    return Container(
      color: _accent.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 28,
            color: _accent,
            tooltip: t.back,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(t.gameWordTitle,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          // Practice only — the daily word is shared, so it gets no hints.
          if (!_isDaily)
            IconButton(
              key: const ValueKey('wordle_hint_button'),
              icon: const Icon(Icons.lightbulb_outline_rounded),
              iconSize: 28,
              color: _accent,
              tooltip: t.useHint,
              onPressed: _loading || _finished ? null : _useHint,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            iconSize: 28,
            color: _accent,
            tooltip: t.howToPlay,
            onPressed: () =>
                showHowToPlay(context, body: t.helpWord, accent: _accent),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            iconSize: 28,
            color: _accent,
            tooltip: t.newWord,
            onPressed: _loading ? null : _startNewWord,
          ),
          PopupMenuButton<String>(
            initialValue: _language.id,
            tooltip: t.language,
            onSelected: _changeLanguage,
            itemBuilder: (_) => [
              for (final l in wordleLanguages)
                PopupMenuItem(value: l.id, child: Text(l.name)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(children: [
                Text(_language.name,
                    style: TextStyle(
                        color: _accent, fontWeight: FontWeight.w700)),
                Icon(Icons.arrow_drop_down_rounded, color: _accent),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    final width = MediaQuery.of(context).size.width;
    final tile = ((width - 48) / wordLength).clamp(0.0, 56.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < maxGuesses; r++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (var c = 0; c < wordLength; c++) _tile(r, c, tile)],
          ),
      ],
    );
  }

  Widget _tile(int row, int col, double size) {
    var letter = '';
    LetterState? state;
    if (row < _guesses.length) {
      letter = _guesses[row][col];
      state = _results[row][col];
    } else if (row == _guesses.length && col < _current.length) {
      letter = _current[col];
    }
    final filled = state != null;
    final bg = filled ? _stateColor(state) : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.all(3),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: filled
              ? bg
              : (letter.isEmpty ? Colors.black26 : Colors.black45),
          width: 2,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Color _stateColor(LetterState s) => switch (s) {
        LetterState.correct => _green,
        LetterState.present => _yellow,
        LetterState.absent => _grey,
      };

  Widget _buildKeyboard() {
    final rows = _language.keyboardRows;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: Row(
              children: [
                if (r == rows.length - 1)
                  _key('ENTER', flex: 3, color: _keyIdle, onTap: _onEnter),
                for (final ch in rows[r].split(''))
                  _key(
                    ch,
                    color: _keyColor(_keyStates[ch]),
                    textColor: _keyStates[ch] == null
                        ? Colors.black87
                        : Colors.white,
                    onTap: () => _onLetter(ch),
                  ),
                if (r == rows.length - 1)
                  _key('⌫', flex: 3, color: _keyIdle, onTap: _onBackspace),
              ],
            ),
          ),
      ],
    );
  }

  Color _keyColor(LetterState? s) =>
      s == null ? _keyIdle : _stateColor(s);

  Widget _key(
    String label, {
    int flex = 2,
    required Color color,
    Color textColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Material(
          // Keyed because a by-text finder would also match the board tiles,
          // which show the same letters.
          key: ValueKey('wordle_key_$label'),
          color: color,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _finished && label.length == 1 ? null : onTap,
            child: SizedBox(
              height: 50,
              child: Center(
                child: label == '⌫'
                    ? Icon(Icons.backspace_outlined, size: 20, color: textColor)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: label.length > 1 ? 12 : 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
