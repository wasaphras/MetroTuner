import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/app.dart';

void main() {
  testWidgets(
    'MetroTunerApp handles AppLifecycleState.detached without error',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MetroTunerApp()),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.detached,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('MetroTunerApp handles pause without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MetroTunerApp()),
    );

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
