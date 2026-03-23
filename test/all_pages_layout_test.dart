import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/app_shell.dart';
import 'package:metrotuner/features/metronome/metronome_page.dart';
import 'package:metrotuner/features/metronome/metronome_sound_page.dart';
import 'package:metrotuner/features/settings/settings_page.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';
import 'package:metrotuner/features/tuner/tuner_page.dart';

import 'support/layout_assertions.dart';

/// Test double: no microphone.
class _TestTunerNotifier extends TunerNotifier {
  @override
  TunerState build() => TunerState.initial();

  @override
  Future<void> start() async {
    state = state.copyWith(
      isRunning: true,
      permissionDenied: false,
      startFailed: false,
      clearPitch: true,
    );
  }

  @override
  Future<void> stop() async {
    state = state.copyWith(
      isRunning: false,
      clearPitch: true,
    );
  }
}

void main() {
  const sizes = <Size>[
    Size(240, 640),
    Size(260, 640),
    Size(280, 640),
    Size(320, 480),
    Size(360, 320),
    Size(360, 640),
    Size(390, 844),
    Size(667, 375),
    Size(844, 390),
  ];

  final tunerOverrides = [
    tunerProvider.overrideWith(_TestTunerNotifier.new),
  ];

  for (final size in sizes) {
    testWidgets('MetronomePage lays out without overflow at $size', (tester) async {
      await pumpWidgetExpectNoOverflow(
        tester,
        size,
        const ProviderScope(
          child: MaterialApp(
            home: MetronomePage(),
          ),
        ),
      );
    });

    testWidgets('TunerPage lays out without overflow at $size', (tester) async {
      await pumpWidgetExpectNoOverflow(
        tester,
        size,
        ProviderScope(
          overrides: tunerOverrides,
          child: const MaterialApp(
            home: TunerPage(),
          ),
        ),
      );
    });

    testWidgets('SettingsPage lays out without overflow at $size', (tester) async {
      await pumpWidgetExpectNoOverflow(
        tester,
        size,
        const ProviderScope(
          child: MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );
    });

    testWidgets('AppShell lays out without overflow at $size', (tester) async {
      await pumpWidgetExpectNoOverflow(
        tester,
        size,
        ProviderScope(
          overrides: tunerOverrides,
          child: const MaterialApp(
            home: AppShell(),
          ),
        ),
      );
    });

    testWidgets('MetronomeSoundPage lays out without overflow at $size',
        (tester) async {
      await pumpWidgetExpectNoOverflow(
        tester,
        size,
        const ProviderScope(
          child: MaterialApp(
            home: MetronomeSoundPage(),
          ),
        ),
      );
    });
  }
}
