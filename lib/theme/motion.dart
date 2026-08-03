/// Timing for animations that move something a screen-dependent distance.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.
library;

/// How long a slide of [distanceDp] logical pixels should take.
///
/// Both arrow games used a *fixed* duration for a slide whose distance scales
/// with the board's cell size — and cell size scales with the screen. So the
/// duration was device-independent while the **speed** was not: on a large phone
/// an arrow crossed far more pixels in the same 520ms and read as a blur. A
/// tester reported "there should be an animation when you click the arrows" for
/// an animation that was already there, just too fast to register.
///
/// Fixing the speed instead makes the motion look the same on every device, and
/// has a pleasant side effect: a long snake takes longer to slither out than a
/// short one, which is what the eye expects anyway.
///
/// Note this is not about refresh rate. Flutter drives animations from wall-clock
/// elapsed time, so a 120Hz screen renders the same animation more smoothly, not
/// faster. Frame rate was never the variable — distance was.
Duration slideDuration(
  double distanceDp, {
  double speedDpPerSecond = _defaultSpeed,
  Duration atLeast = const Duration(milliseconds: 340),
  Duration atMost = const Duration(milliseconds: 820),
}) {
  if (!distanceDp.isFinite || distanceDp <= 0) return atLeast;
  final ms = (distanceDp / speedDpPerSecond * 1000).round();
  if (ms < atLeast.inMilliseconds) return atLeast;
  if (ms > atMost.inMilliseconds) return atMost;
  return Duration(milliseconds: ms);
}

/// Chosen so a full-board arrow slide lands near the upper clamp rather than
/// under it: the old fixed timings worked out around 1400-1900 dp/s, which is
/// where "it moved" turns into "it vanished".
const double _defaultSpeed = 900;
