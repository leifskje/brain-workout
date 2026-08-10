import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// What the player chose on the level-complete dialog.
///
/// [close] means "dismiss and stay on this screen". Only dialogs given a
/// `closeLabel` can return it — every other game still sees just home/next, so
/// their `if (next) … else home` handling stays correct.
enum WinAction { home, next, close }

/// Shows a celebratory "level complete" dialog: it pops in with an elastic
/// scale, the 🎉 bursts, and a row of stars twinkles in. Returns the chosen
/// [WinAction] (or null if dismissed unexpectedly).
///
/// [message] and [nextLabel] default to localized "You cleared level N." /
/// "Next level".
Future<WinAction?> showWinDialog(
  BuildContext context, {
  required int level,
  required Color accent,
  required int stars,
  String? message,
  String? nextLabel,
  bool newRecord = false,
  String? bestText,
  String? closeLabel,
}) {
  return showGeneralDialog<WinAction>(
    context: context,
    barrierDismissible: false,
    barrierLabel: AppLocalizations.of(context).levelComplete,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (context, _, _) => _WinDialog(
        level: level,
        accent: accent,
        stars: stars,
        message: message,
        nextLabel: nextLabel,
        newRecord: newRecord,
        bestText: bestText,
        closeLabel: closeLabel),
    transitionBuilder: (context, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: curved.value, child: child),
      );
    },
  );
}

class _WinDialog extends StatefulWidget {
  const _WinDialog({
    required this.level,
    required this.accent,
    required this.stars,
    this.message,
    this.nextLabel,
    this.newRecord = false,
    this.bestText,
    this.closeLabel,
  });

  final int level;
  final Color accent;
  final int stars;
  final String? message;
  final String? nextLabel;

  /// Shows the "new personal best" badge. Only ever true when a *previous* best
  /// was beaten — never on a first completion.
  final bool newRecord;

  /// The standing best, e.g. "Your best: 12 moves". Shown whether or not this
  /// round beat it, so the number is something to aim at next time.
  final String? bestText;

  /// When set, the secondary button dismisses the dialog *without leaving the
  /// screen* instead of going home. Used where the screen behind the dialog still
  /// has something to offer — the daily word's share buttons, which were
  /// unreachable while the only ways out were "Home" and "New word".
  final String? closeLabel;

  @override
  State<_WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<_WinDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _interval(double start, double end) =>
      ((_c.value - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final pop = Curves.elasticOut.transform(_interval(0.0, 0.7));
                  return Column(
                    children: [
                      Transform.scale(
                        scale: pop,
                        child: const Text('🎉', style: TextStyle(fontSize: 64)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Transform.scale(
                              scale: Curves.easeOutBack.transform(
                                _interval(0.3 + i * 0.12, 0.6 + i * 0.12),
                              ),
                              child: Icon(
                                i < widget.stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: i < widget.stars
                                    ? widget.accent
                                    : Colors.black26,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).wellDone,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                widget.message ??
                    AppLocalizations.of(context).clearedLevel(widget.level),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              if (widget.newRecord) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 22, color: widget.accent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context).newRecord,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: widget.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.bestText != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.bestText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(
                        context,
                        widget.closeLabel == null
                            ? WinAction.home
                            : WinAction.close),
                    child: Text(widget.closeLabel ??
                        AppLocalizations.of(context).home),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style:
                        FilledButton.styleFrom(backgroundColor: widget.accent),
                    onPressed: () => Navigator.pop(context, WinAction.next),
                    child: Text(widget.nextLabel ??
                        AppLocalizations.of(context).nextLevel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
