import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/app.dart';
import 'package:metrotuner/core/app/package_info_provider.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../integration_test/fake_tuner_notifier.dart';
import 'support/pump_until.dart';

/// Regenerate README images (1080×2400, same logical layout as Android tall phones):
///
/// ```bash
/// flutter test test/readme_screenshots_test.dart --update-goldens
/// ```
///
/// Then commit [docs/screenshots/*.png]. [PackageInfo.version] in overrides should
/// match [pubspec.yaml] `version` (name part before `+`).
void main() {
  testWidgets('README screenshots (golden)', (tester) async {
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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/tuner.png'),
    );

    await tester.tap(find.text('Metronome'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('BPM'), maxPumps: 2000);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/metronome.png'),
    );

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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/settings.png'),
    );
  });
}
