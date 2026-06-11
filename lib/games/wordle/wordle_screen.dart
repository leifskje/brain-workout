import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    _startNewWord();
  }

  void _startNewWord() {
    setState(() {
      _loading = false;
      _target = _repo!.randomWord();
      _guesses.clear();
      _results.clear();
      _keyStates.clear();
      _current = '';
      _finished = false;
    });
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
      Future.delayed(const Duration(milliseconds: 200), _showWin);
    } else if (_guesses.length >= maxGuesses) {
      _finished = true;
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
    showWinDialog(
      context,
      level: n,
      accent: _accent,
      stars: wordleStars(n),
      message: AppLocalizations.of(context).solvedInGuesses(n),
      nextLabel: AppLocalizations.of(context).newWord,
    ).then((action) {
      if (!mounted || action == null) return;
      if (action == WinAction.next) {
        _startNewWord();
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
        title: Text(AppLocalizations.of(context).outOfGuesses),
        content: Text(AppLocalizations.of(context).theWordWas(_target)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(AppLocalizations.of(context).home),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              Navigator.pop(dialogContext);
              _startNewWord();
            },
            child: Text(AppLocalizations.of(context).newWord),
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
