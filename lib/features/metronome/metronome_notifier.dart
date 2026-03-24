import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/audio/audio_engine.dart';
import 'package:metrotuner/core/metronome/metronome_models.dart';
import 'package:metrotuner/core/metronome/metronome_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for last meter (local only).
const String kMeterBeatsPrefsKey = 'metronome_meter_beats';
const String kMeterUnitPrefsKey = 'metronome_meter_unit';

/// Minimum / maximum timed session length (wall clock).
const Duration kMetronomeSessionTargetMin = Duration(seconds: 1);
const Duration kMetronomeSessionTargetMax = Duration(hours: 24);

const Object _kSessionTargetUnset = Object();

/// State for the metronome (BPM, meter, transport, UI beat flash).
class MetronomeState {
  /// Creates metronome state.
  const MetronomeState({
    required this.bpm,
    required this.meter,
    required this.isRunning,
    required this.sessionBeatIndex,
    required this.beatFlashGeneration,
    this.sessionTargetDuration,
  });

  /// Initial defaults: 120 BPM, 4/4, stopped.
  factory MetronomeState.initial() => const MetronomeState(
    bpm: MetronomeScheduler.defaultBpm,
    meter: Meter.fourFour,
    isRunning: false,
    sessionBeatIndex: 0,
    beatFlashGeneration: 0,
  );

  final int bpm;
  final Meter meter;
  final bool isRunning;

  /// 0-based count since last start; used for downbeat and scheduling.
  final int sessionBeatIndex;

  /// Increments on each audible beat so the UI can flash without relying on timers.
  final int beatFlashGeneration;

  /// Optional wall-clock cap for the current practice session; null means no limit.
  final Duration? sessionTargetDuration;

  MetronomeState copyWith({
    int? bpm,
    Meter? meter,
    bool? isRunning,
    int? sessionBeatIndex,
    int? beatFlashGeneration,
    Object? sessionTargetDuration = _kSessionTargetUnset,
  }) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      meter: meter ?? this.meter,
      isRunning: isRunning ?? this.isRunning,
      sessionBeatIndex: sessionBeatIndex ?? this.sessionBeatIndex,
      beatFlashGeneration: beatFlashGeneration ?? this.beatFlashGeneration,
      sessionTargetDuration: identical(sessionTargetDuration, _kSessionTargetUnset)
          ? this.sessionTargetDuration
          : sessionTargetDuration as Duration?,
    );
  }
}

/// Tap-to-tempo: stores recent tap intervals in microseconds.
class TapTempoBuffer {
  static const int maxIntervals = 5;

  int? _lastTapMicros;
  final List<int> _intervalMicros = [];

  /// Records a tap; use [estimateBpm] for a BPM from recent intervals.
  void tap() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final last = _lastTapMicros;
    _lastTapMicros = now;
    if (last == null) {
      return;
    }
    final delta = now - last;
    if (delta <= 0) {
      return;
    }
    _intervalMicros.add(delta);
    while (_intervalMicros.length > maxIntervals) {
      _intervalMicros.removeAt(0);
    }
  }

  void clear() {
    _lastTapMicros = null;
    _intervalMicros.clear();
  }

  /// Average BPM from stored intervals, or null if not enough taps.
  int? estimateBpm() {
    if (_intervalMicros.isEmpty) {
      return null;
    }
    final sum = _intervalMicros.fold<int>(0, (a, b) => a + b);
    final avg = sum / _intervalMicros.length;
    if (avg <= 0) {
      return null;
    }
    return MetronomeScheduler.clampBpm((60000000 / avg).round());
  }
}

/// Riverpod controller: start/stop, BPM, meter, tap tempo, and monotonic scheduling.
///
/// **Timed sessions:** `sessionTargetDuration` is wall-clock time from each `start`;
/// BPM/meter changes do not extend or shorten the deadline. Auto-stop uses the same
/// `stop` path as the user (beat + session timers cancelled).
///
/// **Target survives stop:** Opening the metronome sound screen (`openMetronomeSound`),
/// app pause/hide, or manual Stop ends transport but keeps the chosen target so the
/// next Start is still a timed session until cleared.
class MetronomeNotifier extends Notifier<MetronomeState> {
  final Stopwatch _stopwatch = Stopwatch();
  final TapTempoBuffer _tapTempo = TapTempoBuffer();
  int _scheduleGeneration = 0;
  int _beatIndex = 0;
  Timer? _beatTimer;
  Timer? _sessionEndTimer;

  @override
  MetronomeState build() => MetronomeState.initial();

