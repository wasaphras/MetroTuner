import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/features/settings/settings_page.dart';

void main() {
  testWidgets('SettingsPage lays out on small viewport', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await tester.pump();
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Concert pitch'), findsOneWidget);
  });

  testWidgets('SettingsPage lays out at 360x640 portrait', (tester) async {
    final binding = tester.binding;
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await binding.setSurfaceSize(const Size(360, 640));
    await tester.pump();
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
