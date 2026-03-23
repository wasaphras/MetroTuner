import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/app_shell.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';
import 'package:metrotuner/features/tuner/tuner_page.dart';

import 'support/pump_until.dart';

/// Same pattern as tuner page tests — no real mic.
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
  testWidgets('AppShell switches between Metronome and Tuner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(_TestTunerNotifier.new),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );

    expect(find.text('Metronome'), findsWidgets);
    expect(find.text('Tuner'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(TunerPage), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);

    await tester.tap(find.text('Metronome'));
    await tester.pump();
    // IndexedStack swap is synchronous; wait for on-stage content, not a delay.
    await pumpUntilFound(tester, find.text('BPM'));
    expect(find.text('BPM'), findsOneWidget);

    await tester.tap(find.text('Tuner'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('Note'));
    expect(find.text('Note'), findsOneWidget);
  });
}
