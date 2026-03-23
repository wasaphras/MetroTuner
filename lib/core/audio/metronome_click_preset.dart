/// Named timbre presets for synthesized metronome clicks (SoLoud waveforms).
/// Labels describe character, not acoustic instruments (synthesis-only).
enum MetronomeClickPreset {
  /// Balanced tick (triangle; less harsh than raw jaws).
  classic,

  /// Soft, rounded tone (sine).
  bell,

  /// Very short, dry (bounce).
  clap,

  /// Bright, noisy edge (jaws).
  snare,

  /// Sharp attack (square).
  drum,

  /// Bright harmonics (Fourier square).
  piano,

  /// User picks raw waveform index.
  custom,
}

/// Default waveform index per preset (matches `flutter_soloud` enum order).
extension MetronomeClickPresetWaveform on MetronomeClickPreset {
  /// Waveform index 0..8 when not [MetronomeClickPreset.custom].
  int get waveformIndex {
    switch (this) {
      case MetronomeClickPreset.classic:
        return 3; // triangle — softer default tick
      case MetronomeClickPreset.bell:
        return 2; // sin
      case MetronomeClickPreset.clap:
        return 4; // bounce
      case MetronomeClickPreset.snare:
        return 5; // jaws
      case MetronomeClickPreset.drum:
        return 0; // square
      case MetronomeClickPreset.piano:
        return 7; // fSquare
      case MetronomeClickPreset.custom:
        return 3;
    }
  }
}

/// Human-readable labels for settings UI (synthesized timbres).
const List<String> kMetronomeClickPresetLabels = <String>[
  'Neutral tick',
  'Soft tone',
  'Short tick',
  'Bright tick',
  'Sharp tick',
  'Bright harmonics',
  'Custom',
];

/// One-line hint: SoLoud waveform used when preset is not custom.
const List<String> kMetronomeClickPresetSubtitles = <String>[
  'Triangle waveform',
  'Sine waveform',
  'Bounce waveform',
  'Jaws waveform',
  'Square waveform',
  'Fourier square',
  'Pick from list below',
];

/// Parse stored int to preset; unknown → classic.
MetronomeClickPreset metronomeClickPresetFromInt(int? v) {
  if (v == null || v < 0 || v >= MetronomeClickPreset.values.length) {
    return MetronomeClickPreset.classic;
  }
  return MetronomeClickPreset.values[v];
}
