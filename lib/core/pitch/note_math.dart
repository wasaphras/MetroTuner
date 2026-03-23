import 'dart:math' as math;

/// Equal-temperament note math with A4 = 440 Hz.
abstract final class NoteMath {
  NoteMath._();

  static const double defaultA4Hz = 440;

  static const List<String> _names = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  /// MIDI note number (fractional) for [hz] with reference A4 = [a4Hz].
  static double hzToMidi(double hz, {double a4Hz = defaultA4Hz}) {
    return 69 + 12 * (math.log(hz / a4Hz) / math.ln2);
  }

  /// Frequency in Hz for fractional MIDI note [midi] with reference A4 = [a4Hz].
  static double midiToHz(double midi, {double a4Hz = defaultA4Hz}) {
    return a4Hz * math.exp((midi - 69) / 12 * math.ln2);
  }

  /// Nearest chromatic label (e.g. A4) and cents from that note in [-50, 50].
  static ({String label, double cents}) nearestNoteAndCents(
    double hz, {
    double a4Hz = defaultA4Hz,
  }) {
    final midi = hzToMidi(hz, a4Hz: a4Hz);
    final rounded = midi.round();
    final nearestHz = midiToHz(rounded.toDouble(), a4Hz: a4Hz);
    // 1200 cents per octave; clamp defends against float edge cases at semitone boundaries.
    final rawCents = 1200 * (math.log(hz / nearestHz) / math.ln2);
    final cents = rawCents.clamp(-50.0, 50.0);
    final label = _noteLabelForMidi(rounded);
    return (label: label, cents: cents);
  }

  static String _noteLabelForMidi(int midi) {
    final pc = midi % 12;
    final octave = (midi ~/ 12) - 1;
    return '${_names[pc]}$octave';
  }

  /// Chromatic label for integer MIDI note (e.g. 60 → A4 depending on name).
  static String midiToChromaticLabel(int midi) => _noteLabelForMidi(midi);
}
