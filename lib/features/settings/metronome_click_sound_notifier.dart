import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/audio/audio_engine.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
import 'package:metrotuner/features/settings/reference_concert_pitch_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and applies metronome click synthesis (local only).
class MetronomeClickSoundNotifier
    extends Notifier<MetronomeClickSoundSettings> {
  @override
  MetronomeClickSoundSettings build() => MetronomeClickSoundSettings.defaults();

  Future<void> loadFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final beatNew = p.getInt(kMetronomeClickBeatMidiPrefsKey);
      final downNew = p.getInt(kMetronomeClickDownbeatMidiPrefsKey);

      final MetronomeClickSoundSettings s;
      if (beatNew != null && downNew != null) {
        s = metronomeClickSoundSettingsFromPrefs(
          beatMidi: beatNew,
          downbeatMidi: downNew,
          waveformIndex: p.getInt(kMetronomeClickWaveformIndexPrefsKey),
          presetIndex: p.getInt(kMetronomeClickPresetIndexPrefsKey),
          clickDurationMs: p.getDouble(kMetronomeClickDurationMsPrefsKey),
          reverb: p.getDouble(kMetronomeClickReverbPrefsKey),
          echo: p.getDouble(kMetronomeClickEchoPrefsKey),
        );
      } else {
        s = metronomeClickSoundSettingsFromLegacyPrefs(
          baseMidi: p.getInt(kMetronomeClickBaseMidiPrefsKey),
          accentOffsetSemitones: p.getInt(kMetronomeClickAccentOffsetPrefsKey),
          waveformIndex: p.getInt(kMetronomeClickWaveformIndexPrefsKey),
          presetIndex: p.getInt(kMetronomeClickPresetIndexPrefsKey),
          clickDurationMs: p.getDouble(kMetronomeClickDurationMsPrefsKey),
          reverb: p.getDouble(kMetronomeClickReverbPrefsKey),
          echo: p.getDouble(kMetronomeClickEchoPrefsKey),
        );
      }
      state = s;
      final refHz = referenceA4HzFromConcert(
        concert: ref.read(referenceConcertPitchProvider),
      );
      AudioEngine.instance.applyClickSoundSettings(s, referenceA4Hz: refHz);
      await _persist(s);
    } on Object {
      // Tests / platforms without prefs: keep default.
    }
  }

  Future<void> setSettings(MetronomeClickSoundSettings value) async {
    final s = metronomeClickSoundSettingsFromPrefs(
      beatMidi: value.beatMidi,
      downbeatMidi: value.downbeatMidi,
      waveformIndex: value.waveformIndex,
      presetIndex: value.preset.index,
      clickDurationMs: value.clickDurationMs,
      reverb: value.reverb,
      echo: value.echo,
    );
    state = s;
    final refHz = referenceA4HzFromConcert(
      concert: ref.read(referenceConcertPitchProvider),
    );
    AudioEngine.instance.applyClickSoundSettings(s, referenceA4Hz: refHz);
    await _persist(s);
  }

  Future<void> _persist(MetronomeClickSoundSettings s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(kMetronomeClickBeatMidiPrefsKey, s.beatMidi);
      await p.setInt(kMetronomeClickDownbeatMidiPrefsKey, s.downbeatMidi);
      await p.setInt(kMetronomeClickWaveformIndexPrefsKey, s.waveformIndex);
      await p.setInt(kMetronomeClickPresetIndexPrefsKey, s.preset.index);
      await p.setDouble(kMetronomeClickDurationMsPrefsKey, s.clickDurationMs);
      await p.setDouble(kMetronomeClickReverbPrefsKey, s.reverb);
      await p.setDouble(kMetronomeClickEchoPrefsKey, s.echo);
    } on Exception {
      // Best-effort only.
    }
  }
}

/// Metronome click sound settings (MIDI pitch, waveform, effects).
final metronomeClickSoundProvider =
    NotifierProvider<MetronomeClickSoundNotifier, MetronomeClickSoundSettings>(
      MetronomeClickSoundNotifier.new,
    );
