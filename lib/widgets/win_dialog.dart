import 'package:flutter/material.dart';

/// What the player chose on the level-complete dialog.
enum WinAction { home, next }

/// Shows a celebratory "level complete" dialog: it pops in with an elastic
/// scale, the 🎉 bursts, and a row of stars twinkles in. Returns the chosen
/// [WinAction] (or null if dismissed unexpectedly).
Future<WinAction?> showWinDialog(
  BuildContext context, {
  required int level,
  required Color accent,
  required int stars,
  String? message,
}) {
  return showGeneralDialog<WinAction>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Level complete',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (context, _, _) =>
        _WinDialog(level: level, accent: accent, stars: stars, message: message),
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
  });

  final int level;
  final Color accent;
  final int stars;
  final String? message;

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
              const Text(
                'Well done!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                widget.message ?? 'You cleared level ${widget.level}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, WinAction.home),
                    child: const Text('Home'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style:
                        FilledButton.styleFrom(backgroundColor: widget.accent),
                    onPressed: () => Navigator.pop(context, WinAction.next),
                    child: const Text('Next level'),
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
