/// Pure helpers for metronome timing (unit-testable, no periodic Timer).
///
/// Beat scheduling uses a monotonic Stopwatch in the controller; each step
/// schedules a one-shot delay so drift is corrected against the anchor timeline.
/// Clicks are played through AudioEngine on the SoLoud audio device clock.
abstract final class MetronomeScheduler {
  MetronomeScheduler._();

  static const int minBpm = 20;
  static const int maxBpm = 300;
  static const int defaultBpm = 120;

  /// Length of one beat in microseconds for integer [bpm].
  static int beatIntervalMicros(int bpm) {
    return (60000000 / bpm).round();
  }

  /// Delay from [elapsedMicros] until beat index [beatIndex] (0-based), non-negative.
  ///
  /// [phaseOffsetMicros] shifts the beat grid (e.g. half an interval so clicks
  /// align with a sweep crossing center at t = 0.5).
  static int delayUntilBeatMicros({
    required int beatIndex,
    required int bpm,
    required int elapsedMicros,
    int phaseOffsetMicros = 0,
  }) {
    final interval = beatIntervalMicros(bpm);
    final target = beatIndex * interval + phaseOffsetMicros;
    final wait = target - elapsedMicros;
    return wait < 0 ? 0 : wait;
  }

  /// Whether [beatIndex] (0-based, counting from session start) is a downbeat.
  static bool isDownbeat({
    required int beatIndex,
    required int beatsPerBar,
  }) {
    return beatIndex % beatsPerBar == 0;
  }

  /// Clamps [bpm] to the supported range.
  static int clampBpm(int bpm) {
    if (bpm < minBpm) {
      return minBpm;
    }
    if (bpm > maxBpm) {
      return maxBpm;
    }
    return bpm;
  }

  /// Ease-in-out within \[0,1\] (smoothstep); maps 0.5 → 0.5 so center click phase is unchanged.
  static double _smoothstep01(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
  }

  /// Pendulum position along the bar in \[0, 1\]: alternates L→R / R→L each beat.
  /// Uses smoothstep on the within-beat phase so motion eases at the turnarounds.
  /// At [elapsedMicros] % interval == interval/2, value is 0.5 (center click phase).
  static double pendulumSweep01({
    required int elapsedMicros,
    required int beatIntervalMicros,
  }) {
    if (beatIntervalMicros <= 0) {
      return 0;
    }
    final beatIndex = elapsedMicros ~/ beatIntervalMicros;
    final rawFrac =
        (elapsedMicros % beatIntervalMicros) / beatIntervalMicros;
    final fracInBeat = _smoothstep01(rawFrac);
    final tri = beatIndex.isEven ? fracInBeat : 1.0 - fracInBeat;
    return tri.clamp(0.0, 1.0);
  }
}
