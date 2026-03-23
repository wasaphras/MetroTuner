import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/app_shell.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';

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

Future<void> _pumpShell(WidgetTester tester) async {
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
}

void main() {
  testWidgets('AppShell lays out at 320x568 and switches tabs', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await tester.pump();
    await _pumpShell(tester);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Metronome'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Metronome'), findsWidgets);

    await tester.tap(find.text('Tuner'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppShell lays out at 360x640 portrait', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await tester.pump();
    await _pumpShell(tester);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppShell lays out at 390x844 portrait', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await tester.pump();
    await _pumpShell(tester);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
