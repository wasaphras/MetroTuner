import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/features/settings/tuner_strip_edge_settings.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';
import 'package:metrotuner/features/tuner/tuner_page.dart';

/// Test double: no microphone; transport toggles state only.
class TestStripEdgeRight extends TunerStripEdgeNotifier {
  @override
  TunerStripEdge build() => TunerStripEdge.right;
}

class TestTunerNotifier extends TunerNotifier {
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
  testWidgets('TunerPage shows readouts and Start', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(TestTunerNotifier.new),
        ],
        child: const MaterialApp(
          home: TunerPage(),
        ),
      ),
    );

    expect(find.text('Tuner'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Cents'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Start toggles to Stop with fake notifier', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(TestTunerNotifier.new),
        ],
        child: const MaterialApp(
          home: TunerPage(),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('Pitch strip has semantic label', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(TestTunerNotifier.new),
        ],
        child: const MaterialApp(
          home: TunerPage(),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Pitch strip, chromatic ruler from C2 through C8'),
      findsOneWidget,
    );
  });

  testWidgets('TunerPage lays out on small phone viewport', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await tester.pump();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(TestTunerNotifier.new),
        ],
        child: const MaterialApp(
          home: TunerPage(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Portrait layout with strip on right override', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(TestTunerNotifier.new),
          tunerStripEdgeProvider.overrideWith(TestStripEdgeRight.new),
        ],
        child: const MaterialApp(
          home: TunerPage(),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('Pitch strip, chromatic ruler from C2 through C8'),
      findsOneWidget,
    );
  });
}
