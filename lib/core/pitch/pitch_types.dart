import 'package:flutter/foundation.dart';

/// One pitch estimate from the detector (mic + YIN + note mapping).
@immutable
class PitchResult {
  /// Creates a pitch result.
  const PitchResult({
    required this.frequencyHz,
    required this.noteLabel,
    required this.centsFromNearest,
    required this.rms,
  });

  /// Detected fundamental frequency in Hz.
  final double frequencyHz;

  /// Display label like A4 or C#5.
  final String noteLabel;

  /// Cents from the nearest chromatic note; in [-50, 50].
  final double centsFromNearest;

  /// Root-mean-square level of the analyzed frame (0..~1 for normalized input).
  final double rms;
}
