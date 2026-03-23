import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/app_shell.dart';
import 'package:metrotuner/core/audio/audio_engine.dart';
import 'package:metrotuner/features/metronome/metronome_notifier.dart';
import 'package:metrotuner/features/settings/accent_settings.dart';
import 'package:metrotuner/features/settings/metronome_click_sound_notifier.dart';
import 'package:metrotuner/features/settings/tuner_strip_edge_settings.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';
import 'package:metrotuner/ui/theme/app_theme.dart';

/// Root widget for MetroTuner (metronome + chromatic tuner).
class MetroTunerApp extends ConsumerStatefulWidget {
  /// Creates the app root widget.
  const MetroTunerApp({super.key});

  @override
  ConsumerState<MetroTunerApp> createState() => _MetroTunerAppState();
}

class _MetroTunerAppState extends ConsumerState<MetroTunerApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: _onAppDetached,
      onPause: _onAppPaused,
      onHide: _onAppPaused,
    );
    unawaited(ref.read(accentSeedProvider.notifier).loadFromPrefs());
    unawaited(ref.read(tunerStripEdgeProvider.notifier).loadFromPrefs());
    unawaited(ref.read(metronomeProvider.notifier).loadMeterFromPrefs());
    unawaited(ref.read(metronomeClickSoundProvider.notifier).loadFromPrefs());
  }

  void _onAppPaused() {
    ref.read(metronomeProvider.notifier).stop();
    unawaited(ref.read(tunerProvider.notifier).stop());
  }

  /// Release audio, mic, and timers when the Flutter engine is torn down.
  void _onAppDetached() {
    ref.read(metronomeProvider.notifier).stop();
    ref.invalidate(tunerProvider);
    AudioEngine.instance.dispose();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentSeedProvider);
    return MaterialApp(
      title: 'MetroTuner',
      theme: buildAppTheme(accentSeed: accent),
      themeMode: ThemeMode.dark,
      home: const AppShell(),
    );
  }
}
