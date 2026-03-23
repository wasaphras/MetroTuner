import 'dart:math' as math;
import 'dart:typed_data';

import 'package:metrotuner/core/pitch/note_math.dart';
import 'package:metrotuner/core/pitch/pitch_types.dart';
import 'package:metrotuner/core/pitch/pitch_yin.dart';

/// Combines RMS gating, YIN, and note mapping for one PCM frame.
abstract final class PitchDetector {
  PitchDetector._();

  /// Minimum RMS (normalized float PCM) to consider a frame non-silent.
  static const double minRms = 0.002;

  /// Analyzes one mono frame; returns null if too quiet or YIN has no pitch.
  static PitchResult? analyzeFrame(
    Float32List samples,
    int sampleRate, {
    double a4Hz = NoteMath.defaultA4Hz,
  }) {
    final rms = _rms(samples);
    // Gate quiet frames so idle noise does not produce random YIN peaks.
    if (rms < minRms) {
      return null;
    }
    final hz = PitchYin.estimateHz(samples, sampleRate);
    if (hz == null || hz.isNaN || hz.isInfinite) {
      return null;
    }
    final mapped = NoteMath.nearestNoteAndCents(hz, a4Hz: a4Hz);
    return PitchResult(
      frequencyHz: hz,
      noteLabel: mapped.label,
      centsFromNearest: mapped.cents,
      rms: rms,
    );
  }

  static double _rms(Float32List samples) {
    if (samples.isEmpty) {
      return 0;
    }
    var sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      sum += s * s;
    }
    return math.sqrt(sum / samples.length);
  }
}