  /// Loads saved meter from disk; safe to call on startup (ignores invalid data).
  Future<void> loadMeterFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final b = p.getInt(kMeterBeatsPrefsKey);
      final u = p.getInt(kMeterUnitPrefsKey);
      if (b == null || u == null) {
        return;
      }
      final m = Meter(b, u);
      state = state.copyWith(meter: m);
    } on Object {
      // Invalid prefs or missing plugin: keep default.
    }
  }

  Future<void> _persistMeter(Meter value) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(kMeterBeatsPrefsKey, value.beatsPerBar);
      await p.setInt(kMeterUnitPrefsKey, value.beatUnit);
    } on Exception {
      // Best-effort only.
    }
  }

  void setBpm(int value) {
    final v = MetronomeScheduler.clampBpm(value);
    state = state.copyWith(bpm: v);
  }

  void setMeter(Meter value) {
    state = state.copyWith(meter: value);
    unawaited(_persistMeter(value));
  }

  void incrementBpm() => setBpm(state.bpm + 1);

  void decrementBpm() => setBpm(state.bpm - 1);

  /// Sets or clears the timed session cap (clamped to [kMetronomeSessionTargetMin],
  /// [kMetronomeSessionTargetMax]). Reschedules the session end timer if running.
  void setSessionTargetDuration(Duration? value) {
    final clamped = _clampSessionTarget(value);
    state = state.copyWith(sessionTargetDuration: clamped);
    if (state.isRunning) {
      _scheduleSessionEndTimer();
    }
  }

  /// Clears the session target (open-ended practice).
  void clearSessionTarget() => setSessionTargetDuration(null);

  Duration? _clampSessionTarget(Duration? value) {
    if (value == null) {
      return null;
    }
    if (value < kMetronomeSessionTargetMin) {
      return kMetronomeSessionTargetMin;
    }
    if (value > kMetronomeSessionTargetMax) {
      return kMetronomeSessionTargetMax;
    }
    return value;
  }

  void _cancelSessionEndTimer() {
    _sessionEndTimer?.cancel();
    _sessionEndTimer = null;
  }

  /// Wall-clock remainder until auto-stop; null if no target or not running.
  Duration? get sessionRemainingOrNull {
    final target = state.sessionTargetDuration;
    if (target == null || !state.isRunning) {
      return null;
    }
    final left = target - _stopwatch.elapsed;
    return left <= Duration.zero ? Duration.zero : left;
  }

  /// Monotonic time since last [start], for sweep UI; zero when not running.
  int get transportElapsedMicros =>
      state.isRunning ? _stopwatch.elapsedMicroseconds : 0;

  /// Registers a tap for tap-to-set-BPM (does not start transport).
  void registerTapTempo() {
    _tapTempo.tap();
    final bpm = _tapTempo.estimateBpm();
    if (bpm != null) {
      state = state.copyWith(bpm: bpm);
    }
  }

  /// Starts scheduling beats from the next downbeat-aligned instant.
  void start() {
    if (state.isRunning) {
      return;
    }
    final gen = ++_scheduleGeneration;
    _beatIndex = 0;
    _stopwatch
      ..reset()
      ..start();
    state = state.copyWith(
      isRunning: true,
      sessionBeatIndex: 0,
    );
    _scheduleNext(gen);
    _scheduleSessionEndTimer();
  }

  void _scheduleSessionEndTimer() {
    _cancelSessionEndTimer();
    final target = state.sessionTargetDuration;
    if (target == null || !state.isRunning) {
      return;
    }
    final remaining = target - _stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      stop();
      return;
    }
    _sessionEndTimer = Timer(remaining, () {
      if (state.isRunning) {
        stop();
      }
    });
  }

  void _scheduleNext(int gen) {
    if (gen != _scheduleGeneration) {
      return;
    }
    if (!state.isRunning) {
      return;
    }
    final bpm = state.bpm;
    final interval = MetronomeScheduler.beatIntervalMicros(bpm);
    final wait = MetronomeScheduler.delayUntilBeatMicros(
      beatIndex: _beatIndex,
      bpm: bpm,
      elapsedMicros: _stopwatch.elapsedMicroseconds,
      phaseOffsetMicros: interval ~/ 2,
    );
    _beatTimer?.cancel();
    _beatTimer = Timer(Duration(microseconds: wait), () {
      if (gen != _scheduleGeneration) {
        return;
      }
      if (!state.isRunning) {
        return;
      }
      final beats = state.meter.beatsPerBar;
      final accent = MetronomeScheduler.isDownbeat(
        beatIndex: _beatIndex,
        beatsPerBar: beats,
      );
      AudioEngine.instance.playMetronomeClick(accent: accent);
      state = state.copyWith(
        sessionBeatIndex: _beatIndex,
        beatFlashGeneration: state.beatFlashGeneration + 1,
      );
      _beatIndex++;
      _scheduleNext(gen);
    });
  }

  /// Stops the metronome and cancels pending scheduled beats.
  void stop() {
    if (!state.isRunning) {
      return;
    }
    _beatTimer?.cancel();
    _beatTimer = null;
    _cancelSessionEndTimer();
    _scheduleGeneration++;
    _stopwatch.stop();
    state = state.copyWith(isRunning: false);
  }
}

/// Global metronome controller (not auto-dispose so transport survives navigation).
final metronomeProvider = NotifierProvider<MetronomeNotifier, MetronomeState>(
  MetronomeNotifier.new,
);
