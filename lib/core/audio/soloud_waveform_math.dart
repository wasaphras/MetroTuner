import 'dart:math' as math;

/// Matches SoLoud `SoLoud::Misc::generateWaveform` (`soloud_misc.cpp`).
///
/// [phase01] is phase in \[0, 1); [waveIndex] matches `WaveForm` enum order (0–8).
double soloudWaveformSampleRaw(int waveIndex, double phase01) {
  final p = phase01 - phase01.floorToDouble();
  switch (waveIndex) {
    case 0: // WAVE_SQUARE
      return p > 0.5 ? 0.5 : -0.5;
    case 1: // WAVE_SAW
      return p - 0.5;
    case 2: // WAVE_SIN
      return math.sin(p * math.pi * 2) * 0.5;
    case 3: // WAVE_TRIANGLE
      return (p > 0.5 ? (1.0 - (p - 0.5) * 2) : p * 2.0) - 0.5;
    case 4: // WAVE_BOUNCE
      return (p < 0.5
              ? math.sin(p * math.pi * 2) * 0.5
              : -math.sin(p * math.pi * 2) * 0.5) -
          0.5;
    case 5: // WAVE_JAWS
      return (p < 0.25 ? math.sin(p * math.pi * 2) * 0.5 : 0) - 0.5;
    case 6: // WAVE_HUMPS
      return (p < 0.5 ? math.sin(p * math.pi * 2) * 0.5 : 0) - 0.5;
    case 7: // WAVE_FSQUARE
      var f = 0.0;
      for (var i = 1; i < 22; i += 2) {
        f += (4.0 / (math.pi * i)) * math.sin(2 * math.pi * i * p);
      }
      return f * 0.5;
    case 8: // WAVE_FSAW
      var f = 0.0;
      for (var i = 1; i < 15; i++) {
        if (i.isOdd) {
          f += (1.0 / (math.pi * i)) * math.sin(p * 2 * math.pi * i);
        } else {
          f -= (1.0 / (math.pi * i)) * math.sin(p * 2 * math.pi * i);
        }
      }
      return f;
    default:
      return p > 0.5 ? 0.5 : -0.5;
  }
}

/// SoLoud output is roughly ±0.5; map to ±1 for UI graphs.
double soloudWaveformSampleNormalized(int waveIndex, double phase01) {
  return (soloudWaveformSampleRaw(waveIndex, phase01) * 2.0).clamp(-1.0, 1.0);
}
