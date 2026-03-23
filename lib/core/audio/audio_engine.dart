import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
import 'package:metrotuner/core/audio/metronome_echo_mapping.dart';
import 'package:metrotuner/core/pitch/note_math.dart';

/// Singleton facade over SoLoud for MetroTuner playback (metronome; later
/// tuner output).
///
/// Call [ensureInitialized] once before playing. Call [dispose] on app exit
/// (detached lifecycle) or when tearing down tests.
///
/// If the native plugin cannot load (e.g. some `flutter_test` hosts),
/// initialization fails silently and clicks become no-ops.
///
/// Echo filter (wet/delay/decay) approximates room and slapback; per-voice
/// params are not supported on Web ([kIsWeb]), where only click length applies.
class AudioEngine {
  AudioEngine._();

  /// Shared engine instance for the app process.
  static final AudioEngine instance = AudioEngine._();

  Future<void>? _initFuture;

  /// True only after SoLoud init and waveform load succeed.
  bool _nativeReady = false;

  AudioSource? _tickNormal;
  AudioSource? _tickAccent;

  MetronomeClickSoundSettings _clickSettings =
      MetronomeClickSoundSettings.defaults();

  /// Whether SoLoud is usable for playback.
  bool get isInitialized => _nativeReady;

  /// Initializes SoLoud with a small buffer for lower click latency and loads
  /// waveform clicks (accent vs beat).
  Future<void> ensureInitialized() async {
    if (_nativeReady) {
      return;
    }
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = _doInit();
    await _initFuture;
  }

  Future<void> _doInit() async {
    try {
      await SoLoud.instance.init(
        bufferSize: 512,
        channels: Channels.mono,
      );
      _tickNormal = await SoLoud.instance.loadWaveform(
        WaveForm.triangle,
        false,
        0.35,
        1,
      );
      SoLoud.instance.setWaveformFreq(_tickNormal!, 880);
      _tickAccent = await SoLoud.instance.loadWaveform(
        WaveForm.triangle,
        false,
        0.55,
        1,
      );
      SoLoud.instance.setWaveformFreq(_tickAccent!, 440);
      if (!kIsWeb) {
        try {
          _tickNormal!.filters.echoFilter.activate();
          _tickAccent!.filters.echoFilter.activate();
        } on Object {
          // Single-sound filters unavailable on some backends.
        }
      }
      _nativeReady = true;
      applyClickSoundSettings(
        MetronomeClickSoundSettings.defaults(),
        referenceA4Hz: NoteMath.defaultA4Hz,
      );
    } on Object {
      _nativeReady = false;
      _tickNormal = null;
      _tickAccent = null;
    }
  }

  /// Updates waveform frequency, shape, and scales for both click sources.
  /// Cheap to call when settings change; [playMetronomeClick] uses last applied
  /// settings.
  void applyClickSoundSettings(
    MetronomeClickSoundSettings settings, {
    required double referenceA4Hz,
  }) {
    _clickSettings = settings;
    if (!_nativeReady) {
      return;
    }
    final normal = _tickNormal;
    final accent = _tickAccent;
    if (normal == null || accent == null) {
      return;
    }
    final idx = settings.effectiveWaveformIndex.clamp(
      0,
      kMetronomeClickWaveformIndexMax,
    );
    final wf = WaveForm.values[idx];
    SoLoud.instance.setWaveform(normal, wf);
    SoLoud.instance.setWaveform(accent, wf);
    SoLoud.instance.setWaveformFreq(normal, settings.normalHz(referenceA4Hz));
    SoLoud.instance.setWaveformFreq(accent, settings.accentHz(referenceA4Hz));
    // Gain uses per-play volume; Basicwave ignores scale when superwave is off.
    SoLoud.instance.setWaveformScale(normal, 1);
    SoLoud.instance.setWaveformScale(accent, 1);
  }

  /// Plays one metronome click. [accent] is true for the downbeat.
  void playMetronomeClick({required bool accent}) {
    if (!_nativeReady) {
      return;
    }
    final source = accent ? _tickAccent : _tickNormal;
    if (source == null) {
      return;
    }
    final s = _clickSettings;
    unawaited(_playClick(source: source, settings: s, accent: accent));
  }

  Future<void> _playClick({
    required AudioSource source,
    required MetronomeClickSoundSettings settings,
    required bool accent,
  }) async {
    try {
      final handle = await SoLoud.instance.play(
        source,
        volume: accent ? 0.55 : 0.35,
      );
      var ms = settings.clampedClickDurationMs;
      if (accent) {
        ms = (ms * 1.12).clamp(
          kMetronomeClickDurationMsMin,
          kMetronomeClickDurationMsMax,
        );
      }
      final dur = Duration(milliseconds: ms.round().clamp(1, 500));
      SoLoud.instance.scheduleStop(handle, dur);
      if (!kIsWeb) {
        try {
          _applyEchoParams(
            source: source,
            handle: handle,
            params: metronomeEchoParamsFromSliders(
              reverb: settings.clampedReverb,
              echo: settings.clampedEcho,
            ),
          );
        } on Object {
          // Ignore filter errors (e.g. handle invalid).
        }
      }
    } on Object {
      // Play can fail if engine is torn down.
    }
  }

  /// Maps room + echo sliders to SoLoud echo wet/delay/decay (mono-safe).
  static void _applyEchoParams({
    required AudioSource source,
    required SoundHandle handle,
    required MetronomeEchoMappedParams params,
  }) {
    final f = source.filters.echoFilter;
    f.wet(soundHandle: handle).value = params.wet;
    f.delay(soundHandle: handle).value = params.delaySeconds;
    f.decay(soundHandle: handle).value = params.decay;
  }

  /// Stops the engine and releases native audio resources.
  void dispose() {
    if (!_nativeReady) {
      return;
    }
    _tickNormal = null;
    _tickAccent = null;
    _nativeReady = false;
    _initFuture = null;
    SoLoud.instance.deinit();
  }
}
