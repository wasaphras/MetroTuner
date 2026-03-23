import 'package:flutter/foundation.dart';
import 'package:metrotuner/core/audio/metronome_click_preset.dart';
import 'package:metrotuner/core/pitch/note_math.dart';

/// SharedPreferences keys for metronome click synthesis (local only).
const String kMetronomeClickBeatMidiPrefsKey = 'metronome_click_beat_midi';
const String kMetronomeClickDownbeatMidiPrefsKey =
    'metronome_click_downbeat_midi';
const String kMetronomeClickConcertA4PrefsKey = 'metronome_click_concert_a4';

/// Legacy keys (migration only).
const String kMetronomeClickBaseMidiPrefsKey = 'metronome_click_base_midi';
const String kMetronomeClickA4HzPrefsKey = 'metronome_click_a4_hz';
const String kMetronomeClickAccentOffsetPrefsKey =
    'metronome_click_accent_offset_semitones';

const String kMetronomeClickWaveformIndexPrefsKey =
    'metronome_click_waveform_index';
const String kMetronomeClickPresetIndexPrefsKey =
    'metronome_click_preset_index';
const String kMetronomeClickDurationMsPrefsKey =
    'metronome_click_duration_ms';
const String kMetronomeClickReverbPrefsKey = 'metronome_click_reverb';
const String kMetronomeClickEchoPrefsKey = 'metronome_click_echo';

/// Inclusive MIDI range for the click pitch (C3–C7).
const int kMetronomeClickMidiMin = 48;
const int kMetronomeClickMidiMax = 96;

/// Reference A4 for concert pitch (Hz).
const double kMetronomeReferenceA4ConcertHz = 440;

/// Reference A4 for alternate tuning (Hz).
const double kMetronomeReferenceA4AlternateHz = 432;

/// Click length (ms) slider range.
const double kMetronomeClickDurationMsMin = 3;
const double kMetronomeClickDurationMsMax = 80;

/// Default beat pitch (softer than legacy very-high tick).
const int kMetronomeClickDefaultBeatMidi = 81;

/// Default downbeat: one octave below beat.
const int kMetronomeClickDefaultDownbeatMidi = 69;

/// User-tunable metronome click synthesis (equal temperament).
///
/// Beat and downbeat use independent MIDI notes; reference is concert A4 (440)
/// or alternate A4 (432 Hz).
@immutable
class MetronomeClickSoundSettings {
  /// Creates settings.
  const MetronomeClickSoundSettings({
    required this.beatMidi,
    required this.downbeatMidi,
    required this.concertA4,
    required this.waveformIndex,
    required this.preset,
    required this.clickDurationMs,
    required this.reverb,
    required this.echo,
  });

  /// Factory defaults (synthesis; timbre preset tuned separately).
  factory MetronomeClickSoundSettings.defaults() =>
      const MetronomeClickSoundSettings(
        beatMidi: kMetronomeClickDefaultBeatMidi,
        downbeatMidi: kMetronomeClickDefaultDownbeatMidi,
        concertA4: true,
        waveformIndex: 3,
        preset: MetronomeClickPreset.classic,
        clickDurationMs: 16,
        reverb: 0,
        echo: 0,
      );

  final int beatMidi;
  final int downbeatMidi;

  /// `true` = A4 440 Hz (concert); `false` = A4 432 Hz.
  final bool concertA4;

  /// Index into `WaveForm` when [preset] is [MetronomeClickPreset.custom].
  final int waveformIndex;

  /// Timbre preset; non-custom uses [effectiveWaveformIndex] for playback.
  final MetronomeClickPreset preset;

  /// How long each click sounds before forced stop (milliseconds).
  final double clickDurationMs;

  /// Room-like tail via echo wet/decay (0 = dry).
  final double reverb;

  /// Echo delay / repeat amount (0 = none).
  final double echo;

  /// Waveform used for synthesis (custom or preset default).
  int get effectiveWaveformIndex {
    if (preset == MetronomeClickPreset.custom) {
      return waveformIndex.clamp(0, kMetronomeClickWaveformIndexMax);
    }
    return preset.waveformIndex;
  }

  /// Reference A4 in Hz for [NoteMath.midiToHz].
  double get referenceA4Hz =>
      concertA4 ? kMetronomeReferenceA4ConcertHz : kMetronomeReferenceA4AlternateHz;

  /// Clamped MIDI for non-accent beats.
  int get clampedBeatMidi => beatMidi.clamp(
    kMetronomeClickMidiMin,
    kMetronomeClickMidiMax,
  );

  /// Clamped MIDI for downbeat.
  int get clampedDownbeatMidi => downbeatMidi.clamp(
    kMetronomeClickMidiMin,
    kMetronomeClickMidiMax,
  );

  /// Fundamental Hz for a normal (non-accent) click.
  double get normalHz =>
      NoteMath.midiToHz(clampedBeatMidi.toDouble(), a4Hz: referenceA4Hz);

  /// MIDI used for the accent (downbeat).
  int get clampedAccentMidi => clampedDownbeatMidi;

