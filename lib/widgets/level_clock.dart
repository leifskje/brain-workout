import 'dart:async';

import 'package:flutter/material.dart';

import '../services/level_timer.dart';
import '../services/progress_store.dart';

/// The level clock, shown only if the player has asked for it.
///
/// The time is *always* recorded (see [LevelTimer]); this widget is the opt-in
/// display. When the setting is off it renders nothing and starts no periodic
/// callback at all, so the default experience has no clock and no cost.
///
/// Ticks once a second rather than every frame: it displays whole seconds, and
/// driving 60Hz rebuilds to move a seconds counter would be waste.
class LevelClock extends StatefulWidget {
  const LevelClock({super.key, required this.timer, required this.accent});

  final LevelTimer timer;
  final Color accent;

  @override
  State<LevelClock> createState() => _LevelClockState();
}

class _LevelClockState extends State<LevelClock> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (ProgressStore.instance.showTimerDuringPlay) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ProgressStore.instance.showTimerDuringPlay) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        key: const ValueKey('level_clock'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: widget.accent),
          const SizedBox(width: 5),
          Text(
            formatLevelTime(widget.timer.elapsed),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
