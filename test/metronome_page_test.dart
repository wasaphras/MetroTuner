import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/features/metronome/metronome_notifier.dart';
import 'package:metrotuner/features/metronome/metronome_page.dart';
import 'package:metrotuner/features/metronome/metronome_sound_page.dart';

import 'support/pump_until.dart';

/// Pumps [MetronomePage] at a logical surface size; resets in tearDown.
Future<void> pumpMetronomeAtSize(
  WidgetTester tester,
  Size size,
) async {
  final binding = tester.binding;
  await binding.setSurfaceSize(size);
  addTearDown(() async {
    await binding.setSurfaceSize(null);
  });
  await tester.pump();
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: MetronomePage(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('MetronomePage shows BPM and Start', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MetronomePage(),
        ),
      ),
    );

    expect(find.text('Metronome'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Custom…'), findsOneWidget);
    expect(find.text('Custom length…'), findsOneWidget);
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Metronome sound'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('Tap tempo button is tappable', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MetronomePage(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Tap tempo'));
    await tester.tap(find.text('Tap tempo'));
    await tester.pump();
    await tester.ensureVisible(find.text('Tap tempo'));
    await tester.tap(find.text('Tap tempo'));
    await tester.pump();
  });

  testWidgets('Start and Stop metronome via tooltip', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MetronomePage(),
        ),
      ),
    );

    await tester.ensureVisible(find.byTooltip('Start metronome'));
    await tester.tap(find.byTooltip('Start metronome'));
    // Sweep bar runs a ticker while playing; avoid pumpAndSettle (never idles).
    await pumpUntilFound(tester, find.byTooltip('Stop metronome'));

    await tester.ensureVisible(find.byTooltip('Stop metronome'));
    await tester.tap(find.byTooltip('Stop metronome'));
    await tester.pump();
    // Beat timer is cancelled on stop. Avoid pumpAndSettle while transport
    // was running (sweep ticker); wait for the Start tooltip instead.
    await pumpUntilFound(tester, find.byTooltip('Start metronome'));
    expect(find.byTooltip('Start metronome'), findsOneWidget);
  });

  testWidgets('MetronomePage lays out on small phone viewport', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await tester.pump();
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MetronomePage(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'BPM +/- controls are visible and on-screen at narrow and typical widths',
    (tester) async {
      const sizes = <Size>[
        Size(240, 640),
        Size(260, 640),
        Size(280, 640),
        Size(320, 480),
        Size(360, 640),
        Size(390, 844),
      ];
      for (final size in sizes) {
        await pumpMetronomeAtSize(tester, size);
        expect(tester.takeException(), isNull, reason: 'size $size');

        final dec = find.byTooltip('Decrease BPM');
        final inc = find.byTooltip('Increase BPM');
        expect(dec, findsOneWidget, reason: 'size $size');
        expect(inc, findsOneWidget, reason: 'size $size');

        await tester.ensureVisible(dec);
        await tester.ensureVisible(inc);

        final rDec = tester.getRect(dec);
        final rInc = tester.getRect(inc);
        expect(rDec.shortestSide, greaterThan(0), reason: 'Decrease BPM at $size');
        expect(rInc.shortestSide, greaterThan(0), reason: 'Increase BPM at $size');

        final pageRect = tester.getRect(find.byType(MetronomePage).first);
        expect(
          rDec.left >= pageRect.left - 1 &&
              rDec.right <= pageRect.right + 1 &&
              rInc.left >= pageRect.left - 1 &&
              rInc.right <= pageRect.right + 1,
          isTrue,
          reason: 'BPM buttons within MetronomePage bounds at $size',
        );
      }
    },
  );

  testWidgets('MetronomePage lays out at 360x640 portrait', (tester) async {
    final binding = tester.binding;
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await binding.setSurfaceSize(const Size(360, 640));
    await tester.pump();
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MetronomePage(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Session preset 10 min then Start shows remaining', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MetronomePage(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('10 min'));
    await tester.tap(find.text('10 min'));
    await tester.pump();

    await tester.ensureVisible(find.byTooltip('Start metronome'));
    await tester.tap(find.byTooltip('Start metronome'));
    await pumpUntilFound(tester, find.byTooltip('Stop metronome'));

    expect(find.textContaining('Remaining'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop metronome'));
    await tester.pump();
  });

  testWidgets('Opening Metronome sound stops transport', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MetronomePage(),
        ),
      ),
    );

    await tester.ensureVisible(find.byTooltip('Start metronome'));
    await tester.tap(find.byTooltip('Start metronome'));
    await pumpUntilFound(tester, find.byTooltip('Stop metronome'));

    await tester.ensureVisible(find.text('Metronome sound'));
    await tester.tap(find.text('Metronome sound'));
    await pumpUntilFound(tester, find.byType(MetronomeSoundPage));

    expect(find.byType(MetronomeSoundPage), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MetronomeSoundPage)),
    );
    expect(container.read(metronomeProvider).isRunning, false);
  });
}