  /// Fundamental Hz for an accent (downbeat) click.
  double get accentHz =>
      NoteMath.midiToHz(clampedDownbeatMidi.toDouble(), a4Hz: referenceA4Hz);

  /// Clamped click duration for playback.
  double get clampedClickDurationMs => clickDurationMs.clamp(
    kMetronomeClickDurationMsMin,
    kMetronomeClickDurationMsMax,
  );

  double get clampedReverb => reverb.clamp(0.0, 1.0);

  double get clampedEcho => echo.clamp(0.0, 1.0);

  MetronomeClickSoundSettings copyWith({
    int? beatMidi,
    int? downbeatMidi,
    bool? concertA4,
    int? waveformIndex,
    MetronomeClickPreset? preset,
    double? clickDurationMs,
    double? reverb,
    double? echo,
  }) {
    return MetronomeClickSoundSettings(
      beatMidi: beatMidi ?? this.beatMidi,
      downbeatMidi: downbeatMidi ?? this.downbeatMidi,
      concertA4: concertA4 ?? this.concertA4,
      waveformIndex: waveformIndex ?? this.waveformIndex,
      preset: preset ?? this.preset,
      clickDurationMs: clickDurationMs ?? this.clickDurationMs,
      reverb: reverb ?? this.reverb,
      echo: echo ?? this.echo,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MetronomeClickSoundSettings &&
        other.beatMidi == beatMidi &&
        other.downbeatMidi == downbeatMidi &&
        other.concertA4 == concertA4 &&
        other.waveformIndex == waveformIndex &&
        other.preset == preset &&
        other.clickDurationMs == clickDurationMs &&
        other.reverb == reverb &&
        other.echo == echo;
  }

  @override
  int get hashCode => Object.hash(
    beatMidi,
    downbeatMidi,
    concertA4,
    waveformIndex,
    preset,
    clickDurationMs,
    reverb,
    echo,
  );
}

/// Inclusive max [MetronomeClickSoundSettings.waveformIndex] (`WaveForm` enum).
const int kMetronomeClickWaveformIndexMax = 8;

/// Parse and clamp fields from SharedPreferences getters (null → defaults).
MetronomeClickSoundSettings metronomeClickSoundSettingsFromPrefs({
  int? beatMidi,
  int? downbeatMidi,
  bool? concertA4,
  int? waveformIndex,
  int? presetIndex,
  double? clickDurationMs,
  double? reverb,
  double? echo,
}) {
  final d = MetronomeClickSoundSettings.defaults();
  final b = (beatMidi ?? d.beatMidi).clamp(
    kMetronomeClickMidiMin,
    kMetronomeClickMidiMax,
  );
  final db = (downbeatMidi ?? d.downbeatMidi).clamp(
    kMetronomeClickMidiMin,
    kMetronomeClickMidiMax,
  );
  final wi = waveformIndex ?? d.waveformIndex;
  final validWi = (wi >= 0 && wi <= kMetronomeClickWaveformIndexMax)
      ? wi
      : d.waveformIndex;
  final preset = metronomeClickPresetFromInt(presetIndex ?? d.preset.index);
  final dur = (clickDurationMs ?? d.clickDurationMs).clamp(
    kMetronomeClickDurationMsMin,
    kMetronomeClickDurationMsMax,
  );
  final rev = (reverb ?? d.reverb).clamp(0.0, 1.0);
  final ech = (echo ?? d.echo).clamp(0.0, 1.0);
  return MetronomeClickSoundSettings(
    beatMidi: b,
    downbeatMidi: db,
    concertA4: concertA4 ?? d.concertA4,
    waveformIndex: validWi,
    preset: preset,
    clickDurationMs: dur,
    reverb: rev,
    echo: ech,
  );
}

/// Builds settings from legacy prefs (base MIDI, A4 Hz slider, accent offset).
MetronomeClickSoundSettings metronomeClickSoundSettingsFromLegacyPrefs({
  required int? baseMidi,
  required double? a4Hz,
  required int? accentOffsetSemitones,
  int? waveformIndex,
  int? presetIndex,
  double? clickDurationMs,
  double? reverb,
  double? echo,
}) {
  final base = (baseMidi ?? kMetronomeClickDefaultBeatMidi).clamp(
    kMetronomeClickMidiMin,
    kMetronomeClickMidiMax,
  );
  final off = accentOffsetSemitones ?? -12;
  final rawDown = base + off;
  final down = rawDown.clamp(kMetronomeClickMidiMin, kMetronomeClickMidiMax);

  var concert = true;
  if (a4Hz != null) {
    final dist440 = (a4Hz - kMetronomeReferenceA4ConcertHz).abs();
    final dist432 = (a4Hz - kMetronomeReferenceA4AlternateHz).abs();
    concert = dist440 <= dist432;
  }

  return metronomeClickSoundSettingsFromPrefs(
    beatMidi: base,
    downbeatMidi: down,
    concertA4: concert,
    waveformIndex: waveformIndex,
    presetIndex: presetIndex,
    clickDurationMs: clickDurationMs,
    reverb: reverb,
    echo: echo,
  );
}
