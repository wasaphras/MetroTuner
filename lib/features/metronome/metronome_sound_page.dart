import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/features/metronome/metronome_notifier.dart';
import 'package:metrotuner/features/settings/metronome_click_settings.dart';
import 'package:metrotuner/ui/layout/adaptive_breakpoints.dart';
import 'package:metrotuner/ui/layout/phone_layout.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// Fraction of body height used for the scrollable metronome sound controls.
const double _kMetronomeSoundScrollHeightFraction = 0.92;

/// Pushes [MetronomeSoundPage] on the current navigator.
///
/// Stops transport if the metronome was playing so click preview and beats do
/// not overlap.
///
/// Timed session target ([MetronomeState.sessionTargetDuration]) is **not**
/// cleared here — only [MetronomeNotifier.stop] runs. The next Start on the
/// metronome tab begins a fresh run toward the same target.
void openMetronomeSound(BuildContext context) {
  ProviderScope.containerOf(context).read(metronomeProvider.notifier).stop();
  unawaited(
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const MetronomeSoundPage(),
      ),
    ),
  );
}

/// Full-screen metronome click synthesis, pitch, effects, and preview.
class MetronomeSoundPage extends ConsumerWidget {
  /// Creates the metronome sound screen.
  const MetronomeSoundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.mtTheme;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome sound'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = AdaptiveBreakpoints.useCompactVerticalLayout(
              constraints: constraints,
            );
            final m = PhoneLayoutMetrics.fromConstraints(constraints);
            final bottomPad = compact ? m.scale(t.space16) : m.scale(t.space32);
            final maxH = constraints.maxHeight * _kMetronomeSoundScrollHeightFraction;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 640,
                  maxHeight: maxH,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    m.scale(t.space24),
                    m.scale(t.space8),
                    m.scale(t.space24),
                    bottomPad,
                  ),
                  children: [
                    Text(
                      'Beat and downbeat pitch, timbre, A4 reference, and effects.',
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: m.scale(t.space20)),
                    const MetronomeClickSoundSection(showHeading: false),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
