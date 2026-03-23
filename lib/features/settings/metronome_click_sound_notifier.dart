import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/audio/audio_engine.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
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
      final concertStored = p.containsKey(kMetronomeClickConcertA4PrefsKey)
          ? p.getBool(kMetronomeClickConcertA4PrefsKey)
          : null;

      final MetronomeClickSoundSettings s;
      if (beatNew != null && downNew != null) {
        s = metronomeClickSoundSettingsFromPrefs(
          beatMidi: beatNew,
          downbeatMidi: downNew,
          concertA4: concertStored ?? true,
          waveformIndex: p.getInt(kMetronomeClickWaveformIndexPrefsKey),
          presetIndex: p.getInt(kMetronomeClickPresetIndexPrefsKey),
          clickDurationMs: p.getDouble(kMetronomeClickDurationMsPrefsKey),
          reverb: p.getDouble(kMetronomeClickReverbPrefsKey),
          echo: p.getDouble(kMetronomeClickEchoPrefsKey),
        );
      } else {
        s = metronomeClickSoundSettingsFromLegacyPrefs(
          baseMidi: p.getInt(kMetronomeClickBaseMidiPrefsKey),
          a4Hz: p.getDouble(kMetronomeClickA4HzPrefsKey),
          accentOffsetSemitones: p.getInt(kMetronomeClickAccentOffsetPrefsKey),
          waveformIndex: p.getInt(kMetronomeClickWaveformIndexPrefsKey),
          presetIndex: p.getInt(kMetronomeClickPresetIndexPrefsKey),
          clickDurationMs: p.getDouble(kMetronomeClickDurationMsPrefsKey),
          reverb: p.getDouble(kMetronomeClickReverbPrefsKey),
          echo: p.getDouble(kMetronomeClickEchoPrefsKey),
        );
      }
      state = s;
      AudioEngine.instance.applyClickSoundSettings(s);
      await _persist(s);
    } on Object {
      // Tests / platforms without prefs: keep default.
    }
  }

  Future<void> setSettings(MetronomeClickSoundSettings value) async {
    final s = metronomeClickSoundSettingsFromPrefs(
      beatMidi: value.beatMidi,
      downbeatMidi: value.downbeatMidi,
      concertA4: value.concertA4,
      waveformIndex: value.waveformIndex,
      presetIndex: value.preset.index,
      clickDurationMs: value.clickDurationMs,
      reverb: value.reverb,
      echo: value.echo,
    );
    state = s;
    AudioEngine.instance.applyClickSoundSettings(s);
    await _persist(s);
  }

  Future<void> _persist(MetronomeClickSoundSettings s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(kMetronomeClickBeatMidiPrefsKey, s.beatMidi);
      await p.setInt(kMetronomeClickDownbeatMidiPrefsKey, s.downbeatMidi);
      await p.setBool(kMetronomeClickConcertA4PrefsKey, s.concertA4);
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

/// Metronome click sound settings (pitch, reference A4, waveform).
final metronomeClickSoundProvider =
    NotifierProvider<MetronomeClickSoundNotifier, MetronomeClickSoundSettings>(
      MetronomeClickSoundNotifier.new,
    );
