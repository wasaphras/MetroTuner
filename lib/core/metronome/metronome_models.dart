import 'package:flutter/foundation.dart';

/// Time signature for the metronome (numerator / denominator).
@immutable
class Meter {
  /// Creates a meter after validating [beatsPerBar] and [beatUnit].
  factory Meter(int beatsPerBar, int beatUnit) {
    if (beatsPerBar < minBeatsPerBar || beatsPerBar > maxBeatsPerBar) {
      throw ArgumentError.value(
        beatsPerBar,
        'beatsPerBar',
        'expected $minBeatsPerBar–$maxBeatsPerBar',
      );
    }
    if (!_allowedDenominators.contains(beatUnit)) {
      throw ArgumentError.value(
        beatUnit,
        'beatUnit',
        'expected one of $_allowedDenominators',
      );
    }
    return Meter._(beatsPerBar, beatUnit);
  }

  const Meter._(this.beatsPerBar, this.beatUnit);

  /// 2/4
  static const twoFour = Meter._(2, 4);

  /// 3/4
  static const threeFour = Meter._(3, 4);

  /// 4/4
  static const fourFour = Meter._(4, 4);

  /// 6/8
  static const sixEight = Meter._(6, 8);

  /// Preset chips (fixed order for the metronome UI).
  static const List<Meter> presets = [
    twoFour,
    threeFour,
    fourFour,
    sixEight,
  ];

  static const Set<int> _allowedDenominators = {2, 4, 8, 16};

  /// Minimum numerator (beats per bar).
  static const int minBeatsPerBar = 1;

  /// Maximum numerator (beats per bar).
  static const int maxBeatsPerBar = 16;

  /// Beats in one bar (top number), [1–16].
  final int beatsPerBar;

  /// Notated beat unit (bottom number); scheduling uses [beatsPerBar] only;
  /// denominator is for labeling and feel.
  final int beatUnit;

  String get label => '$beatsPerBar/$beatUnit';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meter &&
          beatsPerBar == other.beatsPerBar &&
          beatUnit == other.beatUnit;

  @override
  int get hashCode => Object.hash(beatsPerBar, beatUnit);
}
