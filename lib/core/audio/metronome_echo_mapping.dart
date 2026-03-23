import 'package:flutter/foundation.dart';

/// SoLoud echo filter parameters derived from Room + Echo sliders.
///
/// Shared with the audio engine playback path so UI preview uses identical
/// mapping.
@immutable
class MetronomeEchoMappedParams {
  /// Creates mapped echo params.
  const MetronomeEchoMappedParams({
    required this.wet,
    required this.delaySeconds,
    required this.decay,
  });

  /// Mix of delayed signal \[0, 1].
  final double wet;

  /// Echo delay in seconds.
  final double delaySeconds;

  /// Feedback decay \[0.05, 0.95].
  final double decay;
}

/// Maps room + echo sliders to wet/delay/decay (mono echo filter).
MetronomeEchoMappedParams metronomeEchoParamsFromSliders({
  required double reverb,
  required double echo,
}) {
  final wet = (reverb * 0.55 + echo * 0.38).clamp(0.0, 1.0);
  final delay = 0.02 + reverb * 0.09 + echo * 0.34;
  final decay = (0.22 + reverb * 0.62 * (1 - echo * 0.38)).clamp(
    0.05,
    0.95,
  );
  return MetronomeEchoMappedParams(
    wet: wet,
    delaySeconds: delay,
    decay: decay,
  );
}
