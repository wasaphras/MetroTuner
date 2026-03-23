import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/pitch/pitch_types.dart';
import 'package:metrotuner/core/pitch/tuner_audio_controller.dart';
import 'package:permission_handler/permission_handler.dart';

/// UI state for the chromatic tuner (mic transport + latest pitch estimate).
class TunerState {
  /// Creates tuner state.
  const TunerState({
    required this.isRunning,
    required this.latestPitch,
    required this.permissionDenied,
    required this.startFailed,
  });

  /// Default: stopped, no pitch, no errors.
  factory TunerState.initial() => const TunerState(
    isRunning: false,
    latestPitch: null,
    permissionDenied: false,
    startFailed: false,
  );

  final bool isRunning;

  /// Last pitch sample from the detector (may be null when gated).
  final PitchResult? latestPitch;

  /// Microphone permission was denied (or not granted) on last start attempt.
  final bool permissionDenied;

  /// True when the audio backend failed to start for a non-permission reason.
  final bool startFailed;

  TunerState copyWith({
    bool? isRunning,
    bool? permissionDenied,
    bool? startFailed,
    bool clearPitch = false,
  }) {
    return TunerState(
      isRunning: isRunning ?? this.isRunning,
      latestPitch: clearPitch ? null : latestPitch,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      startFailed: startFailed ?? this.startFailed,
    );
  }

  /// Updates the latest pitch sample (including to null when the detector gates).
  TunerState withLatestPitch(PitchResult? pitch) {
    return TunerState(
      isRunning: isRunning,
      latestPitch: pitch,
      permissionDenied: permissionDenied,
      startFailed: startFailed,
    );
  }
}

/// Controls mic capture and pitch stream for the tuner screen.
class TunerNotifier extends Notifier<TunerState> {
  TunerAudioController? _controller;
  StreamSubscription<PitchResult?>? _pitchSub;

  @override
  TunerState build() {
    _controller = TunerAudioController();
    ref.onDispose(() {
      unawaited(_tearDown());
    });
    return TunerState.initial();
  }

  Future<void> _tearDown() async {
    await _pitchSub?.cancel();
    _pitchSub = null;
    final c = _controller;
    _controller = null;
    if (c != null) {
      await c.dispose();
    }
  }

  /// Starts listening; shows system permission dialog when needed.
  Future<void> start() async {
    final c = _controller;
    if (c == null || state.isRunning) {
      return;
    }
    state = state.copyWith(
      permissionDenied: false,
      startFailed: false,
      clearPitch: true,
    );
    final ok = await c.start();
    if (!ok) {
      final mic = await Permission.microphone.status;
      final denied = !mic.isGranted;
      state = state.copyWith(
        permissionDenied: denied,
        startFailed: !denied,
        isRunning: false,
      );
      return;
    }
    state = state.copyWith(isRunning: true);
    await _pitchSub?.cancel();
    _pitchSub = c.pitchStream.listen(
      (pitch) {
        state = state.withLatestPitch(pitch);
      },
      onError: (_) {
        state = state.copyWith(startFailed: true);
      },
    );
  }

  /// Stops the mic and pitch updates.
  Future<void> stop() async {
    final c = _controller;
    if (c == null || !state.isRunning) {
      return;
    }
    await _pitchSub?.cancel();
    _pitchSub = null;
    await c.stop();
    state = state.copyWith(
      isRunning: false,
      clearPitch: true,
      permissionDenied: false,
      startFailed: false,
    );
  }

  /// Clears error flags after the user acknowledges messaging.
  void clearErrors() {
    state = state.copyWith(
      permissionDenied: false,
      startFailed: false,
    );
  }
}

/// Global tuner controller (same lifetime pattern as the metronome provider).
final tunerProvider = NotifierProvider<TunerNotifier, TunerState>(
  TunerNotifier.new,
);
