import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/app.dart';
import 'package:metrotuner/core/app/package_info_provider.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../integration_test/fake_tuner_notifier.dart';
import 'support/pump_until.dart';

/// Same navigation as README screenshots in docs/screenshots/ (those PNGs come from a
/// release Android capture at 1080×2400; see docs/screenshots/README.md).
void main() {
  testWidgets('README screenshot navigation smoke test', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    final fakePackageInfo = PackageInfo(
      appName: 'MetroTuner',
      packageName: 'com.wasaphras.metrotuner',
      version: '1.1.1',
      buildNumber: '4',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tunerProvider.overrideWith(FakeTunerNotifier.new),
          packageInfoProvider.overrideWith((ref) async => fakePackageInfo),
        ],
        child: const MetroTunerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.text('Start'), maxPumps: 2000);
    await tester.pumpAndSettle();
    expect(find.text('Tuner'), findsWidgets);

    await tester.tap(find.text('Metronome'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('BPM'), maxPumps: 2000);
    await tester.pumpAndSettle();
    expect(find.text('Metronome'), findsWidgets);

    await tester.tap(find.text('Tuner'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('Start'), maxPumps: 2000);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('General'), maxPumps: 2000);
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Version 1.1.1'), maxPumps: 2000);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
