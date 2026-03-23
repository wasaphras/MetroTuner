import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/features/settings/reference_concert_pitch_notifier.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// General setting: concert A4 (440 Hz) vs 432 Hz for tuner and metronome clicks.
class ConcertPitchSection extends ConsumerWidget {
  /// Creates the concert pitch controls.
  const ConcertPitchSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.mtTheme;
    final concert = ref.watch(referenceConcertPitchProvider);
    final notifier = ref.read(referenceConcertPitchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Concert pitch',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: t.space4),
        Text(
          'Reference A4 for the tuner and metronome click pitches.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: t.space8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: true,
              label: Text('440 Hz'),
              tooltip: 'Concert A4',
            ),
            ButtonSegment<bool>(
              value: false,
              label: Text('432 Hz'),
              tooltip: 'Alternate reference',
            ),
          ],
          selected: <bool>{concert},
          onSelectionChanged: (set) {
            if (set.isEmpty) {
              return;
            }
            unawaited(notifier.setConcertA4(concert: set.first));
          },
        ),
      ],
    );
  }
}
