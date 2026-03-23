import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:metrotuner/app.dart';
import 'package:metrotuner/bootstrap.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';

import '../test/support/pump_until.dart';
import 'fake_tuner_notifier.dart';

/// Frame-budget for slow devices / integration binding (no fixed wall-clock sleep).
const int _kIntegrationMaxPumps = 2000;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open app, metronome start/stop, tuner start/stop', (tester) async {
    await bootstrapMetrotuner();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(FakeTunerNotifier.new),
        ],
        child: const MetroTunerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.text('Metronome'),
      maxPumps: _kIntegrationMaxPumps,
    );

    await tester.tap(find.text('Metronome'));
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.text('BPM'),
      maxPumps: _kIntegrationMaxPumps,
    );

    await tester.tap(find.byTooltip('Start metronome'));
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byTooltip('Stop metronome'),
      maxPumps: _kIntegrationMaxPumps,
    );
    await tester.tap(find.byTooltip('Stop metronome'));
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byTooltip('Start metronome'),
      maxPumps: _kIntegrationMaxPumps,
    );

    await tester.tap(find.text('Tuner'));
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.text('Note'),
      maxPumps: _kIntegrationMaxPumps,
    );

    await tester.tap(find.bySemanticsLabel('Start microphone and tuner'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.text('Stop'),
      maxPumps: _kIntegrationMaxPumps,
    );

    await tester.tap(find.bySemanticsLabel('Stop microphone and tuner'));
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.text('Start'),
      maxPumps: _kIntegrationMaxPumps,
    );
  });
}
